# Deal Management System - Complete Implementation Guide

## Overview

The Jeton Deal Management System provides a complete CRUD workflow for managing sales deals through a visual pipeline (Kanban board). Users can create deals, edit them, move them between pipeline stages, and delete them.

## System Architecture

### Route Structure

```
/app/pipeline                    Main pipeline view with Kanban board
/app/deals/create               Create a new deal form
/app/deals/edit/[id]            Edit existing deal form with delete capability
/api/deals                       REST API endpoint for CRUD operations
/api/deals/[id]                 REST API endpoint for single deal operations
/api/staff                       Staff list endpoint (for deal assignment)
/api/valuation                   Valuation metrics endpoint
```

### Database Schema

```sql
deals (
  id                 INTEGER PRIMARY KEY,
  title              VARCHAR(255),
  description        TEXT,
  value_estimate     BIGINT,           -- Amount in UGX (canonical currency)
  probability        INTEGER (0-100),  -- Deal win probability
  stage              VARCHAR(50),      -- Pipeline stage
  assigned_to        INTEGER,          -- FK to staff
  expected_close_date DATE,            -- Expected close date
  created_at         TIMESTAMP,
  updated_at         TIMESTAMP
)
```

### Pipeline Stages

```
Lead                 → Initial opportunity
Contacted            → Initial contact made
Proposal Sent        → Proposal presented
Negotiation          → Active negotiation phase
Won                  → Deal won (final stage)
Lost                 → Deal lost (final stage)
```

## Component Architecture

### Key Components

1. **Pipeline Page** (`/app/app/pipeline/page.js`)
   - Main pipeline view
   - Displays metrics: total value, weighted value, won/lost totals
   - Kanban board with drag-and-drop
   - "New Deal" button linking to create form

2. **Create Deal Form** (`/app/app/deals/create/page.js`)
   - Form inputs:
     - Title (required)
     - Description
     - Value Estimate (required, in currency)
     - Probability (0-100% slider)
     - Stage (dropdown select)
     - Assigned To (staff dropdown)
     - Expected Close Date (date picker)
   - Features:
     - Real-time weighted value calculation (value × probability%)
     - Currency display integration
     - Form validation
     - Loading states
     - Error handling with user feedback
     - POST to `/api/deals`
     - Redirect to pipeline on success

3. **Edit Deal Form** (`/app/app/deals/edit/[id]/page.js`)
   - All features from Create Deal Form
   - Pre-fills existing deal data
   - PUT endpoint for updates
   - Delete button with confirmation dialog
   - 404 handling for missing deals
   - Proper date formatting for date input

4. **Pipeline Card** (`/src/components/financial/PipelineCard.js`)
   - Individual deal display
   - Shows:
     - Deal title
     - Client name
     - Value estimate
     - Expected value (calculated)
     - Probability bar
     - Expected close date
   - Actions:
     - Edit button → links to `/app/deals/edit/[id]`
     - Delete button → inline delete with API call

5. **Pipeline Board** (`/src/components/financial/PipelineBoard.js`)
   - Kanban board layout
   - Drag-and-drop stage transitions
   - Smooth animations
   - Responsive grid layout

6. **Currency Display** (`/src/components/common/CurrencyDisplay.js`)
   - Converts canonical UGX amounts to display currency
   - User-selected currency display
   - Maintains UGX as source of truth

## User Workflows

### Creating a Deal

1. Navigate to `/app/pipeline`
2. Click "New Deal" button
3. Fill deal form:
   - Enter title (required)
   - Enter description (optional)
   - Enter value estimate (required, in UGX)
   - Set probability with slider (0-100%)
   - Select stage from dropdown
   - Select assigned staff member
   - Set expected close date (optional)
4. Watch real-time weighted value calculation
5. Click "Save Deal"
6. System creates deal via POST to `/api/deals`
7. Redirect to pipeline on success
8. New deal appears in selected stage

**Error Handling:**
- Missing required fields → Form validation prevents submission
- API errors → Display error message, allow user to retry
- Unauthorized → Redirect to login

### Editing a Deal

1. From pipeline view, click "Edit" button on a deal card
2. Navigate to `/app/deals/edit/[id]`
3. Form pre-fills with existing deal data
4. Modify any field
5. Updated weighted value displays in real-time
6. Click "Save Changes"
7. System updates deal via PUT to `/api/deals/[id]`
8. Redirect to pipeline on success

**Alternative: Quick Delete**
- From edit form, click "Delete Deal"
- Confirmation dialog appears
- Confirm deletion
- System deletes deal via DELETE to `/api/deals/[id]`
- Redirect to pipeline

### Moving Deal Between Stages

1. From pipeline view, locate deal in current stage
2. Drag deal card to target stage
3. System updates deal stage via PUT to `/api/deals/[id]`
4. Deal smoothly animates to new stage column
5. Metrics update in real-time

### Deleting a Deal

**Option 1: From Edit Form**
- Open edit form
- Click "Delete Deal"
- Confirm in dialog
- Deal deleted

**Option 2: Quick Delete from Pipeline**
- Click "Delete" button on deal card
- Confirm in dialog
- Deal deleted from pipeline
- Metrics update automatically

## API Integration

### Authentication

All API requests require Bearer token:
```javascript
headers: {
  'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
}
```

### Endpoints

#### GET /api/deals
Retrieve all deals
```javascript
Response: {
  deals: [
    {
      id: 1,
      title: "Acme Corp Contract",
      value_estimate: 50000000,
      probability: 75,
      stage: "Negotiation",
      assigned_to: 3,
      expected_close_date: "2024-12-31"
    }
  ]
}
```

#### POST /api/deals
Create a new deal
```javascript
Request: {
  title: "New Deal",
  description: "Deal description",
  value_estimate: 100000000,
  probability: 50,
  stage: "Lead",
  assigned_to: 2,
  expected_close_date: "2024-12-31"
}

Response: { success: true, deal: {...} }
```

#### PUT /api/deals/[id]
Update a deal
```javascript
Request: { same fields as POST }
Response: { success: true, deal: {...} }
```

#### DELETE /api/deals/[id]
Delete a deal
```javascript
Response: { success: true }
```

### Valuation Metrics

#### GET /api/valuation
Retrieve pipeline statistics
```javascript
Response: {
  totalPipelineValue: 5000000000,    // UGX
  weightedPipelineValue: 2500000000, // UGX (value × probability%)
  wonDealsTotal: 1000000000,         // UGX
  lostDealsTotal: 500000000          // UGX
}
```

## UI/UX Features

### Visual Feedback
- Smooth animations on all transitions
- Drag feedback (cursor changes, shadow effects)
- Loading states on buttons
- Error messages with clear guidance
- Success confirmation with navigation

### Dark Mode Support
- All components support light/dark mode
- CSS variables for theme switching
- Background, text, border colors adapt automatically

### Responsive Design
- Mobile-first approach
- Adapts to tablet and desktop
- Touch-friendly button sizes
- Scrollable Kanban board on small screens

### Accessibility
- Semantic HTML
- Proper label associations
- Keyboard navigation support
- ARIA attributes where needed

## Data Validation

### Client-Side Validation
```javascript
const formValidation = {
  title: (value) => value.trim().length > 0,
  value_estimate: (value) => Number(value) > 0,
  probability: (value) => value >= 0 && value <= 100,
  assigned_to: (value) => value !== '',
}
```

### Server-Side Validation
- Required fields checked
- Value constraints validated
- Authorization verified
- Audit logging enabled

## Error Scenarios & Handling

| Scenario | Behavior |
|----------|----------|
| Missing required fields | Form validation prevents submission, shows error message |
| API connection error | Display error message, offer retry button |
| Unauthorized request | Redirect to login page |
| Deal not found (edit) | Show 404 message with link back to pipeline |
| Delete confirmation | Modal dialog prevents accidental deletion |
| Stage transition failure | Revert visual change, show error message |

## Performance Considerations

### Optimization Techniques
1. **Lazy Loading**: Forms use React Suspense for code splitting
2. **Memoization**: Pipeline cards memoized to prevent unnecessary re-renders
3. **Debouncing**: Form inputs debounced for currency conversion
4. **Batch Updates**: Stage changes batched with metric recalculation

### Data Fetching Strategy
- Initial load: Fetch deals and staff in parallel
- Stage change: Immediate optimistic update, fallback on error
- Edit form: Only fetch affected deal and staff list
- Metrics: Recalculated on every deal change

## Currency System Integration

The deal system fully integrates with Jeton's multi-currency system:

### Canonical Currency
- **UGX (Ugandan Shilling)** is the canonical/source currency
- All deal values stored in UGX in database

### Display Currencies
System supports conversion to 11 display currencies:
- UGX, USD, EUR, GBP, JPY, CHF, CAD, AUD, SGD, INR, KES

### Integration Points
1. **Form Inputs**: Accept values in display currency, convert to UGX on submit
2. **Value Display**: Show values in user-selected currency throughout
3. **Metrics**: Calculate all statistics in canonical UGX, display in user currency
4. **Weighted Value**: Calculate using UGX values, display in user currency

### Example Flow
```
User enters: 100 USD
System converts to: 330,000 UGX (using current rate)
Stores in DB: 330000
Displays as: 100 USD (using stored currency preference)
Calculates metrics: Uses stored 330000 UGX for all calculations
```

## Testing Checklist

### Functional Tests
- [ ] Create deal with all fields
- [ ] Create deal with minimal fields
- [ ] Edit existing deal
- [ ] Move deal between stages via drag-and-drop
- [ ] Delete deal with confirmation
- [ ] Verify metrics update correctly
- [ ] Verify currency conversion works
- [ ] Test with multiple staff members
- [ ] Test date picker functionality

### Error Handling Tests
- [ ] Submit form with missing required field
- [ ] Edit deal that doesn't exist
- [ ] Delete deal then cancel confirmation
- [ ] Disconnect network and try to save
- [ ] Test unauthorized access

### Browser/Device Tests
- [ ] Chrome desktop
- [ ] Firefox desktop
- [ ] Safari desktop
- [ ] Mobile Chrome
- [ ] Mobile Safari
- [ ] Dark mode rendering
- [ ] Responsive layout on tablet

### Data Integrity Tests
- [ ] Probability bounds (0-100%)
- [ ] Weighted value calculation accuracy
- [ ] Stage transitions persist correctly
- [ ] Deleted deals don't appear after refresh
- [ ] Metrics sum correctly across all deals

## Future Enhancements

### Planned Features
1. **Deal List View**: Table view of all deals with filtering/sorting
2. **Deal Details Page**: Read-only detail view of deal information
3. **Deal Notes/History**: Audit trail of changes to each deal
4. **Deal Attachments**: Upload and manage deal documents
5. **Pipeline Filters**: Filter by stage, assignee, date range, etc.
6. **Deal Templates**: Pre-fill common deal information
7. **Bulk Actions**: Multi-select and bulk stage updates
8. **Real-time Updates**: WebSocket updates for multi-user scenarios
9. **Deal Forecasting**: Predict win rate by stage
10. **Analytics Dashboard**: Trends, velocity, conversion rates

### Advanced Features
1. **Deal Stages Customization**: Allow custom pipeline stages
2. **Probability Decay**: Auto-decrease probability over time
3. **Win/Loss Analysis**: Reasons and patterns for wins/losses
4. **Deal Dependencies**: Link related deals
5. **Notifications**: Alerts for overdue deals, stage changes
6. **Workflow Automation**: Auto-move deals based on conditions

## Troubleshooting

### Deal Not Appearing After Creation
1. Check browser console for API errors
2. Verify auth token is valid (check localStorage)
3. Check network tab for API response status
4. Verify deal data has valid stage name

### Edit Form Shows Empty Values
1. Verify deal ID in URL is correct
2. Check API response for deal data
3. Verify staff list loaded successfully
4. Check date format (should be YYYY-MM-DD)

### Drag-and-Drop Not Working
1. Verify browser supports drag-drop API
2. Check that deal elements have proper event handlers
3. Verify no JavaScript errors in console
4. Try refreshing the page

### Currency Not Converting
1. Verify user currency selected in settings
2. Check currency conversion API is responding
3. Verify stored deal values are numeric
4. Check browser console for conversion errors

## File Structure

```
src/
├── app/
│   └── app/
│       ├── pipeline/
│       │   └── page.js                 Main pipeline page
│       ├── deals/
│       │   ├── create/
│       │   │   └── page.js              Create deal form
│       │   └── edit/
│       │       └── [id]/
│       │           └── page.js          Edit deal form
│       └── api/
│           └── deals/
│               └── route.js             Deals API endpoint
│
└── components/
    ├── financial/
    │   ├── PipelineBoard.js             Kanban board component
    │   ├── PipelineCard.js              Individual deal card
    │   └── DealDialog.js                Deal editing dialog
    └── common/
        └── CurrencyDisplay.js           Currency conversion component
```

## Deployment Notes

### Environment Variables
```
NEXT_PUBLIC_API_URL=https://api.jeton.io
DATABASE_URL=postgresql://...
AUTH_SECRET=...
```

### Database Migrations
- Ensure deals table exists with all required columns
- Add indexes on frequently queried columns (stage, assigned_to, created_at)
- Set up audit logging for deal operations

### Performance Optimization
- Enable database query caching for valuation metrics
- Implement API response caching (5-10 minute TTL)
- Use CDN for static assets
- Monitor API response times

### Monitoring
- Track creation/deletion success rates
- Monitor form abandonment rates
- Log all deal modifications for audit
- Alert on unusual activity (bulk deletes, etc.)

## Support & Documentation

For additional information:
- See [SIDEBAR_ROUTE_VALIDATION.md](./SIDEBAR_ROUTE_VALIDATION.md) for route configuration
- Check API documentation in server code comments
- Review component PropTypes for expected data structures
- Consult team on business logic requirements

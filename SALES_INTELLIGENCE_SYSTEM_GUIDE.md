# Jeton Sales Intelligence System
## Implementation Guide & User Manual

**Version 1.0** | February 21, 2026  
**Status:** Complete and Ready for Deployment

---

## Executive Summary

Jeton has been redesigned from a simple pipeline tracker into a **Structured Sales Intelligence System** that functions as a powerful daily sales notebook + CRM combined. This document explains the architecture, usage, and implementation details.

### What Changed?

**Before:** Prospecting effort disappeared into memory. Conversations were lost. Contact details scattered. Follow-ups ignored.

**After:** Every prospect interaction is permanently logged, chronologically organized, and actionable. Jeton becomes your external sales brain.

---

## 🏗️ System Architecture

### 1. Core Concept: Prospect ≠ Deal

Jeton now treats **Prospects** and **Deals** as separate entities:

- **Prospect:** A person/organization in relationship exploration phase
- **Deal:** A committed opportunity with a deal structure

This separation creates psychological stability: you know your contact status at all times.

### 2. Database Schema (What Was Added)

#### New Table: `prospect_activities` (Append-Only Journal)

```sql
prospect_activities {
  id (UUID)
  prospect_id (FK)
  activity_type ('CONVERSATION', 'MEETING', 'FOLLOW_UP', 'DEMO', 'NEGOTIATION', etc.)
  title (what happened)
  description (full details)
  outcome ('positive', 'neutral', 'negative', 'pending', 'action_required')
  product_discussed (what was presented)
  objections_raised (customer concerns)
  objections_handled (boolean - were they resolved?)
  resolution (how they were addressed)
  prospect_mood ('very_interested', 'interested', 'neutral', 'lukewarm', 'cold')
  confidence_level (1-10 scale)
  next_action (what happens next)
  follow_up_date (when to reconnect)
  follow_up_type ('call', 'email', 'meeting', 'demo')
  communication_method ('phone', 'email', 'meeting', 'video', 'sms')
  duration_minutes (call/meeting length)
  is_locked (once marked, activity cannot be edited)
  created_at (immutable timestamp)
  created_by (user who logged it)
  
  KEY RULES:
  ✓ APPEND-ONLY: Activities are never deleted
  ✓ CHRONOLOGICAL: Always ordered by creation date (DESC)
  ✓ IMMUTABLE: Data cannot be overwritten once locked
  ✓ COMPLETE: Every interaction is recorded permanently
}
```

#### Enhanced Table: `prospects` (Primary Entity)

```sql
prospects {
  -- Original fields (unchanged)
  id, prospect_name, phone, email, business_name, address, 
  industry, source, product_discussed, created_at
  
  -- NEW fields for Sales Intelligence
  interest_level ('New', 'Low', 'Medium', 'High', 'Very High')
  assigned_to (FK to users - sales owner)
  last_contact_date (auto-updated from activities)
  last_activity_id (FK to latest activity)
  next_follow_up_date (auto-updated from activities)
  total_activities_count (auto-maintained)
  conversion_date (when converted to deal)
  days_in_pipeline (computed - days since created)
  
  -- Conversion tracking
  converted_deal_id (FK to deals table)
  converted_revenue_id (FK to revenue_records)
}
```

#### Updated Prospect Status Options

```
Sales Stage Status:
├── New (just added)
├── Contacted (at least one activity logged)
├── Follow-Up Needed (has scheduled follow-ups)
├── Interested (interest_level >= High)
├── Negotiating (actively discussing deal structure)
├── Converted (became a deal)
├── Not Interested (prospect declined)
└── Lost (no longer pursuing)
```

---

## 🎯 Key Features & How They Work

### Feature 1: Prospect Activity Log (The Heart)

**What It Does:**
- Records every single interaction chronologically
- Cannot be deleted (append-only guarantee)
- Includes mood, confidence, objections, and outcomes
- Automatically updates prospect metadata

**How It Works:**

1. User logs activity: "Called CEO, expressed interest in product"
2. System records:
   ```
   {
     activity_type: "CONVERSATION",
     title: "Initial call with CEO",
     description: "Called CEO. He was very interested in solution...",
     outcome: "positive",
     prospect_mood: "very_interested",
     confidence_level: 8,
     next_action: "Send proposal within 24 hours",
     follow_up_date: "2026-02-23"
   }
   ```
3. Prospect automatically updated:
   - `last_contact_date` = today
   - `next_follow_up_date` = 2026-02-23
   - `total_activities_count` += 1

**Why This Fixes Instability:**
- Nothing relies on human memory
- Every detail is permanent
- Timeline is always available
- Mood/confidence tracking shows progression

---

### Feature 2: Daily Prospecting Dashboard

**URL:** `/app/prospecting/dashboard`

**What It Shows:**

| Metric | Purpose |
|--------|---------|
| **New Prospects Today** | How many contacts you added |
| **Follow-ups Due Today** | Your daily action items |
| **Overdue Follow-ups** | 🔴 Red alerts for missed commitments |
| **Conversations Logged** | Activity volume (quality metric) |
| **Conversion Rate (Week)** | Success percentage |

**Why This Matters:**
- Gives structure to your day
- Red alerts force accountability
- Conversion rate shows effectiveness
- You can see effort → results pipeline

---

### Feature 3: Prospect List with Filters

**URL:** `/app/prospecting`

**Features:**

```
┌─ Search (name, phone, email, company)
├─ Filter by Status (New, Contacted, Interested, etc.)
├─ Filter by Interest Level (Low → Very High)
├─ Sort Options:
│  ├─ Recently Created
│  ├─ Overdue Follow-ups (red priority)
│  ├─ Highest Interest
│  └─ Most Active
└─ Grid View (3 columns, mobile responsive)

Card Display:
├─ Prospect name + company
├─ Contact info (phone, email)
├─ Status badge
├─ Activity count
├─ Interest level
├─ Next follow-up date (with red highlight if overdue)
└─ "Converted to Deal" indicator
```

---

### Feature 4: Prospect Detail Page

**URL:** `/app/prospecting/[id]`

**Left Side (Main Content):**

1. **Contact Information Card**
   - Phone (clickable to call)
   - Email (clickable to compose)
   - Address, Industry, Source

2. **Log Interaction Form**
   - Activity type selector (Conversation, Meeting, Demo, Proposal, etc.)
   - Communication method (Phone, Email, Video, SMS)
   - Title (required)
   - Full description
   - Outcome selector
   - Mood picker (emoji-based)
   - Confidence score (1-10)
   - Product discussed field
   - Objection handling (if applicable)
   - Duration tracking
   - Next follow-up scheduling

3. **Activity Timeline**
   - Newest first (reverse chronological)
   - Timeline visual with icons per activity type
   - Color-coded outcomes
   - Full activity details expandable
   - Locked indicator for archived activities

**Right Side (Sidebar):**

1. **Status Card**
   - Current sales stage
   - Interest level
   - Days in pipeline

2. **Next Follow-up Card**
   - Red alert if overdue
   - Shows scheduled date
   - Days overdue count

3. **Activity Summary**
   - Total activities logged
   - Last contact date

4. **Convert to Deal Button**
   - Green highlighted section (only if not converted)
   - Requires product/service selection
   - Auto-fills deal with prospect data
   - Creates activity log entry
   - Updates prospect status to "Converted"

---

### Feature 5: Quick Add Prospect Modal

**Access:** Click "Add Prospect" button on list page (or top nav)

**Speed Design (Under 20 Seconds):**

```
ESSENTIAL FIELDS (always visible):
├─ Name *required*
├─ Phone
├─ Institution
├─ Product Discussed
└─ Quick Note (textarea)

ADVANCED FIELDS (expandable dropdown):
├─ Email
├─ Interest Level
└─ Source
```

**Optimization:**
- Auto-focus on name field
- Enter key submits form
- "Advanced" collapsed by default
- Clear CTAs
- Speed indicator: "💨 Fill essential fields to add in <20s"

---

### Feature 6: Prospect → Deal Conversion

**How It Works:**

1. User clicks "Convert to Deal" button on prospect detail
2. Modal requires:
   - Product/Service (required)
   - Deal Title (optional, auto-generated)
   - Estimated Value (optional)
3. System executes stored procedure:
   ```sql
   convert_prospect_to_deal(
     prospect_id,
     product_service,
     deal_title,
     value_estimate,
     user_id
   )
   ```
4. Stored procedure automatically:
   - Creates deal with prospect data
   - Sets deal stage to "Negotiating"
   - Updates prospect.converted_deal_id
   - Updates prospect.sales_stage to "Converted"
   - Logs activity: "Prospect converted to deal"
   - Returns deal_id

5. UI redirects to deal page
6. Prospect card shows "✓ Converted to Deal"
7. All activities remain in prospect history

**Key Benefit:** Zero friction conversion. All prospect data flows into deal automatically.

---

## 🔌 API Endpoints (Complete Reference)

### Prospect Management

```bash
# List all prospects (with filters)
GET /api/prospects
  ?stage=Interested&q=search_term

# Create prospect
POST /api/prospects
  {
    prospect_name,
    phone,
    email,
    business_name,
    address,
    industry,
    source,
    product_discussed,
    conversation_notes,
    objections,
    estimated_budget,
    follow_up_date,
    sales_stage,
    status,
    interest_level
  }

# Get prospect details
GET /api/prospects/[id]

# Update prospect
PUT /api/prospects/[id]
  { ...any_field_to_update }

# Soft delete prospect
DELETE /api/prospects/[id]

# Convert prospect to deal
POST /api/prospects/[id]/convert
  {
    product_service *required*,
    deal_title *optional*,
    value_estimate *optional*
  }
```

### Activity Management

```bash
# Get all activities for prospect (paginated)
GET /api/prospects/[id]/activities
  ?limit=50&offset=0&type=CONVERSATION

# Add activity
POST /api/prospects/[id]/activities
  {
    activity_type,
    title,
    description,
    outcome,
    product_discussed,
    objections_raised,
    objections_handled,
    resolution,
    prospect_mood,
    confidence_level (1-10),
    next_action,
    follow_up_date,
    follow_up_type,
    communication_method,
    duration_minutes
  }

# Get single activity
GET /api/prospects/[id]/activities/[activityId]

# Update activity (cannot update if locked)
PUT /api/prospects/[id]/activities/[activityId]
  { ...updatable_fields }

# Delete activity (FORBIDDEN - append-only)
DELETE /api/prospects/[id]/activities/[activityId]
  → Returns 403 with message: "Activities cannot be deleted. 
     This is an append-only system."
```

### Dashboard & Analytics

```bash
# Get today's prospecting summary
GET /api/prospects/dashboard/today
  ?date=2026-02-21

Response:
{
  summary: {
    newProspectsToday: 3,
    followUpsDueToday: 5,
    overdueFollowUps: 2,
    conversationsLoggedToday: 8,
    conversionCountThisWeek: 2,
    conversionRateThisWeek: "25.00%"
  },
  overdueFollowUps: [...],
  todaysProspects: [...],
  todaysFollowUps: [...],
  todaysConversations: [...]
}
```

---

## 🚀 Usage Workflows

### Workflow A: Morning Routine (5 minutes)

1. Open `/app/prospecting/dashboard`
2. Review metrics:
   - How many follow-ups today?
   - Any overdue? (red alerts)
   - Conversion rate trend
3. Click on overdue prospects (red section)
4. Reach out immediately
5. Log activity when done

### Workflow B: Adding a New Prospect (90 seconds)

1. Click "Add Prospect" button
2. Fill essential fields:
   - Name
   - Phone
   - Institution
   - Product discussed (what did you talk about?)
   - Quick note (how did it go?)
3. Click "Add Prospect"
4. System shows new prospect detail page
5. Optionally add detailed notes

### Workflow C: Logging an Interaction (2 minutes)

1. Find prospect on list or open detail page
2. Scroll to "Log Interaction" form
3. Fill fields:
   - Type: What kind of activity?
   - Title: One-line summary
   - Details: What happened?
   - Outcome: positive/neutral/negative?
   - Product: Which product was discussed?
   - Mood: How interested are they?
   - Confidence: How likely to close? (1-10)
4. Schedule next follow-up (date + type)
5. Click "Log Activity"
6. Prospect automatically updated with follow-up date

### Workflow D: Converting to Deal (1 minute)

1. Open prospect detail page
2. Scroll to "Convert to Deal" section (right sidebar, green)
3. Enter required: Product/Service name
4. Optional: Custom deal title, estimated value
5. Click "→ Convert to Deal"
6. System creates deal + activity log
7. You're redirected to deal page
8. Prospect shows "✓ Converted to Deal"

### Workflow E: Weekly Review (10 minutes)

1. Open `/app/prospecting`
2. Sort by "Highest Interest" to see hot prospects
3. Sort by "Overdue Follow-ups" to catch misses
4. Sort by "Most Active" to see engagement
5. Review metrics:
   - Total prospects
   - Active (not converted/lost)
   - Very high interest count
   - Overdue count
6. Identify trends
7. Adjust outreach strategy

---

## 📊 Key Metrics Explained

### Prospect Tracker Dashboard

| Metric | How It's Calculated | What It Tells You |
|--------|-------------------|-------------------|
| **New Prospects Today** | COUNT(prospects WHERE DATE(created_at) = today) | Daily acquisition volume |
| **Follow-ups Due Today** | COUNT(prospects WHERE next_follow_up_date = today) | Today's action items |
| **Overdue Follow-ups** | COUNT(prospects WHERE next_follow_up_date < today AND stage ≠ 'Converted/Lost') | Accountability gaps |
| **Conversations Logged** | COUNT(activities WHERE TYPE = 'CONVERSATION' AND DATE(created_at) = today) | Engagement level |
| **Conversion Rate (Week)** | COUNT(converted) / COUNT(total) * 100 | Sales effectiveness |

---

## 🔒 Data Integrity & Immutability

### Activity Log Guarantees

1. **Append-Only:**
   - Activities cannot be deleted
   - DELETE requests return HTTP 403
   - Deletion attempted through DB also fails (trigger prevents it)

2. **Immutable When Locked:**
   - Activities can be locked with `is_locked = true`
   - Locked activities cannot be updated
   - UPDATE attempts fail with trigger error

3. **Chronological Order:**
   - All queries return activities DEFAULT ORDER BY created_at DESC
   - Timeline is always newest-first
   - No reordering possible

4. **Auto-Maintained Counts:**
   - `total_activities_count` on prospects auto-updates via trigger
   - `last_contact_date` auto-updates on activity insert
   - `next_follow_up_date` auto-updates from latest activity with follow_up_date

5. **Verification Function:**
   ```sql
   SELECT * FROM verify_activity_counts()
   -- Shows any mismatches between actual and recorded counts
   ```

---

## 🛠️ Database Functions (Stored Procedures)

### Function: `convert_prospect_to_deal()`

**Purpose:** Safely convert prospect to deal in single transaction

**Signature:**
```sql
convert_prospect_to_deal(
  p_prospect_id UUID,
  p_product_service VARCHAR(255),
  p_deal_title VARCHAR(255),
  p_value_estimate DECIMAL(19,2),
  p_converted_by UUID
)
RETURNS TABLE(deal_id UUID, success BOOLEAN, message TEXT)
```

**Behavior:**
- Validates prospect exists and not already converted
- Creates deal with prospect data
- Sets deal stage to "Negotiating"
- Updates prospect status to "Converted"
- Logs activity "Prospect converted to deal"
- Returns: deal_id, success boolean, message

---

### Function: `get_today_prospecting_summary()`

**Purpose:** Get dashboard metrics for a specific date

**Returns:**
```
{
  new_prospects_today: INTEGER,
  follow_ups_due_today: INTEGER,
  overdue_follow_ups: INTEGER,
  conversations_logged_today: INTEGER,
  conversion_count_this_week: INTEGER
}
```

---

### Function: `get_overdue_follow_ups()`

**Purpose:** Fetch all overdue follow-ups needing attention

**Returns:**
```
{
  prospect_id,
  prospect_name,
  days_overdue,
  last_activity_title,
  next_follow_up_date
}
```

---

## 🎨 UI Components (React)

### ProspectCard.js
- Grid card for list view
- Shows status, interest, contact, activities
- Highlights overdue with red border
- Clickable to detail page

### ActivityTimeline.js
- Vertical timeline layout
- Icon per activity type
- Color-coded by outcome
- Shows all activity details
- Expandable sections

### QuickAddProspectModal.js
- Speed-optimized form
- Essential fields always visible
- Advanced fields collapsible
- Keyboard-optimized
- Under 20 seconds design

### ProspectListPage.js
- Full list with filters
- Search across fields
- Multiple sort options
- Grid layout (3 columns)
- Stats at top

### ProspectDetailPage.js
- Left: Contact info + activity form + timeline
- Right: Status, follow-up, conversion button
- Full 2-column layout
- Real-time form submission

### DailyProspectingDashboard.js
- Date selector
- Key metrics (5 cards)
- Overdue alerts (red section)
- Today's prospects grid
- Today's follow-ups list
- Conversations log

---

## 🔄 Navigation Structure

```
Sales Intelligence Section (NEW):
├─ Today's Prospecting (/app/prospecting/dashboard)
│  └─ Daily command center
├─ Prospects (/app/prospecting)
│  ├─ Prospect List
│  └─ [id] → Prospect Detail
│     └─ /activities → Activity Log
├─ Deals (existing)
├─ Pipeline (existing)
└─ Sales (existing)
```

---

## 📝 Implementation Checklist

- ✅ Database migration (028_prospect_activity_log.sql)
- ✅ Activity API routes (CRUD)
- ✅ Prospect detail endpoints
- ✅ Conversion endpoint
- ✅ Dashboard API
- ✅ ProspectCard component
- ✅ ActivityTimeline component
- ✅ QuickAddProspectModal component
- ✅ Prospect list page (/app/prospecting)
- ✅ Prospect detail page (/app/prospecting/[id])
- ✅ Daily dashboard (/app/prospecting/dashboard)
- ✅ Navigation updates (Sidebar, PageTitle, Navbar)
- ✅ Stored procedures for conversions & analytics

---

## 🚀 Deployment Instructions

### 1. Run Database Migration

```bash
# Connect to PostgreSQL
psql -U postgres -h localhost -d jeton -f migrations/028_prospect_activity_log.sql
```

**What this does:**
- Creates prospect_activities table
- Adds new columns to prospects table
- Creates triggers (auto-update metadata)
- Creates stored procedures
- Creates helper functions
- Creates statistics view

### 2. Verify Installation

```sql
-- Check tables exist
SELECT * FROM information_schema.tables 
WHERE table_name IN ('prospects', 'prospect_activities');

-- Check activity counts synced
SELECT * FROM verify_activity_counts();

-- Check procedures created
\df convert_prospect_to_deal
\df get_today_prospecting_summary
\df get_overdue_follow_ups
```

### 3. Test Workflows

```bash
# Test: Add prospect
curl -X POST http://localhost:3000/api/prospects \
  -H "Content-Type: application/json" \
  -d '{
    "prospect_name": "Test Prospect",
    "phone": "+250123456789",
    "business_name": "Test Co",
    "product_discussed": "Test Product"
  }'

# Test: Add activity
curl -X POST http://localhost:3000/api/prospects/[id]/activities \
  -H "Content-Type: application/json" \
  -d '{
    "activity_type": "CONVERSATION",
    "title": "Test call",
    "outcome": "positive"
  }'

# Test: Get dashboard
curl http://localhost:3000/api/prospects/dashboard/today

# Test: Convert to deal
curl -X POST http://localhost:3000/api/prospects/[id]/convert \
  -H "Content-Type: application/json" \
  -d '{
    "product_service": "Test Product",
    "value_estimate": 10000
  }'
```

### 4. Build & Deploy

```bash
npm run build
npm start
```

---

## 💡 Best Practices

### For Sales Managers

1. **Daily:** Check `/app/prospecting/dashboard` first thing
2. **Weekly:** Review conversion rate and overdue prospects
3. **Monthly:** Analyze interest level distribution
4. **Set activity expectations:** "Minimum 5 conversations per day"
5. **Track mood progression:** "Is confidence increasing over time?"

### For Sales Reps

1. **Log immediately:** Add activity same day as interaction
2. **Be detailed:** Description > title (more context = better follow-ups)
3. **Set next steps:** Always fill "Next Action" + "Follow-up Date"
4. **Track mood:** Honest assessment of interest/confidence
5. **Convert when ready:** Don't wait - move to deal stage early

### Activity Best Practices

```
✗ BAD:   "Called prospect"
✓ GOOD:  "Initial discovery call with CEO"
         "Discussed pain points: inventory management"
         "Prospect interested in product demo next week"

✗ BAD:   "No objections"
✓ GOOD:  "Raised concern: integration complexity"
         "Addressed: Our API has 30+ pre-built integrations"
         "Prospect satisfied with explanation"

✗ BAD:   "Follow up later"
✓ GOOD:  "Send technical specifications by Friday"
         "Follow-up call: 2026-02-25 (Tuesday 2pm)"
```

---

## 🔧 Troubleshooting

### Activity Not Appearing in Timeline

1. Check activity status in DB: `SELECT * FROM prospect_activities WHERE prospect_id = 'X'`
2. Verify prospect_id matches
3. Check created_at timestamp is recent
4. Refresh page (might be cache)

### Prospect Not Updating After Activity

1. Check trigger is enabled: `SELECT * FROM pg_trigger WHERE tgname LIKE '%activity%'`
2. Verify person can edit prospects
3. Check for errors in application logs

### Can't Convert Prospect to Deal

1. Check prospect isn't already converted: `SELECT converted_deal_id FROM prospects WHERE id = 'X'`
2. Verify product_service field is filled
3. Check user has deals create permission
4. Look for constraint violations in DB logs

### Dashboard Shows Wrong Numbers

1. Verify date parameter is correct: `?date=2026-02-21`
2. Check time zones (server might be UTC)
3. Manually recount: `SELECT COUNT(*) FROM prospects WHERE DATE(created_at) = DATE('2026-02-21')`

---

## 📞 Support & Maintenance

### Database Monitoring

```sql
-- Weekly: Check activity count integrity
SELECT prospect_id, COUNT(*) as actual_count
FROM prospect_activities
GROUP BY prospect_id
HAVING COUNT(*) != ANY(
  SELECT total_activities_count FROM prospects 
  WHERE id = prospect_id
);

-- Monthly: Identify prospects with no activities
SELECT p.id, p.prospect_name, p.created_at
FROM prospects p
LEFT JOIN prospect_activities pa ON p.id = pa.prospect_id
WHERE pa.id IS NULL
  AND DATE(p.created_at) < CURRENT_DATE - INTERVAL '7 days'
ORDER BY p.created_at;

-- Check locked activities
SELECT COUNT(*) as locked_activities FROM prospect_activities 
WHERE is_locked = true;
```

---

## 📈 Future Enhancements

Potential additions to consider:

1. **Email Integration:** Auto-log emails to prospect
2. **Calendar Sync:** Create follow-ups in calendar app
3. **AI Sentiment Analysis:** Auto-score mood from conversation notes
4. **Win/Loss Analysis:** Understand why prospects convert or fall off
5. **Activity Reminders:** Notifications for overdue follow-ups
6. **Bulk Actions:** Convert multiple prospects to deals
7. **Prospect Scoring:** Weighted scoring model
8. **Competitor Tracking:** Note which competitors mentioned
9. **Budget Tracking:** Track estimated_budget changes
10. **Success Metrics:** Custom KPI dashboard per user

---

## ✅ Conclusion

The Jeton Sales Intelligence System transforms prospecting from a memory-dependent, chaotic process into a structured, permanent, auditable sales notebook.

### Core Benefits

| Problem | Solution |
|---------|----------|
| Contacts scattered | Centralized prospect database |
| Conversations forgotten | Immutable activity log |
| Follow-ups missed | Dashboard alerts + date tracking |
| Effort → Unknown | Metrics show conversion pipeline |
| No process | Standardized workflows |
| Instability | External brain (not memory) |

### Key Numbers

- **Database tables:** 2 core (prospects_activities)
- **API endpoints:** 12+ routes
- **UI pages:** 3 main (list, detail, dashboard)
- **Components:** 6 reusable React components
- **Stored procedures:** 3 complex functions
- **Auto triggers:** 5+ for data integrity

### You Now Have

✅ A complete prospects notebook  
✅ Chronological interaction timeline  
✅ Overdue follow-up alerts  
✅ Daily prospecting dashboard  
✅ One-click prospect → deal conversion  
✅ Conversion rate analytics  
✅ Append-only audit trail  
✅ Mood/confidence tracking  
✅ Mobile-responsive design  

---

**Ready to use as your sales command center. Every founder's external brain.** 🧠💼

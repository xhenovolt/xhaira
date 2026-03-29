# JETON MODULE DOCUMENTATION
**Complete System Module Reference**

---

## MODULE 1: DASHBOARD

### Purpose
Central hub providing real-time business overview with key metrics and quick access to critical functions.

### Key Features
- Revenue summary cards
- Active deals count
- Prospect pipeline metrics
- Recent activities feed
- Quick action buttons
- Financial health indicators

### Routes Used
- **UI:** `/app/dashboard`
- **API:** Multiple aggregation endpoints

### Database Tables Used
- `deals` - Deal counts and stages
- `prospects` - Prospect metrics
- `payments` - Revenue totals
- `contracts` - Active contract count

### Typical Workflow
1. User logs in
2. Dashboard loads with current metrics
3. User reviews KPIs
4. User clicks quick actions to navigate

### Common Errors
- **Slow loading:** Large dataset pagination needed
- **Missing data:** Check database connections
- **Permission errors:** Verify user role access

---

## MODULE 2: PROSPECTS

### Purpose
Manage leads from initial contact through conversion to client.

### Key Features
- Prospect list with filtering
- Stage-based pipeline visualization
- Activity tracking (calls, emails, meetings)
- Follow-up scheduling
- Conversion tracking
- Industry and source classification

### Routes Used
- **UI:**
  - `/app/prospecting` - Main list
  - `/app/prospecting/new` - Add prospect
  - `/app/prospecting/[id]` - Prospect details
  - `/app/prospecting/followups` - Today's follow-ups
  - `/app/prospecting/conversions` - Ready to convert
  - `/app/prospecting/dashboard` - Pipeline metrics

- **API:**
  - `GET /api/prospects` - List all
  - `POST /api/prospects` - Create new
  - `GET /api/prospects/[id]` - Get details
  - `PUT /api/prospects/[id]` - Update
  - `DELETE /api/prospects/[id]` - Delete
  - `PUT /api/prospects/[id]/stage` - Update stage
  - `POST /api/prospects/[id]/convert-to-client` - Convert
  - `GET/POST /api/prospects/[id]/activities` - Activity log

### Database Tables Used
- `prospects` - Main prospect records
- `prospect_activities` - Activity log
- `prospect_stages` - Pipeline stages
- `prospect_sources` - Lead sources
- `prospect_industries` - Industry categories
- `prospect_tags` - Tagging system
- `clients` - Conversion target

### Typical Workflow
1. **Add Prospect:** Click "New Prospect" → Fill form → Save
2. **Log Activity:** Open prospect → Add call/meeting note → Schedule follow-up
3. **Advance Stage:** Click stage → Select next stage → Confirm
4. **Convert to Client:** When ready → Click "Convert" → Create client record

### Common Errors
- **Duplicate prospect:** Check email/phone before creating
- **Missing required fields:** Name and contact method required
- **Stage progression invalid:** Follow stage order
- **Conversion fails:** Ensure prospect qualifies

### Business Rules
- ✅ Prospect must have name + (email OR phone)
- ✅ Cannot convert prospect already converted
- ✅ Activities logged automatically on stage changes
- ✅ Follow-ups appear in today's list when due

---

## MODULE 3: DEALS

### Purpose
Manage sales opportunities from initial pitch through closing.

### Key Features
- Deal pipeline visualization
- Stage-based progression (Lead → Qualification → Proposal → Won/Lost)
- Value estimation and probability tracking
- Client/prospect linking
- System (product) association
- Auto-contract creation on win

### Routes Used
- **UI:**
  - `/app/deals` - Deal list
  - `/app/deals/create` - Create deal
  - `/app/deals/edit/[id]` - Edit deal
  - `/app/pipeline` - Pipeline view

- **API:**
  - `GET /api/deals` - List deals
  - `POST /api/deals` - Create deal
  - `GET /api/deals/[id]` - Get deal
  - `PUT /api/deals/[id]` - Update deal
  - `DELETE /api/deals/[id]` - Delete deal
  - `POST /api/deals/[id]/win` - Mark won (creates contract)
  - `GET /api/deals/valuation` - Valuation metrics

### Database Tables Used
- `deals` - Deal records
- `clients` - Client linkage
- `prospects` - Prospect linkage
- `intellectual_property` - System linkage
- `contracts` - Conversion target

### Typical Workflow
1. **Create Deal:** Must have client + system
2. **Progress Stages:** Lead → Qualification → Proposal
3. **Win Deal:** POST to win endpoint → Auto-creates contract
4. **Record Payment:** Navigate to payments

### Common Errors
- **No system selected:** Every deal requires a system_id
- **No client/prospect:** Every deal requires client_id or prospect_id
- **Win fails:** Check if client exists (prospect must be converted first)

### Business Rules
- ✅ Deal MUST have `system_id` (what you're selling)
- ✅ Deal MUST have `client_id` OR `prospect_id`
- ✅ Winning deal auto-creates contract
- ✅ If prospect not converted, auto-converts on win
- ✅ Contract inherits deal's system_id and client_id

---

## MODULE 4: CLIENTS

### Purpose
Manage converted prospects who have become paying clients.

### Key Features
- Client registry
- Contact information management
- Conversion tracking (from prospects)
- Contract linkage
- Revenue history

### Routes Used
- **UI:**
  - `/app/clients` - Client list

- **API:**
  - `GET /api/clients` - List clients
  - `POST /api/clients` - Create client (or convert from prospect)

### Database Tables Used
- `clients` - Client records
- `prospects` - Linked prospect (prospect_id)
- `contracts` - Client contracts
- `payments` - Client payments

### Typical Workflow
1. **Convert Prospect:** From prospect page → Convert button
2. **View Clients:** Navigate to clients list
3. **Review History:** See contracts and payments

### Business Rules
- ✅ Client created from prospect conversion
- ✅ Original prospect_id preserved
- ✅ Cannot reconvert same prospect
- ✅ Client status: active/inactive/churned

---

## MODULE 5: CONTRACTS

### Purpose
Formalize agreements with clients for systems/products sold.

### Key Features
- Installation fee tracking
- Recurring revenue management (monthly/quarterly/yearly)
- Contract lifecycle (draft/active/completed/terminated)
- System and client linkage
- Deal association

### Routes Used
- **UI:**
  - `/app/contracts` - Contract list

- **API:**
  - `GET /api/contracts` - List contracts
  - `POST /api/contracts` - Create contract
  - `GET /api/contracts/[id]` - Get contract
  - `PUT /api/contracts/[id]` - Update contract
  - `DELETE /api/contracts/[id]` - Delete contract

### Database Tables Used
- `contracts` - Contract records
- `clients` - Client linkage
- `intellectual_property` - System linkage
- `deals` - Deal linkage
- `payments` - Payment records

### Typical Workflow
1. **Auto-Created:** When deal is won
2. **Manual Creation:** Create button → Fill form → Save
3. **Record Payment:** Navigate to payments module

### Common Errors
- **Missing client_id:** Contract requires client
- **Missing system_id:** Contract requires system
- **Invalid recurring cycle:** Must be monthly/quarterly/yearly

### Business Rules
- ✅ Contract MUST have `client_id`
- ✅ Contract MUST have `system_id`
- ✅ Can link to deal via `deal_id`
- ✅ Installation fee defaults to 0
- ✅ Recurring enabled separately from installation

---

## MODULE 6: PAYMENTS

### Purpose
Track money received from clients and manage allocation.

### Key Features
- Payment recording with amount and date
- Contract linkage
- Payment method tracking
- Allocation status (pending/partial/allocated)
- Allocated amount tracking

### Routes Used
- **UI:**
  - `/app/payments` - Payment list with allocation

- **API:**
  - `GET /api/payments` - List payments
  - `POST /api/payments` - Create payment
  - `GET /api/payments/[id]` - Get payment
  - `PUT /api/payments/[id]` - Update payment
  - `DELETE /api/payments/[id]` - Delete payment

### Database Tables Used
- `payments` - Payment records
- `contracts` - Contract linkage
- `allocations` - Money distribution

### Typical Workflow
1. **Record Payment:** Click "New Payment" → Select contract → Enter amount → Save
2. **Allocate Funds:** Click "Allocate" → Choose categories → Distribute amount
3. **View Status:** Check allocation_status (pending/partial/allocated)

### Common Errors
- **Missing contract:** Payment requires contract_id
- **Over-allocation:** Cannot allocate more than payment amount
- **Invalid amount:** Must be greater than 0

### Business Rules
- ✅ Payment MUST have `contract_id`
- ✅ Amount must be > 0
- ✅ Allocation status auto-updates via trigger
- ✅ Cannot allocate more than payment amount
- ✅ Payment methods: cash, bank_transfer, mobile_money, card, crypto

---

## MODULE 7: ALLOCATIONS

### Purpose
Distribute received payments to different financial categories.

### Key Features
- Money distribution tracking
- Category-based allocation (vault, operating, expense, investment)
- Validation against payment amount
- Automatic status updates

### Routes Used
- **API:**
  - `GET /api/allocations` - List allocations
  - `POST /api/allocations` - Create allocation
  - `GET /api/allocations/[id]` - Get allocation
  - `PUT /api/allocations/[id]` - Update allocation
  - `DELETE /api/allocations/[id]` - Delete allocation

### Database Tables Used
- `allocations` - Allocation records
- `payments` - Payment source
- `expense_categories` - Expense categorization

### Typical Workflow
1. **Create Allocation:** From payment → Click allocate → Select type → Enter amount
2. **Distribution Types:**
   - **vault:** Long-term savings
   - **operating:** Day-to-day operations
   - **expense:** Direct expenses
   - **investment:** Growth investments
   - **custom:** Other categories

### Business Rules
- ✅ Allocation MUST link to `payment_id`
- ✅ Amount must be > 0
- ✅ Total allocations cannot exceed payment amount
- ✅ Database trigger validates and updates payment status

---

## MODULE 8: FINANCE DASHBOARD

### Purpose
Real-time financial overview showing revenue, expenses, profit, and cash position.

### Key Features
- Total revenue collected
- Total expenses
- Net profit calculation
- Profit margin percentage
- Cash position (vault, operating, investment)
- Recurring revenue tracking
- Top systems by revenue
- Top clients by revenue
- Data integrity alerts

### Routes Used
- **UI:**
  - `/app/finance` - Financial dashboard

- **API:**
  - `GET /api/financial-dashboard` - Complete metrics

### Database Tables Used
- `payments` - Revenue data
- `expenses` - Expense data
- `allocations` - Money distribution
- `vault_balances` - Cash reserves
- `contracts` - Recurring revenue
- `intellectual_property` - System revenue
- `clients` - Client revenue

### Database Views Used
- `v_financial_summary` - Aggregated KPIs
- `v_revenue_by_system` - Revenue per system

### Typical Workflow
1. **View Dashboard:** Navigate to /app/finance
2. **Review Metrics:** Check revenue, expenses, profit
3. **Check Cash Position:** Review vault and operating balances
4. **Analyze Performance:** Top systems and clients
5. **Address Issues:** Data integrity alerts

### Common Errors
- **Unallocated payments:** Shows alert if payments pending allocation
- **Negative profit:** Expenses exceed revenue

### Business Rules
- ✅ Net profit = Total revenue - Total expenses
- ✅ Profit margin = (Net profit / Revenue) × 100
- ✅ All amounts in base currency
- ✅ Real-time updates from database

---

## MODULE 9: INTELLECTUAL PROPERTY (SYSTEMS)

### Purpose
Manage the portfolio of products/systems being sold.

### Key Features
- System/product catalog
- Patent and technology tracking
- Deal and contract linkage
- Revenue per system tracking

### Routes Used
- **UI:**
  - `/app/intellectual-property` - System list

- **API:**
  - `GET /api/intellectual-property` - List systems
  - `POST /api/intellectual-property` - Create system
  - `GET /api/intellectual-property/[id]` - Get system
  - `PUT /api/intellectual-property/[id]` - Update system
  - `DELETE /api/intellectual-property/[id]` - Delete system

### Database Tables Used
- `intellectual_property` - System records
- `deals` - Deal linkage
- `contracts` - Contract linkage

### Typical Workflow
1. **Add System:** Click "New System" → Enter details → Save
2. **Link to Deals:** When creating deals, select system
3. **Track Revenue:** View revenue per system in finance dashboard

### Business Rules
- ✅ Every deal must reference a system
- ✅ Every contract must reference a system
- ✅ System name is required

---

## MODULE 10: INVOICES

### Purpose
Generate and manage invoices for clients.

### Key Features
- Invoice creation and editing
- Line item management
- Status tracking (draft/sent/paid/overdue)
- PDF generation (printable HTML)
- Sequential numbering

### Routes Used
- **UI:**
  - `/app/invoices` - Invoice list
  - `/app/invoices/[id]/view` - View invoice
  - `/app/invoices/[id]/edit` - Edit invoice
  - `/app/invoices/[id]/print` - Print view

- **API:**
  - `GET /api/invoices` - List invoices
  - `POST /api/invoices` - Create invoice
  - `GET /api/invoices/[id]` - Get invoice
  - `PUT /api/invoices/[id]` - Update invoice
  - `DELETE /api/invoices/[id]` - Delete invoice
  - `GET/POST /api/invoices/[id]/items` - Manage items
  - `PUT /api/invoices/[id]/status` - Update status
  - `GET /api/invoices/[id]/pdf` - Generate PDF
  - `GET /api/invoices/next-number` - Next invoice number
  - `GET /api/invoices/stats` - Invoice statistics

### Database Tables Used
- `invoices` - Invoice records
- `invoice_items` - Line items

### Typical Workflow
1. **Create Invoice:** New invoice → Add items → Save
2. **Send Invoice:** Mark as "sent"
3. **Record Payment:** When paid → Update status
4. **Print/Export:** Generate PDF for client

---

## MODULE 11: ADMIN

### Purpose
System administration, user management, and security.

### Key Features
- User account management
- Role assignment
- Permission control
- Audit log viewing
- Activity monitoring

### Routes Used
- **UI:**
  - `/app/admin/users` - User list
  - `/app/admin/users/[userId]` - User details
  - `/app/admin/activity` - Activity monitoring
  - `/app/admin/activity-analytics` - Analytics
  - `/app/admin/audit-logs` - Audit trail
  - `/app/admin/roles` - Role management

- **API:**
  - `GET /api/admin/users` - List users
  - `POST /api/admin/users` - Create user
  - `GET/PUT/DELETE /api/admin/users/[userId]` - Manage user
  - `GET /api/admin/audit-logs` - Audit logs
  - `GET /api/admin/activity-analytics` - Analytics
  - `GET /api/admin/roles` - Roles
  - `GET /api/admin/permissions` - Permissions

### Database Tables Used
- `users` - User accounts
- `roles` - User roles
- `permissions` - Permission definitions
- `role_permissions` - Role-permission mapping
- `audit_logs` - System activity log
- `sessions` - Active sessions

### Typical Workflow
1. **Create User:** Admin panel → New user → Assign role → Save
2. **Monitor Activity:** View activity logs
3. **Manage Permissions:** Assign role-based permissions
4. **Review Audit:** Check system changes

### Access Control
- 🔒 **Admin only:** Requires admin or superadmin role
- 🔒 **Audit trail:** All admin actions logged
- 🔒 **Session management:** Force logout capability

---

## MODULE DEPENDENCY MAP

```
Authentication
    ↓
Dashboard ← (reads from all modules)
    ↓
Prospects → Clients
    ↓           ↓
    → Deals → Contracts → Payments → Allocations → Finance Dashboard
           ↓       ↓           ↓
           ↓       ↓           → Expenses
           ↓       ↓
    Systems (IP) ←┘
```

---

## QUICK REFERENCE

| Module | Primary Route | Create Action | View Action |
|--------|--------------|---------------|-------------|
| Prospects | `/app/prospecting` | New Prospect | Click prospect |
| Deals | `/app/deals` | Create Deal | Click deal |
| Clients | `/app/clients` | Convert Prospect | Click client |
| Contracts | `/app/contracts` | Win Deal (auto) | Click contract |
| Payments | `/app/payments` | New Payment | Click payment |
| Finance | `/app/finance` | N/A | View dashboard |
| Systems | `/app/intellectual-property` | New System | Click system |
| Invoices | `/app/invoices` | New Invoice | View invoice |
| Admin | `/app/admin/users` | New User | Click user |

---

**Document Version:** 1.0  
**Last Updated:** March 8, 2026

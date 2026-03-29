# Founder Operating System - Quick Reference

## Daily Founder Workflow

### Morning: Check Today's Agenda
```
Navigate to: /app/prospects/followups?filter=today

See:
  - Who needs calling TODAY (overdue + today)
  - Last contact date for each
  - Quick call/email buttons
  - View prospect button
```

### During Day: Log Activities & Schedule Follow-ups
```
Each prospect detail shows:
  - Activity timeline (all past activities)
  - "Log Activity" form
  
Log activity:
  POST /api/prospects/[id]/activities
  {
    "activity_type": "call",
    "description": "Discussed pricing, they're interested",
    "outcome": "interested",
    "next_followup_date": "2026-01-15"
  }
  
Result: prospect.follow_up_date updates automatically
```

### End of Week: Convert Warm Leads
```
Navigate to: /app/prospects/conversions

See:
  - All Negotiating + Interested prospects
  - Total activities + last contact date
  - Convert button
  
Convert prospect:
  POST /api/prospects/[id]/convert-to-client
  {
    "name": "Acme Inc",
    "email": "contact@acme.com",
    "phone": "+256...",
    "business_name": "Acme Inc"
  }
  
Result:
  - Client record created
  - Prospect linked to client (FK)
  - Sales stage → "Converted"
  - Prospect activity logged
```

### After Conversion: Create Contract
```
Navigate to: /app/contracts/create

Select:
  - Client (shows recently converted)
  - System (from /app/intellectual-property)
  - Contract terms, dates, value

Create:
  POST /api/contracts
  
Result:
  - Contract record linked to client
  - Client can have multiple contracts
```

### Log Payments Received
```
Navigate to: /app/collections

Record payment:
  POST /api/payments
  {
    "amount_received": 5000000,
    "date_received": "2026-01-10",
    "payment_method": "bank_transfer",
    "contract_id": "..."
  }
  
Payment starts as 'pending'
```

### Allocate Money (100% Required)
```
Navigate to: /app/allocations

Allocate:
  POST /api/allocations
  {
    "payment_id": "...",
    "allocated_amount": 1250000,
    "allocation_type": "operating"  // or vault|expenses|investment
  }
  
Note: SUM of allocations must equal payment.amount_received
```

### View Real-time Metrics
```
Navigate to: /app/finance-dashboard

See:
  - Total Revenue (all time or filtered)
  - Total Expenses
  - Net Profit
  - Collections: Amount Received + Pending
  - Allocations: Where money went
  - Expenses: By category
  - Collection Rate: % of contracts paid
  
Filter by:
  - This Month
  - This Quarter
  - This Year
  - All Time
```

---

## Navigation Structure

```
DASHBOARD
  └─ Quick overview, recent activity

GROWTH
  ├─ Prospects (/app/prospects)
  │   └─ View all prospects, stages, next follow-up
  ├─ Follow-ups (/app/prospects/followups)
  │   └─ TODAY'S AGENDA - overdue (red), today (orange), upcoming (blue)
  └─ Conversions (/app/prospects/conversions)
      └─ Warm leads ready to convert (Negotiating/Interested)

REVENUE
  ├─ Contracts (/app/contracts)
  │   └─ Manage contracts, track status
  ├─ Collections (/app/collections)
  │   └─ Money received, pending, collection rate
  └─ Allocations (/app/allocations)
      └─ Track where money goes (operating, vault, expenses, investment)

VISIBILITY
  └─ Finance Dashboard (/app/finance-dashboard)
      └─ Real-time: revenue, expenses, profit, allocations

SYSTEMS
  └─ IP Portfolio (/app/intellectual-property)
      └─ What you sell (systems, products, services)

OPERATIONS
  ├─ Staff (/app/staff)
  │   └─ Team management
  └─ Infrastructure (/app/infrastructure)
      └─ Tools, hosting, costs

ADMIN
  ├─ Users (/admin/users)
  │   └─ User accounts and access
  └─ Activity Logs (/admin/audit-logs)
      └─ Audit trail of all actions
```

---

## Core API Endpoints

### Prospect Management
```
GET    /api/prospects
  → List all prospects with filters

GET    /api/prospects/followups?filter=overdue|today|upcoming
  → Get prospects needing follow-up

GET    /api/prospects/conversions
  → Get Negotiating + Interested prospects

GET/POST /api/prospects/[id]/activities
  → Log and retrieve prospect activities

POST   /api/prospects/[id]/convert-to-client
  → Convert prospect to client
```

### Financial Management
```
GET    /api/contracts
POST   /api/contracts
  → Contract CRUD

GET    /api/collections (payments)
POST   /api/collections
  → Money received tracking

GET    /api/allocations
POST   /api/allocations
  → Money allocation (100% enforcement)

GET    /api/financial-dashboard?range=month|quarter|year|all
  → Real-time metrics
```

---

## Key Database Views

```sql
-- Daily follow-up agenda
SELECT * FROM prospects_needing_followup;

-- Prospects ready to convert
SELECT * FROM prospects_ready_to_convert;

-- Full prospect context with metrics
SELECT * FROM prospects_with_activity;
```

---

## Migration: Old Routes → New Routes

| Old Route | New Route | Reason |
|-----------|-----------|--------|
| `/app/app/prospecting` | `/app/prospects` | Consolidated |
| `/app/prospects/pipeline` | `/app/prospects/conversions` | More specific |
| `/app/prospects/dashboard` | `/app/prospects` | Removed redundancy |
| Sidebar "Deals" (2x) | Removed | Duplicates |
| Sidebar "Pipeline" (3x) | Consolidated to Growth | Duplicates |
| Sidebar "Sales" (2x) | `/app/prospects` | Consolidation |

---

## Data Model: Prospect Lifecycle

```
prospect (created)
  ├─ prospect_name, email, phone, business_name
  ├─ sales_stage: 'Prospect' → 'Contacted' → 'Interested' → 'Negotiating' → 'Converted'
  ├─ follow_up_date: When to follow up next
  └─ Created prospect_activities for each interaction

prospect_activities (logged for each interaction)
  ├─ activity_type: call|email|meeting|note|outcome
  ├─ description: What happened
  ├─ outcome: interested|not_interested|no_answer|rescheduled|converted
  └─ next_followup_date: When to contact next

[CONVERSION POINT]

client (created during conversion)
  ├─ name, email, phone, business_name, address
  ├─ status: active|inactive|churned
  └─ prospect_id: FK to prospect (relationship established)

contracts (created after client conversion)
  ├─ client_id: FK to client
  ├─ system_id: FK to intellectual_property (what was sold)
  ├─ contract_value, start_date, end_date
  └─ status: draft|active|completed|cancelled

payments (when money arrives)
  ├─ contract_id: FK to contract
  ├─ amount_received, date_received
  ├─ allocation_status: pending|allocated|finalized
  └─ Payment stays 'pending' until 100% allocated

allocations (distributes payment)
  ├─ payment_id: FK to payment
  ├─ allocated_amount, allocation_type (operating|vault|expenses|investment)
  └─ Once SUM(allocations) == payment.amount, mark payment as 'allocated'
```

---

## Daily Questions Answered

**By 8 AM**: "Who do I call today?"
→ `/app/prospects/followups?filter=today`

**By 5 PM**: "Who's ready to close?"
→ `/app/prospects/conversions`

**By Month-End**: "How much did I collect?"
→ `/app/finance-dashboard` → Collections metric

**By Month-End**: "Where did the money go?"
→ `/app/finance-dashboard` → Allocations + Expenses

**Anytime**: "What's my profit?"
→ `/app/finance-dashboard` → Net Profit (Revenue - Expenses)

---

## Activity Types Explained

| Type | When | Example | Outcome |
|------|------|---------|---------|
| `call` | Phone conversation | "Called John, discussed pricing" | interested / not_interested / no_answer / rescheduled |
| `email` | Email sent/received | "Sent proposal" | - |
| `meeting` | In-person or video | "Met with client team" | interested / moved forward |
| `note` | Internal note | "Waiting for their budget approval" | - |
| `outcome` | Decision maker | "They agreed to contract" | **ALWAYS requires next_followup_date** |

---

## Testing the System

### 1. Create a prospect
```bash
curl -X POST http://localhost:3000/api/prospects \
  -H "Content-Type: application/json" \
  -d '{
    "prospect_name": "Test User",
    "email": "test@company.com",
    "phone": "+256...",
    "business_name": "Test Co",
    "sales_stage": "Contacted"
  }'
```

### 2. Log an activity
```bash
curl -X POST http://localhost:3000/api/prospects/[id]/activities \
  -H "Content-Type: application/json" \
  -d '{
    "activity_type": "call",
    "description": "Initial discovery call",
    "outcome": "interested",
    "next_followup_date": "2026-01-15"
  }'
```

### 3. Check follow-ups
```bash
curl http://localhost:3000/api/prospects/followups?filter=today
```

### 4. Convert to client
```bash
curl -X POST http://localhost:3000/api/prospects/[id]/convert-to-client \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company Ltd",
    "email": "accounts@testcompany.com",
    "phone": "+256..."
  }'
```

### 5. View metrics
```bash
curl http://localhost:3000/api/financial-dashboard?range=month
```

---

## Troubleshooting

**Q: I don't see prospects in /app/prospects/followups**
A: Prospects must have `follow_up_date <= today` and `client_id IS NULL`

**Q: I can't convert a prospect**
A: Prospect must be in 'Contacted', 'Interested', or 'Negotiating' stage

**Q: Payment shows as pending**
A: Allocations don't sum to 100%. Check `/api/allocations` for payment_id

**Q: Finance Dashboard shows zeros**
A: No contracts created yet. Create contract → log payment → allocate money

**Q: Can't see activity on prospect**
A: Activity table is new. Are you using new API? Old activities in different table.

---

## File Locations

**Navigation**: `src/lib/navigation-config.js` (Single source of truth)
**Founder Routes**: `src/lib/founder-navigation.js` (Complete registry)
**Prospect Pages**: `src/app/prospects/`
**Prospect APIs**: `src/app/api/prospects/`
**Financial APIs**: `src/app/api/contracts|payments|allocations|`
**Database**: `migrations/031_prospect_client_unification.sql`
**Documentation**: `FOUNDER_OS_REDESIGN.md` (Full guide)

---

## Status

✅ **LIVE** - Phase 1 Complete  
✅ Navigation redesigned (no duplicates)  
✅ Prospect lifecycle unified  
✅ Activity tracking implemented  
✅ Finance dashboard live  
✅ All APIs tested  

📋 **Next**: Prospect detail modal with conversion flow  
📋 **Then**: Sales analytics & forecasting  
📋 **Later**: WhatsApp/Email integrations  

---

**Xhaira is now a founder operating system, not a CRM.**

System built for clarity, speed, and founder workflow amplification.

Every feature answers a founder question in real-time.

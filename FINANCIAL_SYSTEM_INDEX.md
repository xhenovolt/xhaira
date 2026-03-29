# 📚 Jeton Financial System - Documentation Index

## Quick Navigation

**New to this? Start here:**
1. [FINANCIAL_QUICK_REFERENCE.md](FINANCIAL_QUICK_REFERENCE.md) - 5 minute overview
2. [FINANCIAL_SYSTEM_SUMMARY.md](FINANCIAL_SYSTEM_SUMMARY.md) - Complete reference
3. [FINANCIAL_SYSTEM_USAGE_GUIDE.md](FINANCIAL_SYSTEM_USAGE_GUIDE.md) - Detailed walkthrough

**For implementation:**
1. [FINANCIAL_ARCHITECTURE_REDESIGN.md](FINANCIAL_ARCHITECTURE_REDESIGN.md) - Design document
2. List below for specific files

**For debugging/issues:**
1. [FINANCIAL_SYSTEM_COMPLETE.md](FINANCIAL_SYSTEM_COMPLETE.md) - Troubleshooting section
2. Check specific table/API documentation below

---

## Documentation Files

### Core Documentation (4 files)

| File | Purpose | Read Time | For Whom |
|------|---------|-----------|----------|
| [FINANCIAL_QUICK_REFERENCE.md](FINANCIAL_QUICK_REFERENCE.md) | 1-page quick reference with API examples | 5 min | Everyone |
| [FINANCIAL_SYSTEM_SUMMARY.md](FINANCIAL_SYSTEM_SUMMARY.md) | Complete system summary with all details | 20 min | Technical & non-technical |
| [FINANCIAL_SYSTEM_USAGE_GUIDE.md](FINANCIAL_SYSTEM_USAGE_GUIDE.md) | Step-by-step implementation and usage | 30 min | Developers |
| [FINANCIAL_ARCHITECTURE_REDESIGN.md](FINANCIAL_ARCHITECTURE_REDESIGN.md) | Original design document for justification | 20 min | Decision makers |

---

## Code Files Created

### Database Migration
```
migrations/030_financial_architecture_redesign.sql
├── Creates: clients, contracts, payments, allocations, expense_categories, expenses tables
├── Adds: Constraints, triggers, indexes, views
├── Data: Pre-populates 8 system expense categories
└── Run once: psql -U postgres -d jeton < this_file.sql
```

### Backend APIs (14 Endpoints)

#### Contracts
```
src/app/api/contracts/route.js          [Contract CRUD]
  POST   /api/contracts                 Create contract (system+client required)
  GET    /api/contracts                 List contracts with metrics

src/app/api/contracts/[id]/route.js     [Contract Detail]
  GET    /api/contracts/[id]            Get contract with payment history
  PUT    /api/contracts/[id]            Update contract
  DELETE /api/contracts/[id]            Delete contract (safety checks)
```

#### Payments
```
src/app/api/payments/route.js           [Payment CRUD]
  POST   /api/payments                  Record payment (creates as pending)
  GET    /api/payments                  List with allocation status

src/app/api/payments/[id]/route.js      [Payment Detail]
  GET    /api/payments/[id]             Get payment with allocations
  DELETE /api/payments/[id]             Delete unallocated payment
```

#### Allocations
```
src/app/api/allocations/route.js        [Allocation CRUD]
  POST   /api/allocations               Add allocation (enforces sum=payment)
  GET    /api/allocations               List allocations

src/app/api/allocations/[id]/route.js   [Allocation Detail]
  GET    /api/allocations/[id]          Get allocation
  DELETE /api/allocations/[id]          Remove allocation
```

#### Expenses
```
src/app/api/expenses/route.js           [Expense CRUD]
  POST   /api/expenses                  Record expense
  GET    /api/expenses                  List expenses

src/app/api/expenses/[id]/route.js      [Expense Detail]
  GET    /api/expenses/[id]             Get expense
  PUT    /api/expenses/[id]             Update expense
  DELETE /api/expenses/[id]             Delete expense
```

#### Support APIs
```
src/app/api/clients/route.js            [Client Management]
  GET    /api/clients                   List clients
  POST   /api/clients                   Create client

src/app/api/expense-categories/route.js [Category Management]
  GET    /api/expense-categories        List all categories
  POST   /api/expense-categories        Create custom category
```

#### Intelligence & Audit
```
src/app/api/financial-dashboard/route.js
  GET    /api/financial-dashboard       Complete metrics (revenue, expenses, profit, systems, clients)

src/app/api/financial-audit/route.js
  GET    /api/financial-audit           Data integrity check (orphaned money, overallocations, delinquencies)
```

### Business Logic
```
src/lib/financial-validator.js
├── contractCreateSchema               Zod validation
├── paymentCreateSchema
├── allocationCreateSchema
├── expenseCreateSchema
├── validateClientExists()              Database checks
├── validateSystemExists()
├── checkPaymentAllocation()           Allocation status
├── detectOrphanedPayments()           Audit helpers
└── And 5 more validation functions
```

### Frontend Components
```
src/components/FinancialDashboard.jsx
├── Dashboard display with 6 sections
├── Date range filtering
├── Real-time metrics
├── System intelligence
└── Client intelligence

src/components/ContractPaymentFlow.jsx
├── 3-step guided workflow
├── Step 1: Create contract (system+client required)
├── Step 2: Record payment
├── Step 3: Allocate money (enforced 100%)
└── Form validation and error handling
```

---

## Key Tables (What to Know)

### contracts
**What**: Every system sold
```sql
id, client_id, system_id, installation_fee, 
recurring_enabled, recurring_cycle, recurring_amount, 
status, start_date, end_date, terms, metadata
```
**Key Rules**: 
- system_id REQUIRED (FK to intellectual_property)
- client_id REQUIRED (FK to clients)
- If recurring_enabled=true: need cycle + amount
- If recurring_enabled=false: cycle and amount must be NULL

### payments
**What**: Money received (tied to contract)
```sql
id, contract_id, amount_received, date_received, 
payment_method, reference_number, allocation_status, 
allocated_amount, notes
```
**Key Rules**: 
- contract_id REQUIRED
- amount_received > 0
- allocation_status starts as 'pending'
- Cannot finalize until fully allocated

### allocations
**What**: Where the money goes (100% mandatory)
```sql
id, payment_id, allocation_type, category_id, 
custom_category, amount, description
```
**Key Rules**: 
- payment_id REQUIRED
- allocation_type: operating | vault | expense | investment | custom
- amount > 0
- SUM(all allocations for payment) MUST equal payment.amount_received

### expenses
**What**: What you spend money on
```sql
id, category_id, amount, expense_date, 
linked_allocation_id, description, payment_method
```
**Key Rules**: 
- category_id REQUIRED
- amount > 0
- Optional link to allocation

### expense_categories
**What**: Types of expenses (system + custom)
```sql
id, name, description, is_system_defined, created_by
```
**System Categories** (auto-created):
- Hosting
- Salaries
- Transport
- Marketing
- Equipment
- Utilities
- Software Licenses
- Consulting

---

## Common Tasks & How to Do Them

### Task: Create a Contract
**Files Involved**: `src/app/api/contracts/route.js`
```bash
curl -X POST /api/contracts \
  -d '{"client_id":"uuid", "system_id":1, "installation_fee":5000000, "recurring_enabled":true, "recurring_cycle":"monthly", "recurring_amount":500000}'
```
See: [FINANCIAL_SYSTEM_USAGE_GUIDE.md - Step 2](FINANCIAL_SYSTEM_USAGE_GUIDE.md#step-2-create-a-contract-system-required)

### Task: Record Payment
**Files Involved**: `src/app/api/payments/route.js`
```bash
curl -X POST /api/payments \
  -d '{"contract_id":"uuid", "amount_received":5500000, "date_received":"2026-03-05", "payment_method":"bank_transfer"}'
```
See: [FINANCIAL_SYSTEM_USAGE_GUIDE.md - Step 3](FINANCIAL_SYSTEM_USAGE_GUIDE.md#step-3-record-payment)

### Task: Allocate Money
**Files Involved**: `src/app/api/allocations/route.js`
```bash
# Must allocate 100% of payment amount
curl -X POST /api/allocations \
  -d '{"payment_id":"uuid", "allocation_type":"vault", "amount":2500000, "description":"Savings"}'
```
See: [FINANCIAL_SYSTEM_USAGE_GUIDE.md - Step 4](FINANCIAL_SYSTEM_USAGE_GUIDE.md#step-4-allocate-money-mandatory)

### Task: View Financial Dashboard
**Files Involved**: `src/app/api/financial-dashboard/route.js`
```bash
curl "http://localhost:3000/api/financial-dashboard?startDate=2026-03-01&endDate=2026-03-31"
```
See: [FINANCIAL_SYSTEM_USAGE_GUIDE.md - Step 6](FINANCIAL_SYSTEM_USAGE_GUIDE.md#step-6-view-financial-dashboard)

### Task: Check Data Integrity
**Files Involved**: `src/app/api/financial-audit/route.js`
```bash
curl http://localhost:3000/api/financial-audit
```
See: [FINANCIAL_SYSTEM_COMPLETE.md - Data Integrity Check](FINANCIAL_SYSTEM_COMPLETE.md#data-integrity-check)

### Task: Add Custom Expense Category
**Files Involved**: `src/app/api/expense-categories/route.js`
```bash
curl -X POST /api/expense-categories \
  -d '{"name":"Office Supplies", "description":"Stationery and supplies"}'
```

---

## API Reference by Function

### Create Operations (POST)
| Endpoint | File | Validation |
|----------|------|-----------|
| POST /api/contracts | `contracts/route.js` | system_id required, client_id required, recurring config |
| POST /api/payments | `payments/route.js` | contract_id required, amount > 0 |
| POST /api/allocations | `allocations/route.js` | payment_id required, amount <= remaining |
| POST /api/expenses | `expenses/route.js` | category_id required, amount > 0 |
| POST /api/clients | `clients/route.js` | name required |
| POST /api/expense-categories | `expense-categories/route.js` | name required, unique |

### Read Operations (GET)
| Endpoint | File | Returns |
|----------|------|---------|
| GET /api/contracts | `contracts/route.js` | List with metrics |
| GET /api/contracts/[id] | `contracts/[id]/route.js` | Detail with payment history |
| GET /api/payments | `payments/route.js` | List with status |
| GET /api/payments/[id] | `payments/[id]/route.js` | Detail with allocations |
| GET /api/allocations | `allocations/route.js` | List all allocations |
| GET /api/allocations/[id] | `allocations/[id]/route.js` | Single allocation |
| GET /api/expenses | `expenses/route.js` | List filterable |
| GET /api/expenses/[id] | `expenses/[id]/route.js` | Detail |
| GET /api/clients | `clients/route.js` | Client list |
| GET /api/expense-categories | `expense-categories/route.js` | All categories |
| GET /api/financial-dashboard | `financial-dashboard/route.js` | Complete metrics |
| GET /api/financial-audit | `financial-audit/route.js` | Integrity report |

### Update Operations (PUT)
| Endpoint | File | What You Can Update |
|----------|------|-------------|
| PUT /api/contracts/[id] | `contracts/[id]/route.js` | installation_fee, status, end_date, terms (NOT recurring config if active) |
| PUT /api/expenses/[id] | `expenses/[id]/route.js` | category_id, amount, expense_date, description |

### Delete Operations (DELETE)
| Endpoint | File | Can Delete If |
|----------|------|-------------|
| DELETE /api/contracts/[id] | `contracts/[id]/route.js` | No payments exist |
| DELETE /api/payments/[id] | `payments/[id]/route.js` | No allocations exist |
| DELETE /api/allocations/[id] | `allocations/[id]/route.js` | Always (trigger updates payment status) |
| DELETE /api/expenses/[id] | `expenses/[id]/route.js` | Always |

---

## Error Codes & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| 404 Not Found | Record doesn't exist | Create it first |
| 400 Bad Request | Validation failed | Check required fields |
| 400 "system_id required" | Empty system selection | Pick system from list |
| 400 "Allocation exceeds payment" | Allocating more than received | Check remaining amount |
| 400 "Recurring config issue" | Circular logic in validation | See contract rules |
| 400 "Cannot delete" | Has dependent records | Delete dependent first |
| 500 Server Error | Database issue | Check PostgreSQL logs |

---

## Testing Your Implementation

### Minimal Test (5 minutes)
```bash
# 1. Create client
CLIENT=$(curl -s -X POST http://localhost:3000/api/clients \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Client"}' | jq '.client.id')

# 2. Create contract
CONTRACT=$(curl -s -X POST http://localhost:3000/api/contracts \
  -H "Content-Type: application/json" \
  -d "{\"client_id\":\"$CLIENT\",\"system_id\":1,\"installation_fee\":1000000}" | jq '.contract.id')

# 3. Record payment
PAYMENT=$(curl -s -X POST http://localhost:3000/api/payments \
  -H "Content-Type: application/json" \
  -d "{\"contract_id\":\"$CONTRACT\",\"amount_received\":1000000}" | jq '.payment.id')

# 4. Allocate money
curl -s -X POST http://localhost:3000/api/allocations \
  -H "Content-Type: application/json" \
  -d "{\"payment_id\":\"$PAYMENT\",\"allocation_type\":\"vault\",\"amount\":1000000}" | jq '.success'

# Should return: true
```

### Complete Workflow Test (20 minutes)
See: [FINANCIAL_SYSTEM_USAGE_GUIDE.md - Core Workflow](FINANCIAL_SYSTEM_USAGE_GUIDE.md#core-workflow)

---

## Deployment Checklist

- [ ] Read FINANCIAL_QUICK_REFERENCE.md (5 min)
- [ ] Read FINANCIAL_SYSTEM_USAGE_GUIDE.md (30 min)
- [ ] Apply migration (1 min)
- [ ] Test 5 key endpoints (15 min)
- [ ] Integrate frontend components (30 min)
- [ ] Migrate legacy data (1-2 hours)
- [ ] Run audit check (5 min)
- [ ] Train team (1 hour)

---

## Support & Troubleshooting

### "Where do I start?"
→ Read [FINANCIAL_QUICK_REFERENCE.md](FINANCIAL_QUICK_REFERENCE.md) (5 minutes)

### "How do I use this?"
→ Read [FINANCIAL_SYSTEM_USAGE_GUIDE.md](FINANCIAL_SYSTEM_USAGE_GUIDE.md) (30 minutes)

### "What was built exactly?"
→ Read [FINANCIAL_SYSTEM_SUMMARY.md](FINANCIAL_SYSTEM_SUMMARY.md) (20 minutes)

### "Why was it designed this way?"
→ Read [FINANCIAL_ARCHITECTURE_REDESIGN.md](FINANCIAL_ARCHITECTURE_REDESIGN.md) (20 minutes)

### "Something is broken"
→ See [FINANCIAL_SYSTEM_COMPLETE.md - Support & Debugging](FINANCIAL_SYSTEM_COMPLETE.md#support--debugging)

### "What's the business logic?"
→ See `src/lib/financial-validator.js` (validation rules)

### "How do I test it?"
→ Use [minimal test above](# or see FINANCIAL_SYSTEM_COMPLETE.md)

---

## Next Steps

1. **Today**: Read FINANCIAL_QUICK_REFERENCE.md
2. **Tomorrow**: Apply migration + test endpoints
3. **This week**: Integrate frontend components
4. **Next week**: Migrate legacy data + train team
5. **Month 2**: Build custom reports

---

## Files at a Glance

```
📁 Jeton Financial System
├── 📄 FINANCIAL_QUICK_REFERENCE.md          ← Start here (5 min)
├── 📄 FINANCIAL_SYSTEM_SUMMARY.md           ← Complete reference (20 min)
├── 📄 FINANCIAL_SYSTEM_USAGE_GUIDE.md       ← How to use (30 min)
├── 📄 FINANCIAL_ARCHITECTURE_REDESIGN.md    ← Why built this way (20 min)
├── 📄 FINANCIAL_SYSTEM_COMPLETE.md          ← Detailed reference
└── 📁 Code
    ├── 📁 migrations/
    │   └── 030_financial_architecture_redesign.sql
    ├── 📁 src/lib/
    │   └── financial-validator.js
    ├── 📁 src/app/api/
    │   ├── contracts/ (2 files)
    │   ├── payments/ (2 files)
    │   ├── allocations/ (2 files)
    │   ├── expenses/ (2 files)
    │   ├── clients/ (1 file)
    │   ├── expense-categories/ (1 file)
    │   ├── financial-dashboard/ (1 file)
    │   └── financial-audit/ (1 file)
    └── 📁 src/components/
        ├── FinancialDashboard.jsx
        └── ContractPaymentFlow.jsx
```

---

## The Transformation

```
Before:  "I think I made around... UGX last month"
After:   "I made exactly [23,456,789] UGX last month"
         (with full audit trail showing where every coin went)
```

✨ **You now have founder-level financial control.** 

**Next step**: Pick a documentation file above and dive in!

# Jeton Financial System - Implementation & Usage Guide

## Quick Start

### 1. Run Migration
```bash
# The migration file has been created at:
# migrations/030_financial_architecture_redesign.sql

# Apply it to your PostgreSQL database
psql -U postgres -d jeton < migrations/030_financial_architecture_redesign.sql
```

### 2. System Expense Categories (Auto-Created)
The migration automatically creates these system expense categories:
- Hosting
- Salaries
- Transport
- Marketing
- Equipment
- Utilities
- Software Licenses
- Consulting

## Core Workflow

### Step 1: Create a Client
```bash
curl -X POST http://localhost:3000/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corp",
    "email": "contact@acme.com",
    "phone": "+256123456789",
    "business_name": "Acme Corporation Ltd"
  }'
```

### Step 2: Create a Contract (System REQUIRED)
```bash
curl -X POST http://localhost:3000/api/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "uuid-from-step-1",
    "system_id": 1,
    "installation_fee": 5000000,
    "recurring_enabled": true,
    "recurring_cycle": "monthly",
    "recurring_amount": 500000,
    "status": "active",
    "start_date": "2026-03-01"
  }'

```

**Contract Rules:**
- `client_id`: REQUIRED - Must be active client
- `system_id`: REQUIRED - Must be from intellectual_property table
- `recurring_enabled`: Boolean
  - If `true`: `recurring_cycle` and `recurring_amount` MUST be provided
  - If `false`: Both must be null
- `status`: One of: draft, active, completed, suspended

### Step 3: Record Payment
```bash
curl -X POST http://localhost:3000/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "contract_id": "uuid-from-step-2",
    "amount_received": 5500000,
    "date_received": "2026-03-05",
    "payment_method": "bank_transfer",
    "reference_number": "BANK-TXN-12345",
    "notes": "Monthly payment received"
  }'
```

**Payment Rules:**
- `contract_id`: REQUIRED - Must exist
- `amount_received`: REQUIRED - Must be > 0
- `payment_method`: One of: cash, bank_transfer, mobile_money, check, credit_card, crypto, other
- **Payment Status**: Created as `allocation_status: 'pending'` - NOT FINALIZED until fully allocated

### Step 4: Allocate Money (MANDATORY)
Every payment must be fully allocated. This is the critical governance point.

```bash
# Allocate to Operating
curl -X POST http://localhost:3000/api/allocations \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "uuid-from-step-3",
    "allocation_type": "operating",
    "amount": 3000000,
    "description": "Team salaries and operations"
  }'

# Allocate to Vault (Savings)
curl -X POST http://localhost:3000/api/allocations \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "uuid-from-step-3",
    "allocation_type": "vault",
    "amount": 2000000,
    "description": "Emergency fund"
  }'

# Allocate to Expense
curl -X POST http://localhost:3000/api/allocations \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "uuid-from-step-3",
    "allocation_type": "expense",
    "category_id": "hosting-category-uuid",
    "amount": 500000,
    "description": "Monthly hosting costs"
  }'
```

**Allocation Rules:**
- `payment_id`: REQUIRED
- `allocation_type`: One of: operating, vault, expense, investment, custom
- `amount`: Must be > 0 and SUM(all allocations) MUST equal payment amount
- **Validation**: If allocations don't sum to payment, error returned with remaining amount

### Step 5: Record Expenses (Independent)
Expenses can be:
1. **Linked to allocation** (recommended): Track where allocation money went
2. **Standalone** (less preferred): Manual expense entry

```bash
# Create expense linked to allocation
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": "hosting-uuid",
    "amount": 500000,
    "expense_date": "2026-03-10",
    "linked_allocation_id": "allocation-uuid",
    "description": "AWS monthly bill",
    "reference_number": "AWS-INV-2026-03"
  }'

# Create standalone expense (no allocation link)
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": "marketing-uuid",
    "amount": 200000,
    "expense_date": "2026-03-12",
    "description": "Google Ads campaign"
  }'
```

### Step 6: View Financial Dashboard
```bash
curl "http://localhost:3000/api/financial-dashboard?startDate=2026-03-01&endDate=2026-03-31"
```

Response includes:
```json
{
  "dashboard": {
    "revenue": {
      "total_collected": 5500000,
      "installation_total": 5000000,
      "monthly_recurring": 500000,
      "annual_recurring_projection": 6000000
    },
    "expenses": {
      "total_expenses": 700000,
      "by_category": [...]
    },
    "allocations": {
      "vault": { "total": 2000000, "count": 1 },
      "operating": { "total": 3000000, "count": 1 },
      "expense": { "total": 500000, "count": 1 }
    },
    "profitability": {
      "gross_revenue": 5500000,
      "total_expenses": 700000,
      "net_profit": 4800000,
      "profit_margin": 87.27
    },
    "cash_position": {
      "vault_balance": 2000000,
      "operating_balance": 3000000,
      "investment_allocated": 0,
      "total_allocated": 5000000
    },
    "intelligence": {
      "top_systems": [...],
      "top_clients": [...]
    }
  }
}
```

### Step 7: Run Audit (Check Data Integrity)
```bash
curl "http://localhost:3000/api/financial-audit"
```

Returns:
- **Orphaned Payments**: Money with no allocation
- **Overallocated Payments**: Allocations exceed payment amount
- **Contracts Without Revenue**: Active contracts with no payments
- **Delinquent Recurring**: Recurring contracts past due date
- **Unfinalized Payments**: Payments not fully allocated yet

## API Endpoint Reference

### Clients
- `GET /api/clients` - List all clients
- `POST /api/clients` - Create client

### Contracts
- `GET /api/contracts` - List contracts (with metrics)
- `POST /api/contracts` - Create contract
- `GET /api/contracts/[id]` - Get contract with payment history
- `PUT /api/contracts/[id]` - Update contract
- `DELETE /api/contracts/[id]` - Delete contract (only if no payments)

### Payments
- `GET /api/payments` - List payments
- `POST /api/payments` - Create payment (creates as pending/unallocated)
- `GET /api/payments/[id]` - Get payment with allocations
- `DELETE /api/payments/[id]` - Delete payment (only if unallocated)

### Allocations
- `GET /api/allocations` - List allocations
- `POST /api/allocations` - Create allocation (enforces sum = payment)
- `GET /api/allocations/[id]` - Get allocation
- `DELETE /api/allocations/[id]` - Delete allocation (updates payment status)

### Expenses
- `GET /api/expenses` - List expenses
- `POST /api/expenses` - Create expense
- `GET /api/expenses/[id]` - Get expense
- `PUT /api/expenses/[id]` - Update expense
- `DELETE /api/expenses/[id]` - Delete expense

### Expense Categories
- `GET /api/expense-categories` - List all categories
- `POST /api/expense-categories` - Create custom category
- `GET /api/expense-categories?systemOnly=true` - Get system categories only

### Financial Intelligence
- `GET /api/financial-dashboard` - Complete financial metrics
- `GET /api/financial-audit` - Data integrity check

## Enforcement Rules (Guaranteed by API)

### Contract Creation
```javascript
❌ Cannot create without system_id
❌ Cannot create without client_id
❌ If recurring_enabled=true, must have recurring_cycle and recurring_amount
✅ If recurring_enabled=false, both must be null
```

### Payment Recording
```javascript
❌ Cannot create without contract_id
❌ Amount must be > 0
❌ Cannot finalize until fully allocated
✅ Status starts as 'pending'
```

### Money Allocation
```javascript
❌ Cannot have unallocated money (> 0.01 deviation)
❌ Cannot exceed payment amount
❌ Allocations must sum exactly to payment
✅ Every coin has tracked destination
```

### Expense Management
```javascript
❌ Cannot create without category_id
❌ Amount must be > 0
✅ Can be linked to allocation or standalone
```

## Key Differences from Old System

| Aspect | Old | New |
|--------|-----|-----|
| **Sales Entry** | Free text product name | Must select system with system_id |
| **Contracts** | Implicit in deals table | Explicit contracts table |
| **Payment Tracking** | revenue_payments only | Payments + Allocations (mandatory) |
| **Money Routing** | No tracking where cash went | Allocations force destination assignment |
| **Expenses** | Generic assets table | Structured with categories |
| **Dashboard** | Guess-based | Query-based with exact metrics |
| **Orphan Money** | Possible, invisible | Detected in audit |
| **Recurring Config** | Limited | Flexible per contract |
| **Client Management** | Implicit | Explicit clients table |

## Success Metrics (After Implementation)

You can now answer with 100% certainty:

1. ✅ **What systems were sold?** → Query contracts by system_id
2. ✅ **Is it recurring or one-time?** → Check contract.recurring_enabled
3. ✅ **How much was collected?** → SUM(payments.amount_received)
4. ✅ **Where did every coin go?** → Query allocations for payment
5. ✅ **What's allocated to operating/vault?** → SUM(allocations) by type
6. ✅ **What's being spent on what?** → expenses by category
7. ✅ **What's the net profit?** → revenue - expenses
8. ✅ **What's recurring exposure?** → SUM(recurring_amount) for active
9. ✅ **Where is cash?** → vault_balance + operating_balance
10. ✅ **Which system is most profitable?** → System-level intelligence query

## Data Migration (From Old System)

If you have existing revenue_records and deals:

```sql
-- Create legacy contracts from existing deals
INSERT INTO contracts (
  client_id, system_id, installation_fee, 
  recurring_enabled, status, start_date, created_at
)
SELECT 
  gen_random_uuid(), -- You'll need to map this to actual clients
  0, -- Default system ID - UPDATE these
  0, -- No installation fee known
  FALSE,
  'completed',
  CURRENT_DATE,
  deals.created_at
FROM deals
-- This is just a template - you'll need to customize based on your data
```

Then map existing revenue_records to payments, with zero-dollar allocations for audit trail.

## Next Steps

1. **Apply migration** to your database
2. **Test API endpoints** using provided curl examples
3. **Build UI components** for contract, payment, allocation entry
4. **Integrate with existing IP/system table** to enforce system selection
5. **Migrate legacy data** following Data Migration section
6. **Run audit** to identify any outstanding issues
7. **Train team** on new workflow (MUST allocate before considering payment "received")

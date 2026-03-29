# Jeton Financial Architecture Redesign

## Vision
Transform Jeton into a founder-level financial control center with strict data integrity, complete money tracking, and precise profit calculation.

## Current Gaps
- ❌ No contract system (free-text sales)
- ❌ No system selection enforcement when selling
- ❌ No mandatory payment allocation
- ❌ Money can "float" without destination
- ❌ No systematic expense tracking
- ❌ No financial dashboard with accuracy

## Solution Architecture

### Layer 1: Business Model (Contracts)

**contracts** table
```sql
id (UUID, PK)
client_id (FK to leads/clients)  
system_id (FK to intellectual_property, REQUIRED)
installation_fee (DECIMAL)
recurring_enabled (BOOLEAN)
recurring_cycle (ENUM: monthly, quarterly, annual, NULL)
recurring_amount (DECIMAL, nullable if recurring_enabled=false)
status (ENUM: draft, active, completed, suspended)
start_date (DATE)
end_date (DATE, nullable)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
metadata (JSONB)
```

**Contract Rules:**
- ✅ Cannot create without system_id
- ✅ Cannot create without client_id
- ✅ If recurring_enabled=true, recurring_cycle and recurring_amount REQUIRED
- ✅ If recurring_enabled=false, recurring fields NULL
- ✅ Enforce in application logic + database constraints

### Layer 2: Money In (Payments)

**payments** table
```sql
id (UUID, PK)
contract_id (FK to contracts, REQUIRED)
amount_received (DECIMAL, NOT NULL)
date_received (DATE, NOT NULL)
payment_method (ENUM: cash, bank_transfer, mobile_money, check, other)
reference_number (VARCHAR, optional)
notes (TEXT)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

**Payment Rules:**
- ✅ Cannot create without contract_id
- ✅ Cannot save until fully allocated (enforced by API)

### Layer 3: Money Allocation (Where It Goes)

**allocations** table - Forces all money to have a destination
```sql
id (UUID, PK)
payment_id (FK to payments, REQUIRED)
allocation_type (ENUM: operating, vault, expense, investment, custom)
category (VARCHAR)
amount (DECIMAL, NOT NULL)
description (TEXT)
created_at (TIMESTAMP)
```

**Allocation Rules:**
- ✅ SUM(allocations for payment) MUST equal payment.amount_received
- ✅ Cannot save payment until fully allocated
- ✅ No allocations can exceed payment amount
- ✅ Every coin has a tracked destination

### Layer 4: Expenses (What We Spend)

**expense_categories** table - System + Custom
```sql
id (UUID, PK)
name (VARCHAR, NOT NULL)
is_system_defined (BOOLEAN, default true)
description (TEXT)
created_by (FK to users)
created_at (TIMESTAMP)
```

System Categories:
- Hosting
- Salaries
- Transport
- Marketing
- Equipment
- Utilities
- Software Licenses
- Consulting

**expenses** table
```sql
id (UUID, PK)
category_id (FK to expense_categories)
amount (DECIMAL, NOT NULL)
expense_date (DATE, NOT NULL)
description (TEXT)
linked_payment_id (FK to allocations, nullable)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

**Expense Rules:**
- ✅ Must have category
- ✅ Can be linked to allocation or standalone
- ✅ Auto-creates allocation tracking if linked to payment

### Layer 5: Query Layer - Financial Dashboard

Key Metrics to Calculate:

**Revenue Metrics**
```
total_revenue_collected = SUM(payments.amount_received) where status='completed'
installation_revenue = SUM(contracts.installation_fee where status='active' OR 'completed')
recurring_revenue_monthly = SUM(contracts.recurring_amount where recurring_enabled=true AND status='active')
recurring_revenue_projected = recurring_revenue_monthly * 12
revenue_per_system = grouped SUM by system_id
revenue_per_client = grouped SUM by client_id
outstanding_receivables = SUM(contracts.recurring_amount WHERE date > today for active recurring)
```

**Expense Metrics**
```
total_expenses = SUM(expenses.amount)
expenses_by_category = grouped SUM by category_id
operating_expenses = SUM(allocations WHERE allocation_type='operating')
```

**Allocation Metrics**
```
vault_balance = SUM(allocations WHERE allocation_type='vault')
operating_balance = SUM(allocations WHERE allocation_type='operating')
investment_allocated = SUM(allocations WHERE allocation_type='investment')
```

**Profit Analysis**
```
net_profit = total_revenue_collected - total_expenses
operating_cash = operating_balance - operating_expenses_month
vault_savings = vault_balance
```

**System-Level Intelligence**
```
per_system {
  system_name
  total_contracts
  active_clients
  installation_revenue_total
  recurring_revenue_total
  monthly_recurring_active
  churned_clients_count
  gross_profit_estimation
}
```

## Implementation Phases

### Phase 1: Database Schema (Migrations)
- [ ] Create contracts table
- [ ] Create payments table
- [ ] Create allocations table
- [ ] Create expense_categories table
- [ ] Create expenses table
- [ ] Add indexes for query performance
- [ ] Add referential integrity constraints

### Phase 2: API Layer - Backend
- [ ] CREATE /api/contracts/* endpoints
- [ ] CREATE /api/payments/* endpoints
- [ ] CREATE /api/allocations/* endpoints
- [ ] CREATE /api/expenses/* endpoints
- [ ] CREATE /api/financial-dashboard endpoints
- [ ] CREATE validation & enforcement middleware
- [ ] CREATE transaction safety checks

### Phase 3: Business Logic & Validators
- [ ] Contract creation validators (system/client required)
- [ ] Payment validators (amount > 0, contract exists)
- [ ] Allocation validators (sum = payment amount)
- [ ] Expense category validators
- [ ] Recurring revenue calculation logic
- [ ] Churn detection logic
- [ ] Orphan money detection (audit)

### Phase 4: Frontend Components
- [ ] Contract management UI
- [ ] Payment entry form with allocation widget
- [ ] Financial dashboard with charts
- [ ] Expense tracking UI
- [ ] System-level intelligence view

### Phase 5: Integration & Testing
- [ ] Verify no orphan money exists
- [ ] Test all constraints
- [ ] Test recurring revenue calculations
- [ ] Test dashboard accuracy
- [ ] Performance testing

## Enforcement Rules (Non-Negotiable)

```
✅ CONTRACT CREATION
  - system_id: REQUIRED, FK constraint
  - client_id: REQUIRED, FK constraint
  - recurring validation: IF recurring_enabled THEN recurring_cycle + recurring_amount REQUIRED
  - payment: ONLY from valid contracts

✅ PAYMENT RECORDING
  - contract_id: REQUIRED, FK constraint
  - amount_received: MUST be > 0
  - CANNOT save until fully allocated

✅ MONEY ALLOCATION
  - SUM(allocations.amount) MUST equal payment.amount_received
  - allocation_type: ENUM validated
  - NO floating money
  - NO orphaned payments

✅ EXPENSE MANAGEMENT
  - category_id: REQUIRED, FK constraint
  - amount: MUST be > 0
  - Can be linked or standalone

✅ RECURRING LOGIC
  - recurring_cycle ONLY used if recurring_enabled=true
  - Cannot modify active recurring contracts mid-cycle
  - Churn tracking mandatory
```

## Success Criteria

After implementation, founder can answer with 100% accuracy:

1. ✅ What system was sold? (contract.system_id)
2. ✅ Is it recurring or one-time? (contract.recurring_enabled, contract.recurring_cycle)
3. ✅ How much was collected? (SUM payments for contract)
4. ✅ Where did every coin go? (allocations table)
5. ✅ How much was allocated to operating/vault/investment? (allocations by type)
6. ✅ What was spent on what? (expenses by category)
7. ✅ What is net profit? (revenue - expenses)
8. ✅ What is recurring exposure? (active recurring contracts summed)
9. ✅ Where is cash? (operating_balance + vault_balance)
10. ✅ Which system is most profitable? (system-level revenue - allocated expenses)

## Data Migration Strategy

For existing sales/deals:
1. Map current sales/deals to contracts (auto-create)
2. Migrate existing revenue_records to payments
3. Create zero-dollar allocations for historical reference
4. Mark as "legacy" to distinguish from new data entry
5. No data loss - audit trail preserved

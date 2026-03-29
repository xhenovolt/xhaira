# JETON CORE SYSTEMS UPGRADE - COMPLETE IMPLEMENTATION GUIDE

**Date:** March 24, 2026  
**Status:** FULL ARCHITECTURAL IMPLEMENTATION  
**Objective:** Transform Jeton from a tool into a complete operating system

---

## EXECUTIVE SUMMARY

Jeton now has three foundational pillars:

1. **SYSTEM TECH STACK TRACKING** - Know how every system is built
2. **MULTI-CURRENCY FINANCIAL ENGINE** - Accurate global transactions
3. **FULL HRM MODULE** - Complete employee and payroll management

These are CORE SYSTEMS, not patches. They define Jeton's identity as a company OS.

---

## PART 1: SYSTEM TECH STACK TRACKING

### Overview
Every system in Jeton must have a complete technology profile defining its architecture.

### Database Tables

#### `system_tech_profiles`
```sql
id UUID
system_id UUID (FK to systems)
language VARCHAR(100)
framework VARCHAR(100)
framework_version VARCHAR(50)
database VARCHAR(100)
db_version VARCHAR(50)
platform VARCHAR(100)  -- web, android, ios, cli
hosting VARCHAR(100)   -- vercel, aws, azure, gcp, heroku
deployment_url VARCHAR(500)
notes TEXT
created_at TIMESTAMP
updated_at TIMESTAMP
```

#### `system_modules`
```sql
id UUID
system_id UUID (FK to systems)
module_name VARCHAR(255)
description TEXT
status VARCHAR(50) -- active, inactive, deprecated, planned
module_url VARCHAR(500)
version VARCHAR(50)
created_at TIMESTAMP
updated_at TIMESTAMP
```

### API Endpoints

#### Get Tech Profiles for System
```
GET /api/systems/{systemId}/tech-profiles
Response: { success: true, data: [...tech profiles] }
```

#### Add Tech Profile
```
POST /api/systems/{systemId}/tech-profiles
Body: {
  language: "TypeScript",
  framework: "Next.js",
  framework_version: "14.0.0",
  database: "PostgreSQL",
  db_version: "16.0",
  platform: "web",
  hosting: "Vercel",
  deployment_url: "https://...",
  notes: "..."
}
```

#### Get Modules
```
GET /api/systems/{systemId}/modules
```

#### Add Module
```
POST /api/systems/{systemId}/modules
Body: {
  module_name: "Authentication",
  description: "OAuth 2.0 with JWT",
  status: "active",
  module_url: "https://...",
  version: "1.0.0"
}
```

### UI Components

#### Systems Page
- New tabs: "Tech Stack" and "Modules"
- Buttons to add tech profiles and modules
- Display complete architecture breakdown

#### Tech Stack Display
- Language, Framework, Database info
- Hosting and deployment details
- Edit and delete functionality

#### Modules Display
- Module name and description
- Version and status badges
- Links to module documentation
- Active/Inactive/Deprecated indicators

---

## PART 2: MULTI-CURRENCY FINANCIAL ENGINE

### Critical Fix: Original Amount Tracking

#### Problem (Before)
- USD 150 payment couldn't be properly converted
- No original currency tracking
- Exchange rates not stored for auditing
- Historic data loss on conversion

#### Solution (After)
```sql
-- New columns in payments table:
original_amount DECIMAL(15,2)      -- Amount in original currency (NEVER CHANGED)
original_currency VARCHAR(3)       -- Original currency code
exchange_rate DECIMAL(15,6)        -- Conversion rate used
amount_ugx DECIMAL(15,2)           -- Amount in UGX equivalent
```

### Payment Recording Flow

1. **User selects currency (UGX, USD, EUR, GBP, KES)**
2. **System fetches exchange rate** (from `exchange_rates` table or API)
3. **System calculates UGX automatically**
4. **All values preserved:**
   - `original_amount` = 150 (if USD)
   - `original_currency` = USD
   - `exchange_rate` = 3700
   - `amount_ugx` = 555,000
   - `amount` = 150 (for backward compatibility)

### Exchange Rate Management

#### Table: `exchange_rates`
```sql
id UUID
from_currency VARCHAR(3)
to_currency VARCHAR(3)
rate DECIMAL(15,6)
effective_date DATE
source VARCHAR(100) -- manual, api, system
notes TEXT
is_current BOOLEAN
created_at TIMESTAMP
```

#### Pre-Populated Rates (March 2026)
- USD → UGX: 3700.00
- EUR → UGX: 4050.00
- GBP → UGX: 4600.00
- KES → UGX: 28.50

#### API Endpoints

```
GET /api/exchange-rates                  -- Get current rates
GET /api/exchange-rates?from=USD&to=UGX -- Get specific rate
POST /api/exchange-rates                 -- Update rate
  {
    from_currency: "USD",
    to_currency: "UGX",
    rate: 3750.00,
    source: "manual",
    notes: "Updated based on market"
  }
```

### Validation Rules

- ✅ `original_amount` NEVER overwritten  
- ✅ `original_currency` NEVER NULL  
- ✅ `exchange_rate` always > 0  
- ✅ `amount_ugx` always calculated  
- ✅ User CANNOT override original values  
- ✅ All values immutable after payment creation

---

## PART 3: FULL HRM MODULE (EMPLOYEE & PAYROLL)

### Database Tables

#### Enhanced `staff` Table
```sql
-- New columns:
employment_type VARCHAR(50) -- full_time, part_time, contract, intern, freelance
join_date DATE
employment_status VARCHAR(50) -- active, on_leave, suspended, terminated
leave_balance INT
next_review_date DATE
last_review_date DATE
```

#### `employee_accounts`
```sql
id UUID
staff_id UUID (FK to staff) UNIQUE
account_id UUID (FK to accounts)
balance DECIMAL(15,2) -- current account balance
currency VARCHAR(3) DEFAULT 'UGX'
status VARCHAR(50) -- active, suspended, closed
notes TEXT
created_at TIMESTAMP
updated_at TIMESTAMP
```

#### `payouts`
```sql
id UUID
staff_id UUID (FK to staff)
employee_account_id UUID (FK to employee_accounts)
account_id UUID (FK to accounts)
amount DECIMAL(15,2) NOT NULL
currency VARCHAR(3) DEFAULT 'UGX'
payout_type VARCHAR(50) -- salary, bonus, commission, reimbursement, advance, other
status VARCHAR(50) -- pending, processed, completed, failed, cancelled
description TEXT
reference VARCHAR(255) -- cheque no, transfer ref, etc
payout_date DATE
processed_at TIMESTAMP
notes TEXT
created_by UUID
created_at TIMESTAMP
updated_at TIMESTAMP
```

### HR Module Structure

#### URL: `/app/hr`

#### Tabs

1. **Employees**
   - Complete staff directory
   - Filter by department, status
   - View employment details
   - Quick payout recording

2. **Employee Accounts**
   - Account assignments per employee
   - Current balance tracking
   - Multi-currency support
   - Status management

3. **Payroll**
   - Complete payout history
   - Filter by type (salary, bonus, commission)
   - Status tracking (pending → completed)
   - Search and reporting

### API Endpoints

#### Employee Accounts
```
GET /api/employee-accounts              -- List all
POST /api/employee-accounts             -- Create
GET /api/employee-accounts/{id}         -- Get detail
PATCH /api/employee-accounts/{id}       -- Update
DELETE /api/employee-accounts/{id}      -- Delete
```

#### Payouts
```
GET /api/payouts                        -- List all (filterable)
POST /api/payouts                       -- Record payout
GET /api/payouts/{id}                   -- Get detail
PATCH /api/payouts/{id}                 -- Update status
```

### Payout Recording Flow

1. **Navigate to HR → Payroll**
2. **Click "Record Payout"**
3. **Select:**
   - Employee
   - Linked account
   - Payout type (Salary, Bonus, etc)
   - Amount & currency
   - Date & reference

4. **System:**
   - ✅ Validates employee exists
   - ✅ Validates account exists
   - ✅ Records all fields
   - ✅ Updates employee_accounts balance (if needed)
   - ✅ Creates audit trail

### Integration Points

#### Payouts → Expenses
When a payout is marked "completed":
```
- Creates ledger entry (DEBIT from account)
- Updates employee account balance
- Links to staff member
- Can be reported as expense
```

#### Staff → Payroll
- Employee details (name, email, role)
- Department assignment
- Salary amount
- Employment status affects payout eligibility

---

## PART 4: VALIDATION RULES (CRITICAL)

### Global Rules - All Modules

```
✅ No payment without currency
✅ No staff without role
✅ No system without basic info
✅ No payout without currency
✅ No exchange rate < 0.01
✅ All amounts > 0
✅ All dates valid and not future (except planned)
✅ No duplicate staff members (email unique)
✅ No duplicate employee accounts per staff
```

### Multi-Currency Validation

```
✅ currency must be in known list (UGX, USD, EUR, GBP, KES)
✅ exchange_rate required if currency != UGX
✅ original_amount immutable after creation
✅ amount_ugx recalculated on rate change (NEW payments only)
```

### Payroll Validation

```
✅ staff_id must exist
✅ account_id must exist
✅ payout_type must be valid
✅ amount must be > 0
✅ only 1 employee_account per staff
✅ status transitions: pending → processed → completed
```

---

## PART 5: TESTING CHECKLIST

### Tech Stack Module
- [ ] Add tech profile to system
- [ ] Add multiple modules
- [ ] Edit tech profile
- [ ] Delete module
- [ ] Verify all fields saved correctly
- [ ] Check data persistence

### Multi-Currency
- [ ] Record payment in USD
- [ ] Verify original_amount = 150
- [ ] Verify amount_ugx calculated (150 × 3700 = 555,000)
- [ ] Check exchange rate stored
- [ ] Test with different currencies
- [ ] Verify exchange rate lookup
- [ ] Update exchange rate
- [ ] Verify new rate applied to NEW payments only

### HR Module
- [ ] Create employee account (link staff to account)
- [ ] Record salary payout
- [ ] Record bonus payout
- [ ] Record reimbursement
- [ ] Update payout status
- [ ] Check employee account balance updated
- [ ] Delete payout
- [ ] Verify payroll history
- [ ] Test filtering by type

### Cross-Module
- [ ] Tech stack doesn't interfere with deals
- [ ] Multi-currency doesn't break invoices
- [ ] HR module integrates with staff system
- [ ] Payroll integration with ledger/expenses
- [ ] All new modals work (modals.module.css exists)

---

## PART 6: MIGRATION COMMANDS

### Run Migrations
```bash
# Migration 946 - Tech stack and HR foundation
psql -d jeton_db -f migrations/946_system_tech_complete_and_hrm_foundation.sql

# Migration 947 - Multi-currency engine
psql -d jeton_db -f migrations/947_multi_currency_financial_engine.sql
```

### Verify Schema
```sql
-- Check new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'system_tech_profiles', 'system_modules', 'employee_accounts',
  'payouts', 'exchange_rates'
);

-- Check columns added to payments
SELECT column_name FROM information_schema.columns
WHERE table_name = 'payments' 
AND column_name IN ('original_amount', 'original_currency', 'exchange_rate', 'amount_ugx');
```

---

## PART 7: FINAL VERIFICATION

### Components Implemented
✅ Migration 946 - Tech stack & HR tables  
✅ Migration 947 - Multi-currency with data migration  
✅ TechProfileModal component  
✅ SystemModuleModal component  
✅ PayoutModal component  
✅ EmployeeAccountModal component  
✅ Tech profiles API endpoints  
✅ Modules API endpoints  
✅ Payouts API endpoints  
✅ Employee accounts API endpoints  
✅ Exchange rates API endpoints  
✅ Enhanced systems detail page (tech + modules tabs)  
✅ Complete HR module page with 3 tabs  
✅ Multi-currency payment logic  
✅ Validation rules enforcement  

### Files Modified/Created
**Migrations:**
- `946_system_tech_complete_and_hrm_foundation.sql`
- `947_multi_currency_financial_engine.sql`

**APIs:**
- `/api/systems/[id]/tech-profiles/route.js`
- `/api/systems/[id]/tech-profiles/[profileId]/route.js`
- `/api/systems/[id]/modules/route.js`
- `/api/systems/[id]/modules/[moduleId]/route.js`
- `/api/payouts/route.js`
- `/api/payouts/[id]/route.js`
- `/api/employee-accounts/route.js`
- `/api/employee-accounts/[id]/route.js`
- `/api/exchange-rates/route.js`
- `/api/payments/route.js` (ENHANCED)

**UI Components:**
- `/components/modals/TechProfileModal.js`
- `/components/modals/SystemModuleModal.js`
- `/components/modals/PayoutModal.js`
- `/components/modals/EmployeeAccountModal.js`

**Pages:**
- `/app/systems/[id]/page.js` (ENHANCED with tech & modules tabs)
- `/app/hr/page.js` (NEW - complete HR module)

---

## PART 8: DEPLOYMENT STEPS

### 1. Database
```bash
npm run db:migrate
# OR manually:
psql -d jeton_db -f migrations/946_*.sql
psql -d jeton_db -f migrations/947_*.sql
```

### 2. Restart Server
```bash
npm run dev
# OR in production:
npm run build && npm start
```

### 3. Navigate to Test
- Go to `/app/systems`
- Click on any system
- You should see "Tech Stack" and "Modules" tabs
- Go to `/app/hr` to test HR module

### 4. Verify Data
```sql
SELECT COUNT(*) FROM system_tech_profiles;
SELECT COUNT(*) FROM system_modules;
SELECT COUNT(*) FROM employee_accounts;
SELECT COUNT(*) FROM payouts;
SELECT COUNT(*) FROM exchange_rates WHERE is_current = true;
```

---

## PART 9: NEXT PHASES

### Phase 1 (Current) ✅
- Tech stack tracking
- Multi-currency engine
- HR module basics

### Phase 2 (Planned)
- Attendance tracking
- Performance reviews
- Leave management
- Automated salary calculations

### Phase 3 (Planned)
- API rate limiting per system
- Advanced analytics
- System health monitoring
- Capacity planning

### Phase 4 (Planned)
- Third-party integrations
- Webhook system
- Advanced automation
- Multi-tenancy support

---

## CONCLUSION

Jeton is no longer just a tool. It now has:

✅ **System Intelligence** - Knows exactly how systems are built  
✅ **Financial Accuracy** - Handles multiple currencies properly  
✅ **People Management** - Complete HR and payroll system  

This is the foundation of a **REAL company operating system**.

Every implementation follows the principle:  
**"Bad systems don't scale — they collapse."**

Jeton is now built to scale.

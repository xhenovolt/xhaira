# Xhaira Currency Conversion Agent Prompt
## One-Time USD → UGX Conversion for System "Consty"

### MISSION CRITICAL
Your task is to **identify all USD amounts across Xhaira for the "consty" system and convert them to Uganda Shillings (UGX)** as a one-time operation. This is NOT a recurring change - this is a data correction to fix historical USD tracking.

**Exchange Rate: 1 USD = 3,700 UGX** (as of March 2026)

---

## TOTAL SYSTEM SCOPE TO AUDIT

### 1. DATABASE TABLES - DIRECT MONEY FIELDS
Search PostgreSQL database for all records where:
- `system_id` = [consty_system_id] OR `system_name` = 'consty'
- Currency field shows 'USD' or NULL
- Amount fields contain money values

**Tables to audit:**
```
1. payments
   - Columns: amount, currency, original_amount, original_currency, amount_ugx, exchange_rate
   - WHERE: system_id = [consty] AND (currency = 'USD' OR original_currency = 'USD')
   - ACTION: Convert all USD → UGX, update original_currency to 'UGX', recalculate amount_ugx

2. ledger / ledger_entries
   - Columns: amount, currency, original_currency, debit, credit
   - WHERE: account_id IN (SELECT id FROM accounts WHERE system_id = [consty]) AND currency = 'USD'
   - ACTION: Update all debit/credit amounts to UGX equivalent

3. invoices
   - Columns: total_amount, currency, subtotal, tax_amount, discount_amount
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Convert all invoice amounts from USD → UGX

4. deals
   - Columns: value, currency
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Multiply value by 3700, update currency to 'UGX'

5. proposals
   - Columns: amount, currency, total_value
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Convert all proposal amounts

6. expenses / costs
   - Columns: amount, currency, category
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Convert all expense amounts

7. payouts
   - Columns: amount, currency, payout_type
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Convert all payout amounts to UGX

8. accounts
   - Columns: balance, default_currency
   - WHERE: system_id = [consty] AND default_currency = 'USD'
   - ACTION: Update balance = balance * 3700, default_currency = 'UGX'

9. quotes
   - Columns: amount, currency
   - WHERE: system_id = [consty] AND currency = 'USD'
   - ACTION: Convert quote amounts

10. timesheets / time_entries
    - Columns: hourly_rate, total_cost, currency
    - WHERE: system_id = [consty] AND currency = 'USD'
    - ACTION: Convert hourly_rate and total_cost to UGX

11. budgets / budget_allocations
    - Columns: allocated_amount, spent_amount, currency
    - WHERE: system_id = [consty] AND currency = 'USD'
    - ACTION: Convert allocated and spent amounts

12. financial_summaries
    - Columns: total_revenue, total_expenses, net_profit, currency
    - WHERE: system_id = [consty] AND currency = 'USD'
    - ACTION: Recalculate and convert all financial summary amounts
```

### 2. APPLICATION-LEVEL DATA - STORED IN JSONB/TEXT FIELDS
Search for any stored monetary values in JSON or unstructured fields:
```
1. Settings/Configuration tables
   - JSONB columns containing currency preferences
   - WHERE: settings_key LIKE '%currency%currency_preference%' OR
           settings_value LIKE '%USD%' AND system_id = [consty]
   - ACTION: Update system_default_currency from 'USD' to 'UGX'

2. Activity logs / Transaction logs
   - Any log entries showing USD transactions
   - ACTION: Add annotation "CONVERTED USD→UGX (3700:1)" to historical records

3. Comments/Notes with embedded amounts
   - WHERE: content LIKE '%$%' OR content LIKE '%USD%' AND created_for_system = [consty]
   - ACTION: Flag for manual review (don't auto-update)
```

### 3. CACHE & REPORT DATA
**Clear cache to force recalculation:**
- Redis cache keys containing financial summaries for consty
- Invalidate all cached reports for this system
- Force recalculation of all dashboards showing financial data

**Regenerate reports:**
- Profit & loss statement (incorporate USD→UGX conversion)
- Cash flow analysis
- Revenue summary
- Expense breakdown
- Financial health dashboard

---

## CONVERSION FORMULA (CRITICAL)
For each USD record:
```
new_amount_ugx = old_amount_usd * 3700
new_currency = 'UGX'
original_currency = 'USD'
exchange_rate = 3700.00
amount_ugx = new_amount_ugx
conversion_timestamp = NOW()
conversion_note = 'Bulk USD→UGX conversion (1:3700)'
```

### For records with existing multi-currency fields:
```
IF original_currency IS NULL:
  SET original_currency = 'USD'
  SET original_amount = current_amount
  SET exchange_rate = 3700.00
  SET amount_ugx = current_amount * 3700

IF original_currency = 'USD' AND amount_ugx IS NULL:
  SET amount_ugx = original_amount * 3700
```

---

## VALIDATION REQUIREMENTS (BEFORE COMMIT)

1. **Count verification:**
   - Count USD payments BEFORE conversion
   - Count UGX payments AFTER conversion
   - Should be equal (within reasonable margins for changed records)

2. **Amount verification (sample audit):**
   - Pick 5 random USD records
   - Verify: new_ugx_amount = old_usd_amount * 3700
   - Verify currency field updated to 'UGX'
   - Verify original_currency = 'USD'

3. **Financial totals:**
   - Calculate total_original_usd = SUM(original_amount) WHERE original_currency = 'USD'
   - Calculate total_ugx = SUM(amount_ugx) WHERE original_currency = 'USD'
   - Verify: total_ugx ≈ total_original_usd * 3700 (allow ±0.01% variance for rounding)

4. **Null checks:**
   - Verify no NULL amounts remain in amount_ugx for USD records
   - Verify no NULL currency values for converted records
   - Verify exchange_rate field populated for all conversions

5. **Data integrity:**
   - Verify no duplicate payment entries created
   - Verify no amounts duplicated or doubled
   - Verify all account balances reconcile

---

## SQL QUERIES TO EXECUTE (IN ORDER)

### Step 1: Identify the consty system ID
```sql
SELECT id, system_name FROM systems 
WHERE system_name ILIKE '%consty%' OR system_name ILIKE '%const%';
```

### Step 2: Count USD records BY TABLE
```sql
SELECT table_name, COUNT(*) as usd_records FROM (
  SELECT 'payments' as table_name FROM payments WHERE system_id = [CONSTY_ID] AND currency = 'USD'
  UNION ALL
  SELECT 'invoices' FROM invoices WHERE system_id = [CONSTY_ID] AND currency = 'USD'
  UNION ALL
  SELECT 'deals' FROM deals WHERE system_id = [CONSTY_ID] AND currency = 'USD'
  UNION ALL
  SELECT 'accounts' FROM accounts WHERE system_id = [CONSTY_ID] AND default_currency = 'USD'
) t
GROUP BY table_name;
```

### Step 3: Backup original data
```sql
CREATE TABLE usd_conversion_backup_[timestamp] AS
SELECT * FROM payments WHERE system_id = [CONSTY_ID] AND currency = 'USD';
-- Repeat for all tables with USD data
```

### Step 4: Convert each table
```sql
-- PAYMENTS TABLE
UPDATE payments 
SET 
  original_amount = COALESCE(original_amount, amount),
  original_currency = 'USD',
  amount = amount * 3700,
  amount_ugx = amount * 3700,
  exchange_rate = 3700.00,
  currency = 'UGX',
  updated_at = NOW()
WHERE system_id = [CONSTY_ID] AND currency = 'USD';

-- LEDGER TABLE
UPDATE ledger 
SET 
  original_currency = 'USD',
  amount = amount * 3700,
  amount_ugx = amount * 3700,
  exchange_rate = 3700.00,
  currency = 'UGX',
  updated_at = NOW()
WHERE account_id IN (
  SELECT id FROM accounts WHERE system_id = [CONSTY_ID]
) AND currency = 'USD';

-- ACCOUNTS TABLE
UPDATE accounts 
SET 
  balance = balance * 3700,
  default_currency = 'UGX',
  updated_at = NOW()
WHERE system_id = [CONSTY_ID] AND default_currency = 'USD';

-- INVOICES TABLE
UPDATE invoices 
SET 
  total_amount = total_amount * 3700,
  subtotal = subtotal * 3700,
  tax_amount = COALESCE(tax_amount, 0) * 3700,
  discount_amount = COALESCE(discount_amount, 0) * 3700,
  currency = 'UGX',
  updated_at = NOW()
WHERE system_id = [CONSTY_ID] AND currency = 'USD';

-- DEALS TABLE
UPDATE deals 
SET 
  value = value * 3700,
  currency = 'UGX',
  updated_at = NOW()
WHERE system_id = [CONSTY_ID] AND currency = 'USD';

-- PAYOUTS TABLE
UPDATE payouts 
SET 
  amount = amount * 3700,
  currency = 'UGX',
  updated_at = NOW()
WHERE staff_id IN (
  SELECT id FROM staff WHERE system_id = [CONSTY_ID]
) AND currency = 'USD';
```

### Step 5: Verify conversions
```sql
-- Check no USD records remain in payments
SELECT COUNT(*) as remaining_usd_payments FROM payments 
WHERE system_id = [CONSTY_ID] AND currency = 'USD';
-- Expected: 0

-- Check totals
SELECT 
  COUNT(*) as total_records,
  SUM(original_amount) as total_original_usd,
  SUM(amount_ugx) as total_converted_ugx,
  (SUM(amount_ugx) / NULLIF(SUM(original_amount), 0)) as conversion_ratio
FROM payments 
WHERE system_id = [CONSTY_ID] AND original_currency = 'USD';
-- Expected conversion_ratio: ~3700.00

-- Check for NULL amounts
SELECT COUNT(*) as null_checks FROM payments
WHERE system_id = [CONSTY_ID] AND (amount IS NULL OR amount_ugx IS NULL OR currency IS NULL);
-- Expected: 0
```

---

## LOGGING & DOCUMENTATION

Create a conversion log entry:
```sql
INSERT INTO conversion_log (
  system_id, 
  conversion_type, 
  from_currency, 
  to_currency, 
  exchange_rate, 
  records_converted, 
  total_amount_original, 
  total_amount_converted,
  conversion_timestamp,
  notes
) VALUES (
  [CONSTY_ID],
  'bulk_currency_conversion',
  'USD',
  'UGX',
  3700.00,
  [RECORD_COUNT],
  [TOTAL_USD],
  [TOTAL_UGX],
  NOW(),
  'One-time bulk conversion for consty system. All USD amounts converted to UGX (1:3700)'
);
```

---

## ROLLBACK PLAN (IF NEEDED)

If conversion fails or creates inconsistencies:

```sql
-- Restore from backup
TRUNCATE payments CASCADE;
INSERT INTO payments SELECT * FROM usd_conversion_backup_[timestamp];

-- Repeat for all affected tables
-- Investigate error in agent logs
-- Re-run with corrections
```

---

## FINAL CHECKLIST

Before declaring this complete:
- [ ] System ID identified correctly
- [ ] All USD records counted and listed
- [ ] Backup tables created for all affected tables
- [ ] Conversion executed without errors on all tables
- [ ] Verification queries show 0 remaining USD records
- [ ] Conversion ratio validates at ~3700.00
- [ ] No NULL amounts in converted records
- [ ] Financial totals reconcile
- [ ] Conversion log entry created
- [ ] Cache invalidated and reports regenerated
- [ ] Git commit created with message: "Fix: Convert consty system currency from USD to UGX (1:3700)"
- [ ] Deployment tested in staging (if available)

---

## SUCCESS CRITERIA

✅ **This conversion is complete when:**
1. Zero USD records remain in any table for consty system
2. All monetary amounts properly converted (multiplied by 3700)
3. All currency fields updated to 'UGX'
4. Exchange rate metadata populated
5. Financial reports regenerated with UGX values
6. Data audit passes all validation checks
7. Git history reflects the one-time conversion

---

**NOTE: This is a ONE-TIME operation. After this completes, the consty system operates entirely in UGX. Future payments/transactions will use the standard multi-currency exchange rate table if needed.**

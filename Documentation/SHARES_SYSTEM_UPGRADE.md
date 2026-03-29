# Jeton Share System Redesign - Investor Grade Equity

## 🎯 Overview

Your share system has been upgraded from a basic "1M shares" model to a **professional equity scarcity system** used by real founders and investors.

### Core Philosophy

Instead of arbitrary large numbers, companies now control **equity scarcity** intentionally:
- Fewer shares = higher per-share value  
- 100 shares at 10B valuation = 100M per share (real value)
- Instead of 1M shares at 920K = harder to understand

## 📋 What Changed

### 1. Database Schema

**Before:**
```sql
shares TABLE:
- total_shares: BIGINT (e.g., 1,000,000)
- par_value: DECIMAL (e.g., 920,000)
```

**After:**
```sql
shares TABLE:
- authorized_shares: BIGINT (e.g., 100) ← Controls scarcity
- company_valuation: DECIMAL (e.g., 10,000,000,000 UGX)
- price_per_share CALCULATED: valuation / authorized_shares
```

**Migration**: `migrations/012_upgrade_to_authorized_shares.sql`

### 2. Share Price Logic

**Before (Static):**
```
Share Price = Always some fixed par value (920K)
Not based on company value
```

**After (Dynamic):**
```
Price Per Share = Company Valuation / Authorized Shares

Example:
- Company Value: 10 Billion UGX
- Authorized Shares: 100
- Price Per Share: 100M UGX ← Real, meaningful price

If valuation changes to 20B:
- Price immediately updates to 200M per share
```

### 3. Ownership Calculations

**Before:**
```
Ownership % = (shares / 1,000,000) × 100
= Always tiny percentages
```

**After:**
```
Ownership % = (shares / authorized_shares) × 100

Example: 30 shares out of 100 = 30% (clear!)
```

### 4. Share Value in Cap Table

**Before:**
```
Share Value = shares × 920K
= Calculated at fixed par value
```

**After:**
```
Share Value = shares × (company_valuation / authorized_shares)

Example:
- Allocate 30 shares
- Company 10B, 100 authorized
- Value = 30 × 100M = 3 Billion UGX
- If company value increases, allocation value increases too!
```

## 🔧 API Changes

### GET /api/shares

**Response includes:**
```json
{
  "authorized_shares": 100,
  "company_valuation": 10000000000,
  "shares_allocated": 30,
  "shares_remaining": 70,
  "price_per_share": 100000000,
  "allocation_percentage": 30.0
}
```

### PUT /api/shares

**Update structure:**
```json
{
  "authorized_shares": 100,
  "company_valuation": 20000000000
}
```

**Validations:**
- ✅ Cannot reduce authorized_shares below allocated shares
- ✅ Company valuation must be ≥ 0
- ⚠️ Warns before reducing authorized shares
- 🔒 Prevents over-allocation

### GET /api/shares/allocations

**Response includes calculated fields:**
```json
{
  "shares_allocated": 30,
  "authorized_shares": 100,
  "company_valuation": 10000000000,
  "price_per_share": 100000000,
  "ownership_percentage": 30.0,
  "share_value": 3000000000
}
```

### POST /api/shares/allocations

**Validation:**
```
If allocated + new > authorized:
  ❌ Error: "Cannot allocate 40 shares. 
             Only 70 available (100 authorized, 30 allocated)"
```

## 🎨 UI/UX Improvements

### New Metrics Dashboard

Five key cards now displayed:
1. **AUTHORIZED SHARES** - The scarcity lever (100, not 1M)
2. **COMPANY VALUATION** - Your company's value in UGX
3. **PRICE PER SHARE** - Auto-calculated (valuation ÷ authorized)
4. **ALLOCATED SHARES** - How many given out
5. **REMAINING** - Available to allocate

### Configuration Panel

"Configure Equity Structure" button opens modal with:
- **Authorized Shares** input (min: allocated, default: 100)
- **Company Valuation** input (default: 0)
- **Live Preview** of price per share
- **Warning** if reducing authorized shares below allocated

### Share Allocations Table

Shows real cap table:

| Owner | Shares | Ownership % | Value (UGX) | Actions |
|-------|--------|-------------|-------------|---------|
| Founder | 60 | 60% | 6B | Edit/Delete |
| Investor | 30 | 30% | 3B | Edit/Delete |
| Employees | 10 | 10% | 1B | Edit/Delete |
| **TOTAL** | **100** | **100%** | **10B** | |

### Smart Modals

1. **Allocation Modal**
   - Shows max shares you can allocate
   - Real-time ownership % preview
   - Real-time value preview

2. **Configuration Modal**
   - Preview of new price per share
   - Safe defaults (100 shares, 0 valuation)

3. **Warning Modal** (for reducing shares)
   - Shows current allocation
   - Warns about no remaining capacity
   - Requires explicit confirmation

4. **Delete Confirmation**
   - Clear warning
   - Cannot be undone

## 📊 Real-World Examples

### Example 1: Typical Startup

```
Authorized Shares: 100
Company Valuation: 500M UGX (Series A valuation)
Price Per Share: 5M UGX

Cap Table:
- Founder: 60 shares = 60% = 300M UGX
- Investors: 30 shares = 30% = 150M UGX
- Employees: 10 shares = 10% = 50M UGX
```

If company grows to 1B valuation:
- Price Per Share: 10M UGX (doubles!)
- Founder's stake: 600M UGX (doubles!)
- Everyone's allocation value increases automatically

### Example 2: High Scarcity

```
Authorized Shares: 10 (extreme scarcity)
Company Valuation: 1B UGX
Price Per Share: 100M UGX

One share = 100M UGX
Perfect for high-value companies
```

### Example 3: Many Shares

```
Authorized Shares: 10,000 (more distributed)
Company Valuation: 1B UGX
Price Per Share: 100K UGX

More granular allocations possible
```

## 🔐 Guardrails & Constraints

### Cannot Reduce Authorized Shares Below Allocated

```
Current: 100 authorized, 30 allocated
Try to set: 25 authorized
❌ Error: "Cannot reduce authorized shares below 30 already allocated"
```

### Prevent Over-Allocation

```
Authorized: 100
Currently allocated: 60
Try to allocate: 50
❌ Error: "Cannot allocate 50 shares. Only 40 available."
```

### Warning Before Structural Changes

If you reduce authorized shares with existing allocations:
- ⚠️ Modal warns
- Shows current & new allocation percentage
- Shows remaining capacity will be zero
- Requires explicit "Proceed" confirmation

## 🚀 Migration Path

### For Fresh Database

```bash
node scripts/init-db.js
```

Creates shares table with:
- `authorized_shares = 100`
- `company_valuation = 0`

### For Existing Database

```bash
node scripts/run-sql-migrations.js
```

Runs `012_upgrade_to_authorized_shares.sql` which:
- Adds new columns
- Migrates existing data
- Sets authorized_shares = 100 (new default)
- Drops old par_value and total_shares columns

## 💡 How to Use

### Step 1: Configure Equity Structure

1. Go to **Share Management** page
2. Click **"Configure Equity Structure"**
3. Set:
   - **Authorized Shares**: How many shares you'll ever issue (e.g., 100)
   - **Company Valuation**: Your company's value in UGX (e.g., 1,000,000,000)
4. See preview of price per share
5. Click **Save**

### Step 2: Allocate Shares

1. Click **"Allocate Shares"** button
2. Fill in:
   - **Owner Name**: Who gets the shares
   - **Email**: (optional) Contact info
   - **Shares to Allocate**: How many (e.g., 30)
   - **Allocation Date**: When given
   - **Vesting Details**: (optional) Vesting schedule
3. See preview:
   - Ownership %: 30% (30/100)
   - Share Value: 300M UGX
4. Click **Allocate**

### Step 3: Monitor Cap Table

The table shows everyone's ownership in real terms:
- **Shares**: Absolute number
- **Ownership %**: Real percentage
- **Value**: In UGX (updates if valuation changes)

### Step 4: Update Valuation

When your company value changes:
1. Click **"Configure Equity Structure"**
2. Update **Company Valuation** only
3. All allocations automatically recalculate value
4. Ownership % stays the same
5. Price per share updates

## 🧠 Key Insights

### Why Authorized Shares = Scarcity

Real equity works with scarcity:
- Apple has billions of shares = cheap per share = harder to understand ownership
- Early startups often have 10M-100M shares = more reasonable
- Our system: **100 shares is optimal** for clarity

### Price Per Share Reflects Company Value

```
If I own 30 shares:
- Company 1B, 100 authorized → I own 300M
- Company 2B, 100 authorized → I own 600M
- It's real ownership value!
```

NOT:
```
- Fixed 920K per share (old system)
- Doesn't reflect company growth
- Disconnected from reality
```

### Flexible & Professional

Now supports:
- Founders thinking about their stake
- Investors understanding ownership %
- Employees seeing real value
- Multiple rounds (just update valuation)

## 🔄 Future Enhancements

Possible additions (not yet implemented):
- Multiple share classes (preferred, common)
- Stock option pools
- Warrant tracking
- ESOP management
- Scenario modeling ("What if valuation doubles?")
- Share buybacks
- Exercise tracking

## 📝 Files Changed

### Database
- `migrations/012_upgrade_to_authorized_shares.sql` - Schema upgrade

### Backend
- `scripts/init-db.js` - Updated initialization
- `src/app/api/shares/route.js` - New GET/PUT logic
- `src/app/api/shares/allocations/route.js` - Updated validation

### Frontend
- `src/app/app/shares/page.js` - Complete redesign

## ✅ Testing Checklist

- [ ] Configure 100 authorized, 1B valuation
- [ ] Verify price per share = 10M
- [ ] Allocate 30 shares to founder
- [ ] Verify ownership = 30%
- [ ] Verify value = 300M
- [ ] Allocate 20 shares to investor
- [ ] Verify total = 50%
- [ ] Try allocating 60 (should fail - only 70 available)
- [ ] Update valuation to 2B
- [ ] Verify prices doubled
- [ ] Try reducing authorized to 40 (should warn)
- [ ] Confirm reduction
- [ ] Try allocating (should fail - no remaining)

## 🎓 Mental Model

Think of it like this:

```
OLD SYSTEM (Bad):
- "I'm giving you 100,000 shares out of 1,000,000"
- = 10% (feels small even though it's big)
- = Worth 92 Billion UGX (no one understands this)

NEW SYSTEM (Good):
- "I'm giving you 10 shares out of 100"
- = 10% (clear and real)
- = Worth 1 Billion UGX (matches company value!)
```

The math is clearer. The ownership is real. The value scales with the company.

---

**This is now investor-grade equity software.** 🚀

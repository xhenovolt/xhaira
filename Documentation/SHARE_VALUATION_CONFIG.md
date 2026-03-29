# Share Valuation Configuration - 920K UGX Per Share

## Summary of Changes

You now have a properly configured shares system with:
- **Per Share Value**: 920K UGX (920,000 UGX)
- **Total Shares Available**: 1,000,000 (1M maximum)
- **Total Company Value**: 920B UGX (when all shares fully allocated)

## What Was Changed

### 1. Database Schema (scripts/init-db.js)
- Updated `shares` table default `par_value` from 1.00 to **920000.00**
- Initial INSERT now creates shares with 920K UGX par value
- Ensures new database setup uses correct valuation

### 2. Shares Configuration API (src/app/api/shares/route.js)
- Added validation to prevent total_shares exceeding **1,000,000**
- Changed default `par_value` from 1.00 to **920000.00**
- Returns clear error message if attempting to exceed 1M shares

### 3. Share Allocations API (src/app/api/shares/allocations/route.js)
- Updated to use `par_value` from shares table instead of share_price_history
- Each allocated share is valued at 920K UGX
- Share value calculation: **shares_allocated × 920,000 UGX**

### 4. Shares Management UI (src/app/app/shares/page.js)
- Config form now initializes with:
  - Total Shares: 1,000,000
  - Par Value: 920,000 UGX
- Added client-side validation for max 1M shares
- Added help text showing default par value and max shares limit
- Updated input constraints (max="1000000")

### 5. Database Migration (migrations/011_set_share_par_value.sql)
- New migration file to update existing shares configuration
- Sets par_value to 920K UGX for all common shares
- Adds documentation comments to shares table columns

## How It Works Now

### Share Pricing Model
```
Company Valuation = Total Allocated Shares × 920,000 UGX
Share Price = Company Valuation / Total Shares (1M)

Example:
- If 500K shares allocated: Company value = 460B UGX
- Share price: 460B / 1M = 460K UGX per share
- Each allocated share is worth 920K UGX (par value)
```

### Allocated Shares Valuation
When you allocate shares to team members or investors:
```
Allocation Value = Number of Shares × 920,000 UGX

Example:
- Allocate 100K shares to founder
- Value: 100,000 × 920,000 = 92B UGX
```

## Running the Migration

To apply these changes to an existing database:

```bash
# Run all pending migrations including the new share configuration
node scripts/run-sql-migrations.js
```

Or for a fresh setup:

```bash
# Initialize database with new share configuration
node scripts/init-db.js
```

## Frontend Features

### Share Configuration Modal
- Set Total Shares (max 1M)
- Set Par Value in UGX
- Real-time calculation of share price impact
- Validation prevents exceeding limits

### Share Allocations
- Allocate shares to team members/investors
- Automatic calculation of allocation value (shares × 920K UGX)
- Track vesting schedules
- Show ownership percentage

### Dashboard Display
- Share Price: Current valuation ÷ total shares
- Per Share: Shows 920K UGX par value
- Total Shares: Shows 1M authorized shares
- Allocated: Shows how many shares are allocated
- Remaining: Shows available shares for future allocation

## Key Constraints

| Parameter | Value | Notes |
|-----------|-------|-------|
| Total Shares | 1,000,000 | Maximum authorized shares (1M limit) |
| Par Value | 920,000 UGX | Fixed value per share |
| Min Shares to Offer | 0 | Can offer fewer if needed |
| Max Shares to Offer | 1,000,000 | Cannot exceed total authorized |

## Example Allocations

With your 1M shares @ 920K UGX each:

| Scenario | Shares | Value | % of Company |
|----------|--------|-------|--------------|
| Founder Gets | 600,000 | 552B UGX | 60% |
| Investor Round | 300,000 | 276B UGX | 30% |
| Employee Pool | 100,000 | 92B UGX | 10% |
| **Total** | **1,000,000** | **920B UGX** | **100%** |

## Notes

- The `par_value` is the nominal/face value used for calculating share holder valuations
- It represents the base valuation per share (920K UGX)
- Actual share price shown on dashboard = Company Strategic Value ÷ Total Shares
- Allocated shares are always valued at par value (920K UGX) for cap table calculations

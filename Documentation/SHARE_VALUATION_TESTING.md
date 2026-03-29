# Share Valuation Configuration - Verification & Testing

## Quick Start

To enable the new share configuration (920K UGX per share, max 1M shares):

### Option 1: Fresh Database Setup
```bash
node scripts/init-db.js
```

### Option 2: Update Existing Database
```bash
node scripts/run-sql-migrations.js
```

## Verification Checklist

### Database Configuration
- [ ] Run `psql <database> -c "SELECT total_shares, par_value FROM shares;"`
- [ ] Expected: `total_shares = 1000000`, `par_value = 920000.00`

### API Endpoints

#### Get Share Configuration
```bash
curl -X GET http://localhost:3000/api/shares \
  -H "Authorization: Bearer <token>"
```

Expected response:
```json
{
  "success": true,
  "data": {
    "total_shares": 1000000,
    "par_value": 920000,
    "shares_allocated": 0,
    "shares_remaining": 1000000,
    "class_type": "common"
  }
}
```

#### Update Share Configuration (Validation Test)
```bash
# This should FAIL - exceeds 1M max
curl -X PUT http://localhost:3000/api/shares \
  -H "Content-Type: application/json" \
  -d '{"total_shares": 1500000, "par_value": 920000}'
```

Expected error:
```json
{
  "success": false,
  "error": "Total shares cannot exceed 1,000,000 (1M shares maximum)"
}
```

#### Get Share Allocations
```bash
curl -X GET http://localhost:3000/api/shares/allocations \
  -H "Authorization: Bearer <token>"
```

Expected: Allocations show `share_value = shares_allocated × 920000`

### Frontend Pages

#### Share Management Page (/app/shares)
- [ ] Configuration card shows:
  - Total Shares: 1,000,000
  - Price Per Share: 920,000 UGX
- [ ] Config modal has:
  - Total Shares input (max="1000000")
  - Par Value input (default 920000)
- [ ] Allocations show correct values at 920K UGX per share

#### Dashboard (/app/dashboard)
- [ ] Share Price Widget shows:
  - Per Share: `Company Valuation / 1,000,000`
  - Total Shares: 1,000,000
- [ ] Calculations are consistent

## Testing Scenarios

### Scenario 1: Full Allocation (100% of shares)
```
Allocate: 1,000,000 shares to Founder
Expected Value: 1,000,000 × 920,000 = 920B UGX
Expected Ownership: 100%
```

### Scenario 2: Multiple Allocations
```
Founder: 600,000 shares = 552B UGX (60%)
Investors: 300,000 shares = 276B UGX (30%)
Employees: 100,000 shares = 92B UGX (10%)
Total: 1,000,000 shares = 920B UGX (100%)
```

### Scenario 3: Partial Allocation
```
Allocate: 250,000 shares
Expected Value: 250,000 × 920,000 = 230B UGX
Expected Ownership: 25%
Remaining Unallocated: 750,000 shares
```

### Scenario 4: Share Price with Company Valuation
```
Company Valuation: 460B UGX (from deals, assets, IP, etc.)
Total Shares: 1,000,000
Share Price (market): 460B / 1M = 460K UGX
Par Value: 920K UGX (book value)
```

## Key Equations

```
Total Company Value (Par) = Total Authorized Shares × Par Value
                          = 1,000,000 × 920,000 UGX
                          = 920B UGX

Shareholder Value = Shares Owned × Par Value
                  = Shares Owned × 920,000 UGX

Share Price (Market) = Company Strategic Value / Total Authorized Shares

Ownership Percentage = (Shares Owned / Total Authorized Shares) × 100%
```

## Common Issues & Solutions

### Issue: Share price showing very low values
**Cause**: Par value not updated in database
**Fix**: Run migration `node scripts/run-sql-migrations.js`

### Issue: Cannot allocate more than 1M shares
**Cause**: Validation is working correctly
**Fix**: This is expected - system prevents over-allocation

### Issue: Share values not matching expectations
**Cause**: Using old share_price_history instead of par_value
**Fix**: Allocations API updated to use par_value from shares table

## Migration Notes

After running the migration:

1. **Existing shares will be updated** to par_value = 920,000 UGX
2. **New allocations** will automatically use 920K UGX per share
3. **Share price history** can still be used for market tracking
4. **Par value** is independent of market fluctuations

## Rollback (if needed)

To revert to previous configuration:

```sql
UPDATE shares SET par_value = 1.00 WHERE class_type = 'common';
```

But this is not recommended as the new configuration properly valuates shares.

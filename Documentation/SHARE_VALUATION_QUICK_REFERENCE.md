# Share Valuation Configuration - Quick Reference

## Current Configuration

| Setting | Value |
|---------|-------|
| **Per Share Value** | 920,000 UGX (920K) |
| **Total Authorized Shares** | 1,000,000 (1M maximum) |
| **Total Company Par Value** | 920 Billion UGX |
| **Minimum Shares** | 0 (if needed) |
| **Maximum Shares** | 1,000,000 (enforced) |

## How Share Valuation Works

### Par Value (Book Value)
- **Fixed value**: Each share is always worth 920,000 UGX for cap table purposes
- **Used for**: Shareholder valuations, cap table calculations
- **Formula**: Shareholder Value = Shares Owned × 920,000 UGX

### Market Share Price (Variable)
- **Depends on**: Company's strategic valuation (from deals, assets, IP, etc.)
- **Formula**: Market Price = Company Valuation ÷ 1,000,000 shares
- **Example**: If company is worth 460B UGX, each share trades at 460K UGX

## Examples

### Example 1: Cap Table with 920B Valuation
```
Founder allocation:     600,000 shares × 920K UGX = 552B UGX (60% ownership)
Investor round 1:       300,000 shares × 920K UGX = 276B UGX (30% ownership)
Employee pool:          100,000 shares × 920K UGX =  92B UGX (10% ownership)
                       ───────────────            ─────────────
Total:                1,000,000 shares × 920K UGX = 920B UGX (100%)
```

### Example 2: Company with Lower Valuation
```
Current company valuation (from strategic value): 460B UGX
Market share price: 460B ÷ 1,000,000 = 460K UGX per share
Par value (cap table): 920K UGX per share
Difference: Par value is higher (premium valuation)
```

### Example 3: Company with Higher Valuation
```
Current company valuation: 1.84 Trillion UGX (1.84T)
Market share price: 1.84T ÷ 1,000,000 = 1.84M UGX per share
Par value (cap table): 920K UGX per share
Note: Market price exceeds par value (company appreciating)
```

## Configuration Impact

### For Share Allocation
- When you allocate 100,000 shares to someone
- They receive **100,000 × 920K UGX = 92B UGX** in valuation
- This represents their ownership stake in the company

### For Cap Table
- Shows clearly how much each person's stake is worth at par
- Independent of market fluctuations
- Used for legal/regulatory purposes

### For Dashboard
- **Per Share value**: Calculated as Company Valuation ÷ 1,000,000
- **Total Shares**: Shows 1,000,000
- **Allocated**: Shows how many shares given out
- **Remaining**: Shows unallocated shares available

## Key Constraints Enforced

### Total Shares Cannot Exceed 1,000,000
- Prevents over-issuance of shares
- Maintains cap table integrity
- Enforced in API and UI with validation

### Par Value Fixed at 920,000 UGX
- Consistent base for cap table
- Cannot be changed per share individually
- Can be changed globally (requires careful consideration)

## Use Cases

### Initial Founder Allocation
```
Give founder control with 60% equity:
Allocate 600,000 shares = 552B UGX at par
Percentage: 600,000 ÷ 1,000,000 = 60%
```

### Angel/Seed Investment
```
Raise capital with 20% dilution to investors:
Allocate 200,000 shares to investors
Remaining 800,000 shares for founder & employees
Each share = 920K UGX at par
```

### Employee Stock Option Pool
```
Reserve 10% for employees:
100,000 shares × 920K = 92B UGX employee pool
Can vest or grant over time
Each share worth 920K UGX base

If company grows to 1.84T valuation:
Each share trades at 1.84M UGX (market)
Employees benefit from appreciation beyond par value
```

## Technical Details

### Files Modified
1. **scripts/init-db.js** - Database initialization
2. **src/app/api/shares/route.js** - Share configuration API
3. **src/app/api/shares/allocations/route.js** - Allocation valuations
4. **src/app/app/shares/page.js** - Frontend UI
5. **migrations/011_set_share_par_value.sql** - Migration script

### Database Columns
```sql
shares.total_shares    -- Total authorized (max 1,000,000)
shares.par_value       -- Face value per share (920,000 UGX)
share_allocations.shares_allocated  -- Shares given to shareholders
```

### Calculations
```javascript
// Share value in cap table
share_value = shares_allocated × par_value
           = shares_allocated × 920,000

// Ownership percentage
ownership_pct = (shares_allocated / total_shares) × 100
             = (shares_allocated / 1,000,000) × 100

// Market share price
market_price = company_valuation / total_shares
            = company_valuation / 1,000,000
```

## Next Steps

1. **Apply Changes**: Run migration if updating existing database
   ```bash
   node scripts/run-sql-migrations.js
   ```

2. **Allocate Shares**: Go to Share Management page
   - Configure share structure
   - Add shareholder allocations
   - Track cap table

3. **Monitor Valuation**: Watch dashboard
   - Share price updates as company value changes
   - Par value stays fixed at 920K
   - Allocation values automatically calculated

## Questions & Answers

**Q: Why 920K UGX per share?**
A: This is a reasonable denomination that makes shares valuable without being excessive.

**Q: Why 1M shares maximum?**
A: Prevents excessive share issuance and maintains meaningful percentages for allocations.

**Q: Can I change the par value?**
A: Yes, but it's a significant change. All allocations would need recalculation. Not recommended.

**Q: What if I need more than 1M shares?**
A: You would need to consolidate (do a stock split in reverse) or modify the system. This is a business decision, not just technical.

**Q: How does this relate to company valuation?**
A: Par value is independent. Company valuation from deals/assets/IP determines the market price per share.

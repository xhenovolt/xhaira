# Comprehensive Share System - Quick Start Guide

## 5-Minute Setup

### 1. Execute Database Migration

```bash
# Connect to your database and run the migration
psql postgresql://user:password@host:port/jeton < migrations/008_two_layer_share_model.sql
```

This creates:
- `shares_config` table
- `valuation_snapshots` table
- Enhanced `shareholdings` table
- `shareholdings_with_vesting` view
- Audit and tracking tables

### 2. Initialize Backend Library

The backend library is ready to use at `src/lib/shares.js`:

```javascript
import {
  getSharesConfiguration,
  recordValuationRound,
  issueNewShares,
  calculateVestedShares,
  executeBuyback,
  getCapTableWithVesting
} from '@/lib/shares.js';
```

### 3. API Endpoints Ready

All endpoints are automatically available:

- `GET /api/equity/valuation` - Current metrics
- `POST /api/equity/valuation` - Record round
- `GET /api/equity/vesting-status` - Shareholder vesting
- `POST /api/equity/buyback` - Execute buyback

---

## Real-World Usage Examples

### Example 1: Founder Company Setup

```javascript
// Initialize with 100 founder shares (4-year vesting)
await issueNewShares({
  to_shareholder_id: 1,
  shares_amount: 100,
  equity_type: 'GRANTED',
  vesting_start_date: new Date('2024-01-01'),
  vesting_end_date: new Date('2028-01-01'),
  vesting_percentage: 100,
});

// Result: Founder has 100 shares with 4-year vesting cliff
// After 1 year: 25 vested, 75 unvested
// After 4 years: All 100 vested
```

### Example 2: Investor Round

```javascript
// Record Seed round investment
const valuation = await recordValuationRound({
  pre_money_valuation: 92000000,      // UGX 92,000,000
  investment_amount: 1840000,         // UGX 1,840,000
  round_name: 'Seed',
  investor_name: 'Tech Ventures',
});

// valuation.share_price = 920,000 per share
// valuation.shares_to_issue = 2 shares
// valuation.post_money_valuation = 93,840,000

// Issue shares to investor
await issueNewShares({
  to_shareholder_id: 2,
  shares_amount: 2,
  equity_type: 'PURCHASED',
  purchase_price: 920000,
});

// Result: Investor owns 2 shares immediately (no vesting)
```

### Example 3: Check Vesting Progress

```javascript
// Check founder vesting after 1 year
const progress = await getVestingProgress(1);

// Returns:
// {
//   total_shares: 100,
//   vested_shares: 25,
//   unvested_shares: 75,
//   progress_percentage: 25,
//   remaining_days: 1095,
//   status: 'vesting'
// }
```

### Example 4: Execute Buyback

```javascript
// Company buys back 1 founder share
await executeBuyback({
  shareholder_id: 1,
  shares_repurchased: 1,
  buyback_price_per_share: 1000000,
  reason: 'Strategic buyback at premium'
});

// Result:
// - Founder has 99 shares
// - Total issued decreases to 101
// - Unissued increases to 999,899
// - All logged in audit trail
```

### Example 5: Get Current Cap Table

```javascript
const capTable = await getCapTableWithVesting();

// Returns array:
// [
//   {
//     shareholder_name: 'Alice Founder',
//     shares_owned: 99,
//     equity_type: 'GRANTED',
//     vested_shares: 24,
//     ownership_percentage: 49.50,
//     vesting_status: 'vesting'
//   },
//   {
//     shareholder_name: 'Bob Investor',
//     shares_owned: 2,
//     equity_type: 'PURCHASED',
//     vested_shares: 2,
//     ownership_percentage: 1.00,
//     vesting_status: 'fully_vested'
//   }
// ]
```

---

## Key Concepts Cheat Sheet

| Concept | Definition | Example |
|---------|-----------|---------|
| **Authorized Shares** | Company maximum | 1,000,000 |
| **Issued Shares** | Currently allocated | 100 |
| **Unissued Shares** | Available for issuance | 999,900 |
| **PURCHASED Equity** | Immediate ownership (investors) | 2 shares |
| **GRANTED Equity** | Vesting schedule required (founders) | 100 shares over 4 years |
| **Pre-Money Valuation** | Value before investment | $92M |
| **Post-Money Valuation** | Value after investment | $93.84M |
| **Share Price** | Pre-money / Issued shares | $920,000 |
| **Vested Shares** | Earned portion (time-based) | 25 shares (after 1 year) |
| **Unvested Shares** | Not yet earned | 75 shares (remaining 3 years) |

---

## Common Implementation Patterns

### Pattern 1: Initialize Company

```javascript
// 1. Get default config (1M authorized)
const config = await getSharesConfiguration();

// 2. Create founder's vesting grant
await issueNewShares({
  to_shareholder_id: founder_id,
  shares_amount: 100,
  equity_type: 'GRANTED',
  vesting_start_date: today,
  vesting_end_date: addYears(today, 4),
  vesting_percentage: 100,
});

// Result: Founder 100%, no other shareholders
```

### Pattern 2: Investor Entry

```javascript
// 1. Record investment round
const valuation = await recordValuationRound({
  pre_money_valuation: current_company_value,
  investment_amount: investor_cash,
  round_name: `Series ${round_letter}`,
  investor_name: investor_company,
});

// 2. Issue shares to investor
await issueNewShares({
  to_shareholder_id: investor_id,
  shares_amount: valuation.shares_to_issue,
  equity_type: 'PURCHASED',
  purchase_price: valuation.share_price,
});

// 3. Get new cap table
const capTable = await getCapTableWithVesting();
// All existing shareholders auto-diluted correctly
```

### Pattern 3: Employee Equity Grant

```javascript
// 1. Grant employee 10 shares with 4-year vesting
await issueNewShares({
  to_shareholder_id: employee_id,
  shares_amount: 10,
  equity_type: 'GRANTED',
  vesting_start_date: today,
  vesting_end_date: addYears(today, 4),
  vesting_percentage: 100,
});

// 2. Track vesting over time
const vestingProgress = await getVestingProgress(employee_id);
// After 2 years: 5 vested, 5 unvested

// 3. On exit, buyback unvested shares
await executeBuyback({
  shareholder_id: employee_id,
  shares_repurchased: vestingProgress.unvested_shares,
  buyback_price_per_share: 0, // Forfeited
  reason: 'Employee exit - unvested forfeiture'
});
```

### Pattern 4: Secondary Shares Transfer

```javascript
// Founder wants to transfer 5 shares to another founder
await transferShares({
  from_shareholder_id: founder1_id,
  to_shareholder_id: founder2_id,
  shares_amount: 5,
  reason: 'Share gift between founders'
});

// Result:
// - Founder1: 95 shares
// - Founder2: 5 shares (new or added)
// - Total issued unchanged
// - Transaction logged
```

---

## Database Queries Cheat Sheet

### Get current valuation
```sql
SELECT * FROM valuation_snapshots ORDER BY created_at DESC LIMIT 1;
```

### Get full cap table with vesting
```sql
SELECT * FROM shareholdings_with_vesting WHERE status = 'active';
```

### Get shareholder details
```sql
SELECT * FROM shareholdings_with_vesting WHERE shareholder_id = $1;
```

### Get all share transactions (audit trail)
```sql
SELECT * FROM share_transactions ORDER BY created_at DESC;
```

### Get buyback history
```sql
SELECT * FROM share_buybacks ORDER BY created_at DESC;
```

---

## Testing Your Setup

### Test 1: Founder Vesting
```javascript
// Grant 100 shares
await issueNewShares({...});

// After 0 days: 0 vested
const day0 = await calculateVestedShares(founder_id);
assert(day0.vested_shares === 0);

// After 365 days: 25 vested
const day365 = await calculateVestedShares(founder_id);
assert(day365.vested_shares === 25);

// After 1460 days: 100 vested
const day1460 = await calculateVestedShares(founder_id);
assert(day1460.vested_shares === 100);
```

### Test 2: Investor Dilution
```javascript
// Initial: 100 founder shares
// Record $10M pre-money + $2M investment round
const round = await recordValuationRound({
  pre_money_valuation: 10000000,
  investment_amount: 2000000,
});

// Share price = $10M / 100 = $100k
// Shares to issue = $2M / $100k = 20

// After issuance: 120 total (100 founder + 20 investor)
// Founder diluted: 100/120 = 83.33%
// Investor: 20/120 = 16.67%
```

### Test 3: Buyback
```javascript
// Before: Investor has 20 shares
// Buyback 10 at $150k (premium)
await executeBuyback({
  shareholder_id: investor_id,
  shares_repurchased: 10,
  buyback_price_per_share: 150000,
});

// After:
// - Investor has 10 shares
// - Total issued: 110
// - Unissued increased by 10
```

---

## Troubleshooting

### Issue: "Cannot issue more than authorized shares"
- **Cause:** Trying to issue more shares than authorized
- **Fix:** Update authorized shares with `updateAuthorizedShares(newAmount)`

### Issue: "GRANTED equity must have vesting_end_date"
- **Cause:** Missing vesting end date for GRANTED equity
- **Fix:** Always provide `vesting_end_date` for GRANTED equity

### Issue: "Insufficient shares for transfer"
- **Cause:** Trying to transfer more than shareholder owns
- **Fix:** Check current shares with `calculateVestedShares(id)`

### Issue: Vesting shows 0 vested after vesting_end_date
- **Cause:** `vesting_percentage < 100`
- **Fix:** Set `vesting_percentage: 100` for full vesting

---

## Next Steps

1. **Execute Migration** - Run `migrations/008_two_layer_share_model.sql`
2. **Test Library** - Call functions from `src/lib/shares.js`
3. **Integrate API** - Use endpoints in your frontend
4. **Build UI** - Create vesting dashboard, cap table view
5. **Monitor Audit** - Track all transactions in `share_transactions` table

---

## Support

For detailed technical documentation, see:
- `Documentation/COMPREHENSIVE_SHARE_SYSTEM.md` - Full specification
- `src/lib/shares.js` - Function signatures and examples
- `migrations/008_two_layer_share_model.sql` - Database schema

# Equity Type Feature - Quick Start Guide

## What's New?

The equity system now tracks **how shares were acquired**:
- **PURCHASED** 💳 - Cash investment
- **GRANTED** 🎁 - Equity incentive, option grant, or award

## Key Changes

### 1. Database
A new `equity_type` field has been added to:
- `shareholdings` table
- `share_issuances` table
- `share_transfers` table

### 2. Cap Table Display
The cap table now shows equity type for each shareholder with color-coded badges:
- 💳 Blue badge for PURCHASED
- 🎁 Green badge for GRANTED

### 3. Forms
All share-related modals now include an "Equity Type" dropdown:
- **Add Shareholder** - Select equity type for new shareholders
- **Transfer Shares** - Specify equity type for transferred shares
- **Issue New Shares** - Defaults to GRANTED (equity grants)

### 4. API Updates
All equity endpoints now accept/return `equity_type`:

```javascript
// Add shareholder with equity type
POST /api/equity/shareholders
{
  "shares_owned": 5000,
  "equity_type": "PURCHASED"
}

// Transfer shares with equity type
POST /api/equity/transfer
{
  "shares_transferred": 1000,
  "equity_type": "PURCHASED"
}

// Issue shares with equity type
POST /api/equity/issuance
{
  "shares_issued": 50000,
  "equity_type": "GRANTED"
}

// Get cap table (includes equity_type)
GET /api/equity/cap-table
```

## Default Values

| Operation | Default | Reasoning |
|-----------|---------|-----------|
| Add Shareholder | PURCHASED | Direct shareholding is cash investment |
| Share Issuance | GRANTED | Most new issuances are equity grants |
| Share Transfer | PURCHASED | Secondary market transfers are cash sales |

## Migration Notes

✅ **Backward Compatible**
- Existing data automatically defaults to PURCHASED
- All existing calculations unchanged
- No breaking changes to API

✅ **No Vesting Yet**
- GRANTED shares don't auto-generate vesting schedules
- That's for future enhancement
- Currently just tracks equity type

## Common Use Cases

### Founder Equity
```javascript
// Alice invests $100,000 for 500,000 shares
{
  "shareholder_name": "Alice",
  "shares_owned": 500000,
  "equity_type": "PURCHASED",
  "acquisition_price": 0.20
}
```

### Employee Option Grant
```javascript
// Grant 10,000 options to Employee
{
  "shares_issued": 10000,
  "recipient_type": "employee",
  "equity_type": "GRANTED",
  "issuance_reason": "Employee Pool"
}
```

### Advisor Equity
```javascript
// Grant 50,000 shares to advisor
{
  "from_shareholder_id": "company",
  "to_shareholder_id": "advisor",
  "shares_transferred": 50000,
  "equity_type": "GRANTED",
  "transfer_type": "advisor-grant"
}
```

### Secondary Sale
```javascript
// Existing investor sells to new investor
{
  "from_shareholder_id": "original_investor",
  "to_shareholder_id": "new_investor",
  "shares_transferred": 10000,
  "transfer_price_per_share": 2.50,
  "equity_type": "PURCHASED",
  "transfer_type": "secondary-sale"
}
```

## Testing the Feature

1. **Navigate to Equity page** - You'll see the new "Equity Type" column in the cap table

2. **Add a Shareholder:**
   - Click "Add Shareholder"
   - Select an equity type (PURCHASED or GRANTED)
   - Complete the form

3. **Transfer Shares:**
   - Click transfer button on any shareholder
   - Select equity type
   - Execute transfer

4. **Issue Shares:**
   - Click "Propose Issuance"
   - Select equity type (defaults to GRANTED)
   - Propose the issuance

## Database Migration

If you need to manually run the migration:

```bash
# Run migration
psql -d jeton < migrations/007_add_equity_type.sql

# Verify columns added
psql -d jeton
\d shareholdings
\d share_issuances
\d share_transfers
```

## Questions?

Refer to the full documentation: [Documentation/EQUITY_TYPE_FEATURE.md](EQUITY_TYPE_FEATURE.md)

## Checklist for Deployment

- [ ] Run database migration (007_add_equity_type.sql)
- [ ] Restart application (npm start)
- [ ] Test cap table display (should show equity_type column)
- [ ] Test Add Shareholder (should show equity_type dropdown)
- [ ] Test Transfer (should show equity_type dropdown)
- [ ] Test Issuance (should show equity_type dropdown)
- [ ] Verify existing shareholders display correctly
- [ ] Verify API calls include equity_type

**Status:** ✅ Ready for deployment

# Equity Type Enhancement - Complete Implementation

## Overview

The equity system has been extended with an `equity_type` field to track the nature of share acquisition: **PURCHASED** (cash investment) or **GRANTED** (equity incentive/option grant).

## Implementation Details

### Database Changes

**Migration File:** [migrations/007_add_equity_type.sql](migrations/007_add_equity_type.sql)

Three tables have been updated with `equity_type` column:

1. **shareholdings** - Main shareholder cap table
   - Default: `PURCHASED`
   - Constraint: Must be 'PURCHASED' or 'GRANTED'

2. **share_issuances** - Proposed equity issuances
   - Default: `GRANTED` (most issuances are equity grants)
   - Constraint: Must be 'PURCHASED' or 'GRANTED'

3. **share_transfers** - Historical share transfers
   - Default: `PURCHASED`
   - Constraint: Must be 'PURCHASED' or 'GRANTED'

```sql
ALTER TABLE shareholdings 
ADD COLUMN equity_type VARCHAR(50) NOT NULL DEFAULT 'PURCHASED'
CHECK (equity_type IN ('PURCHASED', 'GRANTED'));
```

### Backend Functions Updated

**File:** [src/lib/equity.js](src/lib/equity.js)

#### 1. `addShareholder(shareholder)`
- **New Parameter:** `equity_type` (default: 'PURCHASED')
- **Validation:** Rejects values other than 'PURCHASED' or 'GRANTED'
- **Usage:** Add new shareholder with specified equity type

```javascript
const shareholder = await addShareholder({
  shareholder_name: 'John Doe',
  shares_owned: 10000,
  equity_type: 'PURCHASED', // or 'GRANTED'
});
```

#### 2. `proposeShareIssuance(issuance)`
- **New Parameter:** `equity_type` (default: 'GRANTED')
- **Validation:** Rejects invalid values
- **Usage:** Track whether issuance is equity grant or cash purchase

```javascript
const issuance = await proposeShareIssuance({
  shares_issued: 50000,
  equity_type: 'GRANTED', // Employee option pool
  issuance_reason: 'Employee Pool',
});
```

#### 3. `executeShareIssuance(issuanceId, approvedById)`
- **Updated:** Now uses `equity_type` from issuance record
- **Behavior:** Automatically applies equity_type to recipient shareholding

#### 4. `executeShareTransfer(transfer)`
- **New Parameter:** `equity_type` (default: 'PURCHASED')
- **Validation:** Rejects invalid values
- **Usage:** Track equity type when transferring shares

```javascript
const result = await executeShareTransfer({
  from_shareholder_id: 'user1',
  to_shareholder_id: 'user2',
  shares_transferred: 1000,
  equity_type: 'PURCHASED',
});
```

#### 5. `getCapTable(options)`
- **Updated:** Returns `equity_type` for each shareholder
- **No Changes Required:** Already included in SELECT

### API Endpoints Updated

#### 1. POST /api/equity/shareholders
**Add new shareholder with equity type**

```json
{
  "shareholder_name": "Jane Smith",
  "shareholder_email": "jane@example.com",
  "shares_owned": 5000,
  "holder_type": "investor",
  "equity_type": "PURCHASED",
  "acquisition_price": 1.50
}
```

**Response includes:**
- All shareholder fields plus `equity_type`

#### 2. POST /api/equity/transfer
**Transfer shares between shareholders**

```json
{
  "from_shareholder_id": "uuid1",
  "to_shareholder_id": "uuid2",
  "shares_transferred": 1000,
  "transfer_price_per_share": 2.00,
  "equity_type": "PURCHASED",
  "transfer_type": "secondary-sale",
  "reason": "Secondary funding round"
}
```

**Validation:** Returns 400 if equity_type not in ['PURCHASED', 'GRANTED']

#### 3. POST /api/equity/issuance
**Propose new share issuance**

```json
{
  "shares_issued": 50000,
  "issued_at_price": 1.00,
  "recipient_type": "employee-option-pool",
  "equity_type": "GRANTED",
  "issuance_reason": "Employee Pool",
  "created_by_id": "uuid"
}
```

**Defaults:**
- `equity_type`: 'GRANTED' (most issuances are equity grants)

#### 4. GET /api/equity/cap-table
**Returns cap table with equity_type for each shareholder**

```json
{
  "success": true,
  "data": [
    {
      "shareholder_id": "uuid1",
      "shareholder_name": "John Founder",
      "shares_owned": 100000,
      "equity_type": "PURCHASED",
      "current_ownership_percentage": "50.00"
    }
  ]
}
```

### Frontend Updates

**File:** [src/app/app/equity/page.js](src/app/app/equity/page.js)

#### Cap Table Display
- New column: "Equity Type"
- Visual indicators:
  - 💳 Purchased (Blue badge)
  - 🎁 Granted (Green badge)

#### Add Shareholder Modal
- New field: "Equity Type" dropdown
- Options: 'PURCHASED' or 'GRANTED'
- Help text: "Purchased: Cash investment • Granted: Option grant or incentive"

#### Transfer Shares Modal
- New field: "Equity Type" dropdown
- Allows specifying equity type for transferred shares
- Default: 'PURCHASED'

#### Issue New Shares Modal
- New field: "Equity Type" dropdown
- Default: 'GRANTED' (most issuances are equity grants)
- Help text: "Purchased: Cash for shares • Granted: Option or incentive"

## Usage Examples

### Example 1: Add Founder Investment
```javascript
// Founder purchases 500,000 shares at $1.00 each
await addShareholder({
  shareholder_name: 'Alice Co-founder',
  shares_owned: 500000,
  holder_type: 'founder',
  equity_type: 'PURCHASED', // Cash investment
  acquisition_price: 1.00,
});
```

### Example 2: Grant Employee Options
```javascript
// Propose 10,000 share option grant to employee
await proposeShareIssuance({
  shares_issued: 10000,
  recipient_type: 'employee',
  equity_type: 'GRANTED', // Option grant
  issuance_reason: 'Employee Pool',
});
```

### Example 3: Secondary Share Transfer
```javascript
// Transfer 5,000 shares (purchased) to new investor
await executeShareTransfer({
  from_shareholder_id: 'original_buyer_id',
  to_shareholder_id: 'new_investor_id',
  shares_transferred: 5000,
  transfer_price_per_share: 2.50,
  equity_type: 'PURCHASED',
  transfer_type: 'secondary-sale',
});
```

### Example 4: Grant Advisor Equity
```javascript
// Grant 50,000 shares to advisor (no cash)
await executeShareTransfer({
  from_shareholder_id: 'company_pool',
  to_shareholder_id: 'advisor_id',
  shares_transferred: 50000,
  transfer_price_per_share: null,
  equity_type: 'GRANTED',
  transfer_type: 'advisor-grant',
});
```

## Data Migration Notes

**Existing Data Handling:**
- All existing `shareholdings` records default to `equity_type = 'PURCHASED'`
- All existing `share_transfers` are classified based on `transfer_type`:
  - 'secondary-sale', 'transfer' → 'PURCHASED'
  - 'grant' → 'GRANTED'
  - Other types → 'PURCHASED'

**No Breaking Changes:**
- All calculations remain identical
- Vesting logic unaffected
- Dilution calculations unchanged
- Backward compatible with existing code

## Future Enhancements

The `equity_type` field enables:

1. **Vesting Schedule Differentiation**
   - GRANTED shares can have cliff/vesting periods
   - PURCHASED shares typically vest immediately

2. **Tax Reporting**
   - Separate reporting for granted vs purchased equity
   - Different tax treatment per jurisdiction

3. **Cap Table Analytics**
   - Breakdown of founder vs investor vs employee equity
   - Dilution impact analysis by equity type

4. **Compliance Tracking**
   - SAFE vs Equity tracking
   - Convertible note tracking
   - Different governance rules per type

5. **Equity Grants Management**
   - Integration with vesting schedules
   - Cliff periods for granted equity
   - Acceleration on change of control

## Testing Recommendations

1. **Test equity_type validation:**
   ```javascript
   // Should fail
   await addShareholder({ shares_owned: 1000, equity_type: 'INVALID' });
   ```

2. **Test cap table filtering:**
   ```javascript
   // Get cap table with equity_type in response
   const capTable = await getCapTable();
   capTable.forEach(s => assert(s.equity_type));
   ```

3. **Test transfer with equity_type:**
   ```javascript
   // Ensure equity_type is preserved in database
   await executeShareTransfer({ equity_type: 'GRANTED' });
   ```

4. **Test issuance with equity_type:**
   ```javascript
   // Verify issuance default is 'GRANTED'
   await proposeShareIssuance({ /* no equity_type */ });
   ```

5. **Test UI rendering:**
   - Verify cap table shows equity_type badges
   - Verify forms accept equity_type selection
   - Verify API calls include equity_type

## Implementation Checklist

- [x] Database migration created (007_add_equity_type.sql)
- [x] Backend functions updated (addShareholder, proposeShareIssuance, executeShareTransfer, getCapTable)
- [x] API endpoints updated (shareholders, transfer, issuance, cap-table)
- [x] Frontend cap table display enhanced
- [x] Add Shareholder modal updated
- [x] Transfer Shares modal updated
- [x] Issue New Shares modal updated
- [x] Validation added to all endpoints
- [x] Default values set appropriately
- [x] Backward compatibility maintained

## Migration Guide

### To Deploy:

1. **Run database migration:**
   ```bash
   psql -d jeton < migrations/007_add_equity_type.sql
   ```

2. **Restart application:**
   ```bash
   npm start
   ```

3. **Verify in UI:**
   - Navigate to Equity page
   - View cap table (should show "Equity Type" column)
   - Try adding new shareholder (should show equity_type field)
   - Try transfer (should show equity_type field)
   - Try issuance (should show equity_type field)

4. **Test API endpoints:**
   ```bash
   # Test creating shareholder with equity_type
   curl -X POST http://localhost:3000/api/equity/shareholders \
     -H "Content-Type: application/json" \
     -d '{"shares_owned": 1000, "equity_type": "PURCHASED"}'
   ```

## References

- **Database:** [migrations/007_add_equity_type.sql](migrations/007_add_equity_type.sql)
- **Backend:** [src/lib/equity.js](src/lib/equity.js)
- **API Endpoints:** 
  - [src/app/api/equity/shareholders/route.js](src/app/api/equity/shareholders/route.js)
  - [src/app/api/equity/transfer/route.js](src/app/api/equity/transfer/route.js)
  - [src/app/api/equity/issuance/route.js](src/app/api/equity/issuance/route.js)
- **Frontend:** [src/app/app/equity/page.js](src/app/app/equity/page.js)

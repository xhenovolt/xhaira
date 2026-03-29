# Corporate Equity System - Implementation Guide

**Status**: ✅ COMPLETE - URSB-Compliant Corporate Equity Management

## Overview

Jeton's new **Corporate Equity System** implements professional-grade share management aligned with URSB standards and real-world venture capital practices. This is not a simple equity tracker—it's a founder-grade system for managing cap tables, tracking dilution, and controlling share issuance.

## 🎯 Key Features

### 1. **Three-Tier Share Structure**

```
┌─────────────────────────────────────┐
│   AUTHORIZED SHARES (10,000,000)    │  Maximum allowable
│   ├─ Issued: 1,000,000              │  Actually created
│   │   ├─ Allocated: 950,000         │  Owned by shareholders
│   │   └─ Unallocated: 50,000        │  Pool for allocation
│   └─ Unissued: 9,000,000            │  Available for future issuance
└─────────────────────────────────────┘
```

**Authorized Shares**
- Maximum shares the company can ever issue
- Set by board resolution or bylaws
- Can only be increased, never decreased
- Default: 10,000,000 for Jeton (high ceiling = flexibility)

**Issued Shares**
- Actually created and outstanding
- Cannot exceed authorized shares
- Sum of all shareholder allocations
- Increases with new issuance events

**Allocated Shares**
- Owned by specific shareholders
- Must equal issued shares (perfect balance)
- Tracked per shareholder with percentages
- Updated by transfers or issuance

### 2. **Share Transfer (No Dilution)**

Transfer shares between shareholders without creating new shares:

```javascript
// From: Founder with 500k shares
// To: Investor joining company
// Result: Founder has 250k, Investor has 250k
// Total issued: Still 1M (NO change)
```

**Use Cases:**
- Founder transfers portion of equity to early investor
- Secondary market sales between shareholders
- Employee leaving company (buyback or forfeit)
- Inheritance or gift transfers

**Key Point**: Total issued shares never changes—it's pure ownership redistribution.

### 3. **Share Issuance (With Dilution)**

Create new shares, which dilutes ALL existing shareholders:

```javascript
// Before issuance:
// Founder: 500k shares (50%)
// Investor A: 300k shares (30%)
// Investor B: 200k shares (20%)
// Total: 1M issued

// Issue 500k new shares to Series A round
// Total issued: Now 1.5M

// After issuance:
// Founder: 500k shares (33.33%)  ← DILUTED
// Investor A: 300k shares (20%)  ← DILUTED
// Investor B: 200k shares (13.33%) ← DILUTED
// Series A: 500k shares (33.33%)
// Total: 1.5M issued
```

**Dilution is intentional and tracked:**
- Founder sees ownership % decrease
- Dilution event recorded in cap table
- Percentage ownership recalculated automatically
- All shareholdings updated in real-time

### 4. **Cap Table (Real-Time)**

Complete shareholder registry with live calculations:

```
Shareholder          Shares    Ownership %  Vested    Type        Investment
─────────────────────────────────────────────────────────────────────────────
Alice (Founder)      500,000   33.33%       500,000   Founder     $500,000
Bob (Investor)       300,000   20.00%       300,000   Investor    $600,000
Charlie (Advisor)    200,000   13.33%       50,000    Advisor     $50,000
Employee Pool        500,000   33.33%       0         Emp. Pool   $0
─────────────────────────────────────────────────────────────────────────────
TOTAL              1,500,000  100.00%      850,000                $1,150,000
```

**Calculated for each shareholder:**
- Current shares owned
- Current ownership percentage
- Original ownership percentage (for dilution tracking)
- Vested vs. unvested (for vesting schedules)
- Total capital invested
- Dilution impact from issuances

## 🏗️ Database Structure

### Core Tables

**shares_config**
```sql
authorized_shares    BIGINT   -- Max ever allowed
issued_shares        BIGINT   -- Currently outstanding
par_value            DECIMAL  -- Legal value per share
class_type           VARCHAR  -- Common, Preferred, etc.
```

**shareholdings**
```sql
shareholder_id          UUID          -- User reference
shares_owned            BIGINT        -- Current holdings
vested_shares           BIGINT        -- Vested only
holder_type             VARCHAR       -- founder, investor, employee, advisor
original_ownership_pct  DECIMAL(5,2)  -- At acquisition
current_ownership_pct   DECIMAL(5,2)  -- After dilution
acquisition_price       DECIMAL       -- $ per share paid
investment_total        DECIMAL       -- Total $ invested
vesting_schedule        VARCHAR       -- cliff-4yr-1yr, linear-4yr, etc.
```

**share_transfers**
```sql
from_shareholder_id     UUID
to_shareholder_id       UUID
shares_transferred      BIGINT
transfer_price_per_share DECIMAL     -- NULL = gift
transfer_type           VARCHAR      -- secondary-sale, founder-to-investor, etc.
transfer_date           DATE
transfer_status         VARCHAR      -- completed, pending, cancelled
```

**share_issuances**
```sql
shares_issued                  BIGINT
issued_at_price               DECIMAL
recipient_type                VARCHAR        -- investor, employee-pool, etc.
issuance_reason               VARCHAR        -- seed-round, series-a, etc.
approval_status               VARCHAR        -- pending, approved, executed
ownership_dilution_impact     DECIMAL(5,2)   -- % dilution
previous_issued_shares        BIGINT         -- For history
```

**share_price_history**
```sql
date                   DATE
closing_price         DECIMAL       -- Per share
company_valuation     DECIMAL       -- Total value
issued_shares         BIGINT        -- Shares outstanding on date
event_type            VARCHAR       -- issuance, funding, market-update
event_id              UUID          -- Link to issuance/transfer
```

### Key Constraints

```sql
-- Authorized must be >= Issued
authorized_shares >= issued_shares

-- Issued must be >= Allocated
issued_shares >= SUM(shareholders.shares_owned)

-- Vested cannot exceed owned
vested_shares <= shares_owned

-- Ownership percentages valid
0 <= ownership_percentage <= 100
```

## 📊 API Endpoints

### Configuration Management

**GET /api/equity/config**
```json
{
  "success": true,
  "data": {
    "authorized_shares": 10000000,
    "issued_shares": 1000000,
    "unissued_shares": 9000000,
    "allocated_shares": 950000,
    "unallocated_issued": 50000,
    "par_value": 1.0,
    "allocation_percentage": "95.00"
  }
}
```

**PUT /api/equity/config**
```json
{
  "authorized_shares": 15000000,
  "issued_shares": 1000000,
  "par_value": 1.0,
  "reason": "Board approved increase in authorized shares"
}
```

### Cap Table

**GET /api/equity/cap-table**
```json
{
  "success": true,
  "data": [
    {
      "shareholder_name": "Alice",
      "shares_owned": 500000,
      "current_ownership_percentage": "50.00",
      "vested_shares": 500000,
      "holder_type": "founder",
      "acquisition_price": 1.0,
      "investment_total": 500000
    }
  ],
  "summary": {
    "total_shareholders": 3,
    "total_shares_allocated": 950000,
    "total_investment": 1150000
  }
}
```

### Shareholders

**POST /api/equity/shareholders**
```json
{
  "shareholder_name": "Alice",
  "shareholder_email": "alice@company.com",
  "shares_owned": 500000,
  "holder_type": "founder",
  "acquisition_price": 1.0
}
```

### Share Transfers (No Dilution)

**POST /api/equity/transfer**
```json
{
  "from_shareholder_id": "uuid-alice",
  "to_shareholder_id": "uuid-bob",
  "shares_transferred": 100000,
  "transfer_price_per_share": 10.0,
  "transfer_type": "secondary-sale",
  "reason": "Secondary funding round"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully transferred 100000 shares",
  "data": {
    "from_new_balance": 400000,
    "to_new_balance": 200000,
    "shares_transferred": 100000
  }
}
```

### Share Issuance (With Dilution)

**Propose New Issuance**
```json
{
  "shares_issued": 500000,
  "issued_at_price": 15.0,
  "recipient_type": "investor",
  "issuance_reason": "series-a",
  "issuance_type": "equity",
  "created_by_id": "uuid-founder"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Share issuance proposed - awaiting founder approval",
  "data": {
    "issuance": {
      "id": "uuid-issuance",
      "shares_issued": 500000,
      "approval_status": "pending",
      "ownership_dilution_impact": 33.33
    },
    "dilution_warning": "⚠️ Issuing 500000 new shares will dilute existing shareholders by 33.33%",
    "new_issued_total": 1500000,
    "requires_confirmation": true
  }
}
```

**Approve & Execute Issuance**
```json
{
  "action": "approve",
  "issuance_id": "uuid-issuance",
  "approved_by_id": "uuid-founder"
}
```

## 🎮 UI Components

### Main Equity Dashboard

**Metrics Cards:**
- Authorized Shares (locked, rarely changes)
- Issued Shares (active count)
- Unissued Shares (available capacity)
- Allocated Shares (held by shareholders)

**Cap Table:**
- Sortable shareholder list
- Real-time ownership percentages
- Vesting information
- Investment tracking
- Quick transfer button

**Action Buttons:**
- 📊 Configure Shares
- 👤 Add Shareholder
- ➡️ Transfer Shares
- ⚡ Issue New Shares

### Configuration Modal

Set authorized and issued share counts:
- Authorized Shares: Rarely changes, requires board decision
- Issued Shares: Only increases (never decreases)
- Par Value: Used for tax/legal purposes

### Add Shareholder Modal

Allocate shares to new shareholder:
- Name & email
- Initial share count
- Holder type (founder, investor, employee, advisor)
- Acquisition price (for tracking investment)

### Transfer Shares Modal

Move shares between shareholders (no dilution):
- From shareholder (dropdown)
- To shareholder (dropdown)
- Quantity to transfer
- Price per share (optional, NULL = gift)
- Transfer type (secondary-sale, founder-to-investor, etc.)
- Reason (for audit trail)

### Issue Shares Modal

**⚠️ HIGH ALERT - Requires Extra Confirmation:**
- Shares to issue
- Price per share
- Recipient type
- Issuance reason (seed-round, series-a, etc.)
- Marked as "PENDING" until founder reviews
- Shows dilution impact warning
- Requires explicit approval before execution

## 💡 Usage Scenarios for Jeton

### Scenario 1: Founder Starting Out

**Initial Setup:**
```
Authorized Shares: 10,000,000  (Set once, give room to grow)
Issued Shares: 1,000,000       (Initial float)
Par Value: $1.00
Founder Allocation: 1,000,000 shares (100% of issued)
```

**Key insight:** Start with high authorized (10M) and low issued (1M). This gives flexibility to issue 9M more shares without needing to amend cap table. Matches real VC practice.

### Scenario 2: Early Investor Comes In

**Action 1: Transfer Portion to Investor**
```
Founder transfers 400k shares to Investor
- No new shares created
- Founder: 600k (60%)
- Investor: 400k (40%)
- Total issued: Still 1M
```

**Why transfer instead of issue?** Simpler, no dilution to future shareholders, investor owns actual stock immediately.

### Scenario 3: Series A Funding (500k shares at $15/share = $7.5M valuation)

**Action 1: Propose Issuance**
```
Issue: 500,000 shares
At: $15 per share
Reason: Series A funding
Total raised: $7,500,000
```

**Dilution snapshot:**
```
Before Series A:
- Founder: 600k (60%)
- Investor: 400k (40%)

After Series A (now 1.5M total issued):
- Founder: 600k (40%)        ← Diluted 20%
- Investor: 400k (26.67%)    ← Diluted 13.33%
- Series A: 500k (33.33%)    ← New entrant
```

**This is painful intentionally.** It signals the cost of dilution. That's good—founders should feel it.

### Scenario 4: Employee Stock Options (200k shares @ $5/share)

**Action: Create Employee Option Pool**
```
Issue: 200,000 new shares
Type: option-pool
Reason: employee-pool
```

This dilutes everyone again, but it's the price of building a team.

## 🔒 Security & Audit Trail

**Every action is recorded:**

```sql
-- Share transfer
INSERT INTO audit_logs (action, entity, entity_id, metadata)
VALUES ('SHARE_TRANSFER', 'share_transfer', 'uuid-transfer', {
  from: 'alice-id',
  to: 'bob-id',
  shares: 100000,
  price: 10.0
})

-- Share issuance (requires approval)
INSERT INTO audit_logs (action, entity, entity_id, metadata)
VALUES ('SHARE_ISSUANCE', 'share_issuance', 'uuid-issuance', {
  shares: 500000,
  reason: 'series-a',
  proposed_by: 'founder-id',
  approved_by: 'founder-id'
})
```

**Immutable record:**
- Who created/approved actions
- When they happened
- What changed
- Why (reason field)
- Audit trail for compliance

## 📈 Calculations & Formulas

### Ownership Percentage (Current)
```javascript
ownership_percentage = (shares_owned / total_issued_shares) * 100
```

### Dilution Impact (From Issuance)
```javascript
new_ownership = original_shares / (original_total + new_issued)
dilution = original_ownership - new_ownership
```

### Shareholder Value
```javascript
value_per_share = company_valuation / total_issued_shares
shareholder_value = shares_owned * value_per_share
```

### Fully Diluted Ownership (If all options vest)
```javascript
fully_diluted = shares_owned / (total_issued + unexercised_options)
```

## 🚀 Best Practices

### For Founders

1. **Start Conservative with Issued Shares**
   - Don't issue all authorized shares at once
   - Keep a buffer for future rounds
   - Recommended: Issue 10% of authorized, hold 90%

2. **Guard Dilution Carefully**
   - Each round dilutes you ~25-35%
   - This is normal and expected
   - But it compounds—watch out by Round 3

3. **Use Transfers for Early Investors**
   - Avoid unnecessary issuance
   - Transfer founder shares to early investors
   - Save new issuance for funded rounds

4. **Track Everything**
   - Every transfer is audited
   - Every issuance requires approval
   - Cap table is source of truth
   - Keep it current always

### For Investors

1. **Verify Cap Table Before Investing**
   - Know exactly what percentage you're getting
   - Understand fully diluted shares
   - Check vesting terms

2. **Understand Dilution**
   - Future rounds will dilute you
   - Series B typically dilutes Series A by ~25%
   - This is normal VC math

3. **Watch for Anti-Dilution**
   - Some investors have anti-dilution rights
   - Can affect future round pricing
   - Review term sheet carefully

## 🔍 Monitoring & Alerts

**System tracks and warns about:**

- ❌ Attempting to issue more than authorized
- ❌ Attempting to allocate more than issued
- ⚠️ Large dilution events (>20%)
- ⚠️ High executive compensation (option pools >15%)
- ⚠️ Unusual ownership percentages

## 📚 Related Documentation

- [Database Schema](./DATABASE_SCHEMA.md)
- [API Reference](./API_REFERENCE.md)
- [UI Components](./UI_COMPONENTS.md)
- [Vesting & Options](./VESTING_OPTIONS.md)
- [Cap Table Best Practices](./CAP_TABLE_BEST_PRACTICES.md)

## ✅ Implementation Checklist

- ✅ Database schema with authorized/issued/allocated separation
- ✅ Share transfer endpoints (no dilution)
- ✅ Share issuance endpoints (with dilution tracking)
- ✅ Cap table views and calculations
- ✅ Real-time ownership percentage updates
- ✅ Audit trail for all operations
- ✅ Shareholder management UI
- ✅ Configuration UI
- ✅ Transfer UI
- ✅ Issuance approval workflow
- ✅ Dilution impact warnings
- ✅ Comprehensive error handling
- ✅ Input validation
- ✅ Permission checks

## 🎓 URSB Compliance

This system aligns with URSB standards for:

1. **Share Authorization**
   - Authorized shares must be formally approved
   - Cannot be changed without board/shareholder vote
   - Cap table is official record

2. **Share Issuance**
   - All new shares must be authorized
   - Issuance price must be fair value
   - Fully disclosed to all shareholders

3. **Cap Table**
   - Must be maintained accurately
   - Must show all shareholdings
   - Must be available to all shareholders on request

4. **Dilution**
   - All shareholders must understand impact
   - Must be disclosed before issuance
   - Anti-dilution rights must be honored

5. **Audit Trail**
   - All transactions recorded
   - Timestamps and approval chain
   - Available for investor/tax audit

---

**Jeton Equity System** — Built for founders who take their company seriously.

*Last Updated: December 2025*

# Comprehensive Share System Implementation Guide

## Overview

This document details the complete implementation of a two-layer share model for Jeton, mirroring real-world corporate registry systems like URSB. The system includes:

1. **Two-Layer Share Model** - Authorized vs Issued distinction
2. **Company Valuation Engine** - Pre/post-money calculations with investor tracking
3. **Vesting System** - Linear vesting for GRANTED equity only
4. **Share Buyback & Exit System** - Repurchase and shareholder exit handling
5. **Comprehensive Audit Trail** - Complete transaction logging

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Share System Architecture                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Frontend Components                                              │
│  ├─ Valuation Dashboard (pre/post-money, share price)             │
│  ├─ Vesting Progress UI (timeline, unvested tracking)             │
│  ├─ Cap Table (ownership%, equity type, vesting status)           │
│  └─ Buyback/Exit Management (admin controls)                      │
│                                                                   │
│  API Endpoints                                                    │
│  ├─ POST /api/equity/valuation (record round)                     │
│  ├─ GET /api/equity/valuation (current metrics)                   │
│  ├─ GET /api/equity/vesting-status (shareholder vesting)          │
│  ├─ POST /api/equity/buyback (execute repurchase)                 │
│  └─ POST /api/equity/issue-shares (new issuance)                  │
│                                                                   │
│  Backend Library (src/lib/shares.js)                              │
│  ├─ getSharesConfiguration()                                      │
│  ├─ recordValuationRound()                                        │
│  ├─ calculateVestedShares()                                       │
│  ├─ issueNewShares()                                              │
│  ├─ executeBuyback()                                              │
│  └─ getCapTableWithVesting()                                      │
│                                                                   │
│  Database Layer                                                  │
│  ├─ shares_config (authorized vs issued)                          │
│  ├─ valuation_snapshots (pre/post-money tracking)                 │
│  ├─ shareholdings (with vesting fields)                           │
│  ├─ shareholdings_with_vesting (calculated view)                  │
│  ├─ share_transactions (audit log)                                │
│  ├─ share_buybacks (repurchase tracking)                          │
│  └─ shareholder_exits (exit handling)                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### 1. shares_config Table

Stores company-level share configuration. Enforces that authorized_shares ≥ issued_shares.

```sql
CREATE TABLE shares_config (
  id BIGSERIAL PRIMARY KEY,
  authorized_shares BIGINT NOT NULL,        -- Company maximum
  issued_shares BIGINT NOT NULL DEFAULT 0,  -- Currently allocated
  par_value DECIMAL(10,2),                  -- Face value per share
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (authorized_shares >= issued_shares)
);
```

**Key Constraints:**
- `authorized_shares >= issued_shares` - Company cannot issue more than authorized
- Automatic tracking of unissued_shares = authorized_shares - issued_shares

**Example:**
- Authorized: 1,000,000 shares
- Issued: 100 shares (founder)
- Unissued: 999,900 shares (available for issuance)

### 2. valuation_snapshots Table

Tracks company valuation rounds with calculated metrics.

```sql
CREATE TABLE valuation_snapshots (
  id BIGSERIAL PRIMARY KEY,
  shares_config_id BIGINT REFERENCES shares_config(id),
  pre_money_valuation DECIMAL(15,2),       -- Before investment
  investment_amount DECIMAL(15,2),         -- Cash invested
  post_money_valuation DECIMAL(15,2),      -- After investment
  share_price DECIMAL(12,4),               -- Calculated: pre_money / issued_shares
  issued_shares_after BIGINT,              -- Total issued after round
  round_name VARCHAR(50),                  -- e.g., "Seed", "Series A"
  investor_name VARCHAR(255),
  notes TEXT,
  created_by_id BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Calculations:**
- `post_money_valuation = pre_money_valuation + investment_amount`
- `share_price = pre_money_valuation / issued_shares`
- `shares_to_issue = FLOOR(investment_amount / share_price)`

**Example Scenario:**
- Pre-money: $92,000,000
- Founder shares: 100
- Share price: $92,000,000 / 100 = $920,000 per share
- Investment: $1,840,000 (2 shares)
- Post-money: $93,840,000
- Total issued after: 102 shares

### 3. shareholdings Table (Enhanced)

Tracks individual shareholder equity with vesting support.

```sql
CREATE TABLE shareholdings (
  id BIGSERIAL PRIMARY KEY,
  shareholder_id BIGINT NOT NULL REFERENCES users(id),
  shares_owned BIGINT NOT NULL,
  equity_type VARCHAR(20) NOT NULL,         -- 'PURCHASED' or 'GRANTED'
  vesting_start_date DATE,                  -- Vesting begins (GRANTED only)
  vesting_end_date DATE,                    -- Vesting completes (GRANTED only)
  vesting_percentage DECIMAL(5,2) DEFAULT 100, -- Vest completion % (80, 100, etc)
  acquisition_date DATE,
  purchase_price DECIMAL(12,4),             -- Price per share (PURCHASED only)
  valuation_snapshot_id BIGINT REFERENCES valuation_snapshots(id),
  status VARCHAR(20) DEFAULT 'active',      -- active, vested, forfeited
  holder_type VARCHAR(50),                  -- founder, investor, employee
  investment_total DECIMAL(15,2),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(shareholder_id),
  CHECK (equity_type IN ('PURCHASED', 'GRANTED'))
);
```

**Key Differences by equity_type:**
- `PURCHASED`: No vesting, shares owned immediately (investors)
- `GRANTED`: Full vesting schedule with dates and percentage

### 4. shareholdings_with_vesting View

Calculated view that computes vested/unvested shares using linear vesting formula.

```sql
CREATE VIEW shareholdings_with_vesting AS
SELECT 
  sh.*,
  CASE 
    WHEN sh.equity_type = 'PURCHASED' THEN sh.shares_owned
    WHEN sh.equity_type = 'GRANTED' THEN
      FLOOR(
        sh.shares_owned * 
        GREATEST(0, LEAST(1.0, 
          (EXTRACT(DAY FROM (CURRENT_DATE - sh.vesting_start_date))::FLOAT / 
           NULLIF(EXTRACT(DAY FROM (sh.vesting_end_date - sh.vesting_start_date)), 0))
        )) * 
        (sh.vesting_percentage / 100.0)
      )
  END AS vested_shares,
  sh.shares_owned - CASE 
    WHEN sh.equity_type = 'PURCHASED' THEN sh.shares_owned
    WHEN sh.equity_type = 'GRANTED' THEN
      FLOOR(
        sh.shares_owned * 
        GREATEST(0, LEAST(1.0, 
          (EXTRACT(DAY FROM (CURRENT_DATE - sh.vesting_start_date))::FLOAT / 
           NULLIF(EXTRACT(DAY FROM (sh.vesting_end_date - sh.vesting_start_date)), 0))
        )) * 
        (sh.vesting_percentage / 100.0)
      )
  END AS unvested_shares
FROM shareholdings sh;
```

**Vesting Formula:**
```
vested_shares = FLOOR(total_shares * progress_ratio * vesting_percentage)

Where:
  progress_ratio = days_elapsed / total_vesting_days (capped 0-1)
  vesting_percentage = percentage_target (e.g., 80, 100)
```

**Example:**
- 1000 shares granted
- 4-year vesting (1460 days)
- After 1 year (365 days): 1000 * (365/1460) * (100/100) = 250 vested
- After 2 years (730 days): 1000 * (730/1460) * (100/100) = 500 vested
- After 4 years (1460 days): 1000 * (1460/1460) * (100/100) = 1000 vested

### 5. share_transactions Table (Audit Log)

Complete audit trail of all share movements.

```sql
CREATE TABLE share_transactions (
  id BIGSERIAL PRIMARY KEY,
  transaction_type VARCHAR(50),             -- issuance, transfer, buyback, exit
  from_shareholder_id BIGINT REFERENCES users(id),
  to_shareholder_id BIGINT REFERENCES users(id),
  shares_amount BIGINT,
  price_per_share DECIMAL(12,4),
  equity_type VARCHAR(20),                  -- PURCHASED or GRANTED
  reason TEXT,
  reference_id BIGINT,                      -- Link to buyback/exit/issuance ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by_id BIGINT
);
```

### 6. share_buybacks Table

Tracks share repurchases.

```sql
CREATE TABLE share_buybacks (
  id BIGSERIAL PRIMARY KEY,
  shareholder_id BIGINT NOT NULL REFERENCES users(id),
  shares_repurchased BIGINT,
  buyback_price_per_share DECIMAL(12,4),
  total_repurchase_value DECIMAL(15,2),
  reason TEXT,
  status VARCHAR(20) DEFAULT 'pending',     -- pending, completed, cancelled
  approved_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. shareholder_exits Table

Handles shareholder departures.

```sql
CREATE TABLE shareholder_exits (
  id BIGSERIAL PRIMARY KEY,
  shareholder_id BIGINT NOT NULL REFERENCES users(id),
  exit_type VARCHAR(50),                    -- departure, liquidation, forfeiture
  shares_surrendered BIGINT,
  exit_price_per_share DECIMAL(12,4),
  total_exit_value DECIMAL(15,2),
  reason TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  processed_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Backend Library API

### Shares Configuration

#### `getSharesConfiguration()`
```javascript
const config = await getSharesConfiguration();
// Returns:
{
  authorized_shares: 1000000,
  issued_shares: 100,
  unissued_shares: 999900,
  par_value: 1.00,
  description: "Default company shares configuration"
}
```

#### `updateAuthorizedShares(newCount)`
```javascript
await updateAuthorizedShares(2000000);
// Validates: newCount >= issued_shares
```

### Valuation Engine

#### `recordValuationRound(valuation)`
```javascript
const round = await recordValuationRound({
  pre_money_valuation: 92000000,
  investment_amount: 1840000,
  round_name: 'Seed',
  investor_name: 'Tech Ventures',
});
// Returns:
{
  pre_money_valuation: 92000000,
  investment_amount: 1840000,
  post_money_valuation: 93840000,
  share_price: 920000,
  shares_to_issue: 2,
  round_name: 'Seed'
}
```

#### `getCurrentValuation()`
```javascript
const current = await getCurrentValuation();
// Returns latest valuation snapshot with all metrics
```

### Vesting System

#### `calculateVestedShares(shareholderId)`
```javascript
const vesting = await calculateVestedShares(shareholderId);
// Returns:
{
  total_shares: 1000,
  equity_type: 'GRANTED',
  vested_shares: 250,          // After 1 year
  unvested_shares: 750,
  vesting_start_date: '2024-01-01',
  vesting_end_date: '2028-01-01',
  vesting_percentage: 100,
  is_fully_vested: false
}
```

#### `getVestingProgress(shareholderId)`
```javascript
const progress = await getVestingProgress(shareholderId);
// Returns:
{
  ...calculateVestedShares,
  progress_percentage: 25,     // 1 year of 4
  time_elapsed_days: 365,
  total_vesting_days: 1460,
  remaining_days: 1095,
  status: 'vesting'
}
```

### Share Operations

#### `issueNewShares(issuance)`
```javascript
await issueNewShares({
  to_shareholder_id: 123,
  shares_amount: 10,
  equity_type: 'GRANTED',
  vesting_start_date: '2024-01-01',
  vesting_end_date: '2028-01-01',
  vesting_percentage: 100,
});
// Updates shareholdings and issued_shares in shares_config
```

#### `transferShares(transfer)`
```javascript
await transferShares({
  from_shareholder_id: 123,
  to_shareholder_id: 456,
  shares_amount: 5,
  price_per_share: 920000,
  reason: 'Share transfer agreement'
});
```

#### `executeBuyback(buyback)`
```javascript
await executeBuyback({
  shareholder_id: 123,
  shares_repurchased: 5,
  buyback_price_per_share: 1000000,
  reason: 'Strategic buyback'
});
// Reduces issued_shares and shareholder holdings
```

### Cap Table

#### `getCapTableWithVesting()`
```javascript
const capTable = await getCapTableWithVesting();
// Returns:
[
  {
    shareholder_id: 1,
    shareholder_name: 'Alice Founder',
    shares_owned: 100,
    equity_type: 'GRANTED',
    vested_shares: 100,
    unvested_shares: 0,
    ownership_percentage: 98.04,
    vested_ownership_percentage: 98.04
  },
  {
    shareholder_id: 2,
    shareholder_name: 'Bob Investor',
    shares_owned: 2,
    equity_type: 'PURCHASED',
    vested_shares: 2,
    unvested_shares: 0,
    ownership_percentage: 1.96,
    vested_ownership_percentage: 1.96
  }
]
```

---

## API Endpoints

### Valuation Endpoints

#### `GET /api/equity/valuation`
Returns current company valuation metrics.

**Response:**
```json
{
  "success": true,
  "data": {
    "pre_money_valuation": 92000000,
    "post_money_valuation": 93840000,
    "share_price": 920000,
    "last_round": "Seed",
    "shares_config": {
      "authorized_shares": 1000000,
      "issued_shares": 102,
      "unissued_shares": 999898
    }
  }
}
```

#### `POST /api/equity/valuation`
Record a new valuation round.

**Request:**
```json
{
  "pre_money_valuation": 92000000,
  "investment_amount": 1840000,
  "round_name": "Seed",
  "investor_name": "Tech Ventures",
  "notes": "Initial seed round"
}
```

### Vesting Endpoints

#### `GET /api/equity/vesting-status?shareholder_id=123`
Get vesting progress for a shareholder.

**Response:**
```json
{
  "success": true,
  "data": {
    "total_shares": 1000,
    "equity_type": "GRANTED",
    "vested_shares": 250,
    "unvested_shares": 750,
    "progress_percentage": 25,
    "remaining_days": 1095,
    "status": "vesting"
  }
}
```

### Buyback Endpoints

#### `POST /api/equity/buyback`
Execute share buyback.

**Request:**
```json
{
  "shareholder_id": 123,
  "shares_repurchased": 5,
  "buyback_price_per_share": 1000000,
  "reason": "Strategic buyback"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "new_balance": 95,
    "total_value": 5000000,
    "config": {
      "authorized_shares": 1000000,
      "issued_shares": 97,
      "unissued_shares": 999903
    }
  }
}
```

---

## Implementation Scenarios

### Scenario 1: Founder-Only Company

**Setup:**
```javascript
// Initialize config
const config = await getSharesConfiguration(); // 1,000,000 authorized

// Founder receives 100 shares as GRANTED equity
await issueNewShares({
  to_shareholder_id: 1,
  shares_amount: 100,
  equity_type: 'GRANTED',
  vesting_start_date: '2024-01-01',
  vesting_end_date: '2028-01-01',
  vesting_percentage: 100,
});

// Result: 100 issued, 999,900 unissued
```

**Valuation:**
```javascript
// Calculate share price
const valuation = {
  pre_money_valuation: 92000000,  // UGX 92,000,000
  investment_amount: 0,
};
const share_price = 92000000 / 100 = UGX 920,000 per share
```

### Scenario 2: Investor Entry (Seed Round)

**Setup:**
```javascript
const investment = await recordValuationRound({
  pre_money_valuation: 92000000,
  investment_amount: 1840000,
  round_name: 'Seed',
  investor_name: 'Tech Ventures',
});

// Shares to issue = 1840000 / 920000 = 2 shares
// New issued: 102 (100 founder + 2 investor)
// Post-money: 93840000

// Create shareholding for investor
await issueNewShares({
  to_shareholder_id: 2,
  shares_amount: 2,
  equity_type: 'PURCHASED',
  purchase_price: 920000,
});
```

**Results:**
- Founder: 100 shares (98.04% diluted)
- Investor: 2 shares (1.96% diluted)
- Total issued: 102 shares
- Unissued: 999,898 shares

### Scenario 3: Buyback for Performance

```javascript
// Company wants to buyback shares from shareholder at higher price
await executeBuyback({
  shareholder_id: 2,
  shares_repurchased: 1,
  buyback_price_per_share: 1200000,  // Premium buyback
  reason: 'Performance incentive buyback'
});

// Result:
// - Investor has 1 share remaining
// - Total issued: 101 shares
// - Unissued increases: 999,899
// - Transaction logged for audit
```

---

## Frontend Integration

### Cap Table Display

```jsx
import { getCapTableWithVesting } from '@/lib/shares.js';

export default function CapTable() {
  const [capTable, setCapTable] = useState([]);

  useEffect(async () => {
    const table = await getCapTableWithVesting();
    setCapTable(table);
  }, []);

  return (
    <table>
      <thead>
        <tr>
          <th>Shareholder</th>
          <th>Shares</th>
          <th>Type</th>
          <th>Vested</th>
          <th>Unvested</th>
          <th>Ownership %</th>
        </tr>
      </thead>
      <tbody>
        {capTable.map(row => (
          <tr key={row.shareholder_id}>
            <td>{row.shareholder_name}</td>
            <td>{row.shares_owned}</td>
            <td>{row.equity_type}</td>
            <td>{row.vested_shares}</td>
            <td>{row.unvested_shares}</td>
            <td>{row.ownership_percentage}%</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

### Vesting Timeline

```jsx
import { getVestingProgress } from '@/lib/shares.js';

export default function VestingTimeline({ shareholderId }) {
  const [vesting, setVesting] = useState(null);

  useEffect(async () => {
    const progress = await getVestingProgress(shareholderId);
    setVesting(progress);
  }, [shareholderId]);

  if (!vesting) return null;

  return (
    <div className="vesting-progress">
      <h3>Vesting Progress: {vesting.progress_percentage}%</h3>
      <div className="progress-bar">
        <div style={{ width: `${vesting.progress_percentage}%` }} className="filled" />
      </div>
      <div className="vesting-details">
        <p>Vested: {vesting.vested_shares} / {vesting.total_shares}</p>
        <p>Unvested: {vesting.unvested_shares}</p>
        <p>Time Elapsed: {vesting.time_elapsed_days} days</p>
        <p>Remaining: {vesting.remaining_days} days</p>
      </div>
    </div>
  );
}
```

---

## Testing Checklist

- [ ] Create company with 1,000,000 authorized shares
- [ ] Issue 100 founder shares (GRANTED, 4-year vesting)
- [ ] Verify issued_shares = 100, unissued = 999,900
- [ ] Record Seed round: $92M pre-money, $1.84M investment
- [ ] Verify share price = $920,000
- [ ] Verify 2 investor shares issued
- [ ] Check cap table: Founder 98.04%, Investor 1.96%
- [ ] Advance time 1 year, verify 25 founder shares vested
- [ ] Execute buyback: 1 share at $1.2M
- [ ] Verify issued decreases, vested remains accurate
- [ ] Verify all transactions logged in audit trail

---

## Migration Execution

The migration file `migrations/008_two_layer_share_model.sql` includes all necessary schema changes. Execute with:

```bash
# Using npm script (if configured)
npm run migrate

# Or directly with psql
psql -d jeton_db -f migrations/008_two_layer_share_model.sql
```

---

## Audit & Compliance

All share transactions are automatically logged:
- Who (user_id)
- What (transaction_type)
- When (created_at)
- Amount (shares_amount, price_per_share)
- Reason (for business context)

Access via `share_transactions` table for compliance reporting and cap table verification.

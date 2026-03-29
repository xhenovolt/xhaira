# Single Source of Truth: Valuation Architecture

## 🎯 Overview

Jeton now implements **Single Source of Truth (SSOT)** for company valuation across all modules. This is a critical architectural decision that transforms Jeton from "disconnected modules" into an **integrated executive operating system**.

**The principle:** Company valuation is computed once by the Dashboard's valuation engine, and all other modules (including Shares) consume it—never duplicate or re-calculate.

## 🏗️ Architecture

### Core Concept

```
┌─────────────────────────────────────────┐
│    Dashboard Valuation Engine            │
│  (Single Source of Truth)                │
│                                          │
│  Assets → IP Value → Infrastructure      │
│       ↓                                   │
│  Strategic Company Value (UGX92B)        │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┴──────────┐
        ↓                     ↓
   [Shares Page]      [Other Modules]
   (consumes)         (consumes)
   
NO manual inputs
NO duplicated logic
NO valuation mismatches
```

### Valuation Calculation Flow

```javascript
// SINGLE SOURCE: Dashboard calculates
accountingNetWorth = totalAssets - liabilities
strategicIPValue = SUM(ip.valuation_estimate)
infrastructureValue = SUM(infrastructure.replacement_cost)

strategicCompanyValue = accountingNetWorth + strategicIPValue + infrastructureValue
                      = UGX1.2B + UGX88.2B + UGX2.6B
                      = UGX92B
```

All modules receive `strategicCompanyValue` from the same calculation.

## 🔄 Shares Module Integration

### API: GET /api/shares

**Response now includes complete valuation breakdown:**

```json
{
  "success": true,
  "data": {
    "authorized_shares": 100,
    "price_per_share": 920000000,
    "shares_allocated": 0,
    "shares_remaining": 100,
    "allocation_percentage": 0,
    "valuation": {
      "accounting_net_worth": 1200000,
      "strategic_company_value": 92000000000,
      "total_ip_valuation": 88200000000,
      "infrastructure_value": 2600000000,
      "total_liabilities": 1000000,
      "total_assets_book_value": 2200000,
      "valuation_difference": 90800000000
    }
  }
}
```

**Key field:**
- `valuation.strategic_company_value` - SYNCED from Dashboard
- `price_per_share` - CALCULATED from synced valuation (never manual input)

### API: PUT /api/shares

**CRITICAL GUARDRAIL:**

```javascript
// ❌ This is REJECTED
PUT /api/shares {
  "authorized_shares": 100,
  "company_valuation": 50000000000  // ← FORBIDDEN
}

Response: {
  "success": false,
  "error": "Company valuation cannot be manually set. 
           It is synced from the Executive Valuation Dashboard."
}
```

**ONLY authorized_shares is editable:**

```javascript
// ✅ This is ACCEPTED
PUT /api/shares {
  "authorized_shares": 150  // Can increase/decrease (with constraints)
}

// Valuation is IGNORED if provided
// It will be re-fetched from Dashboard on next GET
```

### Backend Logic: getStrategicCompanyValue()

Both `/api/shares` and `/api/shares/allocations` call the same function:

```javascript
// src/app/api/shares/route.js
async function getStrategicCompanyValue() {
  // Query the SAME data sources as Dashboard
  const assets = await query(`SELECT * FROM assets_accounting WHERE status != 'disposed'`);
  const liabilities = await query(`SELECT SUM(outstanding_amount) FROM liabilities WHERE status IN ('ACTIVE', 'DEFERRED')`);
  const ip = await query(`SELECT * FROM intellectual_property WHERE status IN ('active', 'scaling', 'maintenance')`);
  const infrastructure = await query(`SELECT * FROM infrastructure WHERE status = 'active'`);
  
  // Use SHARED library (same as Dashboard)
  const valuation = getValuationSummary({
    assets: assets.rows,
    liabilities: parseFloat(liabilitiesResult.rows[0]?.total || 0),
    ip: ip.rows,
    infrastructure: infrastructure.rows,
  });
  
  return valuation.strategicCompanyValue;  // SINGLE SOURCE
}
```

## 📊 Shares Page UX: Valuation Display

### Live Sync Indicator

Green banner shows:
```
🟢 Live (auto-updated every 30s)
   Synced from Executive Valuation Dashboard
```

### Four Primary Metrics

1. **STRATEGIC VALUE** (read-only, synced)
   - Source: Dashboard
   - Updates: Every 30 seconds
   - Example: UGX92,000,000,000

2. **AUTHORIZED SHARES** (editable)
   - Controls scarcity
   - Default: 100
   - Can increase/decrease with constraints

3. **PRICE PER SHARE** (derived, not editable)
   - Formula: Strategic Value ÷ Authorized Shares
   - Updates: When valuation changes OR authorized shares change
   - Example: UGX92B ÷ 100 = UGX920M

4. **ALLOCATION STATUS** (auto-calculated)
   - Shows allocated/authorized
   - Example: 30/100 shares

### Valuation Bridge Preview (Collapsed)

Shows how strategic value is calculated:

```
Accounting Net Worth:        UGX1,200,000
+ Strategic IP Value:        UGX88,200,000
+ Infrastructure Value:      UGX2,600,000
= Final Strategic Value:     UGX92,000,000
```

All fields update automatically when assets/IP/infrastructure changes.

### Configure Modal: Authorized Shares

**What IS editable:**
- Authorized Shares input

**What is NOT editable:**
- Company Valuation field shows:
  ```
  🔧 Synced from Executive Valuation Dashboard (read-only)
  
  To influence valuation, update underlying 
  assets, IP value, or infrastructure in the dashboard.
  ```

**Tooltip explains:**
> "Company valuation is computed from assets, IP, and infrastructure. 
> To influence valuation, update underlying components."

## 🔄 Automatic Updates

### 30-Second Refresh Cadence

```javascript
useEffect(() => {
  fetchData();  // Initial load
  
  // SAME cadence as Dashboard
  const interval = setInterval(fetchData, 30000);
  return () => clearInterval(interval);
}, []);
```

**Scenario:**
1. User increases asset book value on Dashboard
2. Dashboard recalculates: strategicCompanyValue increases
3. Shares page auto-fetches new valuation (within 30 seconds)
4. Price per share updates automatically
5. All allocations' value recalculate

**Result:** CEO sees changes propagate across the system in near real-time.

## 🧮 Share Price Calculations

### Formula

```
Price Per Share = Strategic Company Value / Authorized Shares

Example:
- Strategic Value: UGX92,000,000,000
- Authorized Shares: 100
- Price Per Share: UGX920,000,000
```

### When Price Updates

Price updates when:
- ✅ Asset book values change (Dashboard)
- ✅ IP valuation changes (Dashboard)
- ✅ Infrastructure values change (Dashboard)
- ✅ Liabilities change (Dashboard)
- ✅ Authorized shares change (Shares page)

Price does NOT update from:
- ❌ Manual "company_valuation" input (blocked at API)
- ❌ Stored database field (uses live calculation)

## 👥 Ownership & Allocation Accuracy

### Ownership Percentage (Auto-Updated)

```javascript
ownership_percentage = (shares_allocated / authorized_shares) * 100

Example:
- Shares allocated: 30
- Authorized shares: 100
- Ownership: 30%
```

Updates automatically when:
- Authorized shares change
- Share allocation changes

### Share Value (Always Current)

```javascript
share_value = shares_allocated * (strategic_company_value / authorized_shares)

Example:
- Shares allocated: 30
- Strategic value: UGX92B
- Authorized: 100
- Share value: 30 * (92B / 100) = 30 * 920M = UGX27.6B
```

Updates automatically when:
- Company valuation changes (every 30s if assets change)
- Authorized shares change
- Shares allocated change

**Investor-grade:** An investor can see their stake value update in near real-time as company grows.

## 🛡️ Guardrails & Constraints

### 1. Cannot Manually Set Valuation

```javascript
// API validates this
if (body.company_valuation !== undefined) {
  return error("Company valuation cannot be manually set...")
}
```

**Why:** Prevents casually overvaluing company to inflate share prices.

### 2. Cannot Reduce Authorized Shares Below Allocated

```javascript
if (newAuthorized < currentAllocated) {
  return error(`Cannot reduce below ${currentAllocated} already allocated`)
}
```

**Why:** Prevents creating invalid state where allocation % > 100%.

### 3. Cannot Over-Allocate Shares

```javascript
if (currentAllocated + newShares > authorized) {
  return error(`Only ${available} shares available`)
}
```

**Why:** Prevents allocating more shares than authorized.

### 4. Warning Modal on Share Reduction

When reducing authorized shares with allocations:
- Shows current vs. new capacity
- Shows remaining shares available
- Requires explicit confirmation

**Why:** Executive awareness of structural changes.

## 📈 Example Scenario: Company Growth

### Day 1: Seed Stage

```
Assets: UGX1B
IP: UGX10B
Infrastructure: UGX500M
VALUATION: UGX11.5B

Authorized: 100
Price/Share: 115M
Founder 50 shares = 5.75B
Investor 30 shares = 3.45B
```

### Day 30: New IP Created (Dashboard)

CEO updates Infrastructure Insurance policy:
- New value: UGX5B (was 500M)
- Dashboard recalculates strategicCompanyValue
- New valuation: UGX16B (automatic)

Shares Page (auto-refreshes):
```
VALUATION: UGX16B (synced automatically)
Price/Share: 160M (recalculated)
Founder 50 shares = 8B (updated)
Investor 30 shares = 4.8B (updated)
```

Neither founder nor investor needs to do anything. Values update automatically.

## 🏛️ C-Suite Perspective

This architecture makes Jeton behave like a proper executive system:

1. **Single Brain:** One valuation engine, not multiple
2. **Investor-Ready:** Allocations always match real ownership
3. **Audit Trail:** All valuation changes come from assets/IP/infrastructure
4. **No Manipulation:** Can't casually inflate share prices
5. **Real-Time:** Executive sees true company value propagate to equity

**Quote for board:** "Our cap table is always synchronized with our actual asset value. We don't maintain separate equity metrics—our shares reflect real company worth."

## 🔧 Implementation Details

### Database Schema

**Shares Table:**
```sql
CREATE TABLE shares (
  id BIGSERIAL PRIMARY KEY,
  authorized_shares BIGINT DEFAULT 100,  -- EDITABLE
  class_type VARCHAR DEFAULT 'common',
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMP,
  updated_at TIMESTAMP
  
  -- NOTE: NO company_valuation column
  -- Valuation is CALCULATED, not stored
);
```

**Share Allocations Table:**
```sql
CREATE TABLE share_allocations (
  id BIGSERIAL PRIMARY KEY,
  owner_name VARCHAR,
  owner_email VARCHAR,
  shares_allocated BIGINT,
  
  -- Valuation fields are NOT stored
  -- They are CALCULATED on GET using current strategicCompanyValue
  
  allocation_date DATE,
  vesting_start_date DATE,
  vesting_end_date DATE,
  vesting_percentage NUMERIC,
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### API Routes

**GET /api/shares**
- Fetches authorized_shares from database
- Calculates strategicCompanyValue (live)
- Calculates price_per_share (derived)
- Returns with full valuation breakdown

**PUT /api/shares**
- Only accepts authorized_shares
- Rejects company_valuation input
- Updates shares table
- Next GET will fetch fresh valuation

**GET /api/shares/allocations**
- Fetches allocations from database
- Calculates strategicCompanyValue (live, SAME function as /api/shares)
- Calculates ownership_percentage
- Calculates share_value
- Returns with synced valuation

**POST /api/shares/allocations**
- Validates against authorized_shares
- Prevents over-allocation
- Stores only allocation data
- Next GET will calculate current values using fresh valuation

## 📋 Migration Path

### Fresh Database

```bash
node scripts/init-db.js
```

Creates shares table with:
- `authorized_shares = 100`
- NO `company_valuation` field

### Existing Database with Manual Valuation

If you previously stored `company_valuation`:

```sql
-- Remove the stored field
ALTER TABLE shares DROP COLUMN company_valuation;

-- Valuation is now ALWAYS calculated
-- No data loss: all info comes from assets/IP/infrastructure
```

## ✅ Validation Checklist

- [x] GET /api/shares returns strategic_company_value from Dashboard engine
- [x] PUT /api/shares rejects company_valuation input with clear error
- [x] Price per share calculated from synced valuation
- [x] Allocations use same strategicCompanyValue source
- [x] Shares page shows "Synced from Dashboard" label
- [x] 30-second refresh cadence matches Dashboard
- [x] Valuation breakdown displayed with accounting + IP + infrastructure
- [x] Ownership % updates automatically
- [x] Share value updates automatically
- [x] No ability to casually inflate prices
- [x] Investor-ready cap table

## 🎓 Key Takeaways

| Aspect | Before | After |
|--------|--------|-------|
| Valuation | Stored in DB, manual input | Calculated live from assets/IP/infrastructure |
| Price/Share | Static, disconnected from company value | Dynamic, always reflects real valuation |
| Share Value | Used stored valuation | Uses current strategicCompanyValue |
| API Input | company_valuation was editable | Completely removed, read-only |
| Source of Truth | Multiple (manual input + DB) | Single (Dashboard engine) |
| Update cadence | Manual | Automatic every 30s |
| Investor trust | "Why did my stake value change?" | "I can see exactly why: asset values changed" |

---

**This is enterprise-grade equity architecture.** Companies like Carta and Pulley implement similar SSOT patterns. Jeton now competes at that level.

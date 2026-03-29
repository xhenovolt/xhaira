# Valuation SSOT: Developer Quick Reference

## The Rule

> **Company valuation is calculated ONE TIME by the Dashboard.**
> **All other modules consume it. NEVER re-calculate or store it.**

## Code Pattern

### ❌ DON'T Do This

```javascript
// Bad: Duplicating valuation calculation
export async function GET(request) {
  const assets = await query(`SELECT * FROM assets_accounting`);
  const ip = await query(`SELECT * FROM intellectual_property`);
  
  // ❌ Problem: This code exists in TWO places
  // If Dashboard changes its formula, this breaks
  const value = calculateTotalAssetsBookValue(assets) + 
                calculateTotalIPValuation(ip);
  
  return Response.json({ company_value: value });
}
```

### ✅ DO This

```javascript
// Good: Use shared function
import { getValuationSummary } from '@/lib/valuations.js';

export async function GET(request) {
  const assets = await query(`SELECT * FROM assets_accounting`);
  const ip = await query(`SELECT * FROM intellectual_property`);
  const infrastructure = await query(`SELECT * FROM infrastructure`);
  const liabilities = await query(`SELECT SUM(outstanding_amount) FROM liabilities`);
  
  // ✅ Good: This SAME function is used by Dashboard
  // All calculations stay in sync
  const valuation = getValuationSummary({
    assets: assets.rows,
    ip: ip.rows,
    infrastructure: infrastructure.rows,
    liabilities: parseFloat(liabilities.rows[0]?.total || 0)
  });
  
  return Response.json({ 
    company_value: valuation.strategicCompanyValue
  });
}
```

## API Design Checklist

When adding valuation fields to any API:

- [ ] **READ:** `GET` endpoints should fetch strategicCompanyValue fresh
- [ ] **WRITE:** `PUT`/`POST` endpoints should **REJECT** any valuation input
- [ ] **ERROR MSG:** Clear error if someone tries to set valuation:
  ```
  "Company valuation cannot be manually set. 
   It is synced from the Executive Valuation Dashboard."
  ```
- [ ] **RESPONSE:** Include full valuation breakdown for transparency
- [ ] **DOCS:** Explain that valuation is read-only, synced from Dashboard

### PUT Endpoint Template

```javascript
export async function PUT(request) {
  const body = await request.json();
  
  // ✅ GOOD: Reject manual valuation input
  if (body.company_valuation !== undefined) {
    return Response.json({
      success: false,
      error: 'Company valuation cannot be manually set. It is synced from the Executive Valuation Dashboard.'
    }, { status: 400 });
  }
  
  // ✅ GOOD: Accept other editable fields
  if (body.authorized_shares) {
    // Update authorized_shares
  }
  
  // ✅ GOOD: Don't store valuation, it's calculated on GET
  // Just return the updated record
}
```

## Frontend Component Pattern

### Display Valuation (Read-Only)

```jsx
// ✅ Good: Show valuation as read-only with source
<div className="bg-blue-50 p-4 rounded">
  <label className="font-semibold">Company Valuation</label>
  <p className="text-2xl font-bold">
    <CurrencyDisplay amount={strategicValue} />
  </p>
  <p className="text-xs text-gray-500">
    🔧 Synced from Executive Valuation Dashboard (read-only)
  </p>
  <p className="text-xs text-gray-600 mt-2">
    To influence valuation, update underlying assets, IP, 
    or infrastructure in the dashboard.
  </p>
</div>
```

### Show Calculation Breakdown

```jsx
// ✅ Good: Transparent calculation
<div className="space-y-3">
  <div className="flex justify-between">
    <span>Accounting Net Worth</span>
    <span><CurrencyDisplay amount={valuation.accounting_net_worth} /></span>
  </div>
  <div className="flex justify-between text-blue-600">
    <span>+ Strategic IP Value</span>
    <span>+<CurrencyDisplay amount={valuation.total_ip_valuation} /></span>
  </div>
  <div className="flex justify-between text-green-600">
    <span>+ Infrastructure Value</span>
    <span>+<CurrencyDisplay amount={valuation.infrastructure_value} /></span>
  </div>
  <div className="flex justify-between font-bold bg-purple-500 text-white p-3">
    <span>= Strategic Company Value</span>
    <span><CurrencyDisplay amount={valuation.strategic_company_value} /></span>
  </div>
</div>
```

### Auto-Refresh for Sync

```jsx
useEffect(() => {
  // Initial fetch
  fetchData();
  
  // Refresh every 30 seconds (same as Dashboard)
  const interval = setInterval(fetchData, 30000);
  
  return () => clearInterval(interval);
}, []);
```

## Database Schema Rules

### DO Store

```sql
CREATE TABLE shares (
  id BIGSERIAL PRIMARY KEY,
  authorized_shares BIGINT DEFAULT 100,  -- ✅ STORE: Editable parameter
  class_type VARCHAR DEFAULT 'common',   -- ✅ STORE: User input
  status VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
  
  -- NO company_valuation column
  -- Valuation is calculated on-the-fly from assets/ip/infrastructure
);
```

### DON'T Store

```sql
-- ❌ WRONG: Storing calculated value
ALTER TABLE shares ADD company_valuation DECIMAL;

-- ❌ PROBLEM: This becomes stale when assets change
-- ❌ PROBLEM: Multiple modules have different cached values
-- ❌ PROBLEM: No audit trail of calculation
```

## Testing Checklist

- [ ] GET endpoint returns fresh valuation (test after updating assets)
- [ ] PUT endpoint rejects company_valuation input with proper error
- [ ] PUT endpoint accepts authorized_shares
- [ ] Calculated fields (price_per_share, ownership %) are correct
- [ ] Frontend shows "Synced from Dashboard" label
- [ ] Frontend shows valuation breakdown
- [ ] Auto-refresh works (check after asset change)
- [ ] All values update within 30 seconds of asset change

## When Adding a New Module

If you're adding a new module that needs valuation:

1. **Import getValuationSummary**
```javascript
import { getValuationSummary } from '@/lib/valuations.js';
```

2. **Query source data**
```javascript
const assets = await query(`SELECT * FROM assets_accounting`);
const ip = await query(`SELECT * FROM intellectual_property`);
// etc
```

3. **Call shared function**
```javascript
const valuation = getValuationSummary({
  assets: assets.rows,
  ip: ip.rows,
  infrastructure: infrastructure.rows,
  liabilities: parseFloat(liabilities.rows[0]?.total || 0)
});
```

4. **Use strategicCompanyValue**
```javascript
const pricePerShare = valuation.strategicCompanyValue / authorizedShares;
```

5. **NEVER store the result**
- Calculate fresh on every GET
- Don't cache in database
- Don't add manual input field

## Common Mistakes

### ❌ Mistake 1: Storing Valuation in a Table

```javascript
// WRONG
INSERT INTO shares (authorized_shares, company_valuation) VALUES (100, 92000000000);

// PROBLEM: This value becomes stale immediately
// If assets change, this doesn't update
// Dashboard and Shares have different values
```

### ❌ Mistake 2: Manual Input Field in UI

```jsx
// WRONG
<input 
  label="Company Valuation"
  value={companyValuation}
  onChange={setCompanyValuation}
/>

// PROBLEM: CEO can manually change valuation
// Disconnects equity from actual assets
// Breaks audit trail
```

### ❌ Mistake 3: Caching Without Refresh

```javascript
// WRONG
let cachedValuation = 92000000000;  // Set once on startup

function getValuation() {
  return cachedValuation;  // Never updates
}

// PROBLEM: If assets change, cached value is stale
// 30-second refresh becomes 30-day staleness
```

### ✅ Correct: Call Fresh on Every Request

```javascript
// CORRECT
export async function GET(request) {
  // Always fetch fresh data
  const assets = await query(`SELECT * FROM assets_accounting`);
  const valuation = getValuationSummary({ assets: assets.rows });
  
  return Response.json({ 
    value: valuation.strategicCompanyValue  // Always current
  });
}
```

## Performance Note

Getting fresh valuation means querying assets/IP/infrastructure tables. This is **acceptable** because:

1. **Queries are fast** (B-tree indexes on status/type)
2. **Calculation is O(n)** where n = number of assets (~10-100)
3. **Updates every 30 seconds max** in UI (not every render)
4. **Read-heavy** (assets rarely change during trading hours)

If performance becomes an issue:

```javascript
// Cache strategically (NOT permanently)
const valuationCache = new Map();
const CACHE_TTL = 5000; // 5 seconds

function getStrategyValueCached() {
  const now = Date.now();
  const cached = valuationCache.get('value');
  
  if (cached && (now - cached.timestamp) < CACHE_TTL) {
    return cached.value;  // Reuse for 5 seconds
  }
  
  // Otherwise calculate fresh
  const value = calculateFresh();
  valuationCache.set('value', { value, timestamp: now });
  return value;
}

// But UI still refreshes every 30 seconds
// So end-users see updates in reasonable time
```

## Architecture Principle

> **"Write once, read everywhere"**

- Dashboard **writes** to assets/IP/infrastructure
- All modules **read** from the same source
- Valuation **calculated** once using shared library
- No duplication, no sync issues, no conflicts

This is the pattern used by:
- Stripe (singular source for balance)
- Shopify (singular product catalog)
- Carta (singular cap table calculation)
- Linear (singular issue state)

Now Jeton implements it too.

---

**Golden Rule:** If you're re-calculating valuation in a second place, you're doing it wrong.

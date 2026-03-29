# Share Management System - Implementation Guide

## Overview

The Jeton share management system allows complete management of company equity, including share configuration, allocation to owners, and tracking of share price over time based on company valuation.

## Features Implemented

### 1. Share Setup & Configuration

**Endpoint:** `POST/PUT /api/shares`

Allows configuration of:
- Total number of shares issued
- Par value (nominal value)
- Share class type (common, preferred, etc.)

**Automatic Share Price Calculation:**
```
share_price = strategic_company_value ÷ total_shares
```

The share price updates automatically whenever company valuation changes.

### 2. Share Allocation Management

**Endpoint:** `POST/GET /api/shares/allocations`  
**Endpoint:** `PUT/DELETE /api/shares/allocations/[id]`

Features:
- Allocate shares to individual owners
- Track ownership percentage automatically
- Calculate share value based on current share price
- Support for vesting schedules:
  - Vesting start and end dates
  - Vesting percentage
- Add allocation notes for reference
- Edit and deactivate allocations

**Validation:**
- Ensures total allocated shares don't exceed available shares
- Prevents over-allocation with error messages

### 3. Share Price History Tracking

**Endpoint:** `POST/GET /api/shares/price-history`

Tracks:
- Daily share price (OHLC - Open, High, Low, Close)
- Company valuation at time of price record
- Historical price statistics:
  - Current price
  - Price change (absolute and percentage)
  - Min/max prices in period
  - Average price

**Query Parameters:**
- `days` - Number of days of history to fetch (default: 30)

### 4. Frontend Pages

#### Shares Management Page (`/app/app/shares`)

Features:
- **Share Configuration Summary** - 4-card dashboard showing:
  - Total shares
  - Current share price
  - Allocated shares (with owner count)
  - Remaining shares available
  
- **Share Allocations Table** - Complete list showing:
  - Owner name and email
  - Number of shares
  - Ownership percentage
  - Share value (calculated from price × shares)
  - Allocation date
  - Edit and delete actions
  - Footer totals

- **Modals:**
  - **Allocation Modal** - Create/edit allocations with fields:
    - Owner name and email
    - Share quantity (with real-time value preview)
    - Allocation date
    - Vesting schedule (optional)
    - Notes
  
  - **Configuration Modal** - Update share structure:
    - Total shares
    - Par value
    - Real-time share price preview based on company valuation

#### Dashboard Integration

**Share Price Widget** - On the main dashboard:
- Displays current share price prominently
- Shows total and allocated shares count
- Automatically updates with company valuation changes
- Part of the primary KPIs section

### 5. Database Schema

```sql
-- Share Configuration
CREATE TABLE shares (
  id SERIAL PRIMARY KEY,
  total_shares BIGINT,           -- Total issued shares
  par_value DECIMAL(19, 2),      -- Nominal value per share
  class_type VARCHAR(50),         -- Share class
  status VARCHAR(50)              -- active/inactive
)

-- Share Allocations
CREATE TABLE share_allocations (
  id SERIAL PRIMARY KEY,
  owner_id INTEGER,              -- Reference to owner
  owner_name VARCHAR(255),       -- Owner name
  owner_email VARCHAR(255),      -- Contact email
  shares_allocated BIGINT,       -- Number of shares
  allocation_date DATE,          -- When allocated
  vesting_start_date DATE,       -- Vesting schedule
  vesting_end_date DATE,
  vesting_percentage DECIMAL(5,2), -- % vested
  notes TEXT,                    -- Additional notes
  status VARCHAR(50)             -- active/inactive
)

-- Share Price History
CREATE TABLE share_price_history (
  id SERIAL PRIMARY KEY,
  date DATE UNIQUE,              -- Trading date
  opening_price DECIMAL(19, 4),  -- Opening price
  closing_price DECIMAL(19, 4),  -- Closing price
  high_price DECIMAL(19, 4),     -- High price
  low_price DECIMAL(19, 4),      -- Low price
  company_valuation DECIMAL(19,2), -- Company value
  total_shares BIGINT            -- Shares outstanding
)
```

### 6. Utility Functions

**File:** `src/lib/shares.js`

Available functions:

```javascript
// Calculate share price from company valuation
calculateSharePrice(strategicValue, totalShares)

// Calculate total value for given shares
calculateShareValue(sharePrice, shareQuantity)

// Calculate ownership percentage
calculateOwnershipPercentage(sharesOwned, totalShares)

// Record share price in history
recordSharePrice(strategicValue)

// Get current share price
getCurrentSharePrice()

// Get portfolio summary
getSharePortfolioSummary()
```

## Integration with Valuation System

When company valuation is updated (through assets, liabilities, or IP changes):

1. New strategic company value is calculated
2. Share price is automatically recalculated
3. Share price history record is created/updated
4. Dashboard widgets refresh with new share price
5. All owner share values update automatically

## Usage Examples

### Setting up Company Shares

```javascript
// Configure share structure
fetch('/api/shares', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    total_shares: 1000000,
    par_value: 1.00,
    class_type: 'common'
  })
})
```

### Allocating Shares to Owner

```javascript
// Allocate shares to founder
fetch('/api/shares/allocations', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    owner_name: 'John Founder',
    owner_email: 'john@company.com',
    shares_allocated: 500000,
    allocation_date: '2025-01-01',
    vesting_start_date: '2025-01-01',
    vesting_end_date: '2029-01-01',
    vesting_percentage: 100,
    notes: 'Founder equity - 4-year vesting'
  })
})
```

### Fetching Share Price History

```javascript
// Get last 90 days of price history
fetch('/api/shares/price-history?days=90')
  .then(r => r.json())
  .then(data => {
    console.log(data.data)      // Array of price records
    console.log(data.statistics) // Min, max, avg, change
  })
```

## Sidebar Navigation

The Shares page is accessible via:
**Finance → Shares**

Located in the Finance submenu alongside Assets and Liabilities.

## Future Enhancements

### Phase 2: Advanced Visualization
- Candlestick charts using Recharts or Chart.js
- Time period filters (Daily, Weekly, Monthly, Yearly)
- Price trend analysis
- Volume metrics

### Phase 3: Export & Reporting
- CSV export of allocations
- PDF share certificates
- Valuation reports
- Investor dashboards

### Phase 4: Advanced Features
- Share buyback tracking
- Dividend management
- Option pools for employee stock options
- Share transfer workflows
- Shareholder voting rights

## Technical Notes

- Share prices are calculated based on **Strategic Company Value** (not just accounting net worth)
- All prices are stored with 4 decimal precision
- Share allocations use soft deletes (status = 'inactive')
- Real-time price updates via interval polling (30 seconds)
- Responsive design with mobile-first approach
- Full dark/light mode support

## API Response Examples

**Get Share Config:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "total_shares": 1000000,
    "shares_allocated": 600000,
    "shares_remaining": 400000,
    "par_value": 1.00,
    "class_type": "common"
  }
}
```

**Get Allocations:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "owner_name": "John Founder",
      "shares_allocated": 500000,
      "ownership_percentage": "50.00",
      "share_value": "50000000.00",
      "allocation_date": "2025-01-01"
    }
  ]
}
```

**Get Price History:**
```json
{
  "success": true,
  "data": [
    {
      "date": "2025-01-01",
      "opening_price": 100.0000,
      "closing_price": 102.5000,
      "high_price": 103.0000,
      "low_price": 99.5000
    }
  ],
  "statistics": {
    "currentPrice": 102.5,
    "previousPrice": 100.0,
    "priceChange": 2.5,
    "percentChange": "2.50",
    "minPrice": 95.0,
    "maxPrice": 103.0,
    "avgPrice": 99.8
  }
}
```

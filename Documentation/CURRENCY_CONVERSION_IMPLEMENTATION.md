# Currency Conversion System Implementation

## Overview

This document details the implementation of a global currency conversion system for the Jeton application. The system allows users to view all monetary amounts in their preferred currency (UGX, USD, EUR, GBP, JPY, CAD, AUD, CHF, INR, ZAR, KES) while keeping UGX as the canonical internal currency for all database operations and calculations.

## Architecture

### 1. **Currency Context** (`/src/lib/currency-context.js`)

A React Context that provides global state management for:
- **selectedCurrency**: User's preferred currency (stored in localStorage)
- **rates**: Exchange rates object mapping currency codes to conversion factors
- **lastUpdated**: Timestamp of last exchange rate update
- **error**: Any errors encountered during rate fetching
- **isLoading**: Loading state for rate fetches

**Key Functions:**
- `convert(amountInUGX)`: Converts UGX amount to selected currency
- `convertToUGX(amount)`: Converts from selected currency back to UGX
- `formatCurrency(amountInUGX)`: Returns formatted string with symbol (e.g., "$1,200.50")
- `changeCurrency(currency)`: Changes the selected currency and persists to localStorage
- `getAvailableCurrencies()`: Returns list of supported currency codes
- `getCurrencyMetadata(currency)`: Returns metadata (symbol, decimals) for a currency

**Features:**
- Automatic rate fetching on mount
- Hourly automatic refresh of exchange rates
- Fallback to cached rates if API fails
- localStorage persistence of user's currency preference

### 2. **Currency Display Component** (`/src/components/common/CurrencyDisplay.js`)

Reusable React component that converts and displays monetary amounts.

**Main Component:** `CurrencyDisplay`
- Props:
  - `amount`: Amount in UGX to display
  - `showCode`: Show currency code instead of symbol (default: false)
  - `className`: CSS classes to apply
  - `showTooltip`: Show UGX value on hover (default: false)
- Automatically handles null/undefined values with "—" display

**Specialized Components:**
- `CurrencyRange`: Displays a range (min - max)
- `CurrencyTotal`: Displays totals with optional labels
- `CurrencyWithContext`: Displays amount with contextual info (e.g., "per unit")

### 3. **API Route** (`/src/app/api/currency-rates/route.js`)

Backend endpoint that fetches and caches exchange rates from `exchangerate.host` API.

**Features:**
- Free API (no authentication required)
- In-memory caching with 1-hour TTL (configurable)
- Falls back to hardcoded rates if API fails
- Returns both fresh and stale cached rates
- Optional `?refresh=true` query param to force refresh

**Response Format:**
```json
{
  "success": true,
  "base": "UGX",
  "rates": {
    "UGX": 1,
    "USD": 0.00027,
    "EUR": 0.00025,
    ...
  },
  "timestamp": "2025-12-30T15:30:00.000Z",
  "cacheExpiry": "2025-12-30T16:30:00.000Z"
}
```

### 4. **Settings Page** (`/src/app/app/settings/page.js`)

Added "Currency & Localization" section with:
- Dropdown selector for all 11 supported currencies
- Display of last exchange rate update timestamp
- Note that amounts are stored internally in UGX

## Integration Points

### Pages Updated to Use CurrencyDisplay

1. **Dashboard** (`/src/app/app/dashboard/page.js`)
   - KPI cards showing Accounting Net Worth and Strategic Company Value
   - Value Bridge Analysis section showing conversions
   - Assets Breakdown by Type
   - IP Value by Type
   - Summary Stats with Value Premium

2. **Deals Management** (`/src/app/app/deals/page.js`)
   - Pipeline Value metric

3. **Components**:
   - `DealsTable`: Individual deal values
   - `PipelineBoard`: Column totals by stage
   - `PipelineCard`: Deal estimate and expected values

## Supported Currencies

| Code | Name | Symbol | Decimals |
|------|------|--------|----------|
| UGX | Ugandan Shilling | UGX | 0 |
| USD | US Dollar | $ | 2 |
| EUR | Euro | € | 2 |
| GBP | British Pound | £ | 2 |
| JPY | Japanese Yen | ¥ | 0 |
| CAD | Canadian Dollar | C$ | 2 |
| AUD | Australian Dollar | A$ | 2 |
| CHF | Swiss Franc | CHF | 2 |
| INR | Indian Rupee | ₹ | 2 |
| ZAR | South African Rand | R | 2 |
| KES | Kenyan Shilling | KSh | 0 |

## Key Implementation Details

### 1. **Presentation Layer Only**
- All conversions happen at display/presentation layer
- Database stores only UGX values
- No schema modifications required
- All calculations (depreciation, net worth, valuations) remain in UGX

### 2. **Rate Caching Strategy**
- Backend caches rates for 1 hour to minimize API calls
- Browser-level caching (5 minutes) via Cache-Control headers
- Falls back to previous cached rates if API is unavailable
- Manual refresh available via query parameter

### 3. **User Preference Management**
- Currency preference stored in localStorage
- Key: `jeton_preferred_currency`
- Persists across sessions
- Defaults to UGX if no preference stored

### 4. **Automatic Updates**
- When user changes currency, all components re-render with new conversion
- No page reload necessary
- Exchange rate updates happen silently every hour
- Users informed when rates were last updated

## Usage Examples

### In Components

```javascript
import CurrencyDisplay, { CurrencyTotal, CurrencyRange } from '@/components/common/CurrencyDisplay';
import { useCurrency } from '@/lib/currency-context';

export function MyComponent() {
  const { selectedCurrency, convert, formatCurrency } = useCurrency();
  
  // Simple display
  <CurrencyDisplay amount={1000000} /> // Shows "$270" if USD selected
  
  // With tooltip showing original UGX
  <CurrencyDisplay amount={1000000} showTooltip />
  
  // Total with label
  <CurrencyTotal amount={5000000} label="Net Worth" />
  
  // Range
  <CurrencyRange min={1000000} max={5000000} />
  
  // With context
  <CurrencyWithContext amount={100000} context="per unit" />
}
```

### Manual Conversion

```javascript
const { convert, convertToUGX, selectedCurrency } = useCurrency();

const ugxAmount = 1000000;
const convertedAmount = convert(ugxAmount);  // E.g., 270 (if USD)
const backToUGX = convertToUGX(270);  // E.g., 1000000
```

## API Integration

**Frontend fetches rates via:**
```javascript
const response = await fetch('/api/currency-rates');
const data = await response.json();
// data.rates contains { UGX: 1, USD: 0.00027, ... }
```

**Force refresh:**
```javascript
const response = await fetch('/api/currency-rates?refresh=true');
```

## Error Handling

1. **API Failure**: Falls back to hardcoded rates
2. **Missing Conversion Rate**: Returns original amount with warning in console
3. **Invalid Currency**: Returns null and defaults to displaying "—"
4. **Stale Cache**: Returns cached rates anyway rather than failing

## Testing Checklist

- [x] Currency selector appears in Settings
- [x] Selecting a currency persists in localStorage
- [x] Dashboard displays converted values
- [x] Deals pipeline shows converted values
- [x] Exchange rate API returns correct structure
- [x] Fallback rates work when API unavailable
- [x] No page reload needed when changing currency
- [x] All monetary displays support conversion
- [x] Calculations remain accurate in UGX
- [x] Performance is optimal (no excessive re-renders)

## Performance Considerations

1. **Exchange Rate Caching**: 
   - Hourly server-side refresh prevents API rate limiting
   - 5-minute browser cache prevents redundant requests
   
2. **React Context**:
   - Only re-renders components using `useCurrency` hook
   - Consumers wrap their calculations in useCallback to avoid unnecessary updates
   
3. **API Calls**:
   - Single call on app initialization
   - Automatic refresh every hour
   - Manual refresh optional via admin

## Future Enhancements

1. **Database Integration**: Store user's currency preference in user profile
2. **Historical Rates**: Track rate changes over time for reporting
3. **Offline Support**: Service Worker caching of exchange rates
4. **Admin Panel**: Manage currency list, cache TTL, update rates
5. **Notifications**: Alert users when rates update significantly
6. **Rounding**: Implement configurable rounding rules per currency
7. **Reporting**: Include "as of currency" in exported reports

## Troubleshooting

### Currency selector not visible in Settings
- Check that CurrencyProvider wraps the app (in layout-client.js)
- Verify Settings page imports `useCurrency` hook

### Conversions showing wrong amounts
- Check exchange rates via `/api/currency-rates` endpoint
- Clear localStorage and browser cache
- Restart dev server

### API not fetching rates
- Check network tab for `/api/currency-rates` call
- Verify exchangerate.host API is accessible
- Check fallback rates are being used

### Memory issues from hourly refresh
- Verify cache TTL is reasonable (1 hour default)
- Check for memory leaks in useEffect cleanup
- Monitor server logs for API errors

## Code References

- Context Provider: [/src/lib/currency-context.js](/src/lib/currency-context.js)
- Display Component: [/src/components/common/CurrencyDisplay.js](/src/components/common/CurrencyDisplay.js)
- API Route: [/src/app/api/currency-rates/route.js](/src/app/api/currency-rates/route.js)
- Settings Page: [/src/app/app/settings/page.js](/src/app/app/settings/page.js)
- Layout Client (Provider): [/src/app/layout-client.js](/src/app/layout-client.js)
- Dashboard: [/src/app/app/dashboard/page.js](/src/app/app/dashboard/page.js)
- Deals: [/src/app/app/deals/page.js](/src/app/app/deals/page.js)

---

**Implementation Date**: December 30, 2025
**Status**: Production Ready
**Test Coverage**: All UI components tested, API tested

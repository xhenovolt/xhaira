# Currency Conversion - Quick Reference Guide

## For Developers

### Using CurrencyDisplay in Components

```javascript
import CurrencyDisplay from '@/components/common/CurrencyDisplay';
import { useCurrency } from '@/lib/currency-context';

// Simple display of an amount
<CurrencyDisplay amount={1000000} />
// Output: "$270" (if USD selected) or "1,000,000" (if UGX)

// With custom CSS
<CurrencyDisplay amount={5000000} className="text-2xl font-bold" />

// Show tooltip with UGX value
<CurrencyDisplay amount={1000000} showTooltip />

// Specialized components
import { CurrencyTotal, CurrencyRange, CurrencyWithContext } from '@/components/common/CurrencyDisplay';

// Total with label
<CurrencyTotal amount={45000000} label="Net Worth" />

// Range (min-max)
<CurrencyRange min={1000000} max={5000000} />

// With context (e.g., "per unit")
<CurrencyWithContext amount={10000} context="per unit" />
```

### Accessing Currency Context

```javascript
import { useCurrency } from '@/lib/currency-context';

export function MyComponent() {
  const { 
    selectedCurrency,           // Current currency code (e.g., "USD")
    rates,                      // Exchange rates object
    convert,                    // Function: amountInUGX -> convertedAmount
    convertToUGX,              // Function: amount -> amountInUGX
    formatCurrency,            // Function: amountInUGX -> formatted string
    changeCurrency,            // Function: changeCurrency(code)
    getAvailableCurrencies,    // Function: returns array of currency codes
    getCurrencyMetadata,       // Function: getCurrencyMetadata(code)
    lastUpdated,               // Timestamp of last rate update
    isLoading,                 // Boolean: rates loading state
    error,                     // Error message if any
    fetchRates,                // Function: force refresh rates
  } = useCurrency();

  // Manual conversion
  const ugxAmount = 1000000;
  const convertedAmount = convert(ugxAmount);
  
  // Change currency
  const handleSelectCurrency = (currencyCode) => {
    changeCurrency(currencyCode);
  };

  // Build currency selector
  const currencies = getAvailableCurrencies();
  
  return (
    <div>
      <p>Selected: {selectedCurrency}</p>
      <select onChange={(e) => changeCurrency(e.target.value)}>
        {currencies.map(code => {
          const meta = getCurrencyMetadata(code);
          return (
            <option key={code} value={code}>
              {code} - {meta.name} ({meta.symbol})
            </option>
          );
        })}
      </select>
    </div>
  );
}
```

### Important Rules

1. **All database values are stored in UGX**
   ```javascript
   // ✅ Good - store in UGX, convert on display
   await db.insert({ amount_ugx: 1000000 });
   <CurrencyDisplay amount={record.amount_ugx} />
   
   // ❌ Bad - don't store converted amounts
   await db.insert({ amount: 270 }); // Wrong!
   ```

2. **Keep calculations in UGX**
   ```javascript
   // ✅ Good - calculate with UGX
   const total = items.reduce((sum, item) => sum + item.amount_ugx, 0);
   <CurrencyDisplay amount={total} />
   
   // ❌ Bad - don't calculate with converted amounts
   const total = items.reduce((sum, item) => 
     sum + convert(item.amount_ugx), 0); // Wrong!
   ```

3. **Use CurrencyDisplay for all monetary values**
   ```javascript
   // ✅ Good
   <p>Value: <CurrencyDisplay amount={value} /></p>
   
   // ❌ Bad - hardcoding currency
   <p>Value: ${value.toLocaleString()}</p>
   ```

## Exchange Rate Updates

### Automatic (Built-in)
- Fetches on app load
- Refreshes every 1 hour automatically
- Falls back to cached rates if API fails

### Manual Refresh
```javascript
const { fetchRates } = useCurrency();

// Force refresh
const response = await fetch('/api/currency-rates?refresh=true');
// OR
fetchRates(true); // true = forceRefresh
```

### API Endpoint
```
GET /api/currency-rates
```

Response:
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

## Common Patterns

### Display in List/Table
```javascript
{items.map(item => (
  <tr key={item.id}>
    <td>{item.name}</td>
    <td><CurrencyDisplay amount={item.value} /></td>
    <td><CurrencyDisplay amount={item.cost} className="font-bold" /></td>
  </tr>
))}
```

### Display Totals
```javascript
const total = items.reduce((sum, item) => sum + item.amount, 0);
return (
  <div>
    <CurrencyTotal 
      amount={total} 
      label="Total Value"
      className="text-lg"
    />
  </div>
);
```

### Display with Context
```javascript
<CurrencyWithContext 
  amount={100000}
  context="per unit"
/>
// Output: "$27 per unit" (if USD)
```

### Currency Selector Dropdown
```javascript
const { selectedCurrency, changeCurrency, getAvailableCurrencies, getCurrencyMetadata } = useCurrency();

<select 
  value={selectedCurrency} 
  onChange={(e) => changeCurrency(e.target.value)}
>
  {getAvailableCurrencies().map((code) => {
    const meta = getCurrencyMetadata(code);
    return (
      <option key={code} value={code}>
        {code} - {meta.name} ({meta.symbol})
      </option>
    );
  })}
</select>
```

## Troubleshooting

### Problem: Component not showing converted amounts
**Solution**: Check that CurrencyProvider wraps the app (in `layout-client.js`)

### Problem: Conversion shows wrong value
**Solution**: 
- Verify amount is in UGX (not pre-converted)
- Check exchange rates via `/api/currency-rates`
- Clear browser cache and localStorage

### Problem: Currency selector not appearing
**Solution**:
- Verify Settings page imports `useCurrency`
- Check browser console for errors
- Restart dev server

### Problem: Rates not updating
**Solution**:
- Check `/api/currency-rates` endpoint responds
- Verify exchangerate.host API is accessible
- Check browser console for network errors
- Fallback rates should be used if API unavailable

### Problem: Memory keeps growing
**Solution**:
- Check for proper cleanup in useEffect
- Verify component unmounts properly
- Monitor for memory leaks in DevTools

## Best Practices

1. ✅ Always store values in UGX
2. ✅ Always calculate in UGX
3. ✅ Always display with CurrencyDisplay
4. ✅ Use useCallback for conversion functions in loops
5. ✅ Cache computed totals to avoid recalculation
6. ✅ Show tooltip for original UGX value
7. ✅ Test with multiple currencies
8. ✅ Verify calculations match in UGX

## New in This Release

### What Changed
- Added currency selector to Settings page
- Wrapped app with CurrencyProvider
- Updated all monetary displays to use CurrencyDisplay
- Fixed CurrencyDisplay duplicate export bug

### What Stayed the Same
- Database schema (no changes)
- API logic (no changes)
- Calculation functions (no changes)
- All business logic (no changes)

### Migration for Existing Code
If you have existing components with hardcoded currency display:

**Before:**
```javascript
<p>Value: ${amount.toLocaleString()}</p>
```

**After:**
```javascript
import CurrencyDisplay from '@/components/common/CurrencyDisplay';

<p>Value: <CurrencyDisplay amount={amount} /></p>
```

---

**Questions?** Check `CURRENCY_CONVERSION_IMPLEMENTATION.md` for detailed docs

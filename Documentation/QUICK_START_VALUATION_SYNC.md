# Quick Start: Valuation Sync System

## 🎯 In One Sentence

Company valuation is calculated once by the Dashboard and automatically synced to the Shares page every 30 seconds.

---

## 👤 For Executives/Founders

### What Changed?

**Before:**
- Manually update company valuation in Shares module
- Share prices don't automatically reflect company growth
- Different modules might show different valuations

**After:**
- Valuation syncs automatically from Dashboard (every 30s)
- Share prices update automatically as company value changes
- All modules show identical valuation

### How to Use

1. **Update company assets on Dashboard** (as usual)
   - Add assets, update book values, record IP growth

2. **Go to Shares page** (nothing special needed)
   - Strategic Value displays automatically
   - Price per share updates automatically
   - All allocation values recalculate automatically

3. **Configure Authorized Shares** (if needed)
   - Click "Configure Authorized Shares"
   - Edit only the number (e.g., 100, 150, 200)
   - Company Valuation field is read-only (synced from Dashboard)

4. **Allocate Shares** (unchanged process)
   - Click "Allocate Shares"
   - Fill in owner name, shares, dates, vesting
   - See real-time preview of ownership % and value

5. **Monitor Cap Table**
   - Ownership % and values update automatically
   - No manual recalculation needed
   - Everything reflects current company value

---

## 👨‍💻 For Developers

### Key Rules

1. **Never manually set company valuation**
   ```javascript
   // ❌ DON'T DO THIS
   PUT /api/shares { company_valuation: 92000000000 }
   
   // ✅ DO THIS
   PUT /api/shares { authorized_shares: 100 }
   ```

2. **Always use getStrategicCompanyValue() function**
   ```javascript
   // ✅ Good: Uses shared library
   import { getValuationSummary } from '@/lib/valuations.js';
   const valuation = getValuationSummary({ assets, ip, infrastructure, liabilities });
   ```

3. **Never store calculated valuation**
   ```javascript
   // ❌ DON'T: Store in database
   INSERT INTO shares (company_valuation) VALUES (92000000000)
   
   // ✅ DO: Calculate on every GET request
   export async function GET() {
     const valuation = getStrategicCompanyValue();  // Fresh every time
     return Response.json({ strategic_value: valuation });
   }
   ```

4. **Always show where values come from**
   ```jsx
   // ✅ Good: Transparent calculation
   <p className="text-xs text-gray-500">
     🔧 Synced from Executive Valuation Dashboard (read-only)
   </p>
   ```

### Common Tasks

**Add a new field that depends on valuation?**
1. Call `getStrategicCompanyValue()`
2. Calculate your field using that value
3. Never store the result

**User tries to set company valuation?**
1. Reject in API with clear error
2. Explain it's synced from Dashboard
3. Show them where to change it

**Need to know if valuation changed?**
1. Don't cache it
2. Fetch fresh on every request
3. Compare to previous in UI if needed

---

## 🧪 Quick Test

### Test 1: Valuation Syncs
1. Go to Dashboard, increase asset value
2. Go to Shares page
3. Within 30 seconds, Strategic Value updates
4. ✅ **Pass:** Values updated automatically

### Test 2: Cannot Set Manually
1. Try to call:
   ```
   PUT /api/shares { company_valuation: 50000000000 }
   ```
2. Should get error:
   ```
   "Company valuation cannot be manually set..."
   ```
3. ✅ **Pass:** Manual input blocked

### Test 3: Price Per Share Updates
1. Set authorized_shares to 100
2. Strategic Value is 92B (from Dashboard)
3. Price should be 920M (92B ÷ 100)
4. Change authorized_shares to 150
5. Price should now be 613.3M (92B ÷ 150)
6. ✅ **Pass:** Formula works correctly

### Test 4: Allocations Auto-Update
1. Create allocation: 50 shares for Founder
2. Dashboard shows strategic value: 92B
3. Shares page shows founder value: 46B (50 × 920M)
4. Go to Dashboard, increase asset value to 110B
5. Return to Shares page
6. Founder value updates to 55B (50 × 1.1B)
7. ✅ **Pass:** Values auto-update

---

## 📊 API Quick Reference

### GET /api/shares
```
Returns:
- authorized_shares
- valuation (breakdown of accounting + IP + infrastructure)
- price_per_share (calculated)
- shares_allocated
- allocation_percentage
```

### PUT /api/shares
```
Accepts:
- authorized_shares (editable)

Rejects:
- company_valuation (with error message)
```

### GET /api/shares/allocations
```
Returns each allocation with:
- shares_allocated
- ownership_percentage (calculated)
- share_value (calculated using live valuation)
- All other fields (name, email, vesting, etc)
```

### POST /api/shares/allocations
```
Accepts:
- owner_name, owner_email
- shares_allocated (validated against authorized)
- allocation_date, vesting details
- notes

Validates:
- Cannot allocate more than authorized_shares
- Cannot allocate more than remaining
```

---

## 🎨 UI Quick Reference

### Shares Page Top Section
```
🟢 Live (auto-updated every 30s)
   Synced from Executive Valuation Dashboard

4 Metric Cards:
- Strategic Value (UGX92B, synced)
- Authorized Shares (100, editable)
- Price Per Share (UGX920M, calculated)
- Allocation Status (30/100, auto-calculated)
```

### Valuation Bridge (Collapsible)
```
Shows:
Accounting Net Worth:        UGX1.2B
+ Strategic IP Value:        UGX88.2B
+ Infrastructure Value:      UGX2.6B
= Final Strategic Value:     UGX92B

All values update automatically
```

### Configuration Modal
```
Input Fields:
- Authorized Shares (editable text field)

Display Only:
- Company Valuation (shows value, read-only)
- Price Per Share (shows formula)

Special:
- Warns if reducing below allocations
- Shows impact of changes
```

### Cap Table
```
Columns:
- Owner (name & email)
- Shares (integer)
- Ownership % (calculated)
- Share Value (calculated, updates automatically)
- Actions (Edit, Delete)

Footer:
- TOTAL row sums everything
```

---

## 🚀 Deployment Checklist

- [ ] Build passes (`npm run build`)
- [ ] No TypeScript errors
- [ ] Test valuation sync (run Test 1 above)
- [ ] Test cannot set manually (run Test 2)
- [ ] Test formula (run Test 3)
- [ ] Test auto-update (run Test 4)
- [ ] Verify UI shows sync indicator
- [ ] Verify UI shows breakdown preview
- [ ] Verify Company Valuation is read-only
- [ ] Check error messages are clear

---

## 📚 Read More

For deep dives, see:
- `VALUATION_SINGLE_SOURCE_OF_TRUTH.md` - Full architecture
- `DEVELOPER_VALUATION_SSOT_GUIDE.md` - Code patterns
- `VALUATION_SYNC_VISUAL_GUIDE.md` - Diagrams and examples

---

## 🆘 Troubleshooting

**Q: Shares page shows old valuation**
A: Give it 30 seconds for auto-refresh. Check Dashboard to confirm new value.

**Q: Price per share didn't change after modifying authorized_shares**
A: Refresh the page. Should update immediately on PUT success.

**Q: Getting error "Company valuation cannot be manually set"**
A: Remove company_valuation from your PUT request. Only send authorized_shares.

**Q: Allocation values don't match my calculation**
A: Use formula: shares × (strategic_value ÷ authorized_shares)
Verify strategic value in Dashboard matches Shares page.

**Q: Build fails after my changes**
A: Make sure you're not duplicating getValuationSummary() logic.
Always import and use existing function from `/src/lib/valuations.js`

---

## ✅ You're Good To Go!

The system is production-ready. Deploy with confidence.
All valuations are automatically synced. Enjoy the simplicity!

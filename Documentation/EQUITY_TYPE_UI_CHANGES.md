# Equity Type Feature - UI Changes Guide

## Cap Table Display

### Before
```
┌─────────────────────────────────────────────────────────────────┐
│ Cap Table                                                       │
├─────────────────────────────────────────────────────────────────┤
│ Shareholder      │ Shares  │ Ownership │ Vested │ Type    │ ...│
├─────────────────────────────────────────────────────────────────┤
│ John Founder    │ 100,000 │ 50.00%    │ 100K   │ Founder │    │
│ Jane Investor   │ 50,000  │ 25.00%    │ 50K    │ Investor│    │
│ Bob Advisor     │ 25,000  │ 12.50%    │ 25K    │ Advisor │    │
└─────────────────────────────────────────────────────────────────┘
```

### After
```
┌──────────────────────────────────────────────────────────────────────────┐
│ Cap Table                                                                │
├──────────────────────────────────────────────────────────────────────────┤
│ Shareholder      │ Shares  │ Ownership │ Vested │ Type    │ Equity Type │
├──────────────────────────────────────────────────────────────────────────┤
│ John Founder    │ 100,000 │ 50.00%    │ 100K   │ Founder │ 💳 Purchase │
│ Jane Investor   │ 50,000  │ 25.00%    │ 50K    │ Investor│ 💳 Purchase │
│ Bob Advisor     │ 25,000  │ 12.50%    │ 25K    │ Advisor │ 🎁 Granted  │
└──────────────────────────────────────────────────────────────────────────┘
```

**Visual Indicators:**
- 💳 **Purchased** (Blue badge) - Cash investment
- 🎁 **Granted** (Green badge) - Equity incentive

## Add Shareholder Modal

### Before
```
╔══════════════════════════════════════════╗
║          Add Shareholder                 ║
╠══════════════════════════════════════════╣
║                                          ║
║ Name                                     ║
║ [________________]                       ║
║                                          ║
║ Email                                    ║
║ [____________________@example.com_]      ║
║                                          ║
║ Shares to Allocate                       ║
║ [____________]                           ║
║                                          ║
║ Holder Type                              ║
║ [Founder         ▼]                      ║
║   - Founder                              ║
║   - Investor                             ║
║   - Employee                             ║
║   - Advisor                              ║
║                                          ║
║ Acquisition Price (USD)                  ║
║ [____________]  (Optional)               ║
║                                          ║
║ [Cancel] [Add Shareholder]               ║
╚══════════════════════════════════════════╝
```

### After
```
╔══════════════════════════════════════════╗
║          Add Shareholder                 ║
╠══════════════════════════════════════════╣
║                                          ║
║ Name                                     ║
║ [________________]                       ║
║                                          ║
║ Email                                    ║
║ [____________________@example.com_]      ║
║                                          ║
║ Shares to Allocate                       ║
║ [____________]                           ║
║                                          ║
║ Holder Type                              ║
║ [Founder         ▼]                      ║
║   - Founder                              ║
║   - Investor                             ║
║   - Employee                             ║
║   - Advisor                              ║
║                                          ║
║ Equity Type  ← NEW                       ║
║ [💳 Purchased ▼]                         ║
║   - 💳 Purchased                         ║
║   - 🎁 Granted                           ║
║ Purchased: Cash investment               ║
║ Granted: Option grant or incentive       ║
║                                          ║
║ Acquisition Price (USD)                  ║
║ [____________]  (Optional)               ║
║                                          ║
║ [Cancel] [Add Shareholder]               ║
╚══════════════════════════════════════════╝
```

## Transfer Shares Modal

### New Feature: Equity Type Selection
```
╔══════════════════════════════════════════╗
║        Transfer Shares                   ║
║    No dilution • Ownership changes only  ║
╠══════════════════════════════════════════╣
║                                          ║
║ From Shareholder                         ║
║ [John Founder (100,000 sh) ▼]            ║
║                                          ║
║ To Shareholder                           ║
║ [________________▼]                      ║
║                                          ║
║ Shares to Transfer                       ║
║ [____________]                           ║
║                                          ║
║ Price Per Share (USD)                    ║
║ [____________]  (Leave empty for gift)   ║
║                                          ║
║ Transfer Type                            ║
║ [Secondary Sale ▼]                       ║
║   - Secondary Sale                       ║
║   - Founder to Investor                  ║
║   - Gift                                 ║
║   - Other                                ║
║                                          ║
║ Equity Type  ← NEW                       ║
║ [💳 Purchased ▼]                         ║
║   - 💳 Purchased                         ║
║   - 🎁 Granted                           ║
║ Type of equity being transferred         ║
║                                          ║
║ Reason (optional)                        ║
║ [Secondary funding round____]            ║
║                                          ║
║ [Cancel] [Execute Transfer]              ║
╚══════════════════════════════════════════╝
```

## Issue New Shares Modal

### New Feature: Equity Type Selection
```
╔══════════════════════════════════════════╗
║       Issue New Shares                   ║
║ ⚠️  WARNING: This will dilute existing   ║
║    shareholders!                         ║
╠══════════════════════════════════════════╣
║                                          ║
║ Shares to Issue                          ║
║ [____________]                           ║
║ Available: 900,000 shares                ║
║                                          ║
║ Issuance Price (USD per share)           ║
║ [____________]                           ║
║                                          ║
║ Recipient Type                           ║
║ [Investor ▼]                             ║
║   - Investor                             ║
║   - Employee Option Pool                 ║
║   - Advisor                              ║
║   - Convertible Note                     ║
║                                          ║
║ Equity Type  ← NEW (defaults to GRANTED) ║
║ [🎁 Granted ▼]                           ║
║   - 💳 Purchased                         ║
║   - 🎁 Granted                           ║
║ Purchased: Cash for shares               ║
║ Granted: Option or incentive             ║
║                                          ║
║ Issuance Reason                          ║
║ [Seed Round ▼]                           ║
║   - Seed Round                           ║
║   - Series A                             ║
║   - Series B                             ║
║   - Employee Pool                        ║
║   - Advisor Grant                        ║
║   - Strategic Investment                 ║
║                                          ║
║ ✓ Requires founder approval before exec  ║
║                                          ║
║ [Cancel] [Propose Issuance]              ║
╚══════════════════════════════════════════╝
```

## Color Coding

### Equity Type Badges

**PURCHASED (Blue)**
```
┌─────────────────────┐
│ 💳 Purchased        │
│ Background: #DBEAFE │
│ Text: #0C4A6E       │
└─────────────────────┘
```

**GRANTED (Green)**
```
┌─────────────────────┐
│ 🎁 Granted          │
│ Background: #DCFCE7 │
│ Text: #166534       │
└─────────────────────┘
```

## Form Field Details

### Equity Type Selector
```
┌──────────────────────────────────────┐
│ Equity Type                          │
├──────────────────────────────────────┤
│ 💳 Purchased ▼                       │ ← Default for Add Shareholder & Transfer
├──────────────────────────────────────┤
│ Purchased: Cash investment           │
│ Granted: Option grant or incentive   │
└──────────────────────────────────────┘

────────────────────────────────────────

┌──────────────────────────────────────┐
│ Equity Type                          │
├──────────────────────────────────────┤
│ 🎁 Granted ▼                         │ ← Default for Issue New Shares
├──────────────────────────────────────┤
│ Purchased: Cash for shares           │
│ Granted: Option or incentive         │
└──────────────────────────────────────┘
```

## API Response Display

When fetching cap table, each shareholder now includes:

```json
{
  "shareholder_id": "uuid-1234",
  "shareholder_name": "Jane Smith",
  "shares_owned": 50000,
  "equity_type": "PURCHASED",
  "current_ownership_percentage": "25.00",
  "vested_shares": 50000,
  "holder_type": "investor"
}
```

**Display in UI:**
```
Jane Smith
50,000 shares | 25.00% | 50,000 vested | Investor | 💳 Purchased
```

## Accessibility

- All dropdowns include label associations
- Help text provided for each equity type
- Color + emoji indicators (not color-only)
- Clear visual distinction in cap table

## Responsive Design

On mobile, equity type badge maintains:
- Full visibility
- Color coding visible
- Text readable
- Emoji rendered correctly

Example mobile view:
```
┌─────────────────────┐
│ Jane Smith          │
│ 50,000 shares       │
│ Investor            │
│ 🎁 Granted          │
└─────────────────────┘
```

## Summary of Changes

| Component | Change | Location |
|-----------|--------|----------|
| Cap Table | Added equity_type column with badges | Row display |
| Add Modal | Added equity_type dropdown | Below holder_type |
| Transfer Modal | Added equity_type dropdown | Before reason field |
| Issue Modal | Added equity_type dropdown | After recipient_type |
| Badges | Added color-coded visual indicators | Cap table rows |
| Help Text | Added descriptions for equity types | All modals |

## User Workflow

### Adding a Founder
1. Click "Add Shareholder"
2. Enter: Name, Email, Shares, Holder Type (Founder)
3. **Select Equity Type: 💳 Purchased** (cash investment)
4. Enter acquisition price
5. Click "Add Shareholder"

### Granting Employee Options
1. Click "Issue New Shares"
2. Enter shares to issue
3. Select Recipient Type: Employee Option Pool
4. **Equity Type defaults to 🎁 Granted** (option grant)
5. Select reason and click "Propose Issuance"

### Advisor Grant
1. Click "Transfer Shares"
2. Select from company pool to advisor
3. Leave price empty (gift)
4. **Select Equity Type: 🎁 Granted**
5. Click "Execute Transfer"

---

**Visual Implementation Complete** ✅

All UI elements have been updated to display and manage the new equity_type field with clear, intuitive indicators.

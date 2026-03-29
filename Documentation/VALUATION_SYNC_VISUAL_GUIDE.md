# Valuation Sync: Visual Architecture Guide

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        JETON EXECUTIVE SYSTEM                    │
│                                                                   │
│                    Single Valuation Engine                        │
│           (Dashboard: Assets + IP + Infrastructure)              │
│                                                                   │
│  Assets     Intellectual    Infrastructure    Liabilities         │
│  (UGX1.2B)  Property        (UGX2.6B)         (UGX1B)            │
│             (UGX88.2B)                                           │
│         ↓          ↓                  ↓              ↓            │
│         └────────────────────────────────────────────┘            │
│                           ↓                                       │
│              Strategic Company Value                              │
│                    UGX92,000,000,000                             │
│                  (Single Source of Truth)                         │
│                                                                   │
│         ┌──────────────────────────────────────┐                 │
│         │  This value is consumed by:          │                 │
│         │                                      │                 │
│         │  [Dashboard] Shows live value        │                 │
│         │  [Shares]    Calculates price/share  │                 │
│         │  [Equity]    Tracks ownership %      │                 │
│         │  [Reports]   Shows cap table         │                 │
│         │                                      │                 │
│         └──────────────────────────────────────┘                 │
│                                                                   │
│    NO module stores or re-calculates valuation                   │
│    ALL modules fetch fresh value                                 │
│    RESULT: Perfect synchronization                               │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: How Valuation Reaches Shares Page

```
TRIGGER: Asset Changes on Dashboard
│
├─ CEO updates asset book value (UGX100M → UGX500M)
│
│
↓
DATABASE UPDATES
│
├─ assets_accounting table updated
├─ Dashboard recalculates strategicCompanyValue
│
│
↓
SHARES PAGE AUTO-REFRESH (every 30s)
│
├─ Calls GET /api/shares
│  └─ Endpoint calls getStrategicCompanyValue()
│     ├─ Queries assets_accounting
│     ├─ Queries intellectual_property
│     ├─ Queries infrastructure
│     ├─ Calls getValuationSummary() (SHARED LIBRARY)
│     └─ Returns fresh strategicCompanyValue
│
│
↓
FRONTEND UPDATES
│
├─ Strategic Value displayed (UGX92B)
├─ Price Per Share recalculated
├─ All allocations' values updated automatically
│
│
↓
RESULT
│
└─ CEO sees: "My 50 shares now worth UGX46B" (was UGX45.8B)
  ✅ No manual update needed
  ✅ No button to click
  ✅ No sync dialog
  ✅ Fully automatic
```

## Share Price Calculation Flow

```
AUTHORIZATION STRUCTURE
├─ Authorized Shares: 100
│  (Editable by CEO on Shares page)
│
COMPANY VALUE (from Dashboard)
├─ Accounting Net Worth:     UGX1,200,000
├─ + Strategic IP Value:     UGX88,200,000
├─ + Infrastructure Value:   UGX2,600,000
├─ = Strategic Value:        UGX92,000,000,000
│  (Calculated from assets, NOT manual input)
│
SHARE PRICE (Derived, Not Stored)
├─ Formula: Strategic Value ÷ Authorized Shares
├─ Calculation: UGX92B ÷ 100
├─ Result: UGX920,000,000 per share
│
ALLOCATION (Automatic)
├─ Founder: 50 shares × UGX920M = UGX46,000,000,000 (50%)
├─ Investor: 30 shares × UGX920M = UGX27,600,000,000 (30%)
├─ Employee: 20 shares × UGX920M = UGX18,400,000,000 (20%)
├─ ────────────────────────────────────────────────
└─ TOTAL: 100 shares = UGX92,000,000,000 (100%)

KEY: If CEO increases authorized to 200:
     └─ Price drops to UGX460M per share
     └─ Same UGX92B value divided differently
     └─ Useful for option pools, employee grants
```

## UI: Shares Page Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  Cap Table & Share Management                                   │
│  Investor-grade equity system with live valuation sync           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  🟢 Live (auto-updated every 30s)                               │
│     Synced from Executive Valuation Dashboard                   │
└─────────────────────────────────────────────────────────────────┘

┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────┐
│ STRATEGIC      │ │ AUTHORIZED     │ │ PRICE PER      │ │ALLOCATE│
│ VALUE          │ │ SHARES         │ │ SHARE          │ │TION    │
│                │ │                │ │                │ │STATUS  │
│ UGX92,000,000K │ │ 100            │ │ UGX920,000,000 │ │30/100  │
│                │ │                │ │                │ │70 rem  │
│ Synced from    │ │ Controls       │ │ Value ÷        │ │        │
│ Dashboard      │ │ scarcity       │ │ Authorized     │ │        │
└────────────────┘ └────────────────┘ └────────────────┘ └────────┘

┌──────────────────────────────────────────────────────────────┐
│ ▼ Valuation Bridge Preview (collapsed by default)            │
│   Click to see how strategic value is calculated             │
└──────────────────────────────────────────────────────────────┘

[When Expanded ▲]
┌──────────────────────────────────────────────────────────────┐
│ Accounting Net Worth              UGX1,200,000               │
│ + Strategic IP Value              UGX88,200,000              │
│ + Infrastructure Value            UGX2,600,000               │
│ = Final Strategic Value           UGX92,000,000              │
└──────────────────────────────────────────────────────────────┘

[Configure] [Allocate Shares]

┌────────────────────────────────────────────────────────────────┐
│ CAP TABLE                                                      │
├──────────────────────┬──────────┬────────────┬─────────────────┤
│ Owner                │ Shares   │ Ownership  │ Value           │
├──────────────────────┼──────────┼────────────┼─────────────────┤
│ Founder              │ 50       │ 50%        │ UGX46,000,000K  │
│ Early Investor       │ 30       │ 30%        │ UGX27,600,000K  │
│ Employee Pool        │ 20       │ 20%        │ UGX18,400,000K  │
├──────────────────────┼──────────┼────────────┼─────────────────┤
│ TOTAL                │ 100      │ 100%       │ UGX92,000,000K  │
└──────────────────────┴──────────┴────────────┴─────────────────┘

[Edit] [Delete]  [Edit] [Delete]  [Edit] [Delete]
```

## Configuration Modal: Read-Only Valuation

```
┌────────────────────────────────────────────────────────┐
│ Configure Equity Structure                             │
├────────────────────────────────────────────────────────┤
│                                                         │
│ Authorized Shares *                                     │
│ [_______________]  ← EDITABLE                          │
│ Controls the scarcity and denominator for price calc   │
│                                                         │
├─────────────────────────────────────────────────────────│
│ Company Valuation                                       │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ UGX92,000,000,000                                   │ │
│ │ 🔧 Synced from Executive Valuation Dashboard (R/O) │ │
│ │                                                      │ │
│ │ To influence valuation, update underlying assets,   │ │
│ │ IP value, or infrastructure in the dashboard.       │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
├─────────────────────────────────────────────────────────│
│ Price Per Share Preview                                │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ UGX920,000,000                                      │ │
│ │ 92,000,000,000 ÷ 100 = UGX920,000,000             │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ [Save]  [Cancel]                                       │
└────────────────────────────────────────────────────────┘
```

## API Response Comparison

### Before (Old System)
```
GET /api/shares

{
  "authorized_shares": 100,
  "company_valuation": 92000000000,     // ← Stored in DB
  "price_per_share": 920000000,         // ← Calculated once
  "shares_allocated": 30,
  "shares_remaining": 70
}

Symptoms of problem:
- If assets change, this doesn't update automatically
- Manual sync required between Dashboard and Shares
- Stale valuation can exist for hours/days
- No audit trail of WHERE the 92B came from
```

### After (New System - SSOT)
```
GET /api/shares

{
  "authorized_shares": 100,
  
  "valuation": {
    "accounting_net_worth": 1200000,
    "strategic_company_value": 92000000000,      // ← LIVE
    "total_ip_valuation": 88200000000,           // ← LIVE
    "infrastructure_value": 2600000000,          // ← LIVE
    "total_liabilities": 1000000,
    "total_assets_book_value": 2200000,
    "valuation_difference": 90800000000
  },
  
  "price_per_share": 920000000,                  // ← DERIVED
  "shares_allocated": 30,
  "shares_remaining": 70,
  "allocation_percentage": 30.0
}

Advantages:
- Every field is traceable to source (assets/IP/infrastructure)
- Automatically updated every 30s
- Full transparency of calculation
- Impossible to have stale valuation
- Audit-proof
```

## API Error: Manual Valuation Rejected

```
PUT /api/shares
{
  "authorized_shares": 100,
  "company_valuation": 100000000000    ← REJECTED
}

Response:
{
  "success": false,
  "error": "Company valuation cannot be manually set. 
           It is synced from the Executive Valuation Dashboard."
}

This prevents:
❌ CEO overvaluing company to inflate share prices
❌ Disconnecting equity from actual asset value
❌ Having different valuations in different modules
```

## Automatic Update Scenario

```
TIMELINE: Company Growing

T=0: Initial State
├─ Assets: UGX1B
├─ IP: UGX10B  
├─ Infrastructure: UGX500M
├─ Strategic Value: UGX11.5B
├─ Price/Share (100 authorized): UGX115M
└─ Founder (50 shares): UGX5.75B

T=5m: CEO Increases Asset on Dashboard
├─ Updates facility valuation: UGX1B → UGX5B
├─ Dashboard recalculates: UGX15.5B
└─ Shares page NOT yet updated (refreshes in ~30s)

T=10m: Shares Page Auto-Refreshes
├─ GET /api/shares fetches NEW strategicCompanyValue
├─ Strategic Value: UGX15.5B (UPDATED)
├─ Price/Share: UGX155M (UPDATED)
├─ Founder allocation: UGX7.75B (UPDATED)
└─ CEO sees changes without doing anything

RESULT:
✅ Everything synchronized automatically
✅ No manual steps needed
✅ Valuation reflects reality
✅ Investor confidence in accuracy
```

## Comparison: Before vs After

```
BEFORE (Disconnected):
┌──────────────┐         ┌──────────────┐
│  Dashboard   │         │   Shares     │
│              │         │              │
│ Company      │         │ Company      │
│ Value: 92B   │   ???   │ Value: 87B   │
│              │         │              │
└──────────────┘         └──────────────┘
       ↑                       ↑
Automatic                   Manual
update                    update
                          
Problem: CEO sees different valuations in different places


AFTER (Integrated):
┌─────────────────────────────────────────┐
│      Single Valuation Engine             │
│     (Dashboard, Shares, Reports)         │
│                                          │
│     Strategic Value: UGX92,000,000,000  │
│                                          │
│  ✅ Dashboard shows 92B                  │
│  ✅ Shares shows 92B                     │
│  ✅ Cap table values use 92B             │
│  ✅ Everything synchronized              │
└─────────────────────────────────────────┘

Solution: Single source of truth everywhere
```

---

**Core Concept:** Xhaira is now one integrated executive system with perfect synchronization between all modules.

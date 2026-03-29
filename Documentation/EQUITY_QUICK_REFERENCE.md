# 🔑 Corporate Equity System - Quick Reference

## Files Overview

### Database
- **Migration**: `migrations/008_corporate_equity_refactor.sql` (1000+ lines)
  - 5 new tables (shares_config, shareholdings, share_transfers, share_issuances, share_price_history)
  - 3 views for reporting
  - 3 trigger functions
  - Audit actions extended

### Backend Logic
- **Core Library**: `src/lib/equity.js` (450+ lines)
  - 14 exported functions
  - All URSB-compliant validation
  - Transaction-safe operations
  - Complete error handling

### API Routes
- **Config**: `src/app/api/equity/config/route.js` - GET/PUT share config
- **Cap Table**: `src/app/api/equity/cap-table/route.js` - GET shareholders
- **Shareholders**: `src/app/api/equity/shareholders/route.js` - GET/POST
- **Transfers**: `src/app/api/equity/transfer/route.js` - POST share transfer
- **Issuance**: `src/app/api/equity/issuance/route.js` - GET/POST issuance

### Frontend
- **Main Page**: `src/app/app/equity/page.js` (700+ lines)
  - Dashboard with 4 metric cards
  - Cap table with real-time data
  - 4 modal dialogs
  - Full state management
  - Responsive design

### Navigation
- **Sidebar**: `src/components/layout/Sidebar.js`
  - Updated with "Corporate Equity" link
  - Integrated into Finance section

### Documentation
- **Full Guide**: `Documentation/CORPORATE_EQUITY_SYSTEM.md`
- **Implementation**: `EQUITY_IMPLEMENTATION_COMPLETE.md`
- **This File**: Quick reference guide

---

## 🚀 Quick Start

### 1. Run Database Migration
```bash
# Connect to your database and run:
psql -f migrations/008_corporate_equity_refactor.sql

# Or copy-paste into database UI
```

### 2. Access the UI
```
Development: http://localhost:3000/app/equity
```

### 3. Initial Setup
```
1. Click "Configure Shares"
2. Set Authorized: 10,000,000 (or your preference)
3. Set Issued: 1,000,000 (initial float)
4. Click "Update Configuration"

5. Click "Add Shareholder"
6. Add yourself as founder with your initial shares
```

---

## 💻 API Quick Reference

### Get Current Configuration
```bash
GET /api/equity/config

Response:
{
  "authorized_shares": 10000000,
  "issued_shares": 1000000,
  "unissued_shares": 9000000,
  "allocated_shares": 950000,
  "par_value": 1.0
}
```

### Get Cap Table
```bash
GET /api/equity/cap-table

Response:
{
  "data": [
    {
      "shareholder_name": "Alice",
      "shares_owned": 500000,
      "current_ownership_percentage": "50.00",
      "holder_type": "founder"
    }
  ],
  "summary": {
    "total_shareholders": 2,
    "total_shares_allocated": 950000
  }
}
```

### Transfer Shares (No Dilution)
```bash
POST /api/equity/transfer

Body:
{
  "from_shareholder_id": "uuid-alice",
  "to_shareholder_id": "uuid-bob",
  "shares_transferred": 250000,
  "transfer_price_per_share": 10.0,
  "transfer_type": "secondary-sale",
  "reason": "Early investor contribution"
}

Response:
{
  "success": true,
  "message": "Successfully transferred 250000 shares",
  "data": {
    "from_new_balance": 250000,
    "to_new_balance": 250000
  }
}
```

### Propose Share Issuance (With Dilution)
```bash
POST /api/equity/issuance

Body:
{
  "shares_issued": 500000,
  "issued_at_price": 15.0,
  "recipient_type": "investor",
  "issuance_reason": "series-a",
  "created_by_id": "uuid-founder"
}

Response:
{
  "success": true,
  "message": "Share issuance proposed - awaiting founder approval",
  "data": {
    "issuance": {
      "id": "uuid-new-issuance",
      "shares_issued": 500000,
      "approval_status": "pending"
    },
    "dilution_warning": "⚠️ Issuing 500000 new shares will dilute existing shareholders by 33.33%"
  }
}
```

### Approve & Execute Issuance
```bash
POST /api/equity/issuance

Body:
{
  "action": "approve",
  "issuance_id": "uuid-new-issuance",
  "approved_by_id": "uuid-founder"
}

Response:
{
  "success": true,
  "message": "Successfully issued 500000 new shares",
  "data": {
    "new_issued_total": 1500000,
    "dilution_impact": "33.33%"
  }
}
```

---

## 🗂️ Database Queries

### View Current Cap Table
```sql
SELECT * FROM cap_table
ORDER BY shares_owned DESC;
```

### View Shareholder Dilution History
```sql
SELECT * FROM shareholder_dilution_history
ORDER BY total_dilution_pct DESC;
```

### Get Share Authorization Status
```sql
SELECT * FROM share_authorization_status;
```

### View All Transfers
```sql
SELECT 
  from_shareholder_id,
  to_shareholder_id,
  shares_transferred,
  transfer_date,
  transfer_status,
  reason
FROM share_transfers
ORDER BY transfer_date DESC;
```

### View Pending Issuances
```sql
SELECT 
  shares_issued,
  issued_at_price,
  recipient_type,
  ownership_dilution_impact,
  created_at
FROM share_issuances
WHERE approval_status = 'pending'
ORDER BY created_at DESC;
```

---

## 🔐 Key Constraints

All automatically enforced by database:

```
authorized_shares >= issued_shares
issued_shares >= SUM(shares_owned by all shareholders)
vested_shares <= shares_owned
0 <= ownership_percentage <= 100
from_shareholder_id != to_shareholder_id (transfers)
shares_transferred > 0
shares_issued > 0
```

---

## 📊 Real Example: Series A

**Before:**
```
Founder:     500,000 shares (50%)
Early Inv:   300,000 shares (30%)
Advisor:     200,000 shares (20%)
─────────────────────────────
Total:     1,000,000 shares
```

**Issue 500k new shares at $20/share = $10M valuation:**

```
Founder:     500,000 shares (33.33%)  ← Diluted!
Early Inv:   300,000 shares (20%)     ← Diluted!
Advisor:     200,000 shares (13.33%)  ← Diluted!
Series A:    500,000 shares (33.33%)  ← New
─────────────────────────────────────
Total:     1,500,000 shares
```

**Founder's impact:**
- Before: 50%
- After: 33.33%
- Dilution: 16.67%
- Ownership reduced by: 33%

**This is intentional and painful—that's how it should feel.**

---

## ⚡ Performance Tips

### Optimize Cap Table Queries
```sql
-- Add index on status (already done)
CREATE INDEX idx_shareholdings_status ON shareholdings(status);

-- Filter by status for faster queries
SELECT * FROM shareholdings WHERE status = 'active';
```

### Large Cap Tables
```sql
-- Use pagination
SELECT * FROM shareholdings 
WHERE status = 'active'
ORDER BY shares_owned DESC
LIMIT 20 OFFSET 0;
```

### Dilution History
```sql
-- Pre-calculated view
SELECT * FROM shareholder_dilution_history;

-- Much faster than recalculating
```

---

## 🐛 Troubleshooting

### Issue: "Cannot allocate X shares"
```
Error: "Only 50000 unallocated shares available"
Fix: Issue new shares first (increases issued)
```

### Issue: "Cannot reduce authorized below issued"
```
Error: Cannot reduce authorized shares below current issued
Fix: Issue fewer shares or increase authorized capacity
```

### Issue: Transfer won't execute
```
Error: "Insufficient shares to transfer"
Fix: Verify sender owns enough shares
     Check shareholdings table directly
```

### Issue: Dilution percentage seems wrong
```
Verify: previous_issued_shares in issuance record
Formula: (new_issued / (old_issued + new_issued)) * 100
```

---

## 🔍 Audit Trail

All actions logged to `audit_logs` with new actions:

```
SHARE_TRANSFER              Transfer completed successfully
SHARE_TRANSFER_DENIED       Transfer rejected (insufficient balance)
SHARE_ISSUANCE              Issuance proposed
SHARE_ISSUANCE_APPROVED     Issuance approved by founder
SHARE_ISSUANCE_DENIED       Issuance rejected
SHARE_CONFIG_UPDATE         Configuration changed
SHAREHOLDER_ADDED           New shareholder registered
```

Query audit trail:
```sql
SELECT 
  action,
  entity,
  metadata,
  created_at
FROM audit_logs
WHERE entity = 'share_transfer'
  OR entity = 'share_issuance'
  OR action LIKE 'SHARE%'
ORDER BY created_at DESC;
```

---

## 🎯 Next Steps

1. **Run migration** to create tables
2. **Configure shares** (authorized/issued)
3. **Add shareholders** (founder + early investors)
4. **Test transfers** (verify no dilution)
5. **Propose issuance** (see dilution warning)
6. **Approve issuance** (execute and verify ownership %)
7. **Review cap table** (check all calculations)
8. **Check audit logs** (verify all actions recorded)

---

## 📚 Further Reading

- Full System Guide: `Documentation/CORPORATE_EQUITY_SYSTEM.md`
- Implementation Report: `EQUITY_IMPLEMENTATION_COMPLETE.md`
- Database Schema: See `migrations/008_corporate_equity_refactor.sql`
- API Code: See `src/app/api/equity/*/route.js`
- Frontend Code: See `src/app/app/equity/page.js`

---

**Built with ❤️ for founder-grade equity management**

*Questions? Check the docs. Issues? Review the audit logs. Concerns? That's normal—dilution should feel significant.*

# 🎯 Jeton Financial System - Quick Start Guide

## Overview

Jeton now has a complete financial management system that enables Xhenvolt to track assets, liabilities, and calculate net worth automatically.

---

## 📊 Key Metrics Tracked

```
Total Assets       UGX 48,200,000
Total Liabilities  UGX 25,000,000
─────────────────────────────
Net Worth          UGX 23,200,000
```

---

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- PostgreSQL (Neon)
- `.env.local` file with DATABASE_URL and JWT_SECRET

### Initialize Database

```bash
node scripts/init-db.js
```

This creates:
- `assets` table
- `liabilities` table
- Updated `audit_logs` with financial actions

### Start Development Server

```bash
npm run dev
```

Server runs at: `http://localhost:3000`

---

## 📖 API Documentation

### 1️⃣ ASSETS API

#### Create Asset
```bash
POST /api/assets
Authorization: Required (FOUNDER only)
Content-Type: application/json

{
  "name": "Office Laptop",
  "category": "Equipment",
  "acquisition_date": "2024-01-15",
  "acquisition_cost": 2500000,
  "current_value": 2200000,
  "depreciation_rate": 15,
  "notes": "Dell XPS 15"
}

Response: 201 Created
{
  "message": "Asset created successfully",
  "asset": { ... }
}
```

#### Get All Assets
```bash
GET /api/assets
Authorization: Required

Response: 200 OK
{
  "assets": [...],
  "total": 3
}
```

#### Get Single Asset
```bash
GET /api/assets/{id}
Authorization: Required

Response: 200 OK
{
  "asset": { ... }
}
```

#### Update Asset
```bash
PUT /api/assets/{id}
Authorization: Required (FOUNDER only)
Content-Type: application/json

{
  "name": "Updated Laptop",
  "current_value": 2100000
}

Response: 200 OK
{
  "message": "Asset updated successfully",
  "asset": { ... }
}
```

#### Delete Asset
```bash
DELETE /api/assets/{id}
Authorization: Required (FOUNDER only)

Response: 200 OK
{
  "message": "Asset deleted successfully"
}
```

---

### 2️⃣ LIABILITIES API

#### Create Liability
```bash
POST /api/liabilities
Authorization: Required (FOUNDER only)
Content-Type: application/json

{
  "name": "Bank Loan",
  "category": "Loan",
  "creditor": "Stanbic Bank",
  "principal_amount": 30000000,
  "outstanding_amount": 25000000,
  "interest_rate": 8.5,
  "due_date": "2026-12-31",
  "status": "ACTIVE"
}

Response: 201 Created
{
  "message": "Liability created successfully",
  "liability": { ... }
}
```

#### Get All Liabilities
```bash
GET /api/liabilities
Authorization: Required

Response: 200 OK
{
  "liabilities": [...],
  "total": 1
}
```

#### Get Single Liability
```bash
GET /api/liabilities/{id}
Authorization: Required

Response: 200 OK
{
  "liability": { ... }
}
```

#### Update Liability
```bash
PUT /api/liabilities/{id}
Authorization: Required (FOUNDER only)
Content-Type: application/json

{
  "outstanding_amount": 20000000,
  "status": "CLEARED"
}

Response: 200 OK
{
  "message": "Liability updated successfully",
  "liability": { ... }
}
```

#### Delete Liability
```bash
DELETE /api/liabilities/{id}
Authorization: Required (FOUNDER only)

Response: 200 OK
{
  "message": "Liability deleted successfully"
}
```

---

### 3️⃣ NET WORTH API

#### Get Financial Overview
```bash
GET /api/net-worth
Authorization: Required

Response: 200 OK
{
  "totalAssets": 48200000,
  "totalLiabilities": 25000000,
  "netWorth": 23200000,
  "currency": "UGX"
}
```

This endpoint:
- Sums all asset current values
- Sums all outstanding liability amounts (excluding CLEARED)
- Calculates Net Worth = Assets - Liabilities
- Updates in real-time

---

## 🎨 Frontend Pages

### Assets Dashboard
```
URL: /app/assets

Features:
- Total asset value card
- Filterable assets table
- Add new asset button
- Edit/Delete actions
- Depreciation tracking
```

### Liabilities Dashboard
```
URL: /app/liabilities

Features:
- Outstanding amount card
- Status badges (ACTIVE/CLEARED/DEFAULTED/DEFERRED)
- Add new liability button
- Edit/Delete actions
- Due date tracking
```

### Financial Overview
```
URL: /app/overview

Features:
- Three metric cards (Assets, Liabilities, Net Worth)
- Animated counters
- Color-coded indicators
- Quick action links
- Formula visualization
```

---

## 🔐 Authentication & Authorization

### Required Roles
- **FOUNDER**: Can create, read, update, delete all financial records
- **STAFF**: Cannot access financial features (403 Forbidden)
- **VIEWER**: Cannot access financial features (403 Forbidden)

### Token Requirements
All API endpoints require:
1. Valid JWT token in `auth-token` cookie
2. Token must be non-expired
3. User role must be FOUNDER for mutations

---

## 📝 Data Validation

### Asset Validation
```javascript
{
  name: string(1-255)        // Required
  category: string(1-100)    // Required
  current_value: number ≥ 0  // Required
  acquisition_date: DATE     // Optional
  acquisition_cost: number ≥ 0 // Optional
  depreciation_rate: 0-100   // Optional (default 0)
  notes: string              // Optional
}
```

### Liability Validation
```javascript
{
  name: string              // Required
  category: string          // Required
  principal_amount: number ≥ 0 // Required
  outstanding_amount: number ≥ 0 // Required
  interest_rate: 0-100      // Optional (default 0)
  creditor: string          // Optional
  due_date: DATE            // Optional
  status: enum              // ACTIVE|CLEARED|DEFAULTED|DEFERRED
  notes: string             // Optional
}
```

---

## 🔍 Audit Logging

Every financial action is logged:

| Action | Entity | Logged | Reason |
|--------|--------|--------|--------|
| ASSET_CREATE | ASSET | ✓ | Audit trail |
| ASSET_UPDATE | ASSET | ✓ | Change tracking |
| ASSET_DELETE | ASSET | ✓ | Compliance |
| LIABILITY_CREATE | LIABILITY | ✓ | Audit trail |
| LIABILITY_UPDATE | LIABILITY | ✓ | Change tracking |
| LIABILITY_DELETE | LIABILITY | ✓ | Compliance |
| *_DENIED | ASSET/LIABILITY | ✓ | Permission denied |

Logged metadata includes:
- Actor ID (who made the change)
- IP address
- User agent
- Timestamp
- Success/failure status
- Entity details (name, category, amounts)

---

## 📊 Database Schema

### Assets Table
```sql
CREATE TABLE assets (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  acquisition_source TEXT,
  acquisition_date DATE,
  acquisition_cost NUMERIC(14,2),
  current_value NUMERIC(14,2) NOT NULL,
  depreciation_rate NUMERIC(5,2) DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  CONSTRAINT positive_values CHECK (...)
  CONSTRAINT valid_depreciation CHECK (...)
);

CREATE INDEX idx_assets_category ON assets(category);
CREATE INDEX idx_assets_created_by ON assets(created_by);
CREATE INDEX idx_assets_created_at ON assets(created_at);
```

### Liabilities Table
```sql
CREATE TABLE liabilities (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  creditor TEXT,
  principal_amount NUMERIC(14,2) NOT NULL,
  outstanding_amount NUMERIC(14,2) NOT NULL,
  interest_rate NUMERIC(5,2) DEFAULT 0,
  due_date DATE,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  CONSTRAINT positive_amounts CHECK (...)
  CONSTRAINT valid_interest CHECK (...)
  CONSTRAINT valid_status CHECK (...)
);

CREATE INDEX idx_liabilities_category ON liabilities(category);
CREATE INDEX idx_liabilities_status ON liabilities(status);
CREATE INDEX idx_liabilities_created_by ON liabilities(created_by);
CREATE INDEX idx_liabilities_due_date ON liabilities(due_date);
```

---

## ⚡ Performance Optimization

- Database queries use indexes for fast lookups
- Connection pooling (max 10 connections)
- Optimized aggregate queries (SUM) for calculations
- Lazy-loaded frontend components
- Framer Motion animations for smooth UX

---

## 🛠 Troubleshooting

### 401 Unauthorized
- Ensure you're logged in with valid credentials
- Check cookie is being sent with request
- Verify JWT_SECRET is set in `.env.local`

### 403 Forbidden
- Only FOUNDER role can mutate financial records
- Check user role in JWT token

### Validation Failed
- Check required fields are provided
- Verify numeric values are non-negative
- Status must be one of: ACTIVE|CLEARED|DEFAULTED|DEFERRED

### Database Connection Error
- Verify DATABASE_URL in `.env.local`
- Ensure PostgreSQL connection is active
- Run `node scripts/init-db.js` to ensure tables exist

---

## 📚 Example Workflows

### Workflow 1: Record Equipment Purchase
```
1. POST /api/assets
   Create: Office Laptop ($2,500,000)
   
2. GET /api/net-worth
   Updated total assets includes new item
   
3. GET /app/assets
   See laptop in dashboard
```

### Workflow 2: Track Loan Payment
```
1. POST /api/liabilities
   Create: Bank Loan ($30,000,000 principal)
   
2. PUT /api/liabilities/{id}
   Update: outstanding_amount = $25,000,000
   
3. GET /api/net-worth
   Net worth adjusted automatically
```

### Workflow 3: View Financial Status
```
1. GET /app/overview
   See all three metrics
   
2. Check Asset Details
   GET /app/assets
   
3. Check Liability Status
   GET /app/liabilities
```

---

## 🎯 Next Steps

Current system is ready for:
- ✅ Asset tracking & management
- ✅ Liability tracking & management
- ✅ Real-time net worth calculation
- ✅ Complete audit trail
- ✅ Role-based access control

Future enhancements (not included):
- Deals management
- Valuation history
- Charts & reports
- Staff management
- Approval workflows

---

## 📞 Support

For issues or questions:
1. Check audit logs for action history
2. Verify database tables exist
3. Check user permissions (must be FOUNDER)
4. Review error messages for validation details

---

**Status**: ✅ Production Ready

**Last Updated**: December 29, 2025

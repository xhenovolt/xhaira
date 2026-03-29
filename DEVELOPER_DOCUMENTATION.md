# JETON DEVELOPER DOCUMENTATION
**Architecture, APIs, and Extension Guide**

---

## TABLE OF CONTENTS

1. [Project Structure](#project-structure)
2. [Technology Stack](#technology-stack)
3. [Database Architecture](#database-architecture)
4. [API Architecture](#api-architecture)
5. [Authentication & Authorization](#authentication--authorization)
6. [Module Architecture](#module-architecture)
7. [Adding New Features](#adding-new-features)
8. [Database Migrations](#database-migrations)
9. [Validation & Business Rules](#validation--business-rules)
10. [Testing](# testing)
11. [Deployment](#deployment)

---

## PROJECT STRUCTURE

```
xhaira/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── page.js             # Landing page
│   │   ├── login/              # Auth pages
│   │   ├── register/
│   │   ├── app/                # Protected app routes
│   │   │   ├── dashboard/
│   │   │   ├── prospecting/
│   │   │   ├── deals/
│   │   │   ├── clients/
│   │   │   ├── contracts/
│   │   │   ├── payments/
│   │   │   ├── finance/
│   │   │   ├── admin/
│   │   │   └── ...
│   │   └── api/                # API routes
│   │       ├── auth/
│   │       ├── prospects/
│   │       ├── deals/
│   │       ├── clients/
│   │       ├── contracts/
│   │       ├── payments/
│   │       └── ...
│   ├── components/             # React components
│   │   ├── layout/
│   │   ├── ui/
│   │   └── ...
│   └── lib/                    # Core business logic
│       ├── db.js               # Database connection
│       ├── auth.js             # Authentication
│       ├── prospects.js        # Prospect operations
│       ├── deals.js            # Deal operations
│       ├── deal-to-contract.js # Workflow automation
│       ├── validation.js       # Zod schemas
│       └── ...
├── migrations/                 # SQL migrations
│   ├── 001_*.sql
│   ├── 101_add_missing_core_tables.sql
│   └── ...
├── public/                     # Static assets
├── docs/                       # Documentation
├── package.json
├── next.config.mjs
├── tailwind.config.js
└── middleware.ts               # Route protection
```

---

## TECHNOLOGY STACK

### Frontend
- **React 19.0.0** - UI library
- **Next.js 16.1.1** - Framework with App Router
- **Tailwind CSS 4.0.0-alpha** - Styling
- **Framer Motion** - Animations
- **Lucide React** - Icons

### Backend
- **Next.js API Routes** - Serverless API
- **PostgreSQL** (Neon) - Database
- **node-postgres (pg)** - Database driver

### Validation & Security
- **Zod 4.2.1** - Schema validation
- **bcryptjs** - Password hashing
- **uuid** - Unique identifiers

### Development
- **ESLint** - Code linting
- **PostCSS** - CSS processing

---

## DATABASE ARCHITECTURE

### Connection Management

**File:** `/src/lib/db.js`

```javascript
import pg from 'pg';
const { Pool } = pg;

let pool;

export function getPool() {
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  }
  return pool;
}

export async function query(text, params) {
  const client = await getPool().connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}
```

### Schema Organization

#### Core Tables (created in migration 101)
```sql
-- Revenue Chain
clients → contracts → payments → allocations

-- Sales Pipeline
prospects → deals → contracts

-- Financial Tracking
expenses, expense_categories, vault_balances

-- Operations
staff, infrastructure, intellectual_property
```

#### Key Relationships
```sql
deals.client_id → clients.id
deals.system_id → intellectual_property.id
deals.prospect_id → prospects.id

contracts.client_id → clients.id
contracts.system_id → intellectual_property.id
contracts.deal_id → deals.id

payments.contract_id → contracts.id

allocations.payment_id → payments.id
```

### Database Triggers

#### Auto-update Payment Allocation Status
```sql
CREATE TRIGGER trigger_update_payment_allocation
AFTER INSERT OR UPDATE OR DELETE ON allocations
FOR EACH ROW
EXECUTE FUNCTION update_payment_allocation_status();
```

#### Validate Allocation Amount
```sql
CREATE TRIGGER trigger_validate_allocation
BEFORE INSERT OR UPDATE ON allocations
FOR EACH ROW
EXECUTE FUNCTION validate_allocation_amount();
```

---

## API ARCHITECTURE

### Route Structure

**Pattern:** `/api/<resource>` and `/api/<resource>/[id]`

**Example:**
```
GET    /api/deals           # List all
POST   /api/deals           # Create
GET    /api/deals/[id]      # Get one
PUT    /api/deals/[id]      # Update
DELETE /api/deals/[id]      # Delete
POST   /api/deals/[id]/win  # Custom action
```

### Standard API Response Format

```javascript
// Success
{
  success: true,
  data: {...},
  message: "Operation successful" // optional
}

// Error
{
  success: false,
  error: "Error message",
  details: {...} // optional
}
```

### Example API Route

**File:** `/src/app/api/deals/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getDeals, createDeal } from '@/lib/deals.js';
import { validateDeal } from '@/lib/validation.js';

// GET /api/deals
export async function GET(request) {
  try {
    const deals = await getDeals();
    return NextResponse.json({ success: true, data: deals });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// POST /api/deals
export async function POST(request) {
  try {
    const body = await request.json();
    
    // Validate input
    const validation = validateDeal(body);
    if (!validation.success) {
      return NextResponse.json(
        { success: false, error: 'Validation failed', details: validation.errors },
        { status: 400 }
      );
    }
    
    const deal = await createDeal(validation.data);
    return NextResponse.json(
      { success: true, data: deal, message: 'Deal created' },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

---

## AUTHENTICATION & AUTHORIZATION

### Session Management

**File:** `/src/lib/auth.js`

```javascript
import { cookies } from 'next/headers';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { query } from './db.js';

export async function createSession(userId) {
  const sessionId = uuidv4();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
  
  await query(
    'INSERT INTO sessions (id, user_id, expires_at) VALUES ($1, $2, $3)',
    [sessionId, userId, expiresAt]
  );
  
  cookies().set('session', sessionId, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    expires: expiresAt,
  });
  
  return sessionId;
}

export async function getSession() {
  const sessionId = cookies().get('session')?.value;
  if (!sessionId) return null;
  
  const result = await query(
    'SELECT s.*, u.* FROM sessions s JOIN users u ON s.user_id = u.id WHERE s.id = $1 AND s.expires_at > NOW()',
    [sessionId]
  );
  
  return result.rows[0] || null;
}
```

### Middleware Protection

**File:** `/middleware.ts`

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const session = request.cookies.get('session');
  const isAuthPage = request.nextUrl.pathname.startsWith('/login') || 
                     request.nextUrl.pathname.startsWith('/register');
  const isProtected = request.nextUrl.pathname.startsWith('/app');
  
  // Redirect logged-in users away from auth pages
  if (isAuthPage && session) {
    return NextResponse.redirect(new URL('/app/dashboard', request.url));
  }
  
  // Redirect unauthenticated users to login
  if (isProtected && !session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/app/:path*', '/login', '/register'],
};
```

### Role-Based Access Control

```javascript
// Check if user is admin
export function isAdmin(user) {
  return user.role === 'admin' || user.role === 'superadmin' || user.is_superadmin;
}

// Middleware for admin-only routes
export async function requireAdmin(request) {
  const session = await getSession();
  if (!session || !isAdmin(session)) {
    return NextResponse.json(
      { success: false, error: 'Unauthorized' },
      { status: 403 }
    );
  }
  return session;
}
```

---

## MODULE ARCHITECTURE

### Module Pattern

Each business entity has:
1. **Database table(s)** - Data storage
2. **API routes** - HTTP endpoints
3. **Library module** - Business logic (`/lib/*.js`)
4. **UI pages** - User interface (`/app/app/*/page.js`)
5. **Validation schema** - Input validation

### Example: Deals Module

#### 1. Database Table
```sql
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  client_id UUID REFERENCES clients(id),
  prospect_id UUID REFERENCES prospects(id),
  system_id UUID REFERENCES intellectual_property(id),
  value_estimate DECIMAL(15, 2),
  stage VARCHAR(50) DEFAULT 'Lead',
  probability INTEGER DEFAULT 50,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. Library Module (`/lib/deals.js`)
```javascript
import { query } from './db.js';

export async function createDeal(data) {
  // Enforce business rules
  if (!data.system_id) {
    throw new Error('Deal must have a system_id');
  }
  if (!data.client_id && !data.prospect_id) {
    throw new Error('Deal must have a client_id or prospect_id');
  }
  
  const result = await query(
    `INSERT INTO deals (title, client_id, prospect_id, system_id, value_estimate, stage, probability)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [data.title, data.client_id, data.prospect_id, data.system_id, data.value_estimate, data.stage || 'Lead', data.probability || 50]
  );
  
  return result.rows[0];
}

export async function getDeals() {
  const result = await query('SELECT * FROM deals WHERE deleted_at IS NULL ORDER BY created_at DESC');
  return result.rows;
}

// ... more functions
```

#### 3. Validation Schema (`/lib/validation.js`)
```javascript
import { z } from 'zod';

export const dealSchema = z.object({
  title: z.string().min(1, 'Title is required').max(255),
  client_id: z.string().uuid().optional().nullable(),
  prospect_id: z.string().uuid().optional().nullable(),
  system_id: z.string().uuid('System ID is required'),
  value_estimate: z.number().min(0).optional(),
  stage: z.enum(['Lead', 'Qualification', 'Proposal', 'Negotiation', 'Won', 'Lost']).optional(),
  probability: z.number().min(0).max(100).optional(),
});

export function validateDeal(data) {
  const result = dealSchema.safeParse(data);
  return {
    success: result.success,
    data: result.data,
    errors: result.error?.errors,
  };
}
```

#### 4. API Routes (`/api/deals/route.js`)
See [API Architecture](#api-architecture) above

#### 5. UI Page (`/app/app/deals/page.js`)
```javascript
'use client';

import { useEffect, useState } from 'react';

export default function DealsPage() {
  const [deals, setDeals] = useState([]);
  
  useEffect(() => {
    fetch('/api/deals')
      .then(res => res.json())
      .then(data => setDeals(data.data || []));
  }, []);
  
  return (
    <div>
      <h1>Deals</h1>
      {deals.map(deal => (
        <div key={deal.id}>{deal.title}</div>
      ))}
    </div>
  );
}
```

---

## ADDING NEW FEATURES

### Step-by-Step Guide

#### 1. Create Migration

**File:** `/migrations/XXX_add_new_feature.sql`

```sql
CREATE TABLE my_new_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_my_new_table_name ON my_new_table(name);
```

**Run:** Connect to database and execute SQL

#### 2. Create Library Module

**File:** `/src/lib/my-feature.js`

```javascript
import { query } from './db.js';

export async function getMyFeatures() {
  const result = await query('SELECT * FROM my_new_table ORDER BY created_at DESC');
  return result.rows;
}

export async function createMyFeature(data) {
  const result = await query(
    'INSERT INTO my_new_table (name) VALUES ($1) RETURNING *',
    [data.name]
  );
  return result.rows[0];
}

// Export all functions
export default {
  getMyFeatures,
  createMyFeature,
};
```

#### 3. Add Validation Schema

**File:** `/src/lib/validation.js`

```javascript
export const myFeatureSchema = z.object({
  name: z.string().min(1).max(255),
});

export function validateMyFeature(data) {
  const result = myFeatureSchema.safeParse(data);
  return {
    success: result.success,
    data: result.data,
    errors: result.error?.errors,
  };
}
```

#### 4. Create API Routes

**File:** `/src/app/api/my-feature/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getMyFeatures, createMyFeature } from '@/lib/my-feature.js';
import { validateMyFeature } from '@/lib/validation.js';

export async function GET() {
  try {
    const data = await getMyFeatures();
    return NextResponse.json({ success: true, data });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const validation = validateMyFeature(body);
    
    if (!validation.success) {
      return NextResponse.json(
        { success: false, error: 'Validation failed', details: validation.errors },
        { status: 400 }
      );
    }
    
    const data = await createMyFeature(validation.data);
    return NextResponse.json({ success: true, data }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
```

#### 5. Create UI Page

**File:** `/src/app/app/my-feature/page.js`

```javascript
'use client';

import { useEffect, useState } from 'react';

export default function MyFeaturePage() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchItems();
  }, []);
  
  const fetchItems = async () => {
    const response = await fetch('/api/my-feature');
    const data = await response.json();
    if (data.success) {
      setItems(data.data);
    }
    setLoading(false);
  };
  
  const handleCreate = async (name) => {
    const response = await fetch('/api/my-feature', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    
    if (response.ok) {
      fetchItems();
    }
  };
  
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold">My Feature</h1>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <ul>
          {items.map(item => (
            <li key={item.id}>{item.name}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

#### 6. Add to Navigation

**File:** `/src/lib/navigation-config.js`

```javascript
export const menuItems = [
  // ... existing items
  {
    label: 'My Feature',
    href: '/app/my-feature',
    icon: Star, // Import from lucide-react
    category: 'sections',
  },
];
```

---

## DATABASE MIGRATIONS

### Migration Naming Convention
```
<number>_<description>.sql

Examples:
001_create_users_table.sql
101_add_missing_core_tables.sql
102_add_prospect_to_deals.sql
```

### Migration Template

```sql
/**
 * Migration: <number>_<description>
 * Purpose: <what this migration does>
 * Date: <date>
 */

-- ============================================================================
-- ADD YOUR CHANGES HERE
-- ============================================================================

CREATE TABLE IF NOT EXISTS my_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- columns here
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_my_table_field ON my_table(field);

-- Add foreign keys
ALTER TABLE my_table ADD CONSTRAINT fk_my_table_other 
  FOREIGN KEY (other_id) REFERENCES other_table(id) ON DELETE CASCADE;

-- ============================================================================
-- VERIFY MIGRATION
-- ============================================================================

-- Check table exists
SELECT COUNT(*) FROM my_table;
```

### Running Migrations

**Manual (PostgreSQL):**
```bash
psql $DATABASE_URL -f migrations/XXX_migration.sql
```

**From Node.js:**
```javascript
import { query } from './src/lib/db.js';
import fs from 'fs';

const sql = fs.readFileSync('./migrations/XXX_migration.sql', 'utf8');
await query(sql);
```

---

## VALIDATION & BUSINESS RULES

### Enforced Rules (via Database + Code)

#### Deal Creation
```javascript
// /lib/deals.js
if (!data.system_id) {
  throw new Error('Deal must have a system_id');
}
if (!data.client_id && !data.prospect_id) {
  throw new Error('Deal must have client_id or prospect_id');
}
```

#### Contract Creation
```javascript
// /lib/deal-to-contract.js
if (deal.stage !== 'Won') {
  throw new Error('Deal must be Won before creating contract');
}
if (!deal.client_id) {
  if (deal.prospect_id) {
    // Auto-convert prospect
  } else {
    throw new Error('Cannot create contract: no client');
  }
}
```

#### Payment Allocation
```sql
-- Database trigger
CREATE TRIGGER trigger_validate_allocation
BEFORE INSERT OR UPDATE ON allocations
FOR EACH ROW
EXECUTE FUNCTION validate_allocation_amount();

-- Function checks:
-- 1. Total allocations ≤ payment amount
-- 2. Individual allocation > 0
```

---

## TESTING

### Manual Testing Checklist

#### Workflow Testing
```
1. Create Prospect ✅
2. Log Activity ✅
3. Convert to Client ✅
4. Create Deal ✅
5. Win Deal ✅ (auto-creates contract)
6. Record Payment ✅
7. Allocate Funds ✅
8. View Financial Dashboard ✅
```

#### API Testing (with curl)
```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Create Deal
curl -X POST http://localhost:3000/api/deals \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<session_id>" \
  -d '{"title":"Test Deal","system_id":"<uuid>","client_id":"<uuid>"}'

# Win Deal
curl -X POST http://localhost:3000/api/deals/<deal_id>/win \
  -H "Cookie: session=<session_id>"
```

---

## DEPLOYMENT

### Environment Variables

```bash
# .env.local (or production env)
DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require
NODE_ENV=production
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

### Build & Deploy

```bash
# Install dependencies
npm install

# Build for production
npm run build

# Start production server
npm run start
```

### Vercel Deployment

1. Connect GitHub repository
2. Add DATABASE_URL environment variable
3. Deploy automatically on push

### Neon Database (PostgreSQL)

1. Create Neon project
2. Copy connection string
3. Run migrations manually (for now)

---

## BEST PRACTICES

### Code Style
- Use async/await (no callbacks)
- Validate all inputs with Zod
- Return consistent API responses
- Handle errors with try/catch

### Database
- Always use parameterized queries (prevent SQL injection)
- Add indexes on foreign keys and frequently queried columns
- Use transactions for multi-step operations
- Soft delete with `deleted_at` column

### Security
- Never expose internal IDs in URLs (use UUIDs)
- Always check user permissions
- Validate on server-side (never trust client)
- Use HTTPS in production

### Performance
- Paginate large lists
- Use database indexes
- Cache dashboard metrics (if needed)
- Lazy load images and heavy components

---

## TROUBLESHOOTING

### Common Issues

**"Module not found"**
- Check import path (use `@/` alias)
- Verify file extension (.js vs .jsx)

**"Database connection failed"**
- Check DATABASE_URL in .env.local
- Verify Neon database is running
- Check SSL mode (should be enabled for Neon)

**"Unauthorized" when accessing /app/**
- Check session cookie
- Verify middleware.ts is protecting routes
- Clear cookies and login again

**Build fails with type errors**
- Check TypeScript compatibility
- Verify all imports are correct
- Run `npm run build` locally first

---

**Document Version:** 1.0  
**Last Updated:** March 8, 2026  
**For:** Developers extending Xhaira

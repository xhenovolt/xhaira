# Quick Start: Session-Based Authentication

## What Changed?

Your authentication system has been completely refactored from JWT tokens to secure server-side sessions stored in PostgreSQL.

### The Gist
- **Old**: JWT tokens stored in httpOnly cookies, signed/verified with secret
- **New**: Session IDs stored in httpOnly cookies, sessions validated against database
- **Benefit**: More secure, works better with serverless (Vercel), no shared secrets needed

---

## For Developers

### 1. Running Locally

```bash
# Install dependencies
npm install

# Set environment variables
export DATABASE_URL="postgres://..."
export NODE_ENV=development

# Run migrations (creates sessions table)
npm run migrate
# or manually:
node scripts/init-db.js

# Start development server
npm run dev
```

### 2. Testing Login

```bash
# Test login endpoint
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"founder@example.com","password":"password"}' \
  -v

# Look for: Set-Cookie: jeton_session=...; HttpOnly; Path=/;
```

### 3. Testing Protected Routes

```bash
# Test API with session cookie
curl http://localhost:3000/api/auth/me \
  -H "Cookie: jeton_session=<your-session-id>" \
  -v
```

### 4. Using Auth in Your Code

#### In Server Components (Layouts, Pages)
```javascript
import { getCurrentUser } from '@/lib/current-user.js';

export default async function DashboardLayout() {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  return (
    <div>
      <h1>Welcome, {user.email}</h1>
    </div>
  );
}
```

#### In API Routes
```javascript
import { requireApiAuth } from '@/lib/api-auth.js';

export async function GET(request) {
  try {
    const user = await requireApiAuth();
    
    // User object: { userId, email, role }
    console.log(`User ${user.email} accessed API`);
    
    return NextResponse.json({ status: 'ok' });
  } catch (error) {
    if (error instanceof Response) {
      return error; // 401 Unauthorized
    }
    throw error;
  }
}
```

### 5. Checking User in Client Components

For client components that need to know if user is authenticated, call the API:

```javascript
'use client';

import { useEffect, useState } from 'react';

export function UserProfile() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Call /api/auth/me to get user
    fetch('/api/auth/me', { credentials: 'include' })
      .then(r => r.json())
      .then(data => setUser(data.user))
      .catch(() => setUser(null));
  }, []);

  if (!user) return <div>Loading...</div>;
  return <div>Welcome, {user.email}</div>;
}
```

### 6. Session Duration

- Sessions last **7 days**
- Expire automatically (no refresh tokens needed)
- To change duration, edit `SESSION_DURATION` in `src/lib/session.js`

---

## For DevOps / Deployment

### Vercel Configuration

1. **Set Environment Variables**
   - `DATABASE_URL` - Your Neon PostgreSQL connection string
   - `NODE_ENV` - Set to "production"
   - ❌ Remove `JWT_SECRET` (no longer needed)

2. **Run Migrations**
   ```bash
   # Before first deploy, run:
   node scripts/init-db.js
   ```

3. **Deploy**
   ```bash
   git push  # Deploys to Vercel automatically
   ```

### Environment Variables Needed
```env
DATABASE_URL=postgres://user:password@host/database
NODE_ENV=production
```

### Environment Variables NOT Needed
```env
# Remove these (no longer used)
# JWT_SECRET=...
# API_URL=...
```

---

## Known Limitations & Todos

### ⚠️ API Routes Still Using Old Auth

These routes still need to be migrated from JWT to sessions:

```
/api/liabilities/[id]
/api/assets/[id]
/api/deals/[id]
/api/deals/valuation
/api/net-worth
/api/staff
/api/staff/[id]
/api/snapshots
/api/snapshots/[id]
/api/snapshots/create
/api/reports/financial
/api/reports/executive
```

**How to Fix**: See `IMPLEMENTATION_STATUS_SESSION_AUTH.md` for the update pattern.

---

## Troubleshooting

### User Immediately Logs Out

**Check:**
1. Is `jeton_session` cookie being set? (DevTools → Application → Cookies)
2. Is session in database? (Query: `SELECT * FROM sessions`)
3. Has session expired? (Check `expires_at` > NOW)
4. Is user.status = 'active'? (Check users table)

### Middleware Always Redirects to /login

**Check:**
1. Cookie name is `jeton_session` (not `auth-token`)
2. Session ID exists in database
3. Database connection is working
4. Middleware error logs for details

### CORS Issues with Cookies

**Fix:**
```javascript
fetch('/api/endpoint', {
  method: 'POST',
  credentials: 'include',  // ← Important!
  headers: { 'Content-Type': 'application/json' }
})
```

### Sessions Not Cleaning Up

Sessions older than 7 days stay in database. To clean up:

```javascript
import { cleanupExpiredSessions } from '@/lib/session.js';

// Run periodically:
await cleanupExpiredSessions();
```

---

## Architecture Overview

```
User Login
    ↓
/api/auth/login
    ↓
Verify credentials (bcrypt password hash)
    ↓
Create session in database
    ↓
Set jeton_session cookie (httpOnly, secure)
    ↓
Redirect to /dashboard (middleware validates)

--------

Protected Route Access
    ↓
Middleware checks jeton_session cookie
    ↓
Query sessions table + validate expiry + check user.status
    ↓
Set x-user-* headers on request
    ↓
Allow route access
    
--------

Logout
    ↓
/api/auth/logout
    ↓
Delete session from database
    ↓
Clear jeton_session cookie
    ↓
Redirect to /login
```

---

## Security Notes

✅ **Good**: 
- Cookies are httpOnly (JavaScript can't access)
- Cookies are secure in production (HTTPS only)
- sameSite=lax prevents CSRF
- Sessions stored in database (can't be forged)
- Passwords hashed with bcrypt

❌ **Avoid**:
- Don't store session IDs elsewhere
- Don't log session IDs
- Don't expose cookie_secret in code
- Don't bypass middleware protection

---

## Performance Tuning

### Database Indexes
Sessions table already has indexes on:
- `user_id` - Fast user lookup
- `expires_at` - Fast cleanup queries
- `created_at` - Fast sorting

### Connection Pool
Middleware uses minimal connection pool (2 max) for edge runtime compatibility.

### Query Optimization
Session validation is a single indexed query:
```sql
SELECT ... FROM sessions s
JOIN users u ON s.user_id = u.id
WHERE s.id = $1
AND s.expires_at > CURRENT_TIMESTAMP
AND u.status = 'active'
```

---

## Next Steps

1. **Test the login flow**
   - Create account
   - Login
   - Verify session created
   - Check /api/auth/me works
   - Logout and verify deletion

2. **Update remaining API routes**
   - See: `IMPLEMENTATION_STATUS_SESSION_AUTH.md`
   - Pattern is simple (3 changes per file)

3. **Deploy to Vercel**
   - Run migrations first
   - Set `DATABASE_URL` in Vercel env vars
   - Remove `JWT_SECRET` from env vars
   - Push code

4. **Monitor in production**
   - Check logs for session validation errors
   - Monitor database query performance
   - Track session count growth

---

## Files You Need to Know

- **`src/lib/session.js`** - Session management functions
- **`src/lib/api-auth.js`** - API route protection helper
- **`src/lib/current-user.js`** - Server component auth helper
- **`middleware.js`** - Route protection and validation
- **`src/app/api/auth/`** - Login, logout, register, me endpoints
- **`SESSION_BASED_AUTH_MIGRATION.md`** - Detailed migration guide
- **`IMPLEMENTATION_STATUS_SESSION_AUTH.md`** - Implementation checklist

---

## Quick Reference

### Create Session
```javascript
import { createSession } from '@/lib/session.js';
const sessionId = await createSession(userId);
```

### Validate Session (API Routes)
```javascript
import { requireApiAuth } from '@/lib/api-auth.js';
const user = await requireApiAuth(); // Throws 401 if invalid
```

### Get Current User (Server Components)
```javascript
import { getCurrentUser } from '@/lib/current-user.js';
const user = await getCurrentUser(); // Returns null if not auth
```

### Delete Session (Logout)
```javascript
import { deleteSession } from '@/lib/session.js';
await deleteSession(sessionId);
```

### Check User Role
```javascript
import { hasRole } from '@/lib/current-user.js';
const canAdmin = await hasRole('FOUNDER');
```

---

## Contact / Support

For detailed implementation questions, see:
- `SESSION_BASED_AUTH_MIGRATION.md` - Complete migration guide
- `IMPLEMENTATION_STATUS_SESSION_AUTH.md` - Status and checklist
- `src/lib/session.js` - Inline code documentation
- `middleware.js` - Middleware implementation details

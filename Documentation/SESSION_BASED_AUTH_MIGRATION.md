# Session-Based Authentication Migration Guide

## Overview
Jeton has been completely migrated from JWT-based to session-based authentication using secure HTTP-only cookies. This document outlines the changes and implementation details.

## Key Changes

### 1. Authentication Model
- **Before**: JWT tokens signed with `JWT_SECRET`, stored in cookies but accessible to JavaScript
- **After**: Server-side sessions stored in PostgreSQL, referenced by secure HTTP-only cookies

### 2. Database Schema

#### New `sessions` Table
```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_created_at ON sessions(created_at);
```

### 3. Cookie Configuration
- **Name**: `jeton_session`
- **httpOnly**: true (not accessible from JavaScript)
- **secure**: true (production), false (development)
- **sameSite**: "lax"
- **maxAge**: 7 days
- **path**: "/"

### 4. Session Duration
- Sessions are valid for 7 days
- Expired sessions are automatically invalid (checked at query time)
- Sessions have a `last_activity` field that can be used for idle timeouts

## API Changes

### Login Endpoint
**POST** `/api/auth/login`

**Before**:
```javascript
const response = NextResponse.json({
  message: 'Logged in successfully',
  user: { id, email, role, isActive }
}, { status: 200 });
response.cookies.set('auth-token', token, { httpOnly: true, ... });
```

**After**:
```javascript
const sessionId = await createSession(user.id);
const response = NextResponse.json(
  { message: 'Logged in successfully' },
  { status: 200 }
);
response.cookies.set('jeton_session', sessionId, { httpOnly: true, ... });
```

### Logout Endpoint
**POST** `/api/auth/logout`

**Before**:
- Cleared `auth-token` cookie
- No server-side cleanup

**After**:
- Deletes session from database
- Clears `jeton_session` cookie

### Auth Check Endpoint
**GET** `/api/auth/me`

**Before**:
```javascript
const token = cookieStore.get('auth-token')?.value;
const decoded = verifyToken(token);
const user = await findUserById(decoded.userId);
```

**After**:
```javascript
const sessionId = cookieStore.get('jeton_session')?.value;
const session = await getSession(sessionId);
// Returns user data from session.user
```

## Middleware Changes

**File**: `middleware.js`

- Removed all JWT verification logic
- Now queries database to validate sessions
- Validates session hasn't expired
- Checks user is active
- Attaches user context to request headers:
  - `x-user-id`
  - `x-user-email`
  - `x-user-role`

## Server Component Auth Access

### New Utility: `getCurrentUser()`

**File**: `src/lib/current-user.js`

Use in Server Components and API routes:

```javascript
import { getCurrentUser } from '@/lib/current-user.js';

export default async function DashboardLayout() {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  return <div>Welcome, {user.email}!</div>;
}
```

### Helper Functions

- `getCurrentUser()` - Returns user or null
- `getCurrentUserOrThrow()` - Returns user or throws error
- `hasRole(role)` - Check if user has specific role
- `isAuthenticated()` - Check if user is logged in

## API Route Auth

### New Utility: `api-auth.js`

**File**: `src/lib/api-auth.js`

Update API routes to use:

```javascript
import { requireApiAuth } from '@/lib/api-auth.js';

export async function POST(request) {
  try {
    // This throws 401 if not authenticated
    const user = await requireApiAuth();
    
    // User object contains: userId, email, role
    console.log('User ID:', user.userId);
    
    // ... rest of handler
  } catch (error) {
    if (error instanceof Response) {
      return error; // Return 401 from requireApiAuth
    }
    // Handle other errors
  }
}
```

## Migrating API Routes

### Before (JWT)
```javascript
import { verifyToken } from '@/lib/jwt.js';
import { cookies } from 'next/headers.js';

export async function GET(request) {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth-token')?.value;
  
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const decoded = verifyToken(token);
  if (!decoded) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  // Use decoded.userId
}
```

### After (Sessions)
```javascript
import { requireApiAuth } from '@/lib/api-auth.js';

export async function GET(request) {
  try {
    const user = await requireApiAuth();
    // Use user.userId
  } catch (error) {
    if (error instanceof Response) {
      return error;
    }
    // ... error handling
  }
}
```

## Client-Side Changes

### Login Form
No changes needed! The form already:
- Uses `credentials: 'include'` for cookie handling
- Doesn't try to decode tokens
- Navigates based on response status

### What Clients Must NOT Do
- ❌ Store auth tokens in localStorage
- ❌ Decode JWT tokens
- ❌ Check Authorization header
- ❌ Manually verify token expiration

### What Clients CAN Do
- ✅ Call login API
- ✅ Navigate normally (middleware handles redirects)
- ✅ Page refresh works (session still valid in cookie)

## Testing the Migration

### Manual Test: Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  -i

# Check for Set-Cookie: jeton_session=...;HttpOnly
```

### Manual Test: Protected Route
```bash
curl http://localhost:3000/api/auth/me \
  -H "Cookie: jeton_session=<value>"
```

### Manual Test: Logout
```bash
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Cookie: jeton_session=<value>" \
  -i

# Check for Set-Cookie with maxAge=0 to clear cookie
```

## Environment Variables

### No Longer Needed
- ❌ `JWT_SECRET` - Can be removed

### Still Required
- ✅ `DATABASE_URL` - PostgreSQL connection string
- ✅ `NODE_ENV` - Set to "production" on Vercel

## Vercel Deployment

The session-based auth is fully compatible with Vercel:
- ✅ Uses serverless edge runtime
- ✅ Minimal database queries per request
- ✅ HTTP-only cookies work across function invocations
- ✅ No stored secrets needed

### Deployment Checklist
- [ ] Run migrations to create `sessions` table
- [ ] Update API routes to use `requireApiAuth()`
- [ ] Test login/logout flow
- [ ] Verify cookies are httpOnly in production
- [ ] Check middleware is protecting routes correctly
- [ ] Remove `JWT_SECRET` from environment variables

## Removed Files/Code

### Deprecated
- `verifyToken()` from jwt.js - Don't use
- `generateToken()` from jwt.js - Don't use
- `getTokenFromCookies()` from jwt.js - Use session utilities
- Authorization header validation - Use cookies instead

### Still Available (for reference)
- `src/lib/jwt.js` - Kept for any legacy code, but not used
- `auth-token` cookie - Cleared, not set anymore

## Session Cleanup

To clean up expired sessions (optional, can run periodically):

```javascript
import { cleanupExpiredSessions } from '@/lib/session.js';

// Remove sessions older than 7 days
const count = await cleanupExpiredSessions();
console.log(`Cleaned up ${count} expired sessions`);
```

## Troubleshooting

### User is immediately logged out
- Check session validity query - ensure join to users works
- Verify user.status = 'active'
- Check session hasn't expired (expires_at > CURRENT_TIMESTAMP)

### Middleware is redirecting to /login on protected routes
- Verify jeton_session cookie is being set
- Check session ID is valid in database
- Ensure middleware.js is using correct session validation

### CORS issues with cookies
- Ensure client uses `credentials: 'include'`
- Check sameSite cookie setting (use 'lax' for cross-site)
- Verify secure flag in production

## Migration Checklist

- [x] Create sessions table schema
- [x] Implement session.js utilities
- [x] Update login endpoint
- [x] Update logout endpoint
- [x] Update /api/auth/me endpoint
- [x] Create getCurrentUser() utility
- [x] Refactor middleware.js
- [x] Update register endpoint
- [ ] Update remaining API routes to use api-auth.js
  - [ ] /api/assets
  - [ ] /api/assets/[id]
  - [ ] /api/liabilities
  - [ ] /api/liabilities/[id]
  - [ ] /api/deals
  - [ ] /api/deals/[id]
  - [ ] /api/deals/valuation
  - [ ] /api/net-worth
  - [ ] /api/staff
  - [ ] /api/staff/[id]
  - [ ] /api/snapshots
  - [ ] /api/snapshots/[id]
  - [ ] /api/snapshots/create
  - [ ] /api/reports/*
- [ ] Test login/logout
- [ ] Test middleware protection
- [ ] Test session expiration
- [ ] Deploy to Vercel
- [ ] Verify in production

## Production Considerations

1. **Session Duration**: Currently 7 days. Adjust `SESSION_DURATION` in `session.js` if needed.

2. **Idle Timeout**: The `last_activity` field can be used to implement idle logout. Add logic to:
   - Update `last_activity` on each request
   - Invalidate sessions older than idle threshold

3. **Session Cleanup**: Expired sessions accumulate in database. Run periodic cleanup:
   - Via cron job: `cleanupExpiredSessions()`
   - Via scheduled event on Vercel

4. **Database Performance**: Ensure indexes on sessions table:
   - `idx_sessions_user_id` - Fast user session lookup
   - `idx_sessions_expires_at` - Fast expiry cleanup

5. **Security**: 
   - Never log session IDs
   - Use HTTPS in production (secure flag)
   - Consider CSRF tokens if needed

## References

- `src/lib/session.js` - Session management
- `src/lib/api-auth.js` - API route auth helpers
- `src/lib/current-user.js` - Server component auth
- `middleware.js` - Route protection
- `src/app/api/auth/` - Auth endpoints

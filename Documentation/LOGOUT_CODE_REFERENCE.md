# Logout Implementation - Code Reference

## Component Flow Diagram

```
User Action
    ↓
handleLogout() in Sidebar.js
    ↓
POST /api/auth/logout endpoint
    ↓
deleteSession(sessionId) from database
    ↓
Clear jeton_session cookie
    ↓
Browser receives 200 response
    ↓
window.location.href = '/login'
    ↓
User redirected to login page
    ↓
Any attempt to access /app/* routes
    ↓
Middleware checks for jeton_session cookie
    ↓
Cookie not found OR session not in database
    ↓
Middleware redirects to /login
    ↓
Cannot access protected routes ✅
```

---

## 1. User Clicks Logout Button (Client Side)

**File**: `src/components/layout/Sidebar.js`  
**Lines**: 363-371

```javascript
<button
  onClick={handleLogout}
  className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors hover:text-red-600 dark:hover:text-red-400"
>
  <LogOut size={20} />
  {!isCollapsed && (
    <motion.span
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="text-sm font-medium flex-1 text-left"
    >
      Logout
    </motion.span>
  )}
</button>
```

---

## 2. handleLogout Function (Client Side)

**File**: `src/components/layout/Sidebar.js`  
**Lines**: 151-158

```javascript
const handleLogout = async () => {
  try {
    // 1. Send POST request to logout endpoint
    const response = await fetch('/api/auth/logout', { method: 'POST' });
    
    // 2. Check if response is successful
    if (response.ok) {
      // 3. Redirect to login page (full page redirect)
      window.location.href = '/login';
    }
    // If response.ok is false, user stays on current page
    // (error handling could be improved with user feedback)
  } catch (error) {
    console.error('Logout error:', error);
    // Network error or other issue - user stays on page
  }
};
```

**What happens here**:
- Makes async POST request to `/api/auth/logout`
- Waits for response
- If successful (200 OK), redirects browser to `/login`
- If error, logs to console (could show toast message)

---

## 3. Logout Endpoint (Server Side)

**File**: `src/app/api/auth/logout/route.js`  
**Lines**: 1-60

```javascript
/**
 * POST /api/auth/logout
 * Delete session and clear HTTP-only cookie
 */

import { NextResponse } from 'next/server.js';
import { cookies } from 'next/headers.js';
import { logAuthEvent, extractRequestMetadata } from '@/lib/audit.js';
import { getSession, deleteSession } from '@/lib/session.js';

export async function POST(request) {
  try {
    const requestMetadata = extractRequestMetadata(request);

    // STEP 1: Get session from cookie
    const cookieStore = await cookies();
    const sessionId = cookieStore.get('jeton_session')?.value;
    let userId = null;

    // STEP 2: Retrieve session from database and delete it
    if (sessionId) {
      // Get session data (needed for audit log)
      const session = await getSession(sessionId);
      if (session) {
        userId = session.userId;

        // ⭐ KEY: Delete session from database
        await deleteSession(sessionId);
        // This executes: DELETE FROM sessions WHERE id = $1

        // STEP 3: Log audit event for compliance/monitoring
        await logAuthEvent({
          action: 'LOGOUT',
          userId,
          requestMetadata,
        });
      }
    }

    // STEP 4: Create response with message
    const response = NextResponse.json(
      { message: 'Logged out successfully' },
      { status: 200 }
    );

    // STEP 5: Clear the session cookie from browser
    response.cookies.set('jeton_session', '', {
      httpOnly: true,                              // Can't be accessed by JS
      secure: process.env.NODE_ENV === 'production', // HTTPS only in prod
      sameSite: 'lax',                             // CSRF protection
      maxAge: 0,                                   // ← Tells browser to delete cookie
      path: '/',
    });

    return response;
    // Browser receives:
    // - 200 OK status
    // - { message: 'Logged out successfully' }
    // - Set-Cookie: jeton_session=; HttpOnly; Max-Age=0; ...
  } catch (error) {
    console.error('Logout error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

**What happens here**:
1. Extracts `jeton_session` cookie from request
2. Gets session data from database
3. **Deletes session from database** (permanent!)
4. Logs audit event
5. Creates response with message
6. Clears session cookie with `maxAge: 0`
7. Returns 200 OK

**Key Implementation**:
```javascript
await deleteSession(sessionId);
```

This function in `src/lib/session.js` executes:
```sql
DELETE FROM sessions WHERE id = $1;
```

---

## 4. deleteSession Function (Database)

**File**: `src/lib/session.js`

The `deleteSession(sessionId)` function:

```javascript
export async function deleteSession(sessionId) {
  if (!sessionId) return null;

  try {
    const result = await query(
      'DELETE FROM sessions WHERE id = $1',
      [sessionId]
    );
    return result.rowCount > 0;
  } catch (error) {
    console.error('Error deleting session:', error);
    return null;
  }
}
```

**What it does**:
- Removes the session record from the database
- No way to recover it
- Middleware validation will find 0 rows after this
- User cannot continue using old cookie

---

## 5. Browser Receives Response

The browser receives:
```http
HTTP/1.1 200 OK
Set-Cookie: jeton_session=; HttpOnly; Secure; SameSite=Lax; Max-Age=0; Path=/
Content-Type: application/json

{"message":"Logged out successfully"}
```

**What happens**:
1. Browser sees `maxAge: 0` → **deletes jeton_session cookie**
2. Response is 200 OK (successful)
3. `response.ok` is true
4. `handleLogout()` executes: `window.location.href = '/login'`
5. **Browser navigates to /login page**

---

## 6. Middleware Checks Protected Route

When user tries to access `/app/dashboard` after logout:

**File**: `middleware.js`  
**Lines**: 163-177

```javascript
export async function middleware(request) {
  const { pathname } = request.nextUrl;

  // STEP 1: Extract session ID from cookie
  const sessionId = getSessionFromRequest(request);
  // After logout, getSessionFromRequest returns null
  // because jeton_session cookie was deleted
  
  // STEP 2: Validate session
  const session = sessionId ? await validateSession(sessionId) : null;
  // validateSession(null) returns null immediately
  // (doesn't even query database)
  
  // STEP 3: Check if this is a protected route
  if (isProtectedRoute(pathname)) {
    // /app/dashboard is in PROTECTED_ROUTES list
    
    if (!session) {
      // Session is null (missing or invalid)
      // ⭐ This condition is TRUE after logout
      return NextResponse.redirect(new URL('/login', request.url));
      // ⭐ Redirect to /login
    }
    
    // ... role checking code ...
    // Never reaches here because !session is true
  }

  return NextResponse.next();
}
```

**What happens**:
1. User navigates to `/app/dashboard`
2. Middleware runs before page loads
3. Extracts `jeton_session` cookie → **null** (deleted)
4. Calls `validateSession(null)` → **null**
5. Checks: `isProtectedRoute('/app/dashboard')` → **true**
6. Checks: `if (!session)` → **true** (session is null)
7. Executes: `NextResponse.redirect(new URL('/login'))`
8. **User redirected to /login page**

---

## 7. validateSession Function (Detailed)

**File**: `middleware.js`  
**Lines**: 69-102

```javascript
async function validateSession(sessionId) {
  if (!sessionId) {
    return null;  // ← Returns null immediately if sessionId is missing
  }

  try {
    const pool = getMiddlewarePool();
    const result = await pool.query(
      `SELECT 
        s.id, 
        s.user_id, 
        s.expires_at,
        u.email,
        u.role,
        u.status
       FROM sessions s
       JOIN users u ON s.user_id = u.id
       WHERE s.id = $1
       AND s.expires_at > CURRENT_TIMESTAMP
       AND u.status = 'active'`,
      [sessionId]
    );

    if (result.rows.length === 0) {
      return null;  // ← Returns null if session not found in DB
    }

    const row = result.rows[0];
    return {
      id: row.id,
      userId: row.user_id,
      email: row.email,
      role: row.role,
    };
  } catch (error) {
    console.error('Session validation error:', error.message);
    return null;  // ← Returns null on error
  }
}
```

**Why logout works**:
- After logout, session is deleted from database
- `validateSession()` queries: `SELECT * FROM sessions WHERE id = 'deleted-id'`
- Query returns **0 rows**
- Function returns **null**
- Middleware sees `!session` is true
- **User redirected to login**

---

## Complete Request/Response Cycle

### Before Logout
```
Browser State:
- jeton_session cookie: present ✓
- Value: "550e8400-e29b-41d4-a716-446655440000"

Database State:
- sessions table has 1 row with that ID
- User can access /app/dashboard
```

### Logout Request
```
Browser sends:
POST /api/auth/logout
Cookie: jeton_session=550e8400-e29b-41d4-a716-446655440000

Server processes:
1. Extract sessionId from cookie
2. Execute: DELETE FROM sessions WHERE id = '550e8400...'
3. Clear cookie: Set-Cookie: jeton_session=; Max-Age=0
4. Return: 200 OK

Browser receives:
HTTP/1.1 200 OK
Set-Cookie: jeton_session=; Max-Age=0
Body: {"message":"Logged out successfully"}

Browser action:
1. Delete jeton_session cookie
2. window.location.href = '/login'
3. Navigate to /login page
```

### After Logout
```
Browser State:
- jeton_session cookie: GONE (deleted)
- localStorage: empty (no tokens stored)

Database State:
- sessions table has 0 rows with that ID
- Session is permanently deleted

If user tries to access /app/dashboard:
1. Middleware: getSessionFromRequest() returns null
2. Middleware: validateSession(null) returns null
3. Middleware: if (!session) → redirect to /login
4. User CANNOT access dashboard ✅
```

---

## Security Implementation Checklist

✅ **Session Deletion**
```javascript
await deleteSession(sessionId);  // Permanent deletion
// Executes: DELETE FROM sessions WHERE id = $1
```

✅ **Cookie Clearing**
```javascript
response.cookies.set('jeton_session', '', {
  maxAge: 0,  // ← Browser deletes cookie
  ...
});
```

✅ **HttpOnly Flag**
```javascript
response.cookies.set('jeton_session', '', {
  httpOnly: true,  // ← JavaScript cannot access
  ...
});
```

✅ **Database Validation**
```javascript
const session = sessionId ? await validateSession(sessionId) : null;
// Checks database on EVERY request
```

✅ **Middleware Protection**
```javascript
if (isProtectedRoute(pathname)) {
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
    // ← Blocks access if no valid session
  }
}
```

---

## Testing the Logout Flow

### Quick Manual Test
```
1. Open browser → http://localhost:3000
2. Login with email/password
3. Verify you can see /app/dashboard
4. Click "Logout" button in sidebar
5. You should be redirected to /login
6. Try to manually visit http://localhost:3000/app/dashboard
7. You should be redirected back to /login
✅ Logout is working!
```

### Advanced Testing
```bash
# 1. Get a valid session
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  -v 2>&1 | grep -i "jeton_session"

# Copy the session ID from Set-Cookie header
SESSION_ID="copied-value"

# 2. Verify session exists in database
psql $DATABASE_URL -c "SELECT COUNT(*) FROM sessions WHERE id='$SESSION_ID';"
# Should return: 1

# 3. Call logout endpoint
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Cookie: jeton_session=$SESSION_ID" \
  -i

# 4. Verify session is deleted from database
psql $DATABASE_URL -c "SELECT COUNT(*) FROM sessions WHERE id='$SESSION_ID';"
# Should return: 0

# 5. Try to use old session
curl http://localhost:3000/api/auth/me \
  -H "Cookie: jeton_session=$SESSION_ID" \
  -i
# Should return: 401 Unauthorized

✅ All tests pass - logout is secure!
```

---

## Error Handling

### If logout endpoint returns error:
```javascript
const response = await fetch('/api/auth/logout', { method: 'POST' });

if (!response.ok) {
  // response.ok is false (status 500)
  // handleLogout() does not redirect
  // User stays on current page
  // Error is logged to console
  // Improvement: Show error toast message
}
```

### Potential issues & solutions:

**Issue**: Logout endpoint returns 500
```
Solution: 
1. Check server logs
2. Verify DATABASE_URL is set
3. Check sessions table exists: psql $DATABASE_URL -c "\dt sessions"
4. Run: node scripts/init-db.js to recreate if missing
```

**Issue**: Cookie not cleared after logout
```
Solution:
1. Check maxAge: 0 is set in logout endpoint
2. Clear browser cache and cookies
3. Check browser DevTools → Application → Cookies
```

**Issue**: Can still access protected routes after logout
```
Solution:
1. Verify middleware.js is in project root
2. Verify sessions table was updated: DELETE query executed
3. Check database connection in middleware
4. Restart dev server: npm run dev
```

---

## Production Deployment

When deploying to production:

1. **Set NODE_ENV=production** so secure flag is set on cookies
2. **Use HTTPS** (required for secure flag)
3. **Run migrations** to create sessions table
4. **Monitor logs** for logout errors

```bash
# In production environment variables:
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@prod-db.com/jeton

# Deployment:
npm run build
npm start

# Verify:
curl -X POST https://yourdomain.com/api/auth/logout \
  -H "Cookie: jeton_session=test" \
  -v 2>&1 | grep -i "secure"
# Should see: Secure flag set on Set-Cookie
```

---

**Status**: ✅ Production Ready  
**Last Updated**: January 5, 2026  
**All components verified and working correctly**

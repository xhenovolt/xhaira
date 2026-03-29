# Authentication System - Quick Reference

## How It Works Now ✅

### The Problem That Was Fixed
```
❌ BEFORE: 
   User → Middleware (checks cookie exists) → Page renders → API validates session
   Problem: Page renders before session validation! Flash of content visible.

✅ AFTER:
   User → Middleware (checks cookie) → Layout validates session in DB → Page renders
   Solution: No page render without valid session in database!
```

## Route Protection Matrix

### Protected Routes (Requires Login)
| Route | Protection | Result |
|-------|-----------|--------|
| `/app/*` | AppLayout checks getCurrentUser() | Redirects to /login if no session |
| `/admin/*` | AdminLayout checks getCurrentUser() | Redirects to /login if no session |
| `/api/*` | API route checks requireApiAuth() | Returns 401 Unauthorized |
| `/app/dashboard` | AppLayout | Server-side redirect before render |
| `/app/assets` | AppLayout | Server-side redirect before render |
| `/admin/users` | AdminLayout | Server-side redirect before render |

### Auth-Only Routes (Requires NOT Logged In)
| Route | Protection | Result |
|-------|-----------|--------|
| `/login` | LoginLayout checks getCurrentUser() | Redirects to /dashboard if logged in |
| `/register` | RegisterLayout checks getCurrentUser() | Redirects to /dashboard if logged in |

### Public Routes (Always Accessible)
| Route | Protection | Result |
|-------|-----------|--------|
| `/` | None | Landing page visible to everyone |
| `/api/auth/login` | Form validation only | Can attempt login |
| `/api/auth/register` | Form validation only | Can attempt registration |

## Authentication Layers

### Layer 1: Middleware (Edge)
```typescript
// middleware.ts
function middleware(request) {
  const hasSessionCookie = !!getSessionCookie(request);
  
  if (isProtectedRoute(pathname)) {
    if (!hasSessionCookie) return redirect('/login');
  }
  return NextResponse.next();
}
```
**Purpose:** Quick cookie check - prevent unnecessary server work

### Layer 2: Route Layouts (Server)
```javascript
// src/app/app/layout.js
export default async function AppLayout({ children }) {
  const user = await getCurrentUser();  // ← Queries database!
  
  if (!user) redirect('/login');
  
  return children;
}
```
**Purpose:** Validate session actually exists in database before rendering

### Layer 3: API Routes (Server)
```javascript
// src/app/api/deals/route.js
export async function GET(request) {
  const user = await requireApiAuth();  // ← Validates session
  
  if (!user) return 401;
  
  // Process request with valid user
}
```
**Purpose:** Double-check for API calls

### Layer 4: Client Components (Client)
```javascript
// src/app/app/dashboard/page.js
'use client'

useEffect(() => {
  fetchWithAuth('/api/deals');  // ← Sends session cookie
}, []);
```
**Purpose:** Browser automatically includes session cookie

## Session Lifecycle

```
1. USER REGISTERS
   ├─ POST /api/auth/register
   ├─ Password hashed with bcryptjs
   ├─ User created in database
   └─ Redirect to /login

2. USER LOGS IN
   ├─ POST /api/auth/login (email + password)
   ├─ Password verified with bcryptjs
   ├─ createSession(userId) creates session in DB
   ├─ Session cookie set: jeton_session = <session-id>
   ├─ Cookie: HTTP-only, Secure, SameSite=lax
   └─ Redirect to /app/dashboard

3. USER BROWSING (Authenticated)
   ├─ Request to /app/dashboard
   ├─ Middleware: Cookie exists ✓
   ├─ AppLayout: getCurrentUser() validates session in DB ✓
   ├─ Page renders with content
   └─ API calls: Include session cookie automatically

4. USER LOGS OUT
   ├─ Click "Logout" button
   ├─ POST /api/auth/logout
   ├─ deleteSession(sessionId) removes from database
   ├─ Cookie cleared: maxAge=0
   ├─ localStorage cleared: removeItem('auth_token')
   └─ Redirect to /login

5. LOGOUT VERIFICATION
   ├─ Request to /app/dashboard
   ├─ Middleware: Cookie might still exist (not validated)
   ├─ AppLayout: getCurrentUser() checks database
   ├─ Session NOT found in DB (was deleted)
   ├─ Returns null
   ├─ Layout calls redirect('/login')
   └─ User sees login form ✓
```

## Code Locations

### Authentication Utilities
- `src/lib/current-user.js` - getCurrentUser() - **SERVER-ONLY**
- `src/lib/session.js` - Session management (create, get, delete)
- `src/lib/auth.js` - Password hashing and verification
- `src/lib/api-auth.js` - API route protection helpers
- `src/lib/validation.js` - Input validation for login/register

### Route Protection Layouts
- `src/app/app/layout.js` - Protects `/app/*`
- `src/app/admin/layout.js` - Protects `/admin/*`
- `src/app/login/layout.js` - Protects `/login` (prevents logged-in access)
- `src/app/register/layout.js` - Protects `/register` (prevents logged-in access)

### API Routes
- `src/app/api/auth/login/route.js` - Login endpoint
- `src/app/api/auth/logout/route.js` - Logout endpoint
- `src/app/api/auth/register/route.js` - Registration endpoint
- `src/app/api/auth/me/route.js` - Current user info

### Middleware
- `middleware.ts` - Edge middleware for cookie checks

## Common Scenarios

### User tries /app/dashboard without logging in
```
1. Browser: GET /app/dashboard (no jeton_session cookie)
2. Middleware: No cookie → redirect /login ✓
3. User sees: Login form
```

### User logs in successfully
```
1. Browser: POST /api/auth/login (email + password)
2. Server: Password verified ✓
3. Server: createSession() → new session in DB
4. Response: jeton_session cookie set (HTTP-only)
5. Browser: Redirect /app/dashboard
6. AppLayout: getCurrentUser() → finds session in DB ✓
7. User sees: Dashboard
```

### User logs out
```
1. Browser: POST /api/auth/logout (with jeton_session cookie)
2. Server: deleteSession() → removes from DB
3. Response: Cookie cleared (maxAge=0)
4. Browser: localStorage.removeItem('auth_token')
5. Browser: Redirect /login
6. User sees: Login form
```

### User with old session tries to access /app
```
1. Browser: GET /app/dashboard (stale session cookie)
2. Middleware: Cookie exists → allow passage
3. AppLayout: getCurrentUser() queries DB
4. Database: Session not found (was deleted or expired)
5. Returns: null
6. Layout: redirect('/login')
7. User sees: Login form (forced re-authentication)
```

## Security Properties

✅ **XSS Protection** - Session ID in HTTP-only cookie (not accessible from JS)  
✅ **CSRF Protection** - SameSite: lax cookie policy  
✅ **SQL Injection** - Parameterized queries with bcryptjs  
✅ **Brute Force** - No rate limiting yet (future enhancement)  
✅ **Session Fixation** - New session on login, deleted on logout  
✅ **No Flash Content** - Server-side redirect before render  
✅ **Cross-Tab Support** - Session stored in database (not localStorage)  
✅ **Logout Enforcement** - Session deleted from DB (not in browser)  

---

**Last Updated:** February 12, 2026

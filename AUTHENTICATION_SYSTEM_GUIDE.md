# Jeton Authentication System Guide

## Overview

Jeton uses a **session-based authentication system** with HTTP-only cookies for secure user authentication. This guide explains the complete architecture, how sessions work, and how to use authentication in your application.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Key Components](#key-components)
3. [Authentication Flow](#authentication-flow)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Core Libraries](#core-libraries)
7. [Middleware](#middleware)
8. [Using Authentication in Code](#using-authentication-in-code)
9. [Security Features](#security-features)
10. [Session Lifecycle](#session-lifecycle)
11. [Common Patterns](#common-patterns)

---

## Architecture Overview

The authentication system uses a **stateful session model** with cookies instead of JWTs:

```
┌─────────────────────────────────────────────────────────────┐
│                    User Authentication Flow                   │
└─────────────────────────────────────────────────────────────┘

  User Login
     ↓
  POST /api/auth/login
     ↓
  Verify Credentials (bcrypt password hash)
     ↓
  Create Session in Database
     ↓
  Set jeton_session HTTP-Only Cookie
     ↓
  Redirect to Dashboard
     ↓
  Middleware validates cookie on protected routes
     ↓
  API endpoints validate full session
     ↓
  Server components access current user
     ↓
  Logout: Delete session from DB + Clear cookie
```

### Why Session-Based Instead of JWT?

- **Security**: Passwords never exposed in tokens
- **Revocation**: Sessions can be immediately invalidated (logout)
- **Stateful**: Server maintains control over authentication
- **Scalability**: Works with connection pooling and edge runtimes
- **Cookie Safety**: HTTP-only prevents JavaScript access

---

## Key Components

### 1. Sessions Table (Database)

```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_created_at ON sessions(created_at);
```

**Key Features:**
- Session expires after **7 days** by default
- Auto-cascade delete when user is deleted
- Tracks last activity for online status
- Indexed for fast lookups

### 2. jeton_session Cookie

A secure HTTP-only cookie set on login containing the session ID:

```
Name: jeton_session
Value: <UUID>
HttpOnly: true
Secure: true (in production)
SameSite: lax
Max-Age: 7 days
Path: /
```

**HTTP-Only Security**: JavaScript cannot access this cookie, preventing XSS attacks from stealing the session.

### 3. Users Table

The core user data table with password hashing:

```
id (UUID)
email (string, unique)
password_hash (bcrypt hash)
role (string: FOUNDER, STAFF, etc.)
status (string: active, inactive, pending)
created_at
updated_at
last_login
is_online
last_seen
```

---

## Authentication Flow

### Login Flow

```javascript
// 1. User submits credentials
POST /api/auth/login
{
  email: "user@example.com",
  password: "password123"
}

// 2. Server validates input
validateLogin(body) // Check email & password format

// 3. Find user by email
findUserByEmail(email) // Query: SELECT * FROM users WHERE email = $1

// 4. Compare password with hash using bcrypt
comparePassword(plainPassword, storedHash) // Returns true/false

// 5. Create session in database
createSession(userId)
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity)
VALUES ($1, $2, NOW() + interval '7 days', NOW(), NOW())

// 6. Set HTTP-only cookie
response.cookies.set('jeton_session', sessionId, {
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  maxAge: 604800, // 7 days in seconds
  path: '/'
})

// 7. Return success (no user data in response)
return { message: 'Logged in successfully' }
```

### Protected Route Access Flow

```
User Request to /dashboard
         ↓
   Middleware Checks
         ↓
   Has jeton_session cookie?
    ↙                      ↘
  YES                       NO
   ↓                        ↓
Allow access          Redirect to /login
   ↓
API Route Validation
   ↓
Get sessionId from cookie
   ↓
Query: SELECT * FROM sessions s
       JOIN users u ON s.user_id = u.id
       WHERE s.id = $1
       AND s.expires_at > NOW()
       AND u.status = 'active'
   ↓
Valid? → Allow access + Update last_activity
Invalid? → Return 401 Unauthorized
```

### Logout Flow

```javascript
// 1. User clicks logout
POST /api/auth/logout

// 2. Get session from cookie
const sessionId = cookies.get('jeton_session')?.value

// 3. Delete from database
DELETE FROM sessions WHERE id = $1

// 4. Clear cookie
response.cookies.set('jeton_session', '', { maxAge: 0 })

// 5. Redirect to login
return redirect('/login')
```

---

## Database Schema

### Sessions Table Structure

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID | Unique session identifier |
| `user_id` | UUID | Foreign key to users table |
| `expires_at` | TIMESTAMP | When session expires (7 days) |
| `created_at` | TIMESTAMP | Session creation time |
| `last_activity` | TIMESTAMP | Last activity timestamp |

### Example Session Query

```sql
-- Get active session with user info
SELECT 
  s.id,
  s.user_id,
  s.expires_at,
  s.last_activity,
  u.id,
  u.email,
  u.role,
  u.status
FROM sessions s
JOIN users u ON s.user_id = u.id
WHERE s.id = 'abc123-def456-ghi789'
AND s.expires_at > CURRENT_TIMESTAMP
AND u.status = 'active';
```

---

## API Endpoints

### POST /api/auth/login

Authenticate user and create session.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "message": "Logged in successfully"
}
```

**Headers Set:**
```
Set-Cookie: jeton_session=<uuid>; HttpOnly; Secure; SameSite=Lax; Max-Age=604800; Path=/
```

**Errors:**
- `400` - Validation failed (invalid email/password format)
- `401` - Invalid email or password
- `500` - Server error

### POST /api/auth/logout

Delete session and clear cookie.

**Request:**
```
POST /api/auth/logout
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**Headers Set:**
```
Set-Cookie: jeton_session=; HttpOnly; Secure; SameSite=Lax; MaxAge=0; Path=/
```

### POST /api/auth/register

Create new user and automatically log them in.

**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "securepassword123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response (201 Created):**
```json
{
  "message": "User registered successfully"
}
```

**Auto-Login:**
- Session is automatically created after registration
- User redirected to dashboard without additional login

### GET /api/auth/me

Get current authenticated user info.

**Request:**
```
GET /api/auth/me
```

**Response (200 OK):**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "role": "FOUNDER",
  "status": "active",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Errors:**
- `401` - Not authenticated

---

## Core Libraries

### src/lib/session.js

Session management utilities for creating, validating, and deleting sessions.

#### `createSession(userId)`

Creates a new session for a user.

```javascript
import { createSession } from '@/lib/session.js';

const sessionId = await createSession(userId);
// Returns: UUID string (stored in cookie)
```

#### `getSession(sessionId)`

Retrieves and validates a session.

```javascript
import { getSession } from '@/lib/session.js';

const session = await getSession(sessionId);
// Returns: 
// {
//   id: "session-uuid",
//   userId: "user-uuid",
//   expiresAt: Date,
//   user: {
//     id: "user-uuid",
//     email: "user@example.com",
//     role: "FOUNDER",
//     status: "active"
//   }
// }
// Returns: null if invalid or expired
```

#### `deleteSession(sessionId)`

Deletes a session from the database (logout).

```javascript
import { deleteSession } from '@/lib/session.js';

await deleteSession(sessionId);
// Session permanently removed from database
```

#### `updateSessionActivity(sessionId)`

Updates session's last activity timestamp.

```javascript
import { updateSessionActivity } from '@/lib/session.js';

await updateSessionActivity(sessionId);
// Updates last_activity timestamp
```

#### `deleteAllUserSessions(userId)`

Logs out user from all devices by deleting all their sessions.

```javascript
import { deleteAllUserSessions } from '@/lib/session.js';

await deleteAllUserSessions(userId);
// All sessions for this user deleted
```

### src/lib/auth.js

Password hashing and user lookup utilities.

#### `hashPassword(password)`

Hash a plain-text password using bcrypt.

```javascript
import { hashPassword } from '@/lib/auth.js';

const hash = await hashPassword('mypassword');
// Stores in database with: INSERT INTO users (...password_hash...) VALUES ($1, hash, ...)
```

#### `comparePassword(password, hash)`

Verify a password matches its hash.

```javascript
import { comparePassword } from '@/lib/auth.js';

const matches = await comparePassword(plainPassword, storedHash);
// Used in login endpoint: if (!comparePassword(email, password)) return 401
```

#### `findUserByEmail(email)`

Find user record by email address.

```javascript
import { findUserByEmail } from '@/lib/auth.js';

const user = await findUserByEmail('user@example.com');
// Returns: User object or null
```

#### `findUserById(userId)`

Find user record by ID.

```javascript
import { findUserById } from '@/lib/auth.js';

const user = await findUserById('user-uuid');
// Returns: User object or null
```

#### `verifyCredentials(email, password)`

Combined function for login: finds user and verifies password.

```javascript
import { verifyCredentials } from '@/lib/auth.js';

const user = await verifyCredentials(email, password);
// Returns: User object if valid, null if invalid
// Used in: POST /api/auth/login
```

### src/lib/current-user.js

Server-side utilities for accessing the current authenticated user.

#### `getCurrentUser()`

Get the current authenticated user in server components or API routes.

```javascript
import { getCurrentUser } from '@/lib/current-user.js';

const user = await getCurrentUser();
// Returns: 
// {
//   id: "user-uuid",
//   email: "user@example.com",
//   role: "FOUNDER",
//   status: "active",
//   fullName: "John Doe",
//   createdAt: Date
// }
// Returns: null if not authenticated
```

#### `getCurrentUserOrThrow()`

Get current user or throw an error (for required auth).

```javascript
import { getCurrentUserOrThrow } from '@/lib/current-user.js';

const user = await getCurrentUserOrThrow();
// Throws Error if not authenticated
// Use when user MUST be logged in
```

#### `hasRole(requiredRole)`

Check if current user has a specific role.

```javascript
import { hasRole } from '@/lib/current-user.js';

const canAdmin = await hasRole('FOUNDER');
// Returns: true or false

// Check multiple roles
const canAccess = await hasRole(['FOUNDER', 'ADMIN']);
```

#### `isAuthenticated()`

Check if user is currently authenticated.

```javascript
import { isAuthenticated } from '@/lib/current-user.js';

const authed = await isAuthenticated();
// Returns: true or false
```

### src/lib/api-auth.js

API route protection utilities.

#### `getApiAuthUser()`

Get authenticated user in API routes (returns null if not auth).

```javascript
import { getApiAuthUser } from '@/lib/api-auth.js';

const user = await getApiAuthUser();
// Returns: { userId, email, role } or null
```

#### `requireApiAuth()`

Require authentication in API routes (throws 401 if not auth).

```javascript
import { requireApiAuth } from '@/lib/api-auth.js';
import { NextResponse } from 'next/server.js';

export async function GET(request) {
  try {
    const user = await requireApiAuth();
    
    // user = { userId, email, role }
    return NextResponse.json({ user });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    throw error;
  }
}
```

#### `requireApiRole(requiredRoles)`

Require specific role in API routes (throws 401/403).

```javascript
import { requireApiRole } from '@/lib/api-auth.js';

export async function POST(request) {
  try {
    const user = await requireApiRole('FOUNDER');
    // User is authenticated AND has FOUNDER role
    
    return NextResponse.json({ success: true });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }
    if (error.status === 403) {
      return NextResponse.json({ error: 'Insufficient permissions' }, { status: 403 });
    }
    throw error;
  }
}
```

---

## Middleware

The middleware handles initial route protection and only performs cookie checking (no database validation).

### File: middleware.ts

```typescript
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Check if jeton_session cookie exists
  const hasSessionCookie = !!getSessionCookie(request);
  
  // Protected routes: require session cookie
  if (isProtectedRoute(pathname)) {
    if (!hasSessionCookie) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
    return NextResponse.next();
  }
  
  // Auth-only routes: redirect if authenticated
  if (isAuthOnlyRoute(pathname) && hasSessionCookie) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  return NextResponse.next();
}
```

### Protected Routes

Middleware protects these routes (requires jeton_session cookie):

```
/dashboard
/app
/assets
/liabilities
/deals
/pipeline
/reports
/staff
/settings
/shares
/infrastructure
/intellectual-property
/assets-accounting
/equity
/audit-logs
/sales
/admin
```

### Auth-Only Routes

These routes redirect away if user is already authenticated:

```
/login
/register
```

### Key Points

- ✅ **Edge-Safe**: Middleware only reads cookies (no database queries)
- ✅ **Fast**: No validation logic, just existence check
- ✅ **Full Validation**: Happens in API routes and server components
- ✅ **API Routes**: Not matched by middleware, validation in route handlers

---

## Using Authentication in Code

### In Server Components (Layouts, Pages)

```javascript
import { getCurrentUser } from '@/lib/current-user.js';
import { redirect } from 'next/navigation.js';

export default async function DashboardLayout({ children }) {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  return (
    <div>
      <h1>Welcome, {user.email}!</h1>
      <div>Role: {user.role}</div>
      {children}
    </div>
  );
}
```

### In API Routes

```javascript
import { requireApiAuth } from '@/lib/api-auth.js';
import { NextResponse } from 'next/server.js';

export async function GET(request) {
  try {
    const user = await requireApiAuth();
    
    // User is authenticated
    console.log(`User ${user.email} accessed this API`);
    
    return NextResponse.json({
      message: 'Success',
      userId: user.userId
    });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }
    throw error;
  }
}
```

### Role-Based Access Control (RBAC)

```javascript
import { requireApiRole } from '@/lib/api-auth.js';
import { NextResponse } from 'next/server.js';

export async function POST(request) {
  try {
    // Only FOUNDER role can access
    const user = await requireApiRole('FOUNDER');
    
    // Process admin operation
    return NextResponse.json({ success: true });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }
    if (error.status === 403) {
      return NextResponse.json(
        { error: 'Admin access required' },
        { status: 403 }
      );
    }
    throw error;
  }
}
```

### Multiple Roles

```javascript
const user = await requireApiRole(['FOUNDER', 'ADMIN']);
// User must have either FOUNDER or ADMIN role
```

### Check Role Without API

```javascript
import { hasRole } from '@/lib/current-user.js';

const canAdmin = await hasRole('FOUNDER');

if (canAdmin) {
  // Show admin UI
}
```

### Conditional UI Based on Auth

```javascript
import { getCurrentUser } from '@/lib/current-user.js';

export default async function UserProfile() {
  const user = await getCurrentUser();
  
  if (!user) {
    return <div>Please log in</div>;
  }
  
  return (
    <div>
      <h1>{user.email}</h1>
      <p>Role: {user.role}</p>
      <p>Created: {new Date(user.createdAt).toLocaleDateString()}</p>
    </div>
  );
}
```

---

## Security Features

### 1. Password Security

- **Bcrypt Hashing**: Uses bcrypt with salt rounds = 10
- **Hash Verification**: `comparePassword()` uses time-constant comparison
- **Never Logged**: Passwords never appear in logs or responses

```javascript
// Login endpoint never returns password data
return { message: 'Logged in successfully' }; // ✅ Correct

// NOT this:
return { message: 'Success', user: { password: hash } }; // ❌ Wrong
```

### 2. Session Security

- **HTTP-Only Cookies**: JavaScript cannot access the session
- **Secure Flag**: Only sent over HTTPS in production
- **SameSite Lax**: Prevents CSRF attacks
- **7-Day Expiry**: Automatically expires after 7 days
- **Database Validation**: Session can be revoked instantly

### 3. No Token Exposure

Unlike JWTs, session tokens are:
- ✅ Never stored in localStorage (no XSS vulnerability)
- ✅ Automatically included in requests (transparent)
- ✅ Validated on every request
- ✅ Revocable at any time

### 4. SQL Injection Prevention

All database queries use parameterized queries:

```javascript
// ✅ Correct - parameterized
const result = await query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ❌ Wrong - SQL injection vulnerability
const result = await query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

### 5. Input Validation

All login/register endpoints validate input:

```javascript
const validation = validateLogin(body);
if (!validation.success) {
  return { error: 'Validation failed', fields: validation.errors };
}
```

### 6. Rate Limiting (Optional)

Can be added to login endpoint to prevent brute force:

```javascript
// Check if user has too many failed attempts
const failedAttempts = await getFailedLoginAttempts(email);
if (failedAttempts > 5) {
  return { error: 'Too many failed attempts. Try again later.' };
}
```

---

## Session Lifecycle

### Session Timeline

```
Created          Last Activity      Expires
  │                    │               │
  ├─────────────────┬──┼──┬─────────────┤
  │  Day 0          │  │  │  Day 6.5    │ Day 7
  └─────────────────┴──┴──┴─────────────┘
  
  login             requests        auto-logout
```

### Session Duration

- **Default**: 7 days (604,800 seconds)
- **Configurable**: Change `SESSION_DURATION` in `src/lib/session.js`
- **Auto-Cleanup**: Expired sessions should be periodically deleted

```javascript
// In src/lib/session.js
const SESSION_DURATION = 7 * 24 * 60 * 60 * 1000; // Milliseconds
```

### Activity Tracking

```javascript
// Every session access updates last_activity
await updateSessionActivity(sessionId);
// Updates: sessions.last_activity = NOW()
```

### Session Validation Criteria

A session is valid if:

```javascript
expires_at > CURRENT_TIMESTAMP  // Not expired
AND
user.status = 'active'          // User account active
AND
session_id exists               // Session exists in DB
```

### Logout (Immediate Invalidation)

```javascript
// Session is deleted from database
await deleteSession(sessionId);

// Future requests with this sessionId will return null:
const session = await getSession(sessionId); // null
```

### Multi-Device Logout

```javascript
// Delete ALL sessions for a user
await deleteAllUserSessions(userId);

// User logged out from all devices/browsers
```

---

## Common Patterns

### Pattern 1: Protected API Route

```javascript
import { requireApiAuth } from '@/lib/api-auth.js';
import { NextResponse } from 'next/server.js';

export async function POST(request) {
  try {
    const user = await requireApiAuth();
    
    const body = await request.json();
    
    // Create record associated with user
    const result = await createAsset({
      ...body,
      userId: user.userId,
      createdBy: user.email,
    });
    
    return NextResponse.json({ success: true, result });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }
    
    console.error('API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### Pattern 2: Admin-Only API Route

```javascript
import { requireApiRole } from '@/lib/api-auth.js';
import { NextResponse } from 'next/server.js';

export async function DELETE(request) {
  try {
    const user = await requireApiRole('FOUNDER');
    
    const { userId } = await request.json();
    
    // Only founders can delete users
    await deleteUser(userId);
    
    return NextResponse.json({ message: 'User deleted' });
  } catch (error) {
    if (error.status === 401) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }
    if (error.status === 403) {
      return NextResponse.json(
        { error: 'Admin access required' },
        { status: 403 }
      );
    }
    throw error;
  }
}
```

### Pattern 3: Protected Page with Layout

```javascript
import { getCurrentUser } from '@/lib/current-user.js';
import { redirect } from 'next/navigation.js';

export default async function DashboardPage() {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  // Load user-specific data
  const assets = await getAssetsByUser(user.id);
  
  return (
    <div>
      <h1>Dashboard</h1>
      <p>Welcome, {user.email}</p>
      {/* Render assets */}
    </div>
  );
}
```

### Pattern 4: Conditional Navigation

```javascript
import { isAuthenticated } from '@/lib/current-user.js';
import Link from 'next/link.js';

export default async function Navigation() {
  const authed = await isAuthenticated();
  
  return (
    <nav>
      {authed ? (
        <>
          <Link href="/dashboard">Dashboard</Link>
          <Link href="/api/auth/logout">Logout</Link>
        </>
      ) : (
        <>
          <Link href="/login">Login</Link>
          <Link href="/register">Register</Link>
        </>
      )}
    </nav>
  );
}
```

### Pattern 5: Client-Side Logout

```javascript
'use client';

export function LogoutButton() {
  const handleLogout = async () => {
    const response = await fetch('/api/auth/logout', {
      method: 'POST',
      credentials: 'include', // Important: send cookies
    });
    
    if (response.ok) {
      // Middleware will redirect to /login
      window.location.href = '/login';
    }
  };
  
  return <button onClick={handleLogout}>Logout</button>;
}
```

### Pattern 6: API Client with Session

```javascript
// Frontend - fetch with credentials (sends cookies automatically)
const response = await fetch('/api/assets', {
  method: 'POST',
  credentials: 'include', // ✅ Important: send jeton_session cookie
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'Asset Name',
    value: 10000,
  }),
});

const result = await response.json();
```

---

## Troubleshooting

### User Immediately Logs Out

**Check:**
1. Is `jeton_session` cookie being set? (DevTools → Application → Cookies)
2. Is session in database? (Query: `SELECT * FROM sessions WHERE user_id = ?`)
3. Has session expired? (Check `expires_at > NOW()`)
4. Is user.status = 'active'? (Check users table)

### Middleware Always Redirects to /login

**Check:**
1. Cookie name is exactly `jeton_session`
2. Session ID exists in database (not expired)
3. Database connection is working
4. Check middleware logs for errors

### CORS Issues with Cookies

**Solution:** Add `credentials: 'include'` to fetch calls:

```javascript
fetch('/api/endpoint', {
  method: 'POST',
  credentials: 'include', // ← Important!
  headers: { 'Content-Type': 'application/json' }
})
```

### Session Not Found in Database

**Check:**
1. Is the migration applied? (`migrations/013_create_sessions.sql`)
2. Run: `SELECT * FROM sessions LIMIT 1`
3. Check if user_id column exists and has correct reference

### Password Comparison Fails

**Check:**
1. Is password hashed with `hashPassword()` before storing?
2. Is `comparePassword()` used for verification?
3. Password field name is `password_hash` (not `password`)

---

## Configuration

### Environment Variables

No special environment variables needed for sessions (unlike JWT which needs JWT_SECRET).

### Cookie Options

Configured in `src/lib/session.js`:

```javascript
export function getSecureCookieOptions() {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 604800, // 7 days in seconds
    path: '/',
  };
}
```

### Session Duration

Change in `src/lib/session.js`:

```javascript
const SESSION_DURATION = 7 * 24 * 60 * 60 * 1000; // Change this

// Example: 30 days
const SESSION_DURATION = 30 * 24 * 60 * 60 * 1000;

// Example: 24 hours
const SESSION_DURATION = 24 * 60 * 60 * 1000;
```

---

## API Summary Table

| Function | File | Purpose | Returns |
|----------|------|---------|---------|
| `createSession(userId)` | `session.js` | Create new session | Session ID |
| `getSession(sessionId)` | `session.js` | Validate session | Session object or null |
| `deleteSession(sessionId)` | `session.js` | Delete session | void |
| `hashPassword(password)` | `auth.js` | Hash password | Hash string |
| `comparePassword(pwd, hash)` | `auth.js` | Verify password | boolean |
| `findUserByEmail(email)` | `auth.js` | Find user | User object or null |
| `findUserById(userId)` | `auth.js` | Find user | User object or null |
| `getCurrentUser()` | `current-user.js` | Get authenticated user | User object or null |
| `getCurrentUserOrThrow()` | `current-user.js` | Get authenticated user | User object (throws if not) |
| `hasRole(role)` | `current-user.js` | Check user role | boolean |
| `isAuthenticated()` | `current-user.js` | Check if logged in | boolean |
| `getApiAuthUser()` | `api-auth.js` | Get user in API | User object or null |
| `requireApiAuth()` | `api-auth.js` | Require auth in API | User object (throws 401) |
| `requireApiRole(role)` | `api-auth.js` | Require role in API | User object (throws 401/403) |

---

## Summary

Jeton's authentication system provides:

✅ **Secure** - HTTP-only cookies, bcrypt passwords, SQL injection prevention  
✅ **Simple** - No complex JWT logic, transparent to client code  
✅ **Revocable** - Sessions can be deleted instantly  
✅ **Scalable** - Works with connection pooling and edge runtimes  
✅ **Developer Friendly** - Clear APIs for server components and API routes  

The system is fully implemented and production-ready.

# Session-Based Authentication - Visual Architecture Guide

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      BROWSER CLIENT                          │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Login Page  │  │  Dashboard   │  │  Protected   │       │
│  │              │  │              │  │  Routes      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                 │                  │               │
│         └─────────────────┼──────────────────┘               │
│                           │                                   │
│                    jeton_session                             │
│                   (httpOnly cookie)                          │
│                                                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Network   │
                    └──────┬──────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   NEXT.JS SERVER                            │
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │              MIDDLEWARE                             │    │
│  │                                                      │    │
│  │  1. Read jeton_session cookie                       │    │
│  │  2. Query sessions table                            │    │
│  │  3. Validate expiry                                 │    │
│  │  4. Check user.status = 'active'                    │    │
│  │  5. Attach user context headers                     │    │
│  │  6. Redirect unauthenticated users                  │    │
│  └────────────────────────────────────────────────────┘    │
│                           │                                   │
│         ┌─────────────────┼─────────────────┐               │
│         │                 │                 │                │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐          │
│  │   Login     │  │   API       │  │  Protected  │          │
│  │   Endpoint  │  │   Routes    │  │  Pages      │          │
│  │             │  │             │  │             │          │
│  │ POST        │  │ Require     │  │ Use         │          │
│  │ /api/auth/  │  │ ApiAuth()   │  │ getCurrentUser()       │
│  │ login       │  │             │  │             │          │
│  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘          │
│        │                │                │                   │
│        └────────────────┼────────────────┘                   │
│                         │                                     │
│              ┌──────────▼──────────┐                         │
│              │  Session Utilities  │                         │
│              │                      │                         │
│              │ • createSession()    │                         │
│              │ • getSession()       │                         │
│              │ • deleteSession()    │                         │
│              │ • requireApiAuth()   │                         │
│              │ • getCurrentUser()   │                         │
│              └──────────┬───────────┘                         │
│                         │                                     │
└─────────────────────────┼─────────────────────────────────┘
                          │
                   ┌──────▼──────┐
                   │   Network   │
                   └──────┬──────┘
                          │
┌─────────────────────────▼──────────────────────────────────┐
│            POSTGRESQL DATABASE (Neon)                       │
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │            SESSIONS TABLE                           │    │
│  ├────────────────────────────────────────────────────┤    │
│  │ id            │ UUID (PRIMARY KEY)                  │    │
│  │ user_id       │ UUID (FOREIGN KEY → users.id)      │    │
│  │ expires_at    │ TIMESTAMP (indexed)                │    │
│  │ created_at    │ TIMESTAMP (indexed)                │    │
│  │ last_activity │ TIMESTAMP                          │    │
│  └────────────────────────────────────────────────────┘    │
│                         │                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │            USERS TABLE                              │    │
│  ├────────────────────────────────────────────────────┤    │
│  │ id              │ UUID (PRIMARY KEY)               │    │
│  │ email           │ TEXT (UNIQUE)                    │    │
│  │ password_hash   │ TEXT (bcrypt)                    │    │
│  │ role            │ TEXT (FOUNDER, FINANCE, etc)     │    │
│  │ status          │ TEXT ('active', 'suspended')     │    │
│  │ created_at      │ TIMESTAMP                        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## Authentication Flow Sequences

### LOGIN FLOW
```
User                   Client              Server              Database
  │                      │                    │                    │
  ├─ clicks login ───────►│                    │                    │
  │                       │                    │                    │
  ├─ enters email/pwd ───►│                    │                    │
  │                       │                    │                    │
  │                       ├─ POST /auth/login─►│                    │
  │                       │   {email, pwd}     │                    │
  │                       │                    ├─ verify password──►│
  │                       │                    │◄─ user found       │
  │                       │                    │                    │
  │                       │                    ├─ createSession()──►│
  │                       │                    │◄─ sessionId        │
  │                       │                    │                    │
  │                       │◄─ 200 OK ────────┤                    │
  │                       │ Set-Cookie:       │                    │
  │                       │ jeton_session=ID  │                    │
  │                       │                    │                    │
  │◄─ redirect /dash ─────│                    │                    │
  │                       │                    │                    │
  ├─ GET /dashboard ─────►│                    │                    │
  │                       ├─ with cookie ────►│                    │
  │                       │ jeton_session=ID  ├─ Middleware:      │
  │                       │                    ├─ validate session►│
  │                       │                    │◄─ session valid    │
  │                       │                    │                    │
  │                       │◄─ 200 OK ────────┤                    │
  │                       │ [dashboard HTML]  │                    │
  │                       │                    │                    │
  │◄─ render dashboard ──►│                    │                    │
```

### LOGOUT FLOW
```
User                   Client              Server              Database
  │                      │                    │                    │
  ├─ clicks logout ──────►│                    │                    │
  │                       │                    │                    │
  │                       ├─ POST /auth/logout │                    │
  │                       │ with cookie ──────►│                    │
  │                       │ jeton_session=ID  │                    │
  │                       │                    ├─ deleteSession(ID)►│
  │                       │                    │◄─ deleted          │
  │                       │                    │                    │
  │                       │◄─ 200 OK ────────┤                    │
  │                       │ Set-Cookie:       │                    │
  │                       │ jeton_session=   │                    │
  │                       │ (maxAge=0)        │                    │
  │                       │                    │                    │
  │◄─ redirect /login ───│                    │                    │
  │                       │                    │                    │
  ├─ GET /dashboard ─────►│                    │                    │
  │                       ├─ with cookie ────►│                    │
  │                       │ (empty)            ├─ Middleware:      │
  │                       │                    ├─ no session ──────►│
  │                       │                    │                    │
  │                       │◄─ 302 /login ────┤                    │
  │                       │                    │                    │
  │◄─ redirect /login ───│                    │                    │
```

### PROTECTED ROUTE ACCESS
```
User                   Client              Server              Database
  │                      │                    │                    │
  ├─ navigates ──────────►│                    │                    │
  │ to /dashboard         │                    │                    │
  │                       │                    │                    │
  │                       ├─ GET /dashboard ──►│                    │
  │                       │ with cookie        │                    │
  │                       │ jeton_session=ID  │                    │
  │                       │                    │                    │
  │                       │                    ├─ Middleware:      │
  │                       │                    │ ┌──────────────┐  │
  │                       │                    │ │ 1. Read      │  │
  │                       │                    │ │    cookie    │  │
  │                       │                    │ │ 2. Query     │  │
  │                       │                    │ │    sessions ─┼──┼──►│
  │                       │                    │ │    table     │  │   │
  │                       │                    │ │ 3. Validate  │  │   │
  │                       │                    │ │    expiry    │  │◄──┼─ session found
  │                       │                    │ │ 4. Check     │  │   │
  │                       │                    │ │    status    │  │   │
  │                       │                    │ │ 5. Attach    │  │   │
  │                       │                    │ │    headers   │  │   │
  │                       │                    │ └──────────────┘  │   │
  │                       │                    │                    │   │
  │                       │                    ├─ getCurrentUser()──┼───┤
  │                       │                    │◄─ user object     │   │
  │                       │                    │                    │   │
  │                       │◄─ 200 + HTML ────┤                    │   │
  │                       │ [Dashboard Page]   │                    │   │
  │                       │                    │                    │   │
  │◄─ render page ───────│                    │                    │   │
```

### SESSION EXPIRY
```
Old Session (> 7 days)  Client              Server              Database
  │                      │                    │                    │
  │ (User comes back)    │                    │                    │
  │                      │                    │                    │
  │                      ├─ GET /dashboard ──►│                    │
  │                      │ with old cookie    │                    │
  │                      │ jeton_session=OLD │                    │
  │                      │                    ├─ Query:           │
  │                      │                    │ expires_at >      │
  │                      │                    │ CURRENT_TIMESTAMP │
  │                      │                    │ ───────────────── │
  │                      │                    │ (no rows returned)│
  │                      │                    │                   │
  │                      │◄─ 302 /login ────┤                    │
  │                      │                    │                    │
  │◄─ redirect /login ──│                    │                    │
  │                      │                    │                    │
  ├─ re-login required ─►│                    │                    │
```

---

## Data Structures

### Session Table
```sql
sessions {
  id:            UUID              -- Unique session ID (httpOnly cookie value)
  user_id:       UUID              -- Foreign key to users table
  expires_at:    TIMESTAMP         -- Auto-invalidates after 7 days
  created_at:    TIMESTAMP         -- When session was created
  last_activity: TIMESTAMP         -- Track idle time (optional)
}
```

### User Object in Session
```javascript
{
  userId:   UUID,
  email:    string,
  role:     'FOUNDER' | 'FINANCE' | 'SALES' | 'VIEWER',
  status:   'active' | 'suspended'
}
```

### Cookie Header
```
Set-Cookie: jeton_session=550e8400-e29b-41d4-a716-446655440000; 
            HttpOnly; 
            Secure; 
            SameSite=Lax; 
            Path=/; 
            Max-Age=604800
```

---

## Code Flow Diagrams

### LOGIN ENDPOINT CODE FLOW
```
POST /api/auth/login
│
├─ Validate input
│  └─ email & password required
│
├─ verifyCredentials(email, password)
│  ├─ Find user by email
│  ├─ Compare password with hash (bcrypt)
│  └─ Return user or null
│
├─ If no user: return 401
│
├─ updateUserLastLogin(user.id)
│
├─ createSession(user.id)
│  ├─ Generate UUID
│  ├─ Set expires_at = now + 7 days
│  ├─ INSERT into sessions table
│  └─ Return sessionId
│
├─ logAuthEvent('LOGIN_SUCCESS', user.id)
│
├─ Create response
│  ├─ Status 200
│  ├─ Body: { message: 'Logged in successfully' }
│  └─ Set-Cookie: jeton_session=<sessionId>
│
└─ Return response
```

### MIDDLEWARE CODE FLOW
```
Incoming Request
│
├─ Get jeton_session from cookie
│
├─ If no session:
│  └─ Check if route is public (login, register, etc)
│     ├─ If public: allow
│     └─ If protected: redirect to /login
│
├─ validateSession(sessionId)
│  ├─ Query: SELECT ... FROM sessions s
│  │         JOIN users u ON s.user_id = u.id
│  │         WHERE s.id = ? AND expires_at > NOW()
│  │         AND u.status = 'active'
│  │
│  └─ Return session or null
│
├─ If invalid session:
│  └─ Redirect to /login
│
├─ If valid session:
│  ├─ Check route requires specific role
│  │  └─ If role mismatch: redirect to /login
│  │
│  ├─ Attach headers to request:
│  │  ├─ x-user-id
│  │  ├─ x-user-email
│  │  └─ x-user-role
│  │
│  └─ Allow request to proceed
│
└─ Next middleware / handler
```

### API ROUTE PROTECTION FLOW
```
export async function GET(request) {
│
├─ try {
│  │
│  ├─ const user = await requireApiAuth()
│  │  │
│  │  ├─ Read jeton_session cookie
│  │  ├─ Query database
│  │  ├─ Validate expiry
│  │  ├─ If valid: return { userId, email, role }
│  │  └─ If invalid: throw NextResponse.json(401)
│  │
│  ├─ Now user is guaranteed valid
│  │
│  ├─ const data = ... (API logic)
│  │
│  └─ return NextResponse.json(data)
│
├─ } catch (error) {
│  │
│  ├─ if (error instanceof Response) {
│  │  └─ return error  // 401 from requireApiAuth
│  │
│  └─ else {
│     └─ return 500 Internal Server Error
│
└─ }
```

### GET CURRENT USER FLOW
```
import { getCurrentUser } from '@/lib/current-user.js'

export default async function Dashboard() {
│
├─ const user = await getCurrentUser()
│  │
│  ├─ Get cookies (server-side)
│  ├─ Read jeton_session cookie
│  ├─ Query sessions + users table
│  ├─ If valid: return { id, email, role, status, ... }
│  └─ If invalid: return null
│
├─ if (!user) {
│  └─ redirect('/login')
│
└─ Render authenticated content
```

---

## Comparison: JWT vs Sessions

### JWT Flow
```
Login
  ↓
Sign JWT with secret
  ↓
Return JWT to client
  ↓
Store in httpOnly cookie
  ↓
Each request: decode JWT and verify signature
  ↓
(Can't invalidate until expiry)
```

### Session Flow
```
Login
  ↓
Create session in database
  ↓
Return session ID to client
  ↓
Store ID in httpOnly cookie
  ↓
Each request: look up session in database
  ↓
(Can invalidate immediately)
```

---

## Security Layers

```
┌──────────────────────────────────┐
│ 1. HTTPS/TLS                      │
│    (Secure in production)         │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 2. HttpOnly Cookie               │
│    (JavaScript can't access)      │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 3. SameSite=Lax                   │
│    (CSRF protection)              │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 4. Session ID Validation          │
│    (Check database)               │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 5. User Status Check              │
│    (Must be active)               │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 6. Session Expiry Check           │
│    (Time-bound validity)          │
└──────────────────────────────────┘
                ↓
┌──────────────────────────────────┐
│ 7. Role-Based Access Control      │
│    (Route-level permissions)      │
└──────────────────────────────────┘
```

---

## Performance Optimization

```
Request Timeline:

0ms   ├─ Browser sends cookie
      │
5ms   ├─ Server receives request
      │
10ms  ├─ Get cookie from request
      │
15ms  ├─ Query database (indexed lookup)
      │
25ms  ├─ Validate session
      │  ├─ Check expiry
      │  └─ Check user status
      │
30ms  ├─ Attach headers to request
      │
35ms  ├─ Handler executes
      │  ├─ API logic / page render
      │  └─ (additional queries as needed)
      │
100ms ├─ Response ready
      │
105ms └─ Browser receives response
```

**Key Optimizations:**
- Single indexed query for session validation
- Header attachement avoids repeated lookups
- Connection pooling reduces overhead
- Cached user context in request

---

## Deployment Architecture

```
┌────────────────────────────────────┐
│         Vercel Edge Network        │
│  (Global, low-latency)             │
├────────────────────────────────────┤
│  Next.js App Router                │
│  • Middleware (Session Validation) │
│  • API Routes (Session Protected)  │
│  • Pages/Layouts (Auth Utilities)  │
└────────────────┬───────────────────┘
                 │
                 │ HTTPS
                 │
┌────────────────▼───────────────────┐
│     PostgreSQL (Neon/Cloud)        │
│  • Users Table                     │
│  • Sessions Table                  │
│  • Audit Logs                      │
│  (High availability, backup)       │
└────────────────────────────────────┘
```

---

## This Is Your New Architecture 🎉

All the diagrams above represent your new session-based authentication system. It's:
- ✅ **Secure** - Database-backed, can't forge sessions
- ✅ **Scalable** - Works with serverless
- ✅ **Maintainable** - No shared secrets
- ✅ **Simple** - Clear flow, easy to understand
- ✅ **Vercel-Ready** - Compatible with edge runtime

Ready for production! 🚀

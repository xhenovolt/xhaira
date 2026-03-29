# 🟦 PHASE 5 — AUTH FLOW VALIDATION

## PHASE 4 COMPLETION ✅

**Successfully Created 5 Missing Tables:**
- ✅ user_presence (8 columns) - Tracks active users
- ✅ permissions (7 columns) - RBAC permission definitions
- ✅ role_permissions (4 columns) - Role-permission mappings
- ✅ staff_roles (5 columns) - Staff member role assignments
- ✅ approval_requests (8 columns) - Request/approval workflow

**Code Fixes Applied:**
- ✅ Updated /api/presence/ping to return 200 even when table missing (no 401 spam)
- ✅ Added graceful degradation for unauthenticated presence pings
- ✅ Added table-not-exists error handling (code 42P01)

**Database State After Phase 4:**
```
Database: xhaira (Neon PostgreSQL)
Tables: 18 total
  - Core auth: users, roles, sessions, user_roles, staff
  - New RBAC: permissions, role_permissions, staff_roles
  - Tracking: user_presence, audit_logs
  - Business: accounts, clients, deals, budgets, expenses, followups, transfers, payments, prospects, prospect_contacts, offerings, ledger
```

---

## PHASE 5 PLAN: VALIDATE AUTH FLOW

### 5.1 AUTH ROUTE STRUCTURE

**Routes to Validate:**
1. `POST /api/auth/register` - Create first SUPER_ADMIN user
2. `POST /api/auth/login` - Authenticate with credentials
3. `GET /api/auth/me` - Get authenticated user with RBAC
4. `POST /api/presence/ping` - Track user presence (already fixed)

### 5.2 REGISTER FLOW VALIDATION

**Expected Behavior:**
```
POST /api/auth/register
Input:  { email, password }
Steps:
  1. Validate input (email format, password strength)
  2. Check user doesn't exist
  3. Hash password with bcryptjs
  4. Check if first user (getUserCount === 0)
  5. If first user:
     a. Create user with role: 'SUPER_ADMIN'
     b. Call initializeBaseRoles() → Create 5 base roles
     c. Create session
     d. Set HTTP-only cookie
     e. Log auth event
     f. Return 200 + user data
  6. If not first user:
     a. Return 410 Gone (registration closed)
Output: { user: {...}, session: {...} } or 410
```

**Tables Involved:**
- users (INSERT) - New user record
- roles (SELECT/INSERT) - Base roles creation
- sessions (INSERT) - New session
- audit_logs (INSERT) - Auth event log

### 5.3 LOGIN FLOW VALIDATION

**Expected Behavior:**
```
POST /api/auth/login
Input:  { email, password }
Steps:
  1. Validate input
  2. Find user by email
  3. Compare password (bcryptjs)
  4. Parse user agent (device, OS, browser)
  5. Create session with device info
  6. Set HTTP-only cookie + security headers
  7. Log auth event
  8. Return 200 + user data
Output: { user: {...}, session: {...} }
```

**Tables Involved:**
- users (SELECT) - Find user
- sessions (INSERT) - Create session with device tracking
- audit_logs (INSERT) - Auth event log

### 5.4 /ME ROUTE VALIDATION

**Expected Behavior:**
```
GET /api/auth/me
Headers: Cookie: [session_token]
Steps:
  1. Get session token from cookie
  2. Validate session (not expired, not revoked)
  3. Get user from users table
  4. Get role from users.role (basic)
  5. Try to get RBAC roles from staff_roles + role_permissions (optional)
  6. Build user response with authority level
Output: { id, email, name, role, permissions: [...], rbacRoles: [...] }
```

**Tables Involved:**
- sessions (SELECT) - Validate session
- users (SELECT) - Get user
- staff_roles (LEFT JOIN) - Get staff roles (optional)
- role_permissions (LEFT JOIN) - Get permissions (optional)

### 5.5 VALIDATION CHECKS

**For Each Route:**

| Check | Expected | Evidence |
|-------|----------|----------|
| **Register** |  |  |
| Route exists | `/api/auth/register` POST | File exists |
| Input validation | Rejects empty email | Test case |
| Duplicate check | Rejects existing email | Test case |
| First user → SUPER_ADMIN | First user gets superadmin role | DB query |
| Base roles created | 5 roles in DB | DB query |
| Session created | Session in DB | DB query |
| HTTP-only cookie | Cookie flag set | Headers |
| Audit logged | Entry in audit_logs | DB query |
| **Login** |  |  |
| Route exists | `/api/auth/login` POST | File exists |
| Credential validation | Password check works | pwd test |
| Device parsing | Browser/OS extracted | Headers check |
| Session created | Session with device_name | DB query |
| Cookie refresh | Valid cookie returned | Headers |
| **Me Route** |  |  |
| Route exists | `/api/auth/me` GET | File exists |
| Session validation | Reads session cookie | Cookie test |
| User loading | Returns user data | Response test |
| Role loading | Returns role | Response test |
| RBAC degradation | Works even if staff_roles empty | Code review |

---

## PHASE 5 EXECUTION

### 5.5.1 Check Route Files Exist

```bash
ls -la src/app/api/auth/*/route.js
```

Expected: 3 files
- register/route.js
- login/route.js  
- me/route.js

### 5.5.2 Run Auth Flow Test

Create test script: `test-auth-complete-flow.mjs`

```javascript
// Test sequence:
POST /register
  → Get user + session
POST /login
  → Get user + session
GET /me
  → Verify user data
POST /presence/ping
  → Verify tracking
```

### 5.5.3 Database Verification

```sql
-- Check user created
SELECT id, email, role FROM users WHERE email = 'test@example.com';

-- Check roles initialized
SELECT id, name FROM roles ORDER BY created_at;

-- Check session created
SELECT id, user_id, token FROM sessions ORDER BY created_at DESC LIMIT 1;

-- Check audit log
SELECT action, entity_type FROM audit_logs ORDER BY created_at DESC LIMIT 5;

-- Check presence (if table has data)
SELECT user_id, is_online FROM user_presence;
```

---

## SUCCESS CRITERIA

Phase 5 is COMPLETE when:

✅ All 3 auth routes exist and are properly exported
✅ Register flow creates SUPER_ADMIN for first user
✅ Login flow creates sessions with device tracking
✅ /me route returns user with roles and permissions
✅ Presence ping returns 200 even when unauthenticated
✅ All routes log audit events
✅ No 401 spam from presence ping
✅ RBAC tables gracefully degrade (optional RBAC works)

---

## NEXT PHASE

After validation: **Phase 6 — End-to-End Testing**
- Create fresh test user
- Full registration → login → auth/me → presence flow
- Verify database state after each step
- Check audit logs for all events
- Verify cookies work correctly


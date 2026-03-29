# SYSTEM ACCESS & IDENTITY CONTROL MODULE - TEST SCENARIOS

**Date:** March 29, 2026  
**Module Status:** IMPLEMENTATION COMPLETE & READY FOR TESTING  
**System State:** Fresh (0 users, 0 roles)

---

## TEST SCENARIO 1: FRESH SYSTEM - FIRST USER REGISTRATION

### Setup
- System state: NOT INITIALIZED (0 users)
- Database: Empty roles table
- Action: User attempts to register

### Steps

```bash
1. Browser → http://localhost:3000/register
2. See: "System Registration Open" message
3. Form shows: Email, Password, Name fields
4. Enter:
   - Email: admin@xhaira.app
   - Name: System Admin
   - Password: Admin12345 (8+ chars)
5. POST /api/auth/register
```

### Expected Behavior

✅ **Registration succeeds** (201 Created)
- User created in database
- Role automatically set to `superadmin`
- Status automatically set to `active`
- Base roles initialized:
  - superadmin (id: role_superadmin)
  - admin (id: role_admin)
  - staff (id: role_staff)
- Session created (xhaira_session cookie)
- User redirected to /app/dashboard
- Audit log: REGISTER_SUCCESS_FIRST_USER

### Verification

```bash
# Check database
psql '<DATABASE_URL>' -c "SELECT COUNT(*) FROM users;"
# Expected: 1 user

psql '<DATABASE_URL>' -c "SELECT email, role, status FROM users;"
# Expected: admin@xhaira.app | superadmin | active

psql '<DATABASE_URL>' -c "SELECT id, name FROM roles;"
# Expected: 3 roles (superadmin, admin, staff)

psql '<DATABASE_URL>' -c "SELECT action, user_id FROM audit_logs WHERE action LIKE '%REGISTER%' ORDER BY created_at DESC LIMIT 1;"
# Expected: REGISTER_SUCCESS_FIRST_USER | <user_id>
```

---

## TEST SCENARIO 2: SECOND USER REGISTRATION (BLOCKED)

### Setup
- System state: INITIALIZED (1 user exists)
- Previous: Admin user created successfully
- Action: Another user attempts to register

### Steps

```bash
1. Browser → http://localhost:3000/register
2. System checks: isSystemInitialized()
3. Result: true (users exist)
```

### Expected Behavior

✅ **Registration blocked** (410 Gone)
- Page displays: "Registration Closed"
- Message: "Xhaira registration is only available during initial setup"
- Shows: "Contact admin@xhaira.app"
- Auto-redirect to /login after 2 seconds
- Audit log: REGISTER_BLOCKED_SYSTEM_INITIALIZED

### Verification

```bash
# Try to register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user2@xhaira.app",
    "password": "Password123",
    "name": "User Two"
  }'

# Expected response:
{
  "error": "System registration is closed.",
  "message": "Xhaira registration is only available during initial setup..."
}

# HTTP Status: 410 Gone

# Check audit log
psql '<DATABASE_URL>' -c "SELECT action FROM audit_logs WHERE action = 'REGISTER_BLOCKED_SYSTEM_INITIALIZED';"
# Expected: At least one entry
```

---

## TEST SCENARIO 3: ADMIN CREATES NEW USER (SUCCESS)

### Setup
- System: INITIALIZED (admin user exists)
- Admin logged in and viewing /app/admin/users
- Action: Admin creates new staff member

### Steps

```bash
1. Admin navigates to /app/admin/users
2. See: User management interface with "Create User" button
3. Click: "Create User" button
4. Modal appears with form:
   - Name: John Doe
   - Email: john@xhaira.app
   - Temporary Password: TempPass12345
   - Role: Staff (dropdown)
5. Click: "Create User" button in modal
6. POST /api/admin/users/create
```

### Expected Behavior

✅ **User created successfully** (201 Created)
- Response includes new user data
- Email: john@xhaira.app
- Role: staff (not superadmin/admin)
- Status: active (immediately accessible)
- Toast notification: "User john@xhaira.app created successfully"
- Modal closes
- User list refreshes showing new user
- Audit log: USER_CREATE_SUCCESS with creator_id

### Verification

```bash
# Check user in database
psql '<DATABASE_URL>' -c "SELECT email, role, status FROM users WHERE email = 'john@xhaira.app';"
# Expected: john@xhaira.app | staff | active

# Check audit log
psql '<DATABASE_URL>' -c "SELECT action, email FROM audit_logs WHERE action = 'USER_CREATE_SUCCESS';"
# Expected: USER_CREATE_SUCCESS | john@xhaira.app

# Verify user can login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@xhaira.app",
    "password": "TempPass12345"
  }'
# Expected: 200 OK with session token
```

---

## TEST SCENARIO 4: ADMIN CREATES ADMIN USER

### Setup
- System: INITIALIZED
- SUPER_ADMIN logged in at /app/admin/users
- Action: Create another admin user

### Steps

```bash
1. Click: "Create User" button
2. Form:
   - Name: Second Admin
   - Email: admin2@xhaira.app
   - Password: AdminPass123
   - Role: Administrator (dropdown)
3. Click: "Create User"
4. POST /api/admin/users/create with role='admin'
```

### Expected Behavior

✅ **Admin user created** (201 Created)
- New admin has full user management permissions
- Status: active
- Can view /app/admin/users (sees users)
- Can create staff users
- CANNOT create other admin users (only SUPER_ADMIN can)

### Verification

```bash
# Verify user created as admin
psql '<DATABASE_URL>' -c "SELECT email, role FROM users WHERE email = 'admin2@xhaira.app';"
# Expected: admin2@xhaira.app | admin

# Login as new admin
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin2@xhaira.app",
    "password": "AdminPass123"
  }'
# Expected: 200 OK

# Try to create another admin (should fail)
curl -X POST http://localhost:3000/api/admin/users/create \
  -H "Content-Type: application/json" \
  -H "Cookie: xhaira_session=<admin2_token>" \
  -d '{
    "email": "admin3@xhaira.app",
    "password": "Pass123",
    "name": "Admin Three",
    "role": "admin"
  }'
# Expected: 403 Forbidden
# Message: "Only superadmin can create admin users"
```

---

## TEST SCENARIO 5: STAFF USER TRIES TO CREATE USERS (BLOCKED)

### Setup
- System: INITIALIZED
- Staff user (john@xhaira.app) logged in
- Action: Try to access /app/admin/users

### Steps

```bash
1. Staff user navigates to /app/admin/users URL directly
2. Browser checks: is route accessible?
3. RoutePermissionGuard checks: hasPermission('users.view')?
4. Result: User not admin, check fails
```

### Expected Behavior

✅ **Access blocked** (403 Forbidden)
- Page doesn't load
- Redirected to /app/dashboard (or error page)
- Or: Menu item hidden from sidebar
- No "Admin" section visible in sidebar for staff user
- Attempting API call directly returns 403

### Verification

```bash
# Login as staff user
STAFF_SESSION="<session_cookie_from_login>"

# Try to access users list
curl -X GET http://localhost:3000/api/admin/users \
  -H "Cookie: xhaira_session=$STAFF_SESSION"
# Expected: 403 Forbidden
# Message: Permission denied

# Verify sidebar doesn't show Admin section
curl http://localhost:3000/app/admin/users \
  -H "Cookie: xhaira_session=$STAFF_SESSION"
# Expected: 403 or redirect response
```

---

## TEST SCENARIO 6: UNAUTHORIZED USER (NO SESSION) - BLOCKED

### Setup
- No authentication
- User tries to access /app/admin/users without logging in

### Steps

```bash
1. Browser → http://localhost:3000/app/admin/users (not logged in)
2. Middleware checks: getSession() from cookies
3. Result: No xhaira_session cookie found
```

### Expected Behavior

✅ **Redirected to login** (302 Found)
- User redirected to /login
- Message: "Please log in to continue"
- Cannot access any /app/* routes without session

### Verification

```bash
# Try to access admin route without session
curl -L http://localhost:3000/app/admin/users
# Expected: Redirect to /login
# Status: 302 Found

# Try API without session
curl http://localhost:3000/api/admin/users
# Expected: 400/401 Unauthorized
# Message: "Session required"
```

---

## TEST SCENARIO 7: SESSION EXPIRY - RE-AUTHENTICATION

### Setup
- User logged in (has valid xhaira_session cookie)
- Session expires or cookie becomes invalid
- User tries to access protected route

### Steps

```bash
1. Session cookie expires (TTL exceeded)
2. User navigates to /app/dashboard
3. Middleware checks: verifySession()
4. Result: Session invalid/expired
```

### Expected Behavior

✅ **Redirected to login** (302)
- User logged out
- Redirected to /login
- Must authenticate again
- Next session is new

### Verification

```bash
# Login normally
SESSION="<valid_session>"

# Wait for session to expire or manually delete cookie
# Try to use expired session
curl http://localhost:3000/app/dashboard \
  -H "Cookie: xhaira_session=$SESSION"
# Expected: Redirect to /login
```

---

## TEST SCENARIO 8: ADMIN VIEWS USER LIST

### Setup
- Admin user logged in
- Viewing /app/admin/users page

### Steps

```bash
1. Admin navigates to /app/admin/users
2. Page loads: User list interface
3. See: Table of all users with columns:
   - Email
   - Name
   - Role
   - Status
   - Created date
4. See: "Create User" button at top
5. See: Action buttons (Edit, Deactivate, Delete)
```

### Expected Behavior

✅ **User list displays correctly** (200 OK)
- All users in system visible
- Includes:
  - admin@xhaira.app (superadmin)
  - john@xhaira.app (staff)
  - admin2@xhaira.app (admin)
- Sorted by: created_at DESC (newest first)
- No sensitive data exposed (passwords not shown)

### Verification

```bash
# API call to get users
curl -X GET http://localhost:3000/api/admin/users \
  -H "Cookie: xhaira_session=$ADMIN_SESSION"
# Expected: 200 OK

# Response includes:
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "email": "admin@xhaira.app",
      "name": "System Admin",
      "role": "superadmin",
      "status": "active",
      "created_at": "2026-03-29T15:30:00Z"
    },
    // ... more users
  ]
}
```

---

## TEST SCENARIO 9: SIDEBAR PERMISSION FILTERING

### Setup
- Multiple users with different roles
- Each user checks sidebar visibility

### Steps - SUPER_ADMIN

```bash
1. SUPER_ADMIN logs in
2. Sidebar loads
3. User sees sections:
   - Dashboard ✓
   - Pipeline ✓
   - Deals ✓
   - Finance ✓
   - Admin (VISIBLE) ✓
     - Users ✓
     - Roles ✓
     - Permission Manager ✓
     - etc.
```

### Steps - STAFF USER

```bash
1. Staff user logs in
2. Sidebar loads
3. User sees sections:
   - Dashboard ✓
   - Pipeline ✓
   - Deals ✓
   - Finance ✓
   - Admin (HIDDEN) ✗
     - (All items hidden)
4. If user tries /app/admin/users directly:
   - 403 Forbidden
```

### Expected Behavior

✅ **Sidebar correctly filtered by role**
- Menu items shown/hidden based on user.role
- SUPER_ADMIN sees all sections
- ADMIN sees limited admin features
- STAFF sees no admin section
- No privileged information in HTML for staff users

### Verification

```bash
# Check navbar renders with proper items
# Login as SUPER_ADMIN, check browser console:
console.log(document.querySelector('[data-section="Admin"]'))
// Expected: <div data-section="Admin"> visible

# Login as STAFF user, check:
console.log(document.querySelector('[data-section="Admin"]'))
// Expected: null or hidden element
```

---

## TEST SCENARIO 10: CREATE USER VALIDATION FAILURES

### Setup
- Admin at user creation modal
- Entering invalid data

### Steps

**Test 1: Missing fields**
```bash
- Name: (empty)
- Email: test@xhaira.app
- Password: Pass123
- Click: "Create User"
# Expected: Error "All fields are required"
```

**Test 2: Weak password**
```bash
- Name: User
- Email: test@xhaira.app
- Password: 1234567 (7 chars, less than 8)
- Click: "Create User"
# Expected: Error "Password must be at least 8 characters"
```

**Test 3: Invalid email**
```bash
- Name: User
- Email: notanemail
- Password: Pass123
- Click: "Create User"
# Expected: Error "Invalid email address"
```

**Test 4: Duplicate email**
```bash
- Name: Another User
- Email: admin@xhaira.app (already exists)
- Password: Pass123
- Click: "Create User"
# Expected: 409 Conflict
# Message: "Email already registered"
```

### Expected Behavior

✅ **All validations work correctly**
- Frontend validation on submit
- Server-side validation on API
- Clear error messages displayed
- Modal stays open for correction
- Audit logged as failure

---

## QUICK TEST CHECKLIST

Run these in order:

```
[ ] 1. Navigate to /register
    [ ] See: "System Registration Open"
    [ ] Create first user: admin@xhaira.app / Admin123
    [ ] Redirected to dashboard
    [ ] Check DB: 1 user with role=superadmin

[ ] 2. Log out, go to /register
    [ ] See: "Registration Closed" message
    [ ] Auto-redirects to /login in 2 sec

[ ] 3. Log in as admin
    [ ] Navigate to /app/admin/users
    [ ] See: User list with 1 user

[ ] 4. Click "Create User"
    [ ] Create: john@xhaira.app (staff)
    [ ] See: Success toast
    [ ] New user appears in list

[ ] 5. Log out, log in as john
    [ ] Cannot see /app/admin/users
    [ ] No Admin section in sidebar

[ ] 6. Log in as admin, delete user
    [ ] Delete john@xhaira.app
    [ ] John can no longer login

[ ] 7. Create admin user
    [ ] Email: admin2@xhaira.app
    [ ] Role: Administrator
    [ ] Login as admin2
    [ ] Can create staff users
    [ ] Cannot create other admins

[ ] 8. Test validation
    [ ] Try to create user with missing fields
    [ ] Try weak password (< 8 chars)
    [ ] Try duplicate email
    [ ] All blocked with clear errors

[ ] 9. Check audit logs
    [ ] Navigate to /app/admin/audit-logs
    [ ] See: All user creations, deletions, logins

[ ] 10. Test unauthorized access
    [ ] Try /app/admin/users as staff (should fail)
    [ ] Try /api/admin/users without auth (401)
    [ ] Try /api/admin/users with staff perms (403)
```

---

## IMPLEMENTATION VERIFICATION

After running all tests, verify:

**Database State**
```bash
SELECT COUNT(*) FROM users;              # Should have created users
SELECT COUNT(*) FROM roles;              # Should have 3+ roles  
SELECT * FROM audit_logs LIMIT 10;       # Should have logs for all actions
```

**Code Coverage**
```bash
grep -r "isSystemInitialized" src/       # Should find 3+ references
grep -r "requirePermission" src/app/api/ # Should find on all admin routes
grep -r "User Management" src/           # Should find in navigation-config
```

**Security Checklist**
- [ ] Registration blocked after first user
- [ ] First user is superadmin (verified in DB)
- [ ] Non-admin users cannot access /app/admin/*
- [ ] API returns 403 for unauthorized requests
- [ ] All user creations are audit logged
- [ ] Passwords are hashed (never stored plaintext)
- [ ] Session tokens are httpOnly cookies

---

## DEPLOYMENT READINESS

After all tests pass:

1. ✅ Code review: Check all new files for security
2. ✅ Database backups: Verify schema imported correctly
3. ✅ Performance: Test with 100+ users in admin list
4. ✅ Load: Test concurrent registrations (should allow 1)
5. ✅ Refresh: Verify session persistence across page reloads
6. ✅ Mobile: Test admin UI on mobile (Create User button)
7. ✅ Localization: Check error messages display correctly

---

**Module Status:** ✅ READY FOR TESTING  
**Next Phase:** Run test scenarios 1-10 in order  
**Success Criteria:** All 10 scenarios pass without modification  
**Contact:** Database logs visible at /app/admin/audit-logs

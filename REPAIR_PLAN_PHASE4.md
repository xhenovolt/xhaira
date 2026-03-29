# 🟠 PHASE 4 — AUTO-REPAIR PLAN

## CURRENT STATE

**Good News:** The previous phase successfully applied migrate_xhaira_schema.sql

**Current Database Has:**
- ✅ users table with all required columns (username, staff_id, must_reset_password, authority_level, hierarchy_level, first_login_completed, is_online, session_id, last_seen_at)
- ✅ sessions table with last_activity column
- ✅ roles table with all columns
- ✅ staff table
- ✅ user_roles table
- ✅ accounts, clients, deals tables
- ✅ audit_logs table (empty, ready for logs)

**Missing/To Create:**
1. ❌ user_presence TABLE (referenced in /api/presence/ping)
2. ❌ staff_roles TABLE (referenced in /api/auth/me)
3. ❌ approval_requests TABLE (referenced in /api/auth/me)
4. ❌ permissions TABLE (referenced in /lib/permissions.js)

---

## REPAIR FIXES REQUIRED

### FIX 1: Create user_presence TABLE

**File To Create:** `migrations/user_presence_table.sql`

```sql
CREATE TABLE IF NOT EXISTS public.user_presence (
    user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    last_ping timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_seen timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'online' CHECK (status IN ('online', 'idle', 'offline')),
    is_online boolean DEFAULT true,
    current_route varchar(255),
    current_page_title varchar(255),
    device_info jsonb,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_presence_last_ping ON user_presence(last_ping DESC);
CREATE INDEX IF NOT EXISTS idx_user_presence_is_online ON user_presence(is_online);
CREATE INDEX IF NOT EXISTS idx_user_presence_status ON user_presence(status);
```

### FIX 2: Create staff_roles TABLE

```sql
CREATE TABLE IF NOT EXISTS public.staff_roles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id uuid NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_by uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_staff_role UNIQUE (staff_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_staff_roles_staff_id ON staff_roles(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_roles_role_id ON staff_roles(role_id);
```

### FIX 3: Create permissions TABLE

```sql
CREATE TABLE IF NOT EXISTS public.permissions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name varchar(255) NOT NULL UNIQUE,
    module varchar(100) NOT NULL,
    action varchar(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_module_action UNIQUE (module, action)
);

CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module);
CREATE INDEX IF NOT EXISTS idx_permissions_action ON permissions(action);
```

### FIX 4: Create role_permissions TABLE

```sql
CREATE TABLE IF NOT EXISTS public.role_permissions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);
```

### FIX 5: Create approval_requests TABLE (Optional, for future use)

```sql
CREATE TABLE IF NOT EXISTS public.approval_requests (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_type varchar(100) NOT NULL,
    requested_by uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    approver_id uuid REFERENCES users(id) ON DELETE SET NULL,
    status varchar(30) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    details jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_requested_by ON approval_requests(requested_by);
```

### FIX 6: Wrap user_presence calls with error handling

**File:** `/src/app/api/presence/ping/route.js`

Currently tries to insert into user_presence unconditionally. Need to add try-catch:

```javascript
try {
  await query(
    `INSERT INTO user_presence (...)
     VALUES (...)
     ON CONFLICT (user_id) DO UPDATE SET ...`,
    [...]
  );
} catch (err) {
  if (err.code === '42P01') { // relation does not exist
    console.error('user_presence table missing (non-blocking)', err);
    // Continue - presence tracking optional
  } else {
    console.error('Presence update failed:', err);
    throw err;
  }
}
```

### FIX 7: Update /api/auth/me to handle optional tables

Already has try-catch for RBAC tables, but needs validation that it's working correctly.

---

## SUMMARY OF CHANGES

| Item | Issue | Fix | Type |
|------|-------|-----|------|
| user_presence table | Missing | CREATE TABLE + insert wrapper | SQL + Code |
| staff_roles table | Missing | CREATE TABLE | SQL |
| permissions table | Missing | CREATE TABLE | SQL |
| role_permissions table | Missing | CREATE TABLE | SQL |
| approval_requests table | Missing | CREATE TABLE (optional) | SQL |
| /api/presence/ping | No error handling | Add try-catch | Code |
| /api/auth/me | No validation | Add column exists check | Code |

---

## EXECUTION PRIORITY

🔴 **CRITICAL:**
1. Create user_presence table (blocking /api/presence/ping)
2. Wrap user_presence inserts with error handling

🟠 **HIGH:**
3. Create staff_roles table (for RBAC support)
4. Create permissions + role_permissions (for authorization)
5. Validate /api/auth/me handles missing tables

🟡 **OPTIONAL:**
6. Create approval_requests table (future feature)

---

## NEXT PHASE

Execute all SQL migrations against live database, then validate code error handling.

# DRAIS RBAC IMPLEMENTATION GUIDE

## Overview
This guide walks through implementing the JETON RBAC architecture in DRAIS.

**Source Document:** `RBAC_STAFF_ARCHITECTURE.md` (2,047 lines)  
**Quick Reference:** `RBAC_QUICK_REFERENCE.md`  
**Status:** Ready for implementation  

---

## PHASE 1: DATABASE SETUP (30 minutes)

### Step 1.1: Copy Schema

Copy these SQL tables from JETON migrations to DRAIS database:

**Table 1: users**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  
  role VARCHAR(50),
  authority_level INTEGER DEFAULT 10,
  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'suspended', 'terminated')),
  
  staff_id UUID UNIQUE REFERENCES staff(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
```

**Table 2: staff**
```sql
CREATE TABLE staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  position VARCHAR(100),
  school_id UUID,  -- DRAIS-specific: reference to schools table
  hire_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_staff_user_id ON staff(user_id);
CREATE INDEX idx_staff_school_id ON staff(school_id);
```

**Table 3: roles**
```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  hierarchy_level INTEGER DEFAULT 5,
  authority_level INTEGER DEFAULT 20,
  data_scope VARCHAR(50) DEFAULT 'OWN'
    CHECK (data_scope IN ('GLOBAL', 'DEPARTMENT', 'OWN')),
  
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_roles_hierarchy ON roles(hierarchy_level);
CREATE INDEX idx_roles_authority ON roles(authority_level);
```

**Table 4: permissions**
```sql
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module VARCHAR(100) NOT NULL,
  action VARCHAR(100) NOT NULL,
  UNIQUE(module, action),
  
  name VARCHAR(100),
  description TEXT,
  route_path VARCHAR(255),
  method VARCHAR(10),
  
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_permissions_module ON permissions(module);
```

**Table 5: role_permissions** (M:M mapping)
```sql
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  UNIQUE(role_id, permission_id),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
```

**Table 6: staff_roles** (M:M staff → roles)
```sql
CREATE TABLE staff_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE(staff_id, role_id),
  
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
  effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  effective_until TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_staff_roles_staff_id ON staff_roles(staff_id);
CREATE INDEX idx_staff_roles_role_id ON staff_roles(role_id);
```

**Table 7: approval_requests**
```sql
CREATE TABLE approval_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_user_id UUID NOT NULL REFERENCES users(id),
  target_record_type VARCHAR(100) NOT NULL,
  target_record_id UUID NOT NULL,
  action_requested VARCHAR(50) NOT NULL,
  reason TEXT,
  
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  
  approver_user_id UUID REFERENCES users(id),
  approver_notes TEXT,
  resolved_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_approval_requests_status ON approval_requests(status);
```

**Table 8: rbac_audit_logs**
```sql
CREATE TABLE rbac_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id UUID,
  details JSONB DEFAULT '{}',
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_rbac_audit_logs_user ON rbac_audit_logs(user_id);
CREATE INDEX idx_rbac_audit_logs_action ON rbac_audit_logs(action);
CREATE INDEX idx_rbac_audit_logs_created ON rbac_audit_logs(created_at DESC);
```

### Step 1.2: Seed System Roles

```sql
INSERT INTO roles (name, description, is_system, hierarchy_level, authority_level, data_scope) VALUES
  ('superadmin', 'Full system access', true, 1, 100, 'GLOBAL'),
  ('admin', 'System administration', true, 2, 80, 'GLOBAL'),
  ('school_admin', 'School administration', true, 3, 60, 'OWN'),
  ('teacher', 'Teacher/Staff member', true, 5, 40, 'OWN'),
  ('viewer', 'Read-only access', true, 8, 10, 'OWN')
ON CONFLICT (name) DO NOTHING;
```

### Step 1.3: Seed DRAIS Permissions

```sql
INSERT INTO permissions (module, action, name, description, route_path, method) VALUES
  -- Courses
  ('courses', 'view', 'courses_view', 'View courses', '/api/courses', 'GET'),
  ('courses', 'create', 'courses_create', 'Create courses', '/api/courses', 'POST'),
  ('courses', 'update', 'courses_update', 'Update courses', '/api/courses', 'PUT'),
  ('courses', 'delete', 'courses_delete', 'Delete courses', '/api/courses', 'DELETE'),
  
  -- Results
  ('results', 'view', 'results_view', 'View student results', '/api/results', 'GET'),
  ('results', 'create', 'results_create', 'Create/submit results', '/api/results', 'POST'),
  ('results', 'update', 'results_update', 'Update results', '/api/results', 'PUT'),
  ('results', 'delete', 'results_delete', 'Delete results', '/api/results', 'DELETE'),
  ('results', 'approve', 'results_approve', 'Approve results', '/api/results/approve', 'POST'),
  
  -- Students
  ('students', 'view', 'students_view', 'View students', '/api/students', 'GET'),
  ('students', 'create', 'students_create', 'Register students', '/api/students', 'POST'),
  ('students', 'update', 'students_update', 'Update students', '/api/students', 'PUT'),
  ('students', 'delete', 'students_delete', 'Remove students', '/api/students', 'DELETE'),
  
  -- Schools
  ('schools', 'view', 'schools_view', 'View schools', '/api/schools', 'GET'),
  ('schools', 'create', 'schools_create', 'Create school', '/api/schools', 'POST'),
  ('schools', 'manage', 'schools_manage', 'Manage schools', '/api/schools', 'ALL'),
  
  -- Fees/Finance
  ('fees', 'view', 'fees_view', 'View fees', '/api/fees', 'GET'),
  ('fees', 'create', 'fees_create', 'Create fee invoices', '/api/fees', 'POST'),
  ('fees', 'manage', 'fees_manage', 'Manage fees', '/api/fees', 'ALL'),
  ('fees', 'collect', 'fees_collect', 'Mark fees as collected', '/api/fees/collect', 'POST'),
  
  -- Attendance
  ('attendance', 'view', 'attendance_view', 'View attendance', '/api/attendance', 'GET'),
  ('attendance', 'create', 'attendance_create', 'Record attendance', '/api/attendance', 'POST'),
  ('attendance', 'update', 'attendance_update', 'Update attendance', '/api/attendance', 'PUT'),
  
  -- System
  ('system', 'manage', 'system_manage', 'System settings', '/api/admin/settings', 'ALL'),
  ('system', 'audit', 'system_audit', 'View audit logs', '/api/admin/audit', 'GET')
ON CONFLICT (module, action) DO NOTHING;
```

### Step 1.4: Assign Permissions to System Roles

```sql
-- SUPERADMIN: All permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'superadmin'
ON CONFLICT DO NOTHING;

-- ADMIN: All except system settings
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin' AND p.module != 'system'
ON CONFLICT DO NOTHING;

-- SCHOOL_ADMIN: Can manage school data
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'school_admin' AND p.action IN ('view', 'create', 'update', 'manage', 'approve')
ON CONFLICT DO NOTHING;

-- TEACHER: Can view and create results, view students
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'teacher' AND (
  (p.module = 'results' AND p.action IN ('view', 'create'))
  OR (p.module = 'students' AND p.action = 'view')
  OR (p.module = 'courses' AND p.action = 'view')
)
ON CONFLICT DO NOTHING;

-- VIEWER: Read-only on everything
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'viewer' AND p.action = 'view'
ON CONFLICT DO NOTHING;
```

---

## PHASE 2: COPY AUTHORIZATION LIBRARY (30 minutes)

### Step 2.1: Copy permissions.js

From JETON: `src/lib/permissions.js` → DRAIS: `src/lib/permissions.js`

This file is almost entirely portable. Changes needed:

**In permission loading (line ~70):**
```javascript
// BEFORE (JETON):
const result = await query(
  `SELECT DISTINCT p.module, p.action
   FROM users u
   JOIN staff s ON u.staff_id = s.id
   ...

// AFTER (DRAIS): Identical, no change needed
```

**In data scope (line ~170):**
```javascript
// BEFORE (JETON):
const result = await query(
  `SELECT s.department_id FROM users u JOIN staff s ...

// AFTER (DRAIS): Change to school_id if needed
const result = await query(
  `SELECT s.school_id FROM users u JOIN staff s ...
```

### Step 2.2: Copy API Middleware

Create endpoint: `src/app/api/auth/me/route.js` (same as JETON)

```javascript
import { verifyAuth } from '@/lib/auth-utils.js';
import { getCachedPermissions } from '@/lib/permissions.js';
import { NextResponse } from 'next/server';

export async function GET(request) {
  const auth = await verifyAuth(request);
  if (!auth) return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  
  const perms = await getCachedPermissions(auth.userId);
  return NextResponse.json({
    user: auth,
    permissions: perms.permissions,
    hierarchyLevel: perms.hierarchyLevel,
    authorityLevel: perms.authorityLevel,
    dataScope: perms.dataScope
  });
}
```

---

## PHASE 3: ADD PERMISSION CHECKS TO ROUTES (2-3 hours)

### Step 3.1: Audit Existing Routes

List all API routes in DRAIS that need authorization:

```
src/app/api/
├─ courses/
│  ├─ route.js            (GET, POST)
│  └─ [id]/
│     └─ route.js         (GET, PUT, DELETE)
├─ results/
│  ├─ route.js            (GET, POST)
│  ├─ [id]/route.js       (GET, PUT, DELETE)
│  └─ approve/route.js    (POST)
├─ students/
│  ├─ route.js            (GET, POST)
│  └─ [id]/route.js       (GET, PUT, DELETE)
├─ fees/
│  ├─ route.js            (GET, POST)
│  └─ collect/route.js    (POST)
└─ attendance/
   ├─ route.js            (GET, POST)
   └─ [id]/route.js       (PUT)
```

### Step 3.2: Add requirePermission Middleware

Example: `src/app/api/results/route.js`

```javascript
import { requirePermission } from '@/lib/permissions.js';
import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';

export async function GET(request) {
  // Step 1: Check permission FIRST
  const authResult = await requirePermission(request, 'results.view');
  if (authResult instanceof NextResponse) {
    return authResult;  // 403 Forbidden
  }
  
  const { auth, dataScope, schoolId } = authResult;
  
  // Step 2: Build scope-filtered query
  let whereClause = '';
  let params = [];
  
  if (dataScope === 'GLOBAL') {
    // Admin sees all
    whereClause = 'WHERE 1=1';
  } else if (dataScope === 'OWN' || dataScope === 'DEPARTMENT') {
    // Teacher sees own school's results
    whereClause = 'WHERE r.school_id = $1';
    params = [schoolId];
  }
  
  // Step 3: Execute query
  const result = await query(
    `SELECT r.id, r.student_id, r.score, r.created_at
     FROM results r
     ${whereClause}
     ORDER BY r.created_at DESC`,
    params
  );
  
  // Step 4: Log access (audit trail)
  await logAuditEntry({
    user_id: auth.userId,
    action: 'viewed_results',
    entity_type: 'results',
    details: { count: result.rows.length, scope: dataScope }
  });
  
  return NextResponse.json(result.rows);
}

export async function POST(request) {
  // Check permission
  const authResult = await requirePermission(request, 'results.create');
  if (authResult instanceof NextResponse) return authResult;
  
  const { auth, schoolId } = authResult;
  const body = await request.json();
  
  // Validate input
  if (!body.student_id || body.score === undefined) {
    return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
  }
  
  // Insert with creator and school
  const result = await query(
    `INSERT INTO results (student_id, score, school_id, created_by, created_at)
     VALUES ($1, $2, $3, $4, NOW())
     RETURNING *`,
    [body.student_id, body.score, schoolId, auth.userId]
  );
  
  // Log
  await logAuditEntry({
    user_id: auth.userId,
    action: 'created_result',
    entity_type: 'results',
    entity_id: result.rows[0].id,
    details: { student_id: body.student_id, score: body.score }
  });
  
  return NextResponse.json(result.rows[0], { status: 201 });
}
```

### Step 3.3: Template for All Routes

Use this template for every DRAIS route:

```javascript
import { requirePermission } from '@/lib/permissions.js';
import { NextResponse } from 'next/server';

export async function GET/POST/PUT/DELETE(request, { params }) {
  // 1. ALWAYS check permission first
  const authResult = await requirePermission(request, 'module.action');
  if (authResult instanceof NextResponse) return authResult;
  
  const { auth, dataScope, schoolId } = authResult;
  
  // 2. Build scope-filtered query (if needed)
  const filter = buildScopeFilter(dataScope, schoolId);
  
  // 3. Execute logic
  // ... your existing code ...
  
  // 4. Log audit entry
  await logAuditEntry({ user_id: auth.userId, action: '...', ... });
  
  // 5. Return response
  return NextResponse.json(result);
}
```

---

## PHASE 4: ROLE MAPPING (15 minutes)

Map JETON roles to DRAIS:

| JETON Role | DRAIS Role | Data Scope | Use Case |
|------------|-----------|-----------|----------|
| superadmin | superadmin | GLOBAL | System owner |
| admin | admin | GLOBAL | System admin |
| manager | school_admin | OWN | School principal |
| user | teacher | OWN | Teacher/Staff |
| viewer | viewer | OWN | Read-only access |

### Implementation

When migrating existing DRAIS users:

```sql
-- Find users with admin privileges → map to school_admin
UPDATE users u SET role = 'school_admin'
WHERE u.email IN (SELECT email FROM existing_admins);

-- Find users who submit results → map to teacher
UPDATE users u SET role = 'teacher'
WHERE u.email IN (SELECT email FROM existing_teachers);

-- Find auditors/observers → map to viewer
UPDATE users u SET role = 'viewer'
WHERE u.email IN (SELECT email FROM existing_observers);
```

---

## PHASE 5: TESTING (1-2 hours)

### Test Suite

Create `tests/rbac.test.js`:

```javascript
/**
 * RBAC Authorization Tests
 */

describe('RBAC Authorization', () => {
  
  test('Superadmin can access everything', async () => {
    const superadminToken = await login('superadmin@example.com');
    const response = await fetch('/api/results', {
      headers: { Authorization: `Bearer ${superadminToken}` }
    });
    expect(response.status).toBe(200);
  });
  
  test('Teacher cannot delete results', async () => {
    const teacherToken = await login('teacher@example.com');
    const response = await fetch('/api/results/123', {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${teacherToken}` }
    });
    expect(response.status).toBe(403);
  });
  
  test('Teacher only sees own school results', async () => {
    const teacher2Token = await login('teacher2@example.com');  // School 2
    const response = await fetch('/api/results?schoolId=1', {
      headers: { Authorization: `Bearer ${teacher2Token}` }
    });
    // Should be filtered to school 2 only
    const data = await response.json();
    data.forEach(r => expect(r.school_id).toBe(2));
  });
  
  test('Approval workflow works', async () => {
    const teacherToken = await login('teacher@example.com');
    
    // Try to delete (should fail with 202 Accepted + approval request)
    const response = await fetch('/api/results/456', {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${teacherToken}` }
    });
    expect(response.status).toBe(202);  // Approval pending
    
    const { approval_id } = await response.json();
    expect(approval_id).toBeDefined();
  });
  
  test('Audit logs record actions', async () => {
    const token = await login('teacher@example.com');
    
    // Perform action
    await fetch('/api/results', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify({ student_id: 'x', score: 85 })
    });
    
    // Check audit log
    const logs = await query(
      'SELECT * FROM rbac_audit_logs WHERE action = $1 ORDER BY created_at DESC LIMIT 1',
      ['created_result']
    );
    expect(logs.rows.length).toBeGreaterThan(0);
  });
});
```

### Manual Testing

Test these scenarios:

1. **Login with superadmin** → Can access all routes
2. **Login with teacher** → Can only access permitted routes
3. **Try unauthorized action** → Get 403 response
4. **Request approval** → Approval workflow initiated
5. **Check audit log** → Action is logged
6. **Expire temporary role** → Access revoked after effective_until

---

## PHASE 6: DOCUMENTATION (30 minutes)

Create DRAIS-specific documentation:

### File: `docs/DRAIS_RBAC.md`

```markdown
# DRAIS RBAC System

## Roles

- **Superadmin**: Complete system access
- **Admin**: System administration (no superadmin level)
- **School Admin**: Manage school data, approve results
- **Teacher**: Create/view results, view students
- **Viewer**: Read-only access

## Permissions

Core modules:
- `courses`: view, create, update, delete
- `results`: view, create, update, delete, approve
- `students`: view, create, update, delete
- `fees`: view, create, manage, collect
- `schools`: view, create, manage
- `system`: manage, audit

## Data Scopes

- **GLOBAL**: Superadmin, Admin (see all schools)
- **OWN/SCHOOL**: Teachers, School Admins (see own school only)

## How to Check Permission in Code

```javascript
const authResult = await requirePermission(request, 'results.create');
if (authResult instanceof NextResponse) return authResult;
const { auth, schoolId } = authResult;
// Use schoolId to filter: WHERE school_id = $1
```

## How to Check Manually

```sql
-- What can this user do?
SELECT DISTINCT p.module, p.action
FROM staff_roles sr
JOIN role_permissions rp ON sr.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE sr.staff_id = (SELECT id FROM staff WHERE user_id = '<user_id>');

-- Who did what?
SELECT user_id, action, entity_type, created_at FROM rbac_audit_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```
```

---

## PHASE 7: DEPLOYMENT (15 minutes)

### Step 1: Database Migration
```bash
psql $DATABASE_URL < migrations/rbac_schema.sql
psql $DATABASE_URL < migrations/rbac_seed.sql
```

### Step 2: Code Changes
- Copy `src/lib/permissions.js`
- Update all API routes with `requirePermission()`
- Update authentication middleware if needed

### Step 3: Verify
```bash
# Run test suite
npm test tests/rbac.test.js

# Check for missing permission checks
grep -r "export async function" src/app/api/ | grep -v "requirePermission" | head
# (should be empty or minimal)
```

### Step 4: Monitor
```sql
-- Watch audit logs for new DRAIS users
SELECT COUNT(*), action FROM rbac_audit_logs WHERE created_at > NOW() - INTERVAL '1 hour' GROUP BY action;

-- Check for permission violations
SELECT user_id, COUNT(*) FROM rbac_audit_logs WHERE action LIKE '%denied%' GROUP BY user_id;
```

---

## QUICK CHECKLIST

- [ ] Database schema created (8 tables)
- [ ] System roles seeded
- [ ] DRAIS permissions seeded
- [ ] Role-permission mapping created
- [ ] `permissions.js` copied
- [ ] Staff-role mapping updated
- [ ] All API routes protected with `requirePermission()`
- [ ] Data scoping filters added
- [ ] Audit logging working
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] Deployed to production

---

## SUPPORT

For questions:
1. Review `RBAC_STAFF_ARCHITECTURE.md` (main spec)
2. Check `RBAC_QUICK_REFERENCE.md` (quick lookup)
3. Look at JETON implementation (reference)

**Total Implementation Time:** 4-6 hours

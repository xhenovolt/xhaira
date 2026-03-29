# COMPLETE ENTERPRISE RBAC & STAFF ARCHITECTURE
## For JETON and DRAIS Systems
**Version:** 1.0  
**Date:** March 29, 2026  
**Status:** Production-Ready  
**Scope:** System-level authorization (not UI-based)

---

## TABLE OF CONTENTS
1. Core Conceptual Model
2. Staff Hierarchy System
3. Permission Granularity
4. Multi-Tenancy Scoping
5. Complete Database Schema
6. Authorization Flow
7. API-Level Enforcement
8. UI vs Backend Authority
9. Advanced Enterprise Features
10. Real-World Implementation Examples

---

## PHASE 1: CORE CONCEPTUAL MODEL (FOUNDATION)

### 1.1 The Five Entities

#### **Entity 1: Users**
- **What:** Individual account holders who interact with the system
- **Why:** Authentication and identity tracking
- **Properties:**
  - `id`: Unique identifier (UUID)
  - `email`: Login credential
  - `password_hash`: Bcrypt-hashed password
  - `status`: active | pending | suspended | terminated
  - `authority_level`: Denormalized power ranking for fast access
  - `created_at`: Timestamp

**Relationship:** 1:1 with Staff (or 0:1 if external user)

#### **Entity 2: Roles**
- **What:** Collections of permissions grouped by job function
- **Why:** Simplify permission assignment (assign role instead of 50 permissions)
- **Properties:**
  - `id`: UUID
  - `name`: Unique (e.g., 'superadmin', 'manager', 'analyst')
  - `description`: Human-readable purpose
  - `hierarchy_level`: Integer (1=highest, 10=lowest) for reporting structure
  - `authority_level`: Integer (100=CEO, 60=Manager, 20=Staff) for power ranking
  - `data_scope`: GLOBAL | DEPARTMENT | OWN (what data they see)
  - `is_system`: Boolean (true = cannot be deleted)
  - `is_active`: Boolean (soft-delete support)

**Relationship:** M:M with Permissions (role_permissions table)

#### **Entity 3: Permissions**
- **What:** Granular actions that can be performed on resources
- **Why:** Fine-grained control over who can do what
- **Format:** `module:action` (e.g., `deals:create`, `finance:view`)
- **Properties:**
  - `id`: UUID
  - `module`: Resource type (deals, finance, staff, etc.)
  - `action`: Action on resource (create, read, update, delete, manage)
  - `description`: Purpose
  - `route_path`: The API route this guards (e.g., `/api/deals`)
  - `method`: HTTP method (GET, POST, PUT, DELETE, ALL)

**Relationship:** M:M with Roles (role_permissions table)

#### **Entity 4: Staff**
- **What:** Employee/contractor profile linked to a user account
- **Why:** Data scoping and organizational hierarchy
- **Properties:**
  - `id`: UUID
  - `user_id`: FK to users (0:1 relationship)
  - `full_name`: Display name
  - `position`: Job title
  - `department`: Department name (e.g., 'Finance', 'Sales')
  - `department_id`: FK to departments table (hierarchical)
  - `hire_date`: Employment start date
  - `status`: active | inactive | terminated
  - `reports_to`: FK to another staff member (manager relationship)

**Relationship:** 1:M with Staff_Roles AND 1:1 with Users

#### **Entity 5: Staff_Roles**
- **What:** Junction table linking staff members to roles
- **Why:** Support multiple roles per employee (e.g., Manager + Finance Lead)
- **Properties:**
  - `id`: UUID
  - `staff_id`: FK to staff
  - `role_id`: FK to roles
  - `assigned_at`: When role was assigned
  - `assigned_by`: Who assigned the role (FK to users)
  - `effective_until`: Optional expiry for temporary roles

**Relationship:** M:M (staff to roles)

### 1.2 Relationship Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  USERS (identity & auth)                                    │
│  ├─ id (PK)                                                 │
│  ├─ email                                                   │
│  ├─ password_hash                                           │
│  └─ status: active|pending|suspended|terminated             │
│       │                                                      │
│       │ 0:1                                                  │
│       └──→ STAFF (employee profile)                         │
│            ├─ id (PK)                                       │
│            ├─ full_name                                     │
│            ├─ position                                      │
│            ├─ department_id (FK→departments)                │
│            └─ reports_to (FK→staff.id)                      │
│                 │                                           │
│                 │ 1:M                                       │
│                 └──→ STAFF_ROLES (junction)                 │
│                      ├─ staff_id (FK)                       │
│                      ├─ role_id (FK)                        │
│                      └─ assigned_at                         │
│                            │                                │
│                            │ M:1                            │
│                            └──→ ROLES                        │
│                                 ├─ id (PK)                  │
│                                 ├─ name (unique)            │
│                                 ├─ hierarchy_level          │
│                                 ├─ authority_level          │
│                                 └─ data_scope               │
│                                      │                      │
│                                      │ M:M                  │
│                                      └──→ ROLE_PERMISSIONS  │
│                                           ├─ role_id (FK)   │
│                                           └─ perm_id (FK)   │
│                                                 │            │
│                                                 │ M:1        │
│                                                 └──→ PERMS   │
│                                                      ├─ id   │
│                                                      ├─ mod  │
│                                                      └─ act  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Why This Model?

| Entity | Purpose | Benefit |
|--------|---------|---------|
| **Users** | Authentication | Separate identity from employment |
| **Staff** | Data scoping | Enable department/manager-based filtering |
| **Roles** | Permission grouping | Reduce from 200 permissions to 5-10 role assignments |
| **Permissions** | Fine-grain control | System can enforce exactly which API is callable |
| **Staff_Roles** | Multiple roles | Support dual roles (Manager + Analyst) |

---

## PHASE 2: STAFF HIERARCHY (REAL-WORLD STRUCTURE)

### 2.1 Organizational Levels

The system defines 8 clear hierarchy levels (1=highest authority):

```
LEVEL 1: SUPERADMIN
└─ System Owner / Technical Authority
   - Unrestricted access to ALL system resources
   - Can create/delete/modify any data
   - Cannot be restricted by other systems
   - Unaffected by data scoping rules

LEVEL 2: ADMIN / C-LEVEL
└─ Organization Owner / CEO
   - Full control within organization
   - Can manage all users, roles, permissions
   - Can approve workflows
   - Global data access (GLOBAL scope)

LEVEL 3: MANAGER / DIRECTOR
└─ Department/Team Leadership
   - Controls staff in own department
   - Views all data in department (DEPARTMENT scope)
   - Can approve requests from subordinates
   - Can manage team permissions

LEVEL 5: STAFF / ANALYST / SPECIALIST
└─ Individual Contributors
   - Access own data + department data (if assigned)
   - Can view/create/edit own records
   - Cannot modify other user records
   - OWN or DEPARTMENT scope (depends on role)

LEVEL 8: VIEWER / STAKEHOLDER
└─ Read-Only Access
   - View-only permissions (no create/edit/delete)
   - Usually OWN scope (only their own records)
   - Used for auditors, external partners

LEVEL 10+: RESTRICTED / EXTERNAL USER
└─ Minimal Access
   - Single-module access (e.g., only invoices:view)
   - Always OWN scope
   - Cannot approve anything
```

### 2.2 Scope of Authority by Level

| Role | Creates | Edits | Deletes | Approves | Data Access | Notes |
|------|---------|-------|---------|----------|-------------|-------|
| **Superadmin** | ✅ All | ✅ All | ✅ All | ✅ All | GLOBAL | Bypasses all checks |
| **Admin** | ✅ All | ✅ All | ✅ All | ✅ All | GLOBAL | Org-wide authority |
| **Manager** | ✅ Team items | ✅ Own + Team | ✅ With approval | ✅ For subordinates | DEPARTMENT | Manages department |
| **Staff** | ✅ Own items | ✅ Own items | ❌ (needs approval) | ✅ Own requests | OWN | Individual contributor |
| **Viewer** | ❌ | ❌ | ❌ | ❌ | OWN (read) | Read-only access |
| **External** | ❌ | ❌ | ❌ | ❌ | OWN single module | Restricted partner |

### 2.3 Hierarchy in Database

```sql
-- Hierarchy level: determines approval authority
superadmin     → hierarchy_level = 1  (highest)
admin          → hierarchy_level = 2
manager        → hierarchy_level = 3
team_lead      → hierarchy_level = 4
staff          → hierarchy_level = 5
contractor     → hierarchy_level = 7
viewer         → hierarchy_level = 8
restricted     → hierarchy_level = 10 (lowest)

-- Authority level: power ranking (separate from hierarchy)
superadmin     → authority_level = 100 (maximum power)
admin          → authority_level = 80
manager        → authority_level = 60
team_lead      → authority_level = 50
staff          → authority_level = 40
contractor     → authority_level = 30
viewer         → authority_level = 10
restricted     → authority_level = 5  (minimum)
```

---

## PHASE 3: PERMISSION SYSTEM (GRANULAR CONTROL)

### 3.1 Permission Format

All permissions follow:

```
MODULE : ACTION
```

Examples:
- `deals:create` = Create a new deal
- `finance:view` = View financial data
- `staff:delete` = Delete a staff member
- `invoices:approve` = Approve an invoice

### 3.2 Standard Actions

Every resource has up to 5 standard actions:

| Action | HTTP | Meaning | Example |
|--------|------|---------|---------|
| `view` | GET | Read access | `deals:view` |
| `create` | POST | Create new record | `deals:create` |
| `update` | PUT | Edit existing record | `deals:update` |
| `delete` | DELETE | Remove record | `deals:delete` |
| `manage` | ALL | Full control | `finance:manage` |

### 3.3 Permission Grouping by Module

#### **FINANCE Module**
```
finance:view         → See financial data (GET /api/finance)
finance:create       → Create transactions (POST /api/finance)
finance:update       → Edit transactions (PUT /api/finance)
finance:delete       → Delete transactions (DELETE /api/finance)
finance:manage       → Full financial control (all operations)
finance:approve      → Approve large transactions
finance:export       → Export financial reports
finance:audit        → Access audit logs
```

#### **DEALS Module**
```
deals:view           → List deals, see deal details
deals:create         → Create new deal
deals:update         → Edit existing deal
deals:delete         → Delete deal
deals:manage         → Full deal control
deals:assign_owner   → Reassign deal ownership
deals:close          → Mark deal as closed
```

#### **STAFF Module**
```
staff:view           → View employee directory
staff:create         → Hire new employee
staff:update         → Edit employee records
staff:delete         → Terminate employee
staff:manage         → Full employee control
staff:approve_hire   → Approve hiring requests
staff:manage_roles   → Assign roles to staff
```

#### **INVOICES Module**
```
invoices:view        → View invoices
invoices:create      → Create invoice
invoices:update      → Edit invoice
invoices:delete      → Delete invoice
invoices:manage      → Full invoice control
invoices:approve     → Approve invoice for payment
invoices:collect     → Mark invoice as paid
```

#### **OPERATIONS Module**
```
operations:view      → View operational metrics
operations:manage    → Configure operations system
operations:report    → Generate operational reports
```

#### **SYSTEM Control**
```
system:manage        → Global system settings
system:manage_roles  → Create/edit/delete roles
system:audit         → View comprehensive audit logs
system:settings      → Change system configuration
```

### 3.4 Permission Matrix by Role

#### **SUPERADMIN** (unrestricted)
| Module | view | create | update | delete | manage | approve | audit |
|--------|------|--------|--------|--------|--------|---------|-------|
| finance | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| deals | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| staff | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| invoices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **system** | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | ✅ |

#### **ADMIN** (org-wide authority)
| Module | view | create | update | delete | manage | approve | audit |
|--------|------|--------|--------|--------|--------|---------|-------|
| finance | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| deals | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| staff | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| invoices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| system | ✅ | ❌ | ❌ | ❌ | ✅ | N/A | ✅ |

#### **MANAGER** (department authority)
| Module | view | create | update | delete | manage | approve | audit |
|--------|------|--------|--------|--------|--------|---------|-------|
| finance | ✅ (dept) | ✅ | ✅ | ❌ | ✅ | ✅ (own dept) | ✅ (dept) |
| deals | ✅ (dept) | ✅ | ✅ (own) | ❌ | ❌ | ✅ (own dept) | ✅ (dept) |
| staff | ✅ (dept) | ❌ | ✅ (own dept) | ❌ | ❌ | ❌ | ✅ (dept) |
| invoices | ✅ (dept) | ✅ | ✅ (own) | ❌ | ❌ | ✅ (own dept) | ✅ (dept) |
| system | ❌ | ❌ | ❌ | ❌ | ❌| N/A | ❌ |

#### **STAFF** (own records only)
| Module | view | create | update | delete | manage | approve | audit |
|--------|------|--------|--------|--------|--------|---------|-------|
| finance | ✅ (own) | ✅ (own) | ✅ (own) | ❌ | ❌ | ❌ | ❌ |
| deals | ✅ (own) | ✅ | ✅ (own) | ❌ | ❌ | ❌ | ❌ |
| staff | ✅ (own) | ❌ | ✅ (own) | ❌ | ❌ | ❌ | ❌ |
| invoices | ✅ (own) | ✅ | ✅ (own) | ❌ | ❌ | ❌ | ❌ |
| system | ❌ | ❌ | ❌ | ❌ | ❌ | N/A | ❌ |

#### **VIEWER** (read-only)
| Module | view | create | update | delete | manage | approve | audit |
|--------|------|--------|--------|--------|--------|---------|-------|
| finance | ✅ (own) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| deals | ✅ (own) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| staff | ✅ (own) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| invoices | ✅ (own) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| system | ❌ | ❌ | ❌ | ❌ | ❌ | N/A | ❌ |

---

## PHASE 4: MULTI-TENANCY SCOPING (CRITICAL)

### 4.1 The Three Data Scopes

The system supports multi-tenant operations through **data scope enforcement**:

#### **GLOBAL Scope** (superadmin, admin, organization heads)
```
User can access: ALL records in the system
Applied to: Superadmin, Admin
Conditions: No WHERE clause filtering
Database Query:
  SELECT * FROM deals  -- no filter, all deals

Use Case: System administrators and C-level executives
```

#### **DEPARTMENT Scope** (managers, team leads)
```
User can access:
  - All records created by their own department
  - All records created by them personally
  - Restricted: Cannot see other departments

Database Query:
  SELECT * FROM deals 
  WHERE department_id = $1          -- manager's dept
     OR created_by = $2             -- or created by them
  PARAMS: [$managerId, $userId]

Use Case: Department heads seeing their team's work
```

#### **OWN Scope** (staff, contractors, viewers)
```
User can access: ONLY records they created
Applied to: Individual contributors, viewers, external users
Conditions: Strict created_by filter

Database Query:
  SELECT * FROM deals 
  WHERE created_by = $1  -- only own records
  PARAMS: [$userId]

Use Case: Staff members can only see their own work
```

### 4.2 Scope Enforcement in API Routes

```javascript
// Example: GET /api/deals (list deals)

const { auth, dataScope, departmentId } = await requirePermission(request, 'deals.view');

// Build WHERE clause based on scope
const scopeFilter = buildDataScopeFilter({
  dataScope,           // 'GLOBAL', 'DEPARTMENT', or 'OWN'
  userId: auth.userId,
  departmentId,
  tableAlias: 'd',
  createdByCol: 'd.created_by',
  paramOffset: 0
});

const query = `
  SELECT * FROM deals d
  WHERE d.status != 'archived'
  ${scopeFilter.clause}
`;
const params = [...scopeFilter.params];
const result = await pool.query(query, params);
return NextResponse.json(result.rows);
```

### 4.3 Cross-Tenant Permission Bypass

**Superadmin Rule:** Superadmin role is:
- **NOT** filtered by data scope
- **NOT** filtered by department
- **NOT** affected by multi-tenancy rules
- Checked FIRST in authorization pipeline

```javascript
// In requirePermission middleware:
if (auth.role === 'superadmin') {
  return { auth, dataScope: 'GLOBAL', departmentId: null };  // Always global
}
// For other users, continue with normal scope checks...
```

### 4.4 Multi-Organization Support (Future)

When expanding to true multi-organization SaaS:

```sql
-- Add organization_id column
ALTER TABLE deals ADD COLUMN organization_id UUID;
ALTER TABLE staff ADD COLUMN organization_id UUID;
ALTER TABLE users ADD COLUMN organization_id UUID;

-- Scope becomes: organization_id + (GLOBAL|DEPARTMENT|OWN)
-- Query enforcement:
SELECT * FROM deals 
WHERE organization_id = $1  -- multi-org filter
  AND (department_id = $2 OR created_by = $3)  -- scope filter
```

---

## PHASE 5: DATABASE STRUCTURE (NON-NEGOTIABLE)

### 5.1 Complete Schema

```sql
-- ============================================================================
-- USERS TABLE (Authentication & Identity)
-- ============================================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  
  -- Authorization shortcuts (denormalized for performance)
  role VARCHAR(50),  -- Legacy fallback: 'superadmin'|'admin'|'user'|'viewer'
  authority_level INTEGER DEFAULT 10,  -- 100=superadmin, 10=viewer
  
  -- Status tracking
  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'suspended', 'terminated')),
  
  -- Links to staff (optional, null if external user)
  staff_id UUID UNIQUE REFERENCES staff(id) ON DELETE SET NULL,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_staff_id ON users(staff_id);
CREATE INDEX idx_users_status ON users(status);


-- ============================================================================
-- STAFF TABLE (Employee Profiles & Organization)
-- ============================================================================
CREATE TABLE staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Identity
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  
  -- Employment
  position VARCHAR(100),  -- Job title
  department VARCHAR(100),  -- Department name (denormalized)
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  hire_date DATE DEFAULT CURRENT_DATE,
  
  -- Reporting structure
  reports_to UUID REFERENCES staff(id) ON DELETE SET NULL,
  
  -- Compensation (optional)
  salary DECIMAL(15, 2),
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'terminated', 'on_leave')),
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_staff_user_id ON staff(user_id);
CREATE INDEX idx_staff_department_id ON staff(department_id);
CREATE INDEX idx_staff_reports_to ON staff(reports_to);
CREATE INDEX idx_staff_status ON staff(status);


-- ============================================================================
-- DEPARTMENTS TABLE (Organizational Structure)
-- ============================================================================
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  parent_department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  
  -- Head of department
  head_staff_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_departments_parent ON departments(parent_department_id);
CREATE INDEX idx_departments_head ON departments(head_staff_id);


-- ============================================================================
-- ROLES TABLE (Role Definitions)
-- ============================================================================
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Identity
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  alias VARCHAR(100),  -- Display name override
  
  -- Hierarchy (reporting structure)
  hierarchy_level INTEGER DEFAULT 5,  -- 1=top, 10=bottom
  
  -- Authority (power ranking)
  authority_level INTEGER DEFAULT 20,  -- 100=superadmin, 10=viewer
  
  -- Data access scope
  data_scope VARCHAR(50) DEFAULT 'OWN'
    CHECK (data_scope IN ('GLOBAL', 'DEPARTMENT', 'OWN')),
  
  -- Lifecycle
  is_system BOOLEAN DEFAULT false,  -- Cannot be deleted
  is_active BOOLEAN DEFAULT true,
  
  -- Audit
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_roles_hierarchy ON roles(hierarchy_level);
CREATE INDEX idx_roles_authority ON roles(authority_level);
CREATE INDEX idx_roles_active ON roles(is_active);


-- ============================================================================
-- PERMISSIONS TABLE (Granular Actions)
-- ============================================================================
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Permission identity
  module VARCHAR(100) NOT NULL,     -- Resource type: 'deals', 'finance'
  action VARCHAR(100) NOT NULL,     -- Action: 'view', 'create', 'delete'
  UNIQUE(module, action),
  
  -- Metadata
  name VARCHAR(100),                -- Unique key: 'deals_create'
  description TEXT,
  
  -- Routing information
  route_path VARCHAR(255),          -- API route: '/api/deals'
  method VARCHAR(10),               -- HTTP method: 'GET', 'POST', 'PUT', 'DELETE', 'ALL'
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_permissions_module ON permissions(module);
CREATE INDEX idx_permissions_action ON permissions(action);
CREATE INDEX idx_permissions_route ON permissions(route_path);


-- ============================================================================
-- ROLE_PERMISSIONS TABLE (M:M Mapping)
-- ============================================================================
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  UNIQUE(role_id, permission_id),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);


-- ============================================================================
-- STAFF_ROLES TABLE (M:M Mapping - Multiple Roles Per Staff)
-- ============================================================================
CREATE TABLE staff_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE(staff_id, role_id),
  
  -- Temporal constraints (optional)
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
  effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  effective_until TIMESTAMPTZ,  -- NULL = indefinite
  
  -- Audit
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_staff_roles_staff_id ON staff_roles(staff_id);
CREATE INDEX idx_staff_roles_role_id ON staff_roles(role_id);
CREATE INDEX idx_staff_roles_effective ON staff_roles(effective_from, effective_until);


-- ============================================================================
-- APPROVAL_REQUESTS TABLE (Hierarchical Workflow)
-- ============================================================================
CREATE TABLE approval_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Request details
  requester_user_id UUID NOT NULL REFERENCES users(id),
  target_record_type VARCHAR(100) NOT NULL,  -- 'deal', 'staff', 'payment'
  target_record_id UUID NOT NULL,
  action_requested VARCHAR(50) NOT NULL,     -- 'delete', 'update', 'create'
  reason TEXT,
  
  -- Workflow state
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  
  -- Resolution
  approver_user_id UUID REFERENCES users(id),
  approver_notes TEXT,
  resolved_at TIMESTAMPTZ,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_requests_requester ON approval_requests(requester_user_id);
CREATE INDEX idx_approval_requests_status ON approval_requests(status);
CREATE INDEX idx_approval_requests_target ON approval_requests(target_record_type, target_record_id);


-- ============================================================================
-- RBAC_AUDIT_LOGS TABLE (Complete Action Logging)
-- ============================================================================
CREATE TABLE rbac_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Who & What
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,    -- 'created_role', 'assigned_permission'
  entity_type VARCHAR(100),        -- 'role', 'permission', 'staff_role'
  entity_id UUID,
  
  -- Details
  details JSONB DEFAULT '{}',      -- Context-specific metadata
  
  -- Environment
  ip_address VARCHAR(45),
  user_agent TEXT,
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rbac_audit_logs_user ON rbac_audit_logs(user_id);
CREATE INDEX idx_rbac_audit_logs_action ON rbac_audit_logs(action);
CREATE INDEX idx_rbac_audit_logs_entity ON rbac_audit_logs(entity_type, entity_id);
CREATE INDEX idx_rbac_audit_logs_created ON rbac_audit_logs(created_at DESC);
```

### 5.2 Seed Data

```sql
-- ============================================================================
-- SEED SYSTEM ROLES
-- ============================================================================
INSERT INTO roles (name, description, is_system, hierarchy_level, authority_level, data_scope) VALUES
  ('superadmin', 'Full system access — unrestricted', true, 1, 100, 'GLOBAL'),
  ('admin', 'Administrative access — user management, system config', true, 2, 80, 'GLOBAL'),
  ('manager', 'Department manager — team oversight', true, 3, 60, 'DEPARTMENT'),
  ('user', 'Standard authenticated user', true, 5, 40, 'OWN'),
  ('viewer', 'Read-only access to all modules', true, 8, 10, 'OWN')
ON CONFLICT (name) DO NOTHING;


-- ============================================================================
-- SEED COMPREHENSIVE PERMISSIONS
-- ============================================================================
INSERT INTO permissions (module, action, name, description, route_path, method) VALUES
  -- DEALS
  ('deals', 'view', 'deals_view', 'View deals', '/api/deals', 'GET'),
  ('deals', 'create', 'deals_create', 'Create deals', '/api/deals', 'POST'),
  ('deals', 'update', 'deals_update', 'Update deals', '/api/deals', 'PUT'),
  ('deals', 'delete', 'deals_delete', 'Delete deals', '/api/deals', 'DELETE'),
  
  -- FINANCE
  ('finance', 'view', 'finance_view', 'View financial data', '/api/finance', 'GET'),
  ('finance', 'create', 'finance_create', 'Create transactions', '/api/finance', 'POST'),
  ('finance', 'manage', 'finance_manage', 'Manage financial settings', '/api/finance', 'ALL'),
  
  -- STAFF
  ('staff', 'view', 'staff_view', 'View staff directory', '/api/staff', 'GET'),
  ('staff', 'create', 'staff_create', 'Add staff members', '/api/staff', 'POST'),
  ('staff', 'update', 'staff_update', 'Update staff records', '/api/staff', 'PUT'),
  ('staff', 'delete', 'staff_delete', 'Remove staff members', '/api/staff', 'DELETE'),
  
  -- INVOICES
  ('invoices', 'view', 'invoices_view', 'View invoices', '/api/invoices', 'GET'),
  ('invoices', 'create', 'invoices_create', 'Create invoices', '/api/invoices', 'POST'),
  ('invoices', 'update', 'invoices_update', 'Update invoices', '/api/invoices', 'PUT'),
  ('invoices', 'delete', 'invoices_delete', 'Delete invoices', '/api/invoices', 'DELETE'),
  
  -- SYSTEM
  ('system', 'manage', 'system_manage', 'Global system settings', '/api/admin/settings', 'ALL'),
  ('system', 'audit', 'system_audit', 'View audit logs', '/api/admin/audit', 'GET')
ON CONFLICT (module, action) DO NOTHING;


-- ============================================================================
-- ASSIGN PERMISSIONS TO ROLES
-- ============================================================================
-- SUPERADMIN gets ALL permissions (insert when needed)
-- ADMIN gets all except system.manage
-- MANAGER gets view/create/update for own department
-- STAFF/USER gets own records only
-- VIEWER gets read-only

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'superadmin'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin' AND p.module != 'system'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'manager' AND (p.action IN ('view', 'create') OR r.name != 'manager')
ON CONFLICT DO NOTHING;
```

---

## PHASE 6: AUTHORIZATION FLOW (HOW SYSTEM DECIDES)

### 6.1 Complete Request Authorization Flow

When a user makes a request to any protected API route:

```
┌─────────────────────────────────────────────────────────────┐
│ USER REQUEST                                                │
│ GET /api/deals?status=open                                  │
│ Headers: Authorization: Bearer <token>                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: AUTHENTICATION VERIFICATION                         │
│ - Extract JWT token from Authorization header               │
│ - Verify signature and expiration                           │
│ - Load session data (userId, email, role)                   │
│ - Check account status: pending|active|suspended|terminated │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────── Is status active? ───────────┐
        │                                            │
        NO                                          YES
        │                                            │
        ▼                                            ▼
   DENY 403                         ┌─────────────────────────────┐
                                     │ STEP 2: SUPERADMIN BYPASS?  │
                                     │ Check: auth.role === 'super │
                                     │        admin'               │
                                     └──────────┬──────────────────┘
                                                 │
                                    ┌────────────┴────────────┐
                                    │                         │
                                  YES                        NO
                                    │                         │
                                    ▼                         ▼
                          ┌──────────────────┐    ┌──────────────────────┐
                          │ GRANT ACCESS     │    │ STEP 3: PERMISSION   │
                          │ dataScope:GLOBAL │    │ CHECK                │
                          │ (bypass all      │    │                      │
                          │  restrictions)   │    │ Load all permissions │
                          └──────────────────┘    │ for user's roles     │
                                                  │ from database cache  │
                                                  │                      │
                                                  │ Check: Do their      │
                                                  │ permissions include  │
                                                  │ 'deals.view'?        │
                                                  └──────────┬───────────┘
                                                              │
                                                   ┌──────────┴──────────┐
                                                   │                     │
                                                  YES                   NO
                                                   │                     │
                                                   ▼                     ▼
                                          ┌──────────────────┐      DENY 403
                                          │ STEP 4: DATA     │      "Permission
                                          │ SCOPE RESOLUTION │       denied:
                                          │                  │       deals.view"
                                          │ Load user's      │
                                          │ data_scope:      │
                                          │ - GLOBAL         │
                                          │ - DEPARTMENT     │
                                          │ - OWN            │
                                          │                  │
                                          │ Load department  │
                                          │ _id (if DEPT)    │
                                          └────────┬─────────┘
                                                   │
                                                   ▼
                                           ┌────────────────────┐
                                           │ STEP 5: BUILD      │
                                           │ QUERY FILTER       │
                                           │                    │
                                           │ IF GLOBAL:         │
                                           │   No WHERE clause   │
                                           │                    │
                                           │ IF DEPARTMENT:     │
                                           │   WHERE dept_id=$1 │
                                           │   OR created_by=$2 │
                                           │                    │
                                           │ IF OWN:            │
                                           │   WHERE            │
                                           │   created_by=$1    │
                                           └────────┬───────────┘
                                                    │
                                                    ▼
                                           ┌──────────────────────┐
                                           │ STEP 6: EXECUTE      │
                                           │ FILTERED QUERY       │
                                           │                      │
                                           │ SELECT * FROM deals  │
                                           │ WHERE status='open'  │
                                           │ ${scopeFilter}       │
                                           └────────┬─────────────┘
                                                    │
                                                    ▼
                                           ┌──────────────────────┐
                                           │ STEP 7: LOG AUDIT    │
                                           │                      │
                                           │ INSERT INTO          │
                                           │  audit_logs:         │
                                           │ - user_id            │
                                           │ - action: 'viewed'   │
                                           │ - resource: 'deals'  │
                                           │ - returned: N rows   │
                                           └────────┬─────────────┘
                                                    │
                                                    ▼
                                           ┌──────────────────────┐
                                           │ STEP 8: RETURN       │
                                           │ FILTERED RESULTS     │
                                           │                      │
                                           │ 200 OK               │
                                           │ [...filtered deals]  │
                                           └──────────────────────┘
```

### 6.2 Permission Aggregation Algorithm

```javascript
/**
 * When loading permissions for a user, the system follows this path:
 */

async function loadPermissionsForUser(userId) {
  // PRIMARY PATH: Normalized JETON architecture
  const staffRecord = await db.query(
    'SELECT s.id, s.department_id FROM staff s JOIN users u ON u.staff_id = s.id WHERE u.id = $1',
    [userId]
  );
  
  if (staffRecord) {
    // User has a staff record → follow normalized chain
    const permissions = await db.query(
      `SELECT DISTINCT p.module, p.action
       FROM staff s
       JOIN staff_roles sr ON sr.staff_id = s.id
       JOIN roles r ON r.id = sr.role_id
       JOIN role_permissions rp ON rp.role_id = r.id
       JOIN permissions p ON p.id = rp.permission_id
       WHERE s.id = $1
       AND sr.effective_from <= NOW()
       AND (sr.effective_until IS NULL OR sr.effective_until > NOW())
       AND r.is_active = true`,
      [staffRecord.id]
    );
    return permissions;
  }
  
  // FALLBACK PATH A: Denormalized users.role field
  const userRecord = await db.query(
    'SELECT role FROM users WHERE id = $1',
    [userId]
  );
  
  if (userRecord.role) {
    const permissions = await db.query(
      `SELECT DISTINCT p.module, p.action
       FROM roles r
       JOIN role_permissions rp ON rp.role_id = r.id
       JOIN permissions p ON p.id = rp.permission_id
       WHERE r.name = $1 AND r.is_active = true`,
      [userRecord.role]
    );
    return permissions;
  }
  
  // FALLBACK PATH B: Default to 'viewer' (safest)
  return await loadPermissionsForRole('viewer');
}
```

### 6.3 Final Authorization Decision Table

| Condition | Result | Why |
|-----------|--------|-----|
| Token invalid or expired | DENY 401 | Not authenticated |
| Account status ≠ 'active' | DENY 403 | Account disabled |
| Role = 'superadmin' | ALLOW + GLOBAL | Bypass all checks |
| Permission not in user's role | DENY 403 | Lacks capability |
| Permission exists but filtered | ALLOW + FILTERED | Show only allowed data |

---

## PHASE 7: API-LEVEL ENFORCEMENT (CRITICAL)

### 7.1 Middleware Pattern

The `requirePermission` middleware is **absolutely required** on every protected API route:

```javascript
/**
 * File: src/app/api/deals/route.js
 * This route MUST enforce permission checks
 */

import { requirePermission } from '@/lib/permissions.js';
import { NextResponse } from 'next/server';

export async function GET(request) {
  // ✅ ALWAYS: First line of route — check permission
  const authResult = await requirePermission(request, 'deals.view');
  if (authResult instanceof NextResponse) {
    return authResult;  // Error response
  }
  
  // Now authResult = { auth, dataScope, departmentId }
  const { auth, dataScope, departmentId } = authResult;
  
  // Build scope-filtered query
  const scopeFilter = buildDataScopeFilter({
    dataScope,
    userId: auth.userId,
    departmentId,
    tableAlias: 'd'
  });
  
  const query = `
    SELECT d.id, d.name, d.value, d.created_by, d.created_at
    FROM deals d
    WHERE d.status != 'archived'
    ${scopeFilter.clause}
    ORDER BY d.created_at DESC
  `;
  
  const result = await pool.query(query, scopeFilter.params);
  
  // ✅ LOG: Audit the access
  await logAuditEntry({
    user_id: auth.userId,
    action: 'viewed_deals',
    resource_type: 'deals',
    result_count: result.rows.length,
    data_scope: dataScope
  });
  
  return NextResponse.json(result.rows);
}

export async function POST(request) {
  // ✅ Always check
  const authResult = await requirePermission(request, 'deals.create');
  if (authResult instanceof NextResponse) {
    return authResult;
  }
  
  const { auth, departmentId } = authResult;
  const body = await request.json();
  
  // Insert with creator and department
  const result = await pool.query(
    `INSERT INTO deals (name, value, created_by, department_id, created_at)
     VALUES ($1, $2, $3, $4, NOW())
     RETURNING *`,
    [body.name, body.value, auth.userId, departmentId]
  );
  
  return NextResponse.json(result.rows[0], { status: 201 });
}
```

### 7.2 Guards for Different Scenarios

#### **Guard 1: Simple Permission Check**
```javascript
const authResult = await requirePermission(request, 'deals.view');
if (authResult instanceof NextResponse) return authResult;
```

#### **Guard 2: Permission + Hierarchy Check**
```javascript
const authResult = await requirePermission(request, 'deals.delete');
if (authResult instanceof NextResponse) return authResult;

const { auth } = authResult;
const record = await fetchRecord(id);

const hierarchyCheck = await checkHierarchyAuthority(
  auth.userId,      // Acting user
  record.created_by,  // Record owner
  'delete'
);

if (!hierarchyCheck.allowed) {
  if (hierarchyCheck.requiresApproval) {
    // Create approval request instead of outright denial
    const approval = await createApprovalRequest({
      requesterUserId: auth.userId,
      targetRecordType: 'deals',
      targetRecordId: id,
      actionRequested: 'delete'
    });
    return NextResponse.json({
      error: 'Approval required',
      approvalId: approval.id
    }, { status: 202 });  // ACCEPTED (pending approval)
  }
  return NextResponse.json({ error: 'Insufficient authority' }, { status: 403 });
}

// Permission granted, proceed with delete
```

#### **Guard 3: Own Records Only**
```javascript
const authResult = await requirePermission(request, 'deals.update');
if (authResult instanceof NextResponse) return authResult;

const { auth, dataScope } = authResult;
const record = await fetchRecord(id);

// Check data scope: user can only update own records (unless GLOBAL/DEPT manager)
if (dataScope === 'OWN' && record.created_by !== auth.userId) {
  return NextResponse.json({ error: 'Cannot edit other users\' records' }, { status: 403 });
}

// For DEPARTMENT scope, allow editing own + team records
if (dataScope === 'DEPARTMENT') {
  const isTeamMember = await isTeamRecord(record.id, auth.userId, departmentId);
  if (!isTeamMember && record.created_by !== auth.userId) {
    return NextResponse.json({ error: 'Not in your department' }, { status: 403 });
  }
}

// Update allowed
```

#### **Guard 4: Role-Specific Logic**
```javascript
const authResult = await requirePermission(request, 'finance.manage');
if (authResult instanceof NextResponse) return authResult;

const { auth } = authResult;
const userRole = await getUserHighestRole(auth.userId);

// Superadmin can do anything
if (userRole.name === 'superadmin') {
  // Execute operation
}

// Admin can do most things
else if (userRole.name === 'admin') {
  // Execute operation with some restrictions
}

// Manager can only manage own department
else if (userRole.name === 'manager') {
  const record = await fetchRecord(id);
  if (record.department_id !== departmentId) {
    return NextResponse.json({ error: 'Not your department' }, { status: 403 });
  }
}

// Staff cannot access
else {
  return NextResponse.json({ error: 'Admin role required' }, { status: 403 });
}
```

### 7.3 Permission Cache Invalidation

Critical when roles/permissions change:

```javascript
// When assigning a role to a staff member
import { invalidatePermissionCache } from '@/lib/permissions.js';

async function assignRoleToStaff(staffId, roleId) {
  const staff = await db.query(
    'SELECT user_id FROM staff WHERE id = $1',
    [staffId]
  );
  
  // Insert staff_roles record
  await db.query(
    'INSERT INTO staff_roles (staff_id, role_id) VALUES ($1, $2)',
    [staffId, roleId]
  );
  
  // ✅ Invalidate cache so new permissions take effect immediately
  invalidatePermissionCache(staff.user_id);
}

// When bulk changes occur
import { invalidateAllPermissionCaches } from '@/lib/permissions.js';

async function bulkUpdatePermissions() {
  // ... perform updates ...
  
  // Clear cache for all users (expensive, use sparingly)
  invalidateAllPermissionCaches();
}
```

---

## PHASE 8: UI vs BACKEND AUTHORITY (IMPORTANT)

### 8.1 The Critical Truth

**UI controls and backend enforcement are TWO SEPARATE SYSTEMS.**

❌ **NEVER** rely on:
```javascript
// WRONG: This is a UX nicety, NOT security
if (user.hasPermission('deals.delete')) {
  <button>Delete Deal</button>  // User can just inspect element!
}
```

✅ **ALWAYS** enforce:
```javascript
// RIGHT: Server-side enforcement
export async function DELETE(request, { params: { id } }) {
  // Step 1: Verify permission
  const authResult = await requirePermission(request, 'deals.delete');
  if (authResult instanceof NextResponse) return authResult;  // Backend denies
  
  // Step 2: Verify record ownership/hierarchy
  const record = await fetchRecord(id);
  const hierarchyCheck = await checkHierarchyAuthority(
    authResult.auth.userId,
    record.created_by,
    'delete'
  );
  if (!hierarchyCheck.allowed) return forbiddenResponse();
  
  // Step 3: Delete
  await deleteRecord(id);
  return NextResponse.json({ success: true });
}
```

### 8.2 The Attack Chain

**Scenario: User without permission tries to delete a record**

```
┌──────────────────────────────────┐
│ Browser Dev Tools                │
│ > Delete button is hidden        │
│ > User inspects element          │
│ > Manually calls DELETE /api/deals/123
└──────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────┐
│ Server Route Handler             │
│ requirePermission(request, 'delete')
│                                  │
│ ❌ User has NO 'deals.delete'    │
│ Returns 403 FORBIDDEN            │
│ "Access denied: deals.delete"    │
└──────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────┐
│ Request DENIED — record safe     │
│ Backend enforcement protected     │
│ UI hiding was just UX bonus       │
└──────────────────────────────────┘
```

### 8.3 Multi-Layer Defense

```
LAYER 1: Frontend UI
├─ Hide buttons user can't click
├─ Disable form fields
├─ Show "unauthorized" messages
└─ Scope: SPEED & UX ONLY

LAYER 2: API Authentication
├─ Verify JWT token
├─ Check account status
└─ Scope: BASIC IDENTITY

LAYER 3: API Authorization ⭐ CRITICAL
├─ requirePermission() checks
├─ Role-based permission lookup
├─ Data scope enforcement
├─ Hierarchy authority checks
└─ Scope: PERMITS OR DENIES ACTION

LAYER 4: Data-level Constraints
├─ Database unique constraints
├─ Foreign key enforcement
├─ Check() constraints
└─ Scope: PREVENTS DATA CORRUPTION

LAYER 5: Audit Logging
├─ Log all successful access
├─ Log all denied attempts
├─ Log data modifications
└─ Scope: FORENSIC TRAIL
```

### 8.4 Why Frontend Hiding Is Not Security

| Aspect | Frontend Hiding | Backend Enforcement |
|--------|-----------------|-------------------|
| **Can user bypass?** | YES (F12 dev tools) | NO (server validates) |
| **Affects API calls?** | NO | YES |
| **Affects database?** | NO | YES |
| **Protects data?** | NO | YES |
| **Purpose** | UX/Speed | Security |

---

## PHASE 9: ADVANCED FEATURES (ENTERPRISE LEVEL)

### 9.1 Role Inheritance

Problem: Manager role should have all Staff permissions + additional ones.

Solution: Don't duplicate—define hierarchy:

```sql
-- Approach: Assign both roles
STAFF has: deals:view, deals:create
MANAGER adds: staff:view, approvals:approve

INSERT INTO staff_roles (staff_id, role_id)
SELECT s.id, r.id FROM staff s, roles r
WHERE s.position = 'Manager' AND r.name = 'manager';

-- Permissions are aggregated automatically
-- SELECT DISTINCT merges permissions from all assigned roles
```

Better: Define role hierarchy in business logic:

```javascript
/**
 * When checking permissions, consider role hierarchy
 */
async function getFullPermissionStack(userId) {
  const roles = await getUserRoles(userId);  // e.g., ['manager', 'finance_lead']
  
  const allPermissions = new Set();
  
  for (const role of roles) {
    // Each role might inherit from a base role
    const inheritedFrom = ROLE_HIERARCHY[role];  // 'manager' → ['user']
    
    const roleChain = [role, ...(inheritedFrom || [])];
    
    for (const r of roleChain) {
      const perms = await getPermissionsForRole(r);
      perms.forEach(p => allPermissions.add(`${p.module}.${p.action}`));
    }
  }
  
  return Array.from(allPermissions);
}

// Define hierarchy
const ROLE_HIERARCHY = {
  'superadmin': [],           // Inherits nothing (has all permissions by default)
  'admin': [],                // Has specific permissions, no inheritance
  'manager': ['user'],        // Manager gets user permissions + own
  'finance_lead': ['user'],   // Finance lead gets user permissions + own
  'user': [],                 // Base level
  'viewer': [],               // Base level
};
```

### 9.2 Temporary Permissions

Allow limited-time access:

```sql
-- Extend staff_roles with time windows
ALTER TABLE staff_roles ADD COLUMN
  effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  effective_until TIMESTAMPTZ;  -- NULL = indefinite

-- Example: Emergency access for 24 hours
INSERT INTO staff_roles (staff_id, role_id, effective_from, effective_until)
SELECT s.id, r.id, NOW(), NOW() + INTERVAL '24 hours'
FROM staff s, roles r
WHERE s.id = 'xyz' AND r.name = 'emergency_admin';
```

Enforce in permission checks:

```javascript
async function loadUserPermissionsFromDB(userId) {
  // Only include roles where the user is currently within effective window
  return await query(
    `SELECT DISTINCT p.module, p.action
     FROM users u
     JOIN staff s ON u.staff_id = s.id
     JOIN staff_roles sr ON sr.staff_id = s.id
     JOIN roles r ON r.id = sr.role_id
     JOIN role_permissions rp ON rp.role_id = r.id
     JOIN permissions p ON rp.permission_id = p.id
     WHERE u.id = $1
       AND sr.effective_from <= NOW()
       AND (sr.effective_until IS NULL OR sr.effective_until > NOW())
       AND r.is_active = true`,
    [userId]
  );
}
```

### 9.3 Audit Logging

Every RBAC action must be logged:

```javascript
/**
 * Log every permission-related action
 */
export async function logAuditEntry({
  user_id,
  action,                    // 'assigned_role', 'removed_permission'
  entity_type,               // 'role', 'permission', 'staff_role'
  entity_id,
  details = {},
  ip_address,
  user_agent
}) {
  await query(
    `INSERT INTO rbac_audit_logs 
     (user_id, action, entity_type, entity_id, details, ip_address, user_agent)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [user_id, action, entity_type, entity_id, JSON.stringify(details), ip_address, user_agent]
  );
}

// Usage in API routes
const ip = request.headers.get('x-forwarded-for') || request.socket.remoteAddress;
const ua = request.headers.get('user-agent');

// Log permission checks
await logAuditEntry({
  user_id: auth.userId,
  action: 'accessed_deals',
  entity_type: 'deals',
  entity_id: null,
  details: {
    permission_required: 'deals.view',
    permission_granted: true,
    data_scope: dataScope,
    record_count_returned: 42
  },
  ip_address: ip,
  user_agent: ua
});

// Log permission assignments
await logAuditEntry({
  user_id: auth.userId,
  action: 'assigned_role',
  entity_type: 'staff_role',
  entity_id: staffRoleId,
  details: {
    staff_id: staffId,
    role_name: 'manager',
    assigned_to_email: targetUser.email,
    effective_from: new Date(),
    effective_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)  // 7 days
  },
  ip_address: ip,
  user_agent: ua
});
```

### 9.4 Permission Overrides (Edge Cases)

When standard rules don't apply:

```sql
-- Temporary override table
CREATE TABLE permission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  permission_pattern VARCHAR(255),  -- 'deals.*' or 'deals.create'
  override_type VARCHAR(50),         -- 'grant' or 'deny'
  reason TEXT,
  created_by UUID REFERENCES users(id),
  effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  effective_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

Check overrides in permission logic:

```javascript
async function hasPermissionWith Overrides(userId, module, action) {
  // Check for explicit overrides first (highest priority)
  const override = await query(
    `SELECT override_type FROM permission_overrides
     WHERE user_id = $1
       AND (permission_pattern = $2 OR permission_pattern = $3)
       AND effective_from <= NOW()
       AND (effective_until IS NULL OR effective_until > NOW())
     LIMIT 1`,
    [userId, `${module}.${action}`, `${module}.*`]
  );
  
  if (override.rows.length > 0) {
    return override.rows[0].override_type === 'grant';  // Explicit grant or deny
  }
  
  // Normal permission check
  return await hasPermission(userId, module, action);
}
```

### 9.5 Approval Workflows

When user lacks authority for an action:

```javascript
/**
 * Hierarchy-aware approval
 */
export async function performOrApprove(userId, action, recordId, recordCreatorId) {
  const hierarchyCheck = await checkHierarchyAuthority(userId, recordCreatorId, action);
  
  if (hierarchyCheck.allowed) {
    // User has authority — execute immediately
    return { executed: true };
  }
  
  if (hierarchyCheck.requiresApproval) {
    // Create approval request — requires manager sign-off
    const approval = await createApprovalRequest({
      requesterUserId: userId,
      targetRecordType: determineRecordType(recordId),
      targetRecordId: recordId,
      actionRequested: action,
      reason: null
    });
    
    // Find approvers (people with higher authority in hierarchy)
    const approvers = await findApprovingAuthorities(userId);
    
    // Notify approvers
    await notifyApprovers(approvers, approval);
    
    return { approval_required: true, approval_id: approval.id };
  }
  
  // User cannot perform and approval won't help
  return { denied: true, reason: 'Insufficient authority' };
}
```

---

## PHASE 10: REAL-WORLD IMPLEMENTATION EXAMPLES

### 10.1 Example 1: New User Onboarding

**Scenario:** Hire a new salesperson named "Alice"

```javascript
/**
 * Step 1: Create user account
 */
const user = await pool.query(
  `INSERT INTO users (email, password_hash, role, status)
   VALUES ($1, $2, $3, $4)
   RETURNING id`,
  ['alice@company.com', bcrypt('securePassword'), 'user', 'pending']
);
const userId = user.rows[0].id;

// Log: User created
await logAuditEntry({
  user_id: adminUserId,
  action: 'created_user',
  entity_type: 'users',
  entity_id: userId,
  details: { email: 'alice@company.com', initial_status: 'pending' }
});

/**
 * Step 2: Create staff profile
 */
const staff = await pool.query(
  `INSERT INTO staff (user_id, full_name, email, position, department_id, hire_date)
   VALUES ($1, $2, $3, $4, $5, NOW())
   RETURNING id`,
  [userId, 'Alice Johnson', 'alice@company.com', 'Sales Rep', salesDeptId]
);
const staffId = staff.rows[0].id;

// Log: Staff record created
await logAuditEntry({
  user_id: adminUserId,
  action: 'created_staff_record',
  entity_type: 'staff',
  entity_id: staffId,
  details: { position: 'Sales Rep', department_id: salesDeptId }
});

/**
 * Step 3: Assign 'user' role (standard permissions)
 */
const staffRole = await pool.query(
  `INSERT INTO staff_roles (staff_id, role_id, assigned_by)
   VALUES ($1, (SELECT id FROM roles WHERE name = $2), $3)
   RETURNING id`,
  [staffId, 'user', adminUserId]
);

// Log: Role assignment
await logAuditEntry({
  user_id: adminUserId,
  action: 'assigned_role',
  entity_type: 'staff_role',
  entity_id: staffRole.rows[0].id,
  details: {
    staff_id: staffId,
    role_name: 'user',
    permissions: ['deals.view', 'deals.create', 'deals.update', ...]
  }
});

// Invalidate cache (new role takes effect immediately)
invalidatePermissionCache(userId);

/**
 * Step 4: Activate account
 */
await pool.query(
  'UPDATE users SET status = $1 WHERE id = $2',
  ['active', userId]
);

// Log: Account activated
await logAuditEntry({
  user_id: adminUserId,
  action: 'activated_account',
  entity_type: 'users',
  entity_id: userId
});

// RESULT: Alice can now:
// ✅ View deals (deals:view)
// ✅ Create deals (deals:create)
// ✅ Edit own deals (deals:update + OWN scope)
// ❌ Delete deals (permission not assigned)
// ❌ View finance reports (permission not assigned)
```

### 10.2 Example 2: Promoting Manager

**Scenario:** Promote Bob (staff) to Sales Manager

```javascript
/**
 * Step 1: Add 'manager' role while keeping 'user' role
 * (Manager inherits user permissions + gains management permissions)
 */
const staffId = await getStaffIdFromUserId(bobUserId);

const managerRole = await pool.query(
  `INSERT INTO staff_roles (staff_id, role_id, assigned_by)
   VALUES ($1, (SELECT id FROM roles WHERE name = $2), $3)
   RETURNING *`,
  [staffId, 'manager', adminUserId]
);

// Log: Manager role assigned
await logAuditEntry({
  user_id: adminUserId,
  action: 'assigned_role',
  entity_type: 'staff_role',
  entity_id: managerRole.rows[0].id,
  details: {
    staff_id: staffId,
    role_name: 'manager',
    previous_roles: ['user'],
    new_roles: ['user', 'manager'],
    permissions_gained: ['staff:view', 'staff:update', 'approvals:approve']
  }
});

// Invalidate cache
invalidatePermissionCache(bobUserId);

/**
 * Step 2: Set reports_to and update department_id
 */
await pool.query(
  `UPDATE staff SET department_id = $1 WHERE id = $2`,
  [salesDeptId, staffId]
);

// Log
await logAuditEntry({
  user_id: adminUserId,
  action: 'updated_staff_hierarchy',
  entity_type: 'staff',
  entity_id: staffId,
  details: { role_change: 'staff→manager', department: 'Sales' }
});

// RESULT: Bob can now:
// ✅ All his previous staff permissions
// ✅ View team members (staff:view)
// ✅ Update team members (staff:update, DEPARTMENT scope)
// ✅ Approve deals created in his department
// ❌ Delete staff (no staff:delete permission)
// ❌ Delete deals (no deals:delete permission)
```

### 10.3 Example 3: Temporary Emergency Access

**Scenario:** CEO needs finance access for one day

```javascript
/**
 * Grant 'finance_lead' role with 24-hour expiry
 */
const currentTime = new Date();
const expiryTime = new Date(currentTime.getTime() + 24 * 60 * 60 * 1000);  // +24h

const emergencyRole = await pool.query(
  `INSERT INTO staff_roles (
    staff_id, role_id, assigned_by, effective_from, effective_until
  ) VALUES (
    $1, (SELECT id FROM roles WHERE name = $2), $3, $4, $5
  ) RETURNING id`,
  [ceoStaffId, 'finance_lead', systemAdminUserId, currentTime, expiryTime]
);

// Log: Emergency access granted
await logAuditEntry({
  user_id: systemAdminUserId,
  action: 'granted_temporary_access',
  entity_type: 'staff_role',
  entity_id: emergencyRole.rows[0].id,
  details: {
    staff_id: ceoStaffId,
    role_name: 'finance_lead',
    reason: 'Quarterly financial review',
    duration_hours: 24,
    effective_from: currentTime.toISOString(),
    effective_until: expiryTime.toISOString(),
    auto_revokes_at: expiryTime.toISOString()
  }
});

invalidatePermissionCache(ceoUserId);

// After 24 hours (background job or next request):
// The effective_until check in permission loading will make this role inactive
// CEO automatically loses finance:manage permission
```

### 10.4 Example 4: Permission Denied with Approval Workflow

**Scenario:** Staff member tries to delete a deal they didn't create

```javascript
/**
 * In API route: DELETE /api/deals/[id]
 */
export async function DELETE(request, { params: { id } }) {
  // Step 1: Check basic permission
  const authResult = await requirePermission(request, 'deals.delete');
  if (authResult instanceof NextResponse) {
    return authResult;  // e.g., 403 "deals.delete not in permissions"
  }
  
  const { auth, dataScope } = authResult;
  const deal = await pool.query(
    'SELECT id, created_by, name FROM deals WHERE id = $1',
    [id]
  );
  
  if (!deal.rows[0]) {
    return NextResponse.json({ error: 'Deal not found' }, { status: 404 });
  }
  
  // Step 2: Check hierarchy authority
  const authority = await checkHierarchyAuthority(auth.userId, deal.rows[0].created_by, 'delete');
  
  if (authority.allowed) {
    // User has authority — execute
    await pool.query('DELETE FROM deals WHERE id = $1', [id]);
    
    await logAuditEntry({
      user_id: auth.userId,
      action: 'deleted_deal',
      entity_type: 'deals',
      entity_id: id,
      details: { deal_name: deal.rows[0].name, authorized: true }
    });
    
    return NextResponse.json({ success: true });
  }
  
  if (authority.requiresApproval) {
    // Cannot delete (insufficient authority) but approval might help
    const approval = await createApprovalRequest({
      requesterUserId: auth.userId,
      targetRecordType: 'deals',
      targetRecordId: id,
      actionRequested: 'delete',
      reason: null
    });
    
    // Find approver (someone with higher hierarchy_level)
    const dealCreator = await pool.query(
      'SELECT u.id FROM users u WHERE u.id = $1',
      [deal.rows[0].created_by]
    );
    
    const approvers = await pool.query(
      `SELECT DISTINCT u.id, u.email, s.full_name
       FROM users u
       JOIN staff s ON u.staff_id = s.id
       JOIN staff_roles sr ON sr.staff_id = s.id
       JOIN roles r ON r.id = sr.role_id
       WHERE r.hierarchy_level < $1  -- Only higher authority
         AND s.department_id = $2
       ORDER BY r.hierarchy_level ASC
       LIMIT 1`,
      [userHierarchyLevel, userDepartmentId]
    );
    
    // Send email to approver
    if (approvers.rows[0]) {
      await sendEmail({
        to: approvers.rows[0].email,
        subject: 'Deal Deletion Request Pending Approval',
        body: `${requesterName} is requesting to delete the deal "${deal.name}".`
      });
    }
    
    await logAuditEntry({
      user_id: auth.userId,
      action: 'requested_delete_approval',
      entity_type: 'deals',
      entity_id: id,
      details: {
        deal_name: deal.rows[0].name,
        created_by: deal.rows[0].created_by,
        requester_hierarchy: userHierarchyLevel,
        approval_id: approval.id,
        approver_id: approvers.rows[0]?.id
      }
    });
    
    return NextResponse.json({
      error: 'Approval required',
      message: 'Your request has been sent to your manager for approval',
      approval_id: approval.id
    }, { status: 202 });  // ACCEPTED (pending)
  }
  
  // Cannot delete under any circumstance
  await logAuditEntry({
    user_id: auth.userId,
    action: 'denied_delete_attempt',
    entity_type: 'deals',
    entity_id: id,
    details: {
      deal_name: deal.rows[0].name,
      created_by: deal.rows[0].created_by,
      reason: 'Insufficient authority even for approval'
    }
  });
  
  return NextResponse.json({
    error: 'Insufficient authority',
    message: 'You do not have permission to delete this deal'
  }, { status: 403 });
}
```

### 10.5 Example 5: Audit Log Query

**Scenario:** Admin queries what an employee did last week

```javascript
/**
 * In API route: GET /api/admin/audit-logs
 */
export async function GET(request) {
  // Only admin can access audit logs
  const authResult = await requirePermission(request, 'system.audit');
  if (authResult instanceof NextResponse) return authResult;
  
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get('user_id');
  const daysBack = parseInt(searchParams.get('days') || '7');
  
  // Find all actions by this user in past N days
  const logs = await pool.query(
    `SELECT 
      id, user_id, action, entity_type, entity_id, details,
      ip_address, user_agent, created_at
    FROM rbac_audit_logs
    WHERE user_id = $1
      AND created_at >= NOW() - INTERVAL $2 DAY
    ORDER BY created_at DESC`,
    [userId, daysBack]
  );
  
  // Parse and return
  const enriched = logs.rows.map(log => ({
    ...log,
    details: JSON.parse(log.details || '{}'),
    created_at: log.created_at.toISOString(),
    human_readable: humanizeAction(log.action, log.entity_type)
  }));
  
  return NextResponse.json(enriched);
}

// Helper to make logs readable
function humanizeAction(action, entityType) {
  const map = {
    'assigned_role': 'Assigned a role',
    'removed_role': 'Removed a role',
    'created_user': 'Created a user account',
    'viewed_deals': 'Viewed deals',
    'created_deal': 'Created a deal',
    'deleted_deal': 'Deleted a deal',
    'requested_delete_approval': 'Requested approval to delete',
    'denied_delete_attempt': 'Attempted unauthorized delete'
  };
  return map[action] || action;
}

/**
 * RESULT (example):
 * [
 *   {
 *     action: 'created_deal',
 *     entity_type: 'deals',
 *     human_readable: 'Created a deal',
 *     created_at: '2026-03-29T10:15:00Z',
 *     details: { deal_name: 'Acme Corp Q2', value: 50000 }
 *   },
 *   {
 *     action: 'viewed_deals',
 *     entity_type: 'deals',
 *     human_readable: 'Viewed deals',
 *     created_at: '2026-03-29T14:22:00Z',
 *     details: { record_count_returned: 12, data_scope: 'OWN' }
 *   },
 *   ...
 * ]
 */
```

---

## MIGRATION GUIDE: JETON → DRAIS

To port this architecture into DRAIS:

### Step 1: Database Setup
Copy the schema from Phase 5 directly. DRAIS will use identical tables.

### Step 2: Role Mapping
Map JETON roles to DRAIS roles:
```
JETON Superadmin → DRAIS SuperAdmin
JETON Admin      → DRAIS SystemAdmin
JETON Manager    → DRAIS SchoolAdmin (DEPARTMENT scoped to school)
JETON Staff      → DRAIS Teacher/Staff
JETON Viewer     → DRAIS Observer (read-only)
```

### Step 3: Permission Translation
Map JETON permissions to DRAIS resources:
```
JETON: deals            → DRAIS: courses|results|schools
JETON: finance          → DRAIS: fees|payments
JETON: staff            → DRAIS: teachers|admin staff
JETON: invoices         → DRAIS: fee invoices
DRAIS-specific:              payments, attendance, results_management
```

### Step 4: Reuse Authorization Code
The `permissions.js` library is portable — DRAIS can use it as-is with permission name updates.

### Step 5: Adapt Data Scoping
```
GLOBAL scope  → System-wide (superadmin only)
DEPARTMENT    → School-scoped (SchoolAdmin sees only their school)
OWN          → Personal records (teacher sees own submissions)
```

---

## SUMMARY & NEXT STEPS

This document provides:

✅ **Complete conceptual model** — 5 entities, relationships, purpose  
✅ **8-level organizational hierarchy** — from Superadmin to External  
✅ **Granular permission system** — module:action format, permission matrix  
✅ **Production database schema** — all tables, columns, indexes  
✅ **Authorization flow** — step-by-step decision logic  
✅ **API enforcement pattern** — requirePermission middleware  
✅ **Advanced features** — inheritance, temporary access, approval workflow  
✅ **Real-world examples** — onboarding, promotion, emergency access, audit  

**Status:** Ready for immediate implementation in JETON and porting to DRAIS.

---

**Document Version:** 1.0 | **Last Updated:** 2026-03-29 | **Author:** Senior Systems Architect

# RBAC ARCHITECTURE — QUICK REFERENCE GUIDE

## Document Location
📄 **File:** `RBAC_STAFF_ARCHITECTURE.md` (2,047 lines)  
**Status:** ✅ Complete, production-ready  
**Last Updated:** 2026-03-29  

---

## QUICK NAVIGATION

### Phase 1: Core Model
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 1  
**Topics:**
- Users, Roles, Permissions, Staff, Staff_Roles entities
- Why this 5-entity model
- Relationship diagram

### Phase 2: Hierarchy
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 2  
**Topics:**
- 8 organizational levels (1=Superadmin → 10=Restricted)
- Hierarchy_level vs Authority_level
- Scope of authority table

### Phase 3: Permissions
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 3  
**Topics:**
- Format: `module:action` (e.g., `deals:create`)
- Standard actions: view, create, update, delete, manage
- Permission matrix by role (Superadmin, Admin, Manager, Staff, Viewer)

### Phase 4: Data Scoping
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 4  
**Topics:**
- GLOBAL: all records
- DEPARTMENT: team records + own
- OWN: personal records only
- Multi-tenant support pattern

### Phase 5: Schema
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 5  
**Topics:**
- Complete CREATE TABLE statements
- All indexes and relationships
- Seed data for roles and permissions
- **READY TO EXECUTE**

### Phase 6: Authorization Flow
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 6  
**Topics:**
- Step-by-step request flow diagram
- Permission aggregation algorithm
- Authorization decision table

### Phase 7: API Enforcement
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 7  
**Topics:**
- `requirePermission()` middleware pattern
- 4 guard patterns with full code
- Cache invalidation strategy

### Phase 8: UI vs Backend
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 8  
**Topics:**
- Why frontend UI is NOT security
- Multi-layer defense diagram
- Attack chain example
- **Critical security principle**

### Phase 9: Advanced Features
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 9  
**Topics:**
- Role inheritance
- Temporary/time-limited roles
- Audit logging (rbac_audit_logs table)
- Permission overrides
- Approval workflows

### Phase 10: Implementation Examples
**File:** RBAC_STAFF_ARCHITECTURE.md → Section: PHASE 10  
**Topics:**
- User onboarding workflow
- Promotion to manager
- Emergency 24-hour access
- Permission denied + approval flow
- Audit log queries

---

## KEY TABLES

| Table | Purpose | Key Columns |
|-------|---------|------------|
| `users` | Auth + identity | id, email, role, status |
| `staff` | Employee profile | id, user_id, department_id, reports_to |
| `roles` | Role definitions | id, name, hierarchy_level, authority_level, data_scope |
| `permissions` | Granular actions | id, module, action, route_path, method |
| `staff_roles` | M:M staff → roles | staff_id, role_id, effective_until |
| `role_permissions` | M:M roles → perms | role_id, permission_id |
| `approval_requests` | Workflow | requester_user_id, status, approver_user_id |
| `rbac_audit_logs` | Complete audit trail | user_id, action, entity_type, details |

---

## KEY FUNCTIONS

### In `src/lib/permissions.js`

| Function | Purpose | Returns |
|----------|---------|---------|
| `requirePermission(request, 'module.action')` | API middleware | `{ auth, dataScope, departmentId }` or 403 error |
| `hasPermission(userId, module, action)` | Check permission | Boolean |
| `getUserDataScope(userId)` | Load user's scope | 'GLOBAL' \| 'DEPARTMENT' \| 'OWN' |
| `buildDataScopeFilter({...})` | SQL WHERE clause | `{ clause, params }` for scoping data |
| `getUserHierarchyLevel(userId)` | Get reporting level | Integer (1=top, 10=bottom) |
| `checkHierarchyAuthority(acting, creator, action)` | Authority check | `{ allowed, requiresApproval }` |
| `createApprovalRequest({...})` | Request approval | approval_requests row |
| `logAuditEntry({...})` | Log RBAC action | rbac_audit_logs row |
| `invalidatePermissionCache(userId)` | Refresh permissions | void |

---

## CORE CONCEPTS

### Authorization Decision Tree
```
1. Is token valid?          → NO → 401 Unauthorized
                            → YES → Next
2. Is account active?       → NO → 403 Forbidden
                            → YES → Next
3. Is user superadmin?      → YES → ALLOW (all access)
                            → NO → Next
4. Has required permission? → NO → 403 Forbidden
                            → YES → Next
5. Apply data scope filter  → Return filtered results
```

### Three Data Scopes
```
GLOBAL     Users can see:  All records in system
           Applied to:     Superadmin, Admin
           Example query:  SELECT * FROM deals

DEPARTMENT Users can see:  Records in their dept + own records
           Applied to:     Managers, Team Leads
           Example query:  WHERE dept_id = $1 OR created_by = $2

OWN        Users can see:  Only records they created
           Applied to:     Staff, Viewers, Contractors
           Example query:  WHERE created_by = $1
```

### Eight Hierarchy Levels
```
Level 1  Superadmin        → 100 authority (unrestricted)
Level 2  Admin             → 80 authority (org-wide)
Level 3  Manager           → 60 authority (department)
Level 5  Staff             → 40 authority (own records)
Level 8  Viewer            → 10 authority (read-only)
Level 10 Restricted        → 5 authority (minimal)

Lower number = Higher authority (can approve others)
```

---

## IMPLEMENTATION CHECKLIST

### For JETON (Already Implemented)
- ✅ Database schema (migrations 201, 930)
- ✅ Permission middleware (src/lib/permissions.js)
- ✅ API enforcement (requirePermission on all routes)
- ✅ Permission cache (5-minute TTL)
- ✅ Data scope filtering (buildDataScopeFilter)
- ✅ Audit logging (rbac_audit_logs table)

### For DRAIS (Porting)
- [ ] Copy database schema from Phase 5
- [ ] Update permission names for DRAIS modules
- [ ] Copy permissions.js library (minimal changes)
- [ ] Add requirePermission to DRAIS API routes
- [ ] Map JETON roles to DRAIS equivalent roles
- [ ] Test authorization flows
- [ ] Verify audit logging works
- [ ] Document role assignments for DRAIS staff

---

## CRITICAL SECURITY RULES

### Rule 1: No Frontend Security
**❌ WRONG:**
```javascript
if (user.hasPermission('deals.delete')) {
  <button>Delete</button>  // User can just remove button!
}
```

**✅ RIGHT:**
```javascript
// Backend MUST check
const authResult = await requirePermission(request, 'deals.delete');
if (authResult instanceof NextResponse) return authResult;
```

### Rule 2: Superadmin Bypass
Superadmin bypasses ALL checks:
- No permission checks
- No data scope filtering
- No hierarchy authority checks
- Direct query access to all records

### Rule 3: Cache Invalidation
When roles/permissions change, MUST invalidate:
```javascript
invalidatePermissionCache(userId);  // Single user
invalidateAllPermissionCaches();    // All users (expensive)
```

### Rule 4: Audit Everything
Log every RBAC action:
```javascript
await logAuditEntry({
  user_id, action, entity_type, entity_id,
  details: { /* context */ },
  ip_address, user_agent
});
```

### Rule 5: Temporal Constraints
Support time-limited roles:
```sql
effective_from TIMESTAMPTZ,
effective_until TIMESTAMPTZ,  -- NULL = indefinite
```

---

## PERMISSION NAMING CONVENTION

### Format
```
module:action
  module = resource type (deals, finance, staff, invoices)
  action = operation (view, create, update, delete, manage)
```

### Standard Actions
| Action | HTTP | Meaning |
|--------|------|---------|
| `view` | GET | Read access |
| `create` | POST | Create new |
| `update` | PUT | Edit existing |
| `delete` | DELETE | Remove |
| `manage` | ALL | Full control |

### Examples
```
deals:view           → GET /api/deals
deals:create         → POST /api/deals
deals:update         → PUT /api/deals
deals:delete         → DELETE /api/deals

finance:manage       → /api/finance (all operations)
staff:view           → GET /api/staff
invoices:approve     → POST /api/invoices/{id}/approve
```

---

## MODULE DIRECTORY

### Finance Module
```
finance:view         → Read financial data
finance:create       → Create transactions
finance:manage       → Full control
finance:approve      → Approve payments
finance:export       → Export reports
```

### Deals Module
```
deals:view           → List deals
deals:create         → Create deal
deals:update         → Edit deal
deals:delete         → Delete deal
deals:assign_owner   → Reassign ownership
```

### Staff Module
```
staff:view           → View directory
staff:create         → Hire employee
staff:update         → Edit profile
staff:delete         → Terminate employee
staff:manage_roles   → Assign roles
```

### System Control
```
system:manage        → Global settings
system:audit         → View all audit logs
```

---

## TESTING CHECKLIST

### Test Scenarios
- [ ] Superadmin can access everything
- [ ] Admin can't create new superadmins
- [ ] Manager only sees department records
- [ ] Staff member can only edit own records
- [ ] Temporary role expires after time window
- [ ] Permission cache invalidates correctly
- [ ] Approval request routes to right approver
- [ ] Audit logs record all actions
- [ ] Data scope filters work (GLOBAL/DEPT/OWN)
- [ ] Hierarchy authority blocks inappropriate deletes

### Audit Log Validation
```javascript
// Verify entry exists
SELECT * FROM rbac_audit_logs 
WHERE user_id = $1 AND action = 'assigned_role' AND created_at > NOW() - INTERVAL '1 hour';

// Check permission change
SELECT * FROM rbac_audit_logs
WHERE action LIKE 'assigned_%' 
ORDER BY created_at DESC LIMIT 10;
```

---

## MIGRATION JETON → DRAIS

**Step 1:** Copy database schema (Phase 5)  
**Step 2:** Update permission names (deals → courses, staff → teachers)  
**Step 3:** Copy permissions.js with module name updates  
**Step 4:** Map roles (Manager → SchoolAdmin)  
**Step 5:** Add requirePermission to all DRAIS routes  
**Step 6:** Test complete workflows  

---

## SUPPORT & QUESTIONS

### Common Questions

**Q: How do I check if user has permission?**
```javascript
const allowed = await hasPermission(userId, 'deals', 'view');
```

**Q: How do I filter data by scope?**
```javascript
const filter = buildDataScopeFilter({ dataScope, userId, departmentId });
const result = await pool.query(`SELECT * FROM deals ${filter.clause}`, filter.params);
```

**Q: How do I grant temporary access?**
```sql
INSERT INTO staff_roles (staff_id, role_id, effective_until)
VALUES ($1, $2, NOW() + INTERVAL '24 hours');
```

**Q: How do I revoke a role?**
```sql
UPDATE staff_roles SET revoked_at = NOW() WHERE staff_id = $1 AND role_id = $2;
```

**Q: How do I audit who did what?**
```sql
SELECT * FROM rbac_audit_logs WHERE user_id = $1 ORDER BY created_at DESC;
```

---

**Document Status:** ✅ Complete  
**Last Verified:** 2026-03-29  
**Implementation Status:** JETON (30%), DRAIS (Ready for porting)

# HARDENING PHASE - QUICK REFERENCE GUIDE

## New Tables

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `system_tech_stack` | Track tech stack per system | system_id, language, framework, database, platform |
| `salary_accounts` | Link staff salary to accounts | staff_id, account_id, salary_amount, frequency |
| `issues` | Issue tracking & analytics | title, severity, system_id, status, resolution_time |

## Enhanced Tables

| Table | New Columns | Purpose |
|-------|------------|---------|
| `payments` | currency, exchange_rate, amount_ugx | Multi-currency support |
| `accounts` | status, account_type | Account lifecycle management |
| `sessions` | invalidated_at, invalidation_reason | Session invalidation tracking |
| `users` | last_seen_at, online_status | Presence tracking |
| `operations_log` | duration_ms, status | Operation duration & status |
| `follow_ups` | status, user_id | Centralized follow-ups |
| `licenses` | validation_status, validated_at, validation_errors | License validation chain |

## New API Endpoints

### Tech Stack
```
GET    /api/systems/[systemId]/tech-stack
POST   /api/systems/[systemId]/tech-stack
PUT    /api/systems/[systemId]/tech-stack/[id]
DELETE /api/systems/[systemId]/tech-stack/[id]
```

### Issues
```
GET    /api/issues
POST   /api/issues
GET    /api/issues/[id]
PUT    /api/issues/[id]
DELETE /api/issues/[id]
```

### Follow-ups (Enhanced)
```
GET    /api/follow-ups
POST   /api/follow-ups
```

### Salary Accounts
```
GET    /api/salary-accounts
POST   /api/salary-accounts
```

### Accounts (Enhanced CRUD)
```
GET    /api/accounts
POST   /api/accounts
PUT    /api/accounts/[id]
PATCH  /api/accounts/[id]         (+ suspend/activate actions)
DELETE /api/accounts/[id]         (soft delete)
```

### Payments (Multi-Currency)
```
GET    /api/payments/convert?amount=X&currency=USD
POST   /api/payments              (auto-converts to UGX)
```

### Sessions
```
POST   /api/auth/sessions/invalidate
DELETE /api/auth/sessions/[sessionId]
```

### Presence
```
POST   /api/auth/me/presence      (heartbeat update)
GET    /api/auth/me/presence      (get current status)
```

### Staff
```
POST   /api/admin/staff/create-with-account  (transactional creation)
```

### Departments
```
PUT    /api/departments/[id]      (update)
DELETE /api/departments/[id]      (with safety checks)
```

### Licenses
```
POST   /api/admin/licenses/validate
PUT    /api/admin/licenses/validate (issue after validation)
```

### Data Consistency
```
GET    /api/admin/data-consistency/scan (detect orphans)
POST   /api/admin/data-consistency/fix  (auto-fix issues)
```

### Operations Log
```
GET    /api/operations-log
POST   /api/operations-log
```

## New Libraries

### Presence Tracker
```javascript
import { usePresenceTracker, calculateOnlineStatus } from '@/lib/presence-tracker.js'

const { isTracking, startTracking, stopTracking } = usePresenceTracker()
const status = calculateOnlineStatus(lastSeenAt)  // 'online' | 'away' | 'offline'
```

## New UI Components

```javascript
import {
  LoadingSpinner,
  Skeleton,
  TableSkeleton,
  CardSkeleton,
  EmptyState,
  ErrorState,
  FormError,
  FieldError
} from '@/components/ui/LoadingStates.jsx'

// Usage examples
<LoadingSpinner size="md" message="Loading..." />
<TableSkeleton rows={10} columns={5} />
<EmptyState icon={EmptyIcon} title="No data" description="..." action={<Button/>} />
<ErrorState title="Error" onRetry={() => retry()} />
```

## Database Functions

### Session Management
```sql
invalidate_user_sessions(user_id UUID, reason TEXT) -> INTEGER
```

### Data Cleanup
```sql
cleanup_orphaned_records() -> TABLE(orphan_type TEXT, record_count INTEGER)
```

### Presence Calculation
```sql
calculate_online_status(user_id UUID) -> VARCHAR(20)
```

### Currency Conversion
```sql
convert_payment_to_ugx(amount DECIMAL, currency VARCHAR, exchange_rate DECIMAL) -> DECIMAL
```

## Database Views

### Data Consistency
```sql
v_orphaned_users           -- Users not linked to staff/roles
v_orphaned_staff           -- Staff without user accounts  
v_invalid_roles            -- Invalid role assignments
v_inconsistent_currencies  -- Payment currency mismatches
```

## Database Triggers

### Session Management
```sql
trg_staff_delete       -- Invalidate sessions when staff deleted
trg_staff_deactivate   -- Invalidate sessions when staff deactivated
```

## Migration Files

- **945_hardening_phase_schema.sql** - Core tables and columns
- **946_data_consistency_logging.sql** - Procedures, triggers, views, cleanup logic

## Quick Start Examples

### Create Tech Stack Entry
```bash
curl -X POST http://localhost:3000/api/systems/[SYSTEM_ID]/tech-stack \
  -H "Content-Type: application/json" \
  -d '{
    "language": "Node.js",
    "framework": "Next.js",
    "database": "PostgreSQL",
    "platform": "Web",
    "notes": "Production stack"
  }'
```

### Create Issue
```bash
curl -X POST http://localhost:3000/api/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Payment processing slow",
    "description": "Payments take > 5 seconds",
    "severity": "critical",
    "system_id": "[SYSTEM_ID]",
    "assigned_to": "[USER_ID]"
  }'
```

### Convert Currency
```bash
curl "http://localhost:3000/api/payments/convert?amount=100&currency=USD&exchange_rate=3800"
```

### Create Staff with Account (Transaction)
```bash
curl -X POST http://localhost:3000/api/admin/staff/create-with-account \
  -H "Content-Type: application/json" \
  -d '{
    "staff_name": "John Doe",
    "staff_email": "john@example.com",
    "username": "johndoe",
    "password": "SecurePass123!",
    "role_name": "manager",
    "department_id": "[DEPT_ID]"
  }'
```

### Invalidate User Sessions
```bash
curl -X POST http://localhost:3000/api/auth/sessions/invalidate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "[USER_ID]",
    "reason": "Staff deactivated"
  }'
```

### Update Presence (Heartbeat)
```javascript
// Automatic via usePresenceTracker()
// Or manual:
fetch('/api/auth/me/presence', {
  method: 'POST',
  body: JSON.stringify({
    last_seen_at: new Date().toISOString()
  })
})
```

### Scan Data Consistency
```bash
curl http://localhost:3000/api/admin/data-consistency/scan
```

### Fix Data Issues
```bash
curl -X POST http://localhost:3000/api/admin/data-consistency/fix
```

## Monitoring & Logging

### View System Logs
```sql
SELECT * FROM system_logs 
WHERE level IN ('error', 'critical')
ORDER BY created_at DESC
LIMIT 100;
```

### Check Orphaned Records
```sql
SELECT * FROM v_orphaned_users;
SELECT * FROM v_orphaned_staff;
SELECT * FROM v_invalid_roles;
```

### Monitor Session Invalidations
```sql
SELECT * FROM sessions
WHERE invalidated_at IS NOT NULL
ORDER BY invalidated_at DESC;
```

### Track Presence
```sql
SELECT username, online_status, last_seen_at 
FROM users 
ORDER BY last_seen_at DESC;
```

### View Issue Analytics
```sql
SELECT 
  severity,
  COUNT(*) as count,
  ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 60)::numeric, 1) as avg_minutes
FROM issues
GROUP BY severity
ORDER BY severity;
```

## Performance Indexes

All critical queries have indexes:
- System lookups: `idx_system_tech_stack_system_id`
- Issue filtering: `idx_issues_system_id`, `idx_issues_status`, `idx_issues_severity`
- Session validity: `idx_sessions_user_id_active`
- User presence: `idx_users_last_seen_at`
- Salary accounts: `idx_salary_accounts_staff_id`, `idx_salary_accounts_account_id`

## Configuration

### Exchange Rates
Hardcoded defaults (enhance with config service):
- USD: 3800
- EUR: 4200
- GBP: 4800
- ZAR: 200
- KES: 36

### Presence Intervals
- Heartbeat: 30 seconds
- Online: < 60 seconds
- Away: 1-5 minutes
- Offline: > 5 minutes

## Troubleshooting

### Sessions Not Invalidating
Check: `SELECT * FROM sessions WHERE user_id = '[ID]' AND invalidated_at IS NULL;`

### Missing Tech Stack
Ensure `system_id` exists: `SELECT * FROM systems WHERE id = '[ID]';`

### Currency Conversion Failing
Verify `currency` field populated: `SELECT * FROM payments WHERE currency IS NULL;`

### Orphaned Records
Run: `SELECT * FROM cleanup_orphaned_records();`

### Log Storage
Monitor: `SELECT COUNT(*) FROM system_logs WHERE created_at > NOW() - INTERVAL '1 day';`

---

**For complete details, see: HARDENING_PHASE_COMPLETE.md**

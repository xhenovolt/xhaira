# 🚀 Enterprise User Governance - Quick Setup Guide

## One-Minute Setup

```bash
# 1. Apply migration
node scripts/setup-governance.js

# 2. Open browser
http://localhost:3000/admin/users

# 3. Log in as superadmin
Email: xhenonpro@gmail.com
(Account must exist - create via registration first if needed)

# 4. Start managing users!
```

## What Just Happened?

Your database now has:
- ✅ 10 new tables for RBAC
- ✅ 4 system roles (superadmin, admin, staff, viewer)
- ✅ 40 permissions across 10 modules
- ✅ Session tracking (device, browser, geolocation)
- ✅ Activity analytics
- ✅ Immutable audit logs

## Key Files

| File | Purpose |
|------|---------|
| `migrations/015_user_access_governance.sql` | Database schema |
| `src/app/api/admin/` | API endpoints |
| `src/app/admin/users/` | Admin UI |
| `src/lib/auth-enhanced.js` | Permission utilities |
| `ENTERPRISE_USER_GOVERNANCE_GUIDE.md` | Detailed docs |

## Admin Panel Features

### `/admin/users`
- 📋 List all users
- ➕ Create new users
- 🔄 Filter by status
- ✏️ Edit user details
- 🔐 Manage roles
- 📱 View active sessions
- 🔨 Kill sessions

### User Detail Page
- 👤 Edit profile (name, username, dept, phone)
- 📸 Set profile photo
- 🔐 Assign roles
- 📱 View/kill sessions
- 📊 Activity stats
- ⚙️ Account settings

## Common Tasks

### Create a New User
```bash
POST /api/admin/users
{
  "email": "john@example.com",
  "username": "john_doe",
  "full_name": "John Doe",
  "password": "SecurePassword123",
  "department": "Engineering"
}
```

### Activate Dormant User
```bash
PATCH /api/admin/users/[userId]
{
  "status": "active"
}
```

### Assign Roles
```bash
PATCH /api/admin/users/[userId]
{
  "role_ids": ["admin-uuid", "staff-uuid"]
}
```

### Kill a Session
```bash
DELETE /api/admin/users/[userId]/sessions/[sessionId]
```

### View Audit Trail
```bash
GET /api/admin/audit-logs?limit=50&page=1
```

### Get Analytics
```bash
GET /api/admin/activity-analytics?period=7
```

## User Statuses

| Status | Meaning | Can Login? |
|--------|---------|-----------|
| **active** | Ready to use | ✅ Yes |
| **inactive** | Disabled | ❌ No |
| **dormant** | Awaiting activation | ❌ No |
| **suspended** | Revoked access | ❌ No |

## Roles & Permissions

### Superadmin
- Has ALL permissions
- Cannot be deleted/demoted
- Is xhenonpro@gmail.com

### Admin
- Can manage users
- Can manage roles
- Cannot access audit settings

### Staff
- Module-specific access
- View, Create, Update
- Cannot delete

### Viewer
- Read-only access
- All modules

## Security Rules

🔒 **Immutable Superadmin**
```
- Cannot delete: xhenonpro@gmail.com
- Cannot demote: is_superadmin = true
- System prevents modifications
```

🔐 **Session Tracking**
```
- Device name, Browser, OS
- IP address + Geolocation
- Last activity timestamp
- Admin can kill sessions
```

📋 **Audit Logging**
```
- Append-only (cannot delete)
- Every action logged
- Actor, IP, timestamp, changes
- Immutable for compliance
```

## Real User Data

The navbar shows:
- ✅ Real user from database (not mocked)
- ✅ Real roles from user_roles table
- ✅ Real permissions from role_permissions
- ✅ Real active sessions count
- ✅ Real last seen timestamp

## Troubleshooting

### "Access Denied" Error
→ You're not superadmin/admin
→ Ask your admin to assign you the admin role

### Can't See "/admin/users"
→ Not logged in
→ Or not an admin
→ Check status in /api/auth/me

### User Can't Login
→ Status is not "active"
→ Change status from admin panel
→ Or dormant user waiting activation

### Sessions Not Showing
→ No active sessions for this user
→ Sessions expire after 30 days
→ Check if user is logged in elsewhere

## Next Steps

1. **Create Users**
   - Go to /admin/users
   - Click "+ New User"
   - Activate them (status → active)

2. **Assign Roles**
   - Click user name
   - Select roles
   - Save

3. **Manage Permissions**
   - Go to admin/roles
   - Modify role permissions
   - Changes apply immediately

4. **Monitor Activity**
   - Check audit logs
   - View analytics
   - Track user sessions

## Advanced Usage

### Permission Overrides
Grant temporary permission to user (with optional expiry):
```javascript
INSERT INTO user_permissions (user_id, permission_id, expires_at)
SELECT u.id, p.id, NOW() + INTERVAL '7 days'
FROM users u, permissions p
WHERE u.id = '[userId]' AND p.name = 'reports.delete'
```

### Bulk Activate Users
```sql
UPDATE users 
SET status = 'active' 
WHERE status = 'dormant' 
AND created_at > NOW() - INTERVAL '1 day';
```

### View Active Sessions
```bash
GET /api/admin/users/[userId]/sessions
```

### Check User Permissions
```bash
GET /api/admin/users/[userId]
```
(Returns roles + permissions)

## Documentation

📖 **Full Documentation**
→ Read `ENTERPRISE_USER_GOVERNANCE_GUIDE.md`

🏗️ **Architecture**
→ Check `GOVERNANCE_IMPLEMENTATION_COMPLETE.md`

## Support

- Check the comprehensive guide first
- Review API comments in code
- Check database schema in migration
- Look at error messages/logs

---

**You're all set!** 🎉

Your enterprise governance system is ready to use.

Start at: `/admin/users`

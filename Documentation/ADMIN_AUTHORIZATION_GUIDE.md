# Admin Access & Authorization System

## Overview

The Jeton admin panel now includes a robust authorization system with clear error messages and proper HTTP status codes.

## Error Codes & Responses

### 401 Unauthorized
**When:** User is not logged in or session has expired
**Message:** "You must be logged in to access the admin panel."
**Action:** Redirects to login page
**UI:** Orange-themed error card with "Log In" button

### 403 Forbidden  
**When:** User is logged in but does not have admin/superadmin role
**Message:** Shows user's email and explains they don't have admin privileges
**Action:** Provides "Back to Dashboard" button
**UI:** Red-themed error card with account information

### 500 Server Error
**When:** Error checking authorization
**Message:** "An error occurred while checking your permissions. Please try again."
**Action:** Provides "Retry" button
**UI:** Gray-themed error card

## Admin Routes

All these routes require `admin` or `superadmin` role:

- `/admin/users` - User Management
- `/admin/users/[userId]` - Edit User
- `/admin/roles` - Roles & Permissions
- `/admin/audit-logs` - Audit Trail
- `/admin/activity-analytics` - Activity Analytics

## How Authorization Works

1. **User visits admin route** (e.g., `/admin/users`)
2. **AdminLayout component loads**
3. **Checks session** via `/api/auth/me` endpoint
4. **Validates user role:**
   - ✅ If `is_superadmin = true` → Allow access
   - ✅ If role includes 'admin' or 'superadmin' → Allow access
   - ❌ Otherwise → Show 403 error
5. **Shows appropriate error** or renders admin page

## Database Requirements

### User Roles Setup

For a user to access admin pages, they must be assigned the `admin` role:

```sql
-- 1. Ensure roles table has 'admin' role
INSERT INTO roles (role_name, description, is_system_role) 
VALUES ('admin', 'System Administrator', true)
ON CONFLICT (role_name) DO NOTHING;

-- 2. Assign admin role to user
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE u.email = 'xhenonpro@gmail.com' 
  AND r.role_name = 'admin'
ON CONFLICT DO NOTHING;
```

Or set superadmin flag directly:

```sql
UPDATE users SET is_superadmin = true WHERE email = 'xhenonpro@gmail.com';
```

### Required Tables

The migration `migrations/015_user_access_governance.sql` creates:
- `roles` - Role definitions
- `permissions` - Permission definitions
- `user_roles` - User-Role mapping (many-to-many)
- `role_permissions` - Role-Permission mapping (many-to-many)
- `sessions` - Session tracking with device info
- `activity_logs` - User activity tracking
- `audit_logs` - System event audit trail
- Enhanced `users` table with: `is_superadmin`, `profile_photo_url`, `full_name`

## Testing the Authorization System

### Test Case 1: Not Logged In
1. Open incognito/private window
2. Navigate to `/admin/users`
3. **Expected:** See 401 error with "You must be logged in" message
4. **Action:** Click "Log In" button

### Test Case 2: Logged In But Not Admin
1. Log in as non-admin user
2. Navigate to `/admin/users`
3. **Expected:** See 403 error with account email shown
4. **Message:** "does not have administrator privileges"
5. **Action:** Click "Back to Dashboard" button

### Test Case 3: Logged In As Admin
1. Log in as admin user (with admin role or is_superadmin=true)
2. Navigate to `/admin/users`
3. **Expected:** Admin page loads successfully
4. **Header:** Shows "Administration Panel" with admin badge

## Making a User Admin

### Method 1: Via Database (Recommended for testing)
```sql
UPDATE users SET is_superadmin = true WHERE email = 'xhenonpro@gmail.com';
```

### Method 2: Via API (requires existing admin)
```bash
curl -X POST http://localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -H "Cookie: jeton_session=..." \
  -d '{
    "email": "newadmin@example.com",
    "username": "newadmin",
    "full_name": "New Admin",
    "password": "SecurePassword123!",
    "role_ids": [<admin_role_id>]
  }'
```

### Method 3: Via UI (once first admin exists)
1. Go to `/admin/users`
2. Click "Create User"
3. Fill in details
4. Assign "admin" role
5. Click "Create User"

## Troubleshooting

### Issue: Still seeing login redirect for admin user
**Solution:**
1. Verify user has admin role assigned in `user_roles` table:
   ```sql
   SELECT ur.*, r.role_name FROM user_roles ur 
   JOIN roles r ON ur.role_id = r.id
   WHERE ur.user_id = (SELECT id FROM users WHERE email = 'your@email.com');
   ```

2. Or verify is_superadmin flag:
   ```sql
   SELECT is_superadmin FROM users WHERE email = 'your@email.com';
   ```

3. Clear browser cache and refresh page

### Issue: 403 error but should be admin
1. Check admin role exists in database:
   ```sql
   SELECT * FROM roles WHERE role_name = 'admin';
   ```

2. Verify user is assigned to admin role:
   ```sql
   SELECT ur.* FROM user_roles ur 
   WHERE ur.user_id = (SELECT id FROM users WHERE email = 'your@email.com');
   ```

3. Run migration if not applied:
   ```bash
   npm run migration:up
   ```

### Issue: Getting 500 error
1. Check server console for error logs
2. Verify `/api/auth/me` endpoint is working:
   ```bash
   curl http://localhost:3000/api/auth/me \
     -H "Cookie: jeton_session=..."
   ```

3. Check database connection is working

## API Endpoints Used

### GET `/api/auth/me`
Returns current user info with roles

**Headers:**
```
Cookie: jeton_session=<session_id>
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "email": "admin@example.com",
    "username": "admin",
    "full_name": "Admin User",
    "is_superadmin": true,
    "roles": ["admin"],
    "profile_photo_url": "...",
    "status": "active"
  }
}
```

**Response (401):**
```json
{
  "error": "Unauthorized"
}
```

## Security Features

1. **Server-side authorization check** - Not just client-side
2. **Role-based access control** - Users need explicit admin role
3. **Session validation** - Every request validates session
4. **Audit logging** - All admin actions are logged
5. **Clear error messages** - Users know why they can't access something
6. **No information leakage** - Error messages don't reveal sensitive info

## Admin Pages Available (After Authorization)

### `/admin/users`
- View all system users
- Create new users
- Edit user profiles
- Manage user roles
- View active sessions
- Deactivate accounts

### `/admin/roles`
- View all roles
- Create custom roles
- Assign permissions to roles

### `/admin/audit-logs`
- View system activity
- Filter by action, entity, user, date
- Search capability
- Export logs

### `/admin/activity-analytics`
- Active users count
- Online users count
- Module usage statistics
- Feature popularity
- User behavior analysis
- Refresh analytics

## Next Steps

1. **Apply migration:** `npm run migration:up`
2. **Make yourself admin:** Update `is_superadmin` to true in database
3. **Test access:** Navigate to `/admin/users`
4. **Verify error messages:** Try logging out and accessing admin routes
5. **Create other admins:** Use `/admin/users` page to create additional admin accounts

# Quick Reference: Admin Access Setup

## Problem Solved
When accessing `/admin/*` routes, you were silently redirected to login. Now you get clear error messages with HTTP status codes and actionable solutions.

## Error Codes Explained

| Code | Meaning | What to Do |
|------|---------|-----------|
| **401** | Not logged in | Click "Log In" button |
| **403** | Logged in but not admin | Contact your admin or check database |
| **500** | Server error | Refresh page or check logs |

## Make Yourself Admin (Pick One)

### Option 1: Quickest (Superadmin)
```sql
UPDATE users SET is_superadmin = true 
WHERE email = 'xhenonpro@gmail.com';
```

### Option 2: Recommended (Admin Role)
```sql
-- Make sure admin role exists
INSERT INTO roles (role_name, description) 
VALUES ('admin', 'Administrator')
ON CONFLICT DO NOTHING;

-- Assign admin role to user
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE u.email = 'xhenonpro@gmail.com'
  AND r.role_name = 'admin'
ON CONFLICT DO NOTHING;
```

## Test It

1. **Grant yourself admin access** (use SQL above)
2. **Clear browser cache** (Ctrl+Shift+Delete)
3. **Log in** (or log out and back in)
4. **Go to** `/admin/users`
5. **Expected:** Admin dashboard loads ✅

## If Still Getting 403

```sql
-- Check if you have admin role
SELECT u.email, ARRAY_AGG(r.role_name) as roles
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
WHERE u.email = 'xhenonpro@gmail.com'
GROUP BY u.email;

-- Check if superadmin flag is set
SELECT is_superadmin FROM users 
WHERE email = 'xhenonpro@gmail.com';
```

## Admin Routes Now Available
- `/admin/users` - Manage users
- `/admin/roles` - Manage roles
- `/admin/audit-logs` - View activity
- `/admin/activity-analytics` - View analytics

## Browser Console

You'll see helpful logs:
```javascript
Authorization Check: {
  email: "you@email.com",
  is_superadmin: true,
  roles: ["admin"],
  isAdmin: true  // ✅ Access granted
}
```

## Need Help?

1. Check browser console (F12) for logs
2. Run the SQL verification queries above
3. Verify migration 015 was applied
4. Clear cache and refresh
5. Try incognito window to test

---

**All admin pages now show professional error messages with clear instructions instead of silent redirects!**

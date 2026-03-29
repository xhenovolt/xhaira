# Implementation Commands - Complete the Refactoring

## 🎯 Quick Start Commands

### 1. Verify Installation

```bash
# Check Node.js and npm
node --version
npm --version

# Install dependencies
npm install

# Check environment variables
cat .env.local
```

### 2. Setup Local Database

```bash
# Run database migrations (creates sessions table)
node scripts/init-db.js

# Verify sessions table was created
psql $DATABASE_URL -c "\\dt sessions"
psql $DATABASE_URL -c "SELECT * FROM sessions LIMIT 1"
```

### 3. Test Locally

```bash
# Start development server
npm run dev

# In another terminal, test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  -i

# Look for Set-Cookie: jeton_session=... header
```

---

## 📝 Remaining API Routes to Update

### Pattern for Each File

Each API route needs these changes:

```diff
- import { verifyToken } from '@/lib/jwt.js';
+ import { requireApiAuth } from '@/lib/api-auth.js';

- const token = ...
- const decoded = verifyToken(token);
+ const user = await requireApiAuth();

- decoded.userId
+ user.userId
```

### File-by-File Updates

#### 1. `/api/liabilities/[id]`

```bash
# Files to update
src/app/api/liabilities/[id]/route.js

# Changes needed
- Import requireApiAuth instead of verifyToken
- Replace all token verification logic
- Replace decoded.userId with user.userId
- Add try/catch with Response check
```

#### 2. `/api/assets/[id]`

```bash
src/app/api/assets/[id]/route.js

# Copy the pattern from assets/route.js (already updated)
# Apply same changes to [id] routes
```

#### 3. `/api/deals/[id]`

```bash
src/app/api/deals/[id]/route.js

# Copy the pattern from deals/route.js (already updated)
```

#### 4. `/api/deals/valuation`

```bash
src/app/api/deals/valuation/route.js

# Single endpoint, straightforward update
```

#### 5. `/api/net-worth`

```bash
src/app/api/net-worth/route.js

# GET endpoint, simple update
```

#### 6. `/api/staff`

```bash
src/app/api/staff/route.js

# GET and POST handlers
```

#### 7. `/api/staff/[id]`

```bash
src/app/api/staff/[id]/route.js

# GET, PATCH, DELETE handlers
```

#### 8. `/api/snapshots`

```bash
src/app/api/snapshots/route.js

# GET and POST
```

#### 9. `/api/snapshots/[id]`

```bash
src/app/api/snapshots/[id]/route.js

# GET, PATCH, DELETE
```

#### 10. `/api/snapshots/create`

```bash
src/app/api/snapshots/create/route.js

# POST endpoint
```

#### 11. `/api/reports/financial`

```bash
src/app/api/reports/financial/route.js

# GET endpoint
```

#### 12. `/api/reports/executive`

```bash
src/app/api/reports/executive/route.js

# GET endpoint
```

#### 13. Bonus Routes (If They Exist)

```bash
# Check for any other routes still importing jwt
grep -r "from '@/lib/jwt" src/app/api --include="*.js"

# Update any remaining files found
```

---

## 🔍 Verification Commands

### Check Progress

```bash
# Count files still using JWT
grep -r "from '@/lib/jwt" src/app/api --include="*.js" | wc -l

# List all files still using JWT
grep -r "from '@/lib/jwt" src/app/api --include="*.js" | cut -d: -f1 | sort -u

# Check imports of api-auth
grep -r "from '@/lib/api-auth" src/app/api --include="*.js" | wc -l
```

### Verify Migrations

```bash
# Check if sessions table exists
psql $DATABASE_URL -c "SELECT table_name FROM information_schema.tables WHERE table_name='sessions';"

# Check sessions table structure
psql $DATABASE_URL -c "\\d sessions"

# Check indexes
psql $DATABASE_URL -c "SELECT indexname FROM pg_indexes WHERE tablename='sessions';"
```

### Test Each Updated Route

```bash
# After updating each route, test it
curl http://localhost:3000/api/assets -i
curl http://localhost:3000/api/deals -i
curl http://localhost:3000/api/liabilities -i

# Should return 401 without session cookie
# Should return 200 with valid session cookie
```

---

## 🧪 Complete Testing Workflow

### 1. Setup

```bash
# Clean start
rm src/app/api/auth/__cache__ 2>/dev/null || true
npm run build
npm run dev
```

### 2. Test Login

```bash
# Create test user (if not exists)
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"test123456"
  }' -i

# Login and capture session
SESSION=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123456"}' \
  -v 2>&1 | grep "jeton_session=" | \
  sed 's/.*jeton_session=//;s/;.*//')

echo "Session ID: $SESSION"
```

### 3. Test Protected Routes

```bash
# Test with valid session
curl http://localhost:3000/api/assets \
  -H "Cookie: jeton_session=$SESSION" -i

# Test without session (should be 401)
curl http://localhost:3000/api/assets -i

# Test dashboard (should work)
curl http://localhost:3000/dashboard \
  -H "Cookie: jeton_session=$SESSION" \
  -i | head -20
```

### 4. Test Logout

```bash
# Logout
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Cookie: jeton_session=$SESSION" -i

# Try to use old session (should redirect)
curl http://localhost:3000/api/assets \
  -H "Cookie: jeton_session=$SESSION" -i

# Should be 401
```

### 5. Database Verification

```bash
# Check session was created
psql $DATABASE_URL -c "SELECT COUNT(*) FROM sessions;"

# Check session is valid
psql $DATABASE_URL -c "
  SELECT s.id, s.user_id, s.expires_at 
  FROM sessions s 
  WHERE s.expires_at > NOW() 
  LIMIT 1;
"

# Check after logout (should be deleted or expired)
psql $DATABASE_URL -c "
  SELECT COUNT(*) FROM sessions 
  WHERE s.expires_at > NOW();
"
```

---

## 📦 Deployment Commands

### Pre-Deployment Verification

```bash
# Check all files compile
npm run build

# Run linter (if configured)
npm run lint

# Type check (if using TypeScript)
npm run type-check

# Check for any remaining JWT imports
grep -r "jwt" src --include="*.js" --include="*.ts" | grep -v "node_modules" | grep -v ".next"
```

### Deploy to Vercel

```bash
# Commit changes
git add .
git commit -m "refactor: complete session-based authentication migration"

# Push (Vercel auto-deploys)
git push origin main

# Monitor deployment
# View Vercel dashboard for logs

# After deployment succeeds
# Test in production: https://your-domain.vercel.app
```

### Post-Deployment

```bash
# Test production login
curl -X POST https://your-domain.vercel.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  -i

# Check for httpOnly flag in Set-Cookie
# Should see: Set-Cookie: jeton_session=...; HttpOnly; Secure; ...

# Test protected route
curl https://your-domain.vercel.app/api/assets \
  -H "Cookie: jeton_session=<sessionid>" \
  -i
```

---

## 🔧 Optional: Cleanup Old Code

### Remove JWT Dependency

```bash
# After confirming all routes work without JWT

# Remove from package.json
npm uninstall jsonwebtoken

# Delete JWT file
rm src/lib/jwt.js

# Verify no imports of jwt.js remain
grep -r "jwt.js" src --include="*.js"

# Should return no results
```

### Remove JWT_SECRET from Environment

```bash
# Remove from .env.local
# Remove: JWT_SECRET=...

# Remove from Vercel
# Dashboard → Settings → Environment Variables
# Delete JWT_SECRET

# Verify it's gone
env | grep JWT
# Should return nothing
```

---

## 📊 Monitoring Commands

### Session Metrics

```bash
# Active sessions
psql $DATABASE_URL -c "
  SELECT COUNT(*) as active_sessions 
  FROM sessions 
  WHERE expires_at > NOW();
"

# Sessions created today
psql $DATABASE_URL -c "
  SELECT COUNT(*) as new_sessions_today
  FROM sessions 
  WHERE DATE(created_at) = CURRENT_DATE;
"

# Session expiration distribution
psql $DATABASE_URL -c "
  SELECT 
    DATE(expires_at) as expiry_date,
    COUNT(*) as count
  FROM sessions
  WHERE expires_at > NOW()
  GROUP BY DATE(expires_at)
  ORDER BY expiry_date;
"
```

### User Activity

```bash
# Active users (with sessions)
psql $DATABASE_URL -c "
  SELECT COUNT(DISTINCT user_id) 
  FROM sessions 
  WHERE expires_at > NOW();
"

# Recent logins
psql $DATABASE_URL -c "
  SELECT DISTINCT 
    al.user_id,
    al.created_at
  FROM audit_logs al
  WHERE al.action = 'LOGIN_SUCCESS'
  AND al.created_at > NOW() - INTERVAL '24 hours'
  ORDER BY al.created_at DESC;
"
```

### Error Monitoring

```bash
# Check middleware logs (from application monitoring)
# Look for: "Session validation error"

# Check for 401 responses (from logs)
# Spike in 401s might indicate session validation issues

# Monitor database query time
# Each session lookup should be < 50ms
```

---

## 🚨 Troubleshooting Commands

### If Sessions Aren't Created

```bash
# Check database connection
psql $DATABASE_URL -c "SELECT NOW();"

# Check sessions table exists
psql $DATABASE_URL -c "\\dt sessions"

# Check sessions table structure
psql $DATABASE_URL -c "\\d sessions"

# Try manual insert
psql $DATABASE_URL -c "
  INSERT INTO sessions (user_id, expires_at) 
  VALUES ('550e8400-e29b-41d4-a716-446655440000'::uuid, NOW() + INTERVAL '7 days')
  RETURNING id;
"
```

### If Cookies Aren't Httponly

```bash
# Check response headers
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  -v 2>&1 | grep -i "set-cookie"

# Should see: HttpOnly (in development: might not see Secure flag)
# In production: Should see both HttpOnly and Secure
```

### If Middleware Isn't Protecting Routes

```bash
# Check middleware.js is deployed
grep -n "validateSession" src/../middleware.js

# Check matcher config
grep -n "matcher" middleware.js

# Test middleware directly
curl http://localhost:3000/dashboard -i
# Should redirect to /login (301)
```

### If 401 Responses on Protected Routes

```bash
# Verify session exists in database
psql $DATABASE_URL -c "
  SELECT COUNT(*) FROM sessions 
  WHERE expires_at > NOW();
"

# Verify session ID matches cookie
curl http://localhost:3000/api/auth/me \
  -H "Cookie: jeton_session=<id>" \
  -v 2>&1 | grep -i "jeton_session"

# Check error logs for session validation failures
# Look for: "Session validation error" in logs
```

---

## ✅ Completion Checklist

### Day 1: Testing
- [ ] Verify local setup works
- [ ] Test login creates session
- [ ] Test logout deletes session
- [ ] Test protected route protection

### Day 2: API Routes
- [ ] Update 13 remaining API routes
- [ ] Test each updated route
- [ ] Verify all return 401 without session

### Day 3: Deployment
- [ ] Run build and linting
- [ ] Deploy to staging
- [ ] Test staging login/logout
- [ ] Deploy to production
- [ ] Verify production login works

### After Deployment
- [ ] Monitor error logs
- [ ] Check session creation rate
- [ ] Verify httpOnly flag in production
- [ ] Test from multiple browsers
- [ ] Optional: Cleanup JWT code

---

## 📞 Quick Help

### Can't login?
1. Check database connection: `psql $DATABASE_URL -c "SELECT NOW();"`
2. Check user exists: `psql $DATABASE_URL -c "SELECT * FROM users WHERE email='test@example.com';"`
3. Check password is correct
4. Look for errors in server logs

### Middleware redirecting everyone?
1. Check sessions table was created
2. Verify middleware.js is reading jeton_session cookie
3. Check route matcher in middleware.js

### API routes returning 401?
1. Ensure session is valid: `psql` check expires_at
2. Check api-auth.js is imported correctly
3. Verify user.status = 'active' in users table

### Need to cleanup old code?
```bash
# After everything works
npm uninstall jsonwebtoken
rm src/lib/jwt.js
# Remove JWT_SECRET from environment
```

---

## 🎯 Success Indicators

After completing all commands, you should see:

✅ Login creates session in database
✅ Session cookie is set with httpOnly flag
✅ Protected routes require valid session
✅ Logout deletes session from database
✅ Page refresh maintains session
✅ All API routes now using api-auth.js
✅ No JWT imports remain in codebase
✅ Vercel deployment shows no auth errors
✅ Middleware protecting all critical routes
✅ Performance is consistent (< 50ms session lookup)

---

**Ready to go! Run these commands in order and you're done.** 🚀

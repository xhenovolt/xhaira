# DRAIS Integration - Deployment Checklist

## Pre-Deployment

### Environment Setup
- [ ] DRAIS API endpoint identified and accessible
- [ ] DRAIS API credentials obtained (key + secret)
- [ ] Test DRAIS API connectivity from server
- [ ] SSL/TLS certificates valid
- [ ] DNS resolved correctly
- [ ] Firewall rules allow outbound HTTPS to DRAIS

### Configuration
- [ ] `.env.local` has `DRAIS_API_BASE_URL`
- [ ] `.env.local` has `DRAIS_API_KEY`
- [ ] `.env.local` has `DRAIS_API_SECRET`
- [ ] Environment variables NOT committed to Git
- [ ] Environment variables backed up securely

### Database
- [ ] PostgreSQL/Neon accessible
- [ ] Backup created before migrations
- [ ] Migration 950_drais_pricing_config.sql prepared
- [ ] Migration tested in dev environment

### Permissions
- [ ] RBAC system has our permission records
- [ ] `drais.view` permission created
- [ ] `drais.edit` permission created
- [ ] `drais.control` permission created
- [ ] Roles assigned with appropriate permissions
- [ ] Test user has required permissions

---

## Deployment Steps

### Step 1: Code Deployment
```bash
# Pull latest code
git pull origin main

# Install dependencies (if any new ones)
npm install

# Build Next.js app
npm run build

# Verify build succeeds
```

- [ ] No build errors
- [ ] All TypeScript files compile
- [ ] All imports resolved

### Step 2: Database Migration
```bash
# Back up database
pg_dump $DATABASE_URL > backup_$(date +%s).sql

# Run migration
psql $DATABASE_URL < migrations/950_drais_pricing_config.sql

# Verify tables created
psql $DATABASE_URL -c "\dt drais_*"
```

Expected output:
```
           List of relations
 Schema | Name | Type | Owner
--------+------+------+--------
 public | drais_pricing_changes | table | user
 public | drais_pricing_config | table | user
```

- [ ] Tables created successfully
- [ ] Indexes created
- [ ] No errors in migration

### Step 3: Permission Setup
```bash
# Connect to database
psql $DATABASE_URL

# Add permissions
INSERT INTO permissions (name, description, category) VALUES
('drais.view', 'View DRAIS schools and activity', 'DRAIS'),
('drais.edit', 'Update DRAIS schools and pricing', 'DRAIS'),
('drais.control', 'Suspend/activate schools (destructive)', 'DRAIS');

# Verify permissions added
SELECT * FROM permissions WHERE name LIKE 'drais.%';
```

- [ ] All 3 permissions created
- [ ] No duplicate permissions

### Step 4: Role Assignment
```bash
-- Assign all DRAIS permissions to admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin' AND p.name LIKE 'drais.%';

-- Assign view + edit to managers
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'manager' AND p.name IN ('drais.view', 'drais.edit');

-- Verify
SELECT r.name as role, p.name as permission 
FROM role_permissions rp
JOIN roles r ON rp.role_id = r.id
JOIN permissions p ON rp.permission_id = p.id
WHERE p.name LIKE 'drais.%'
ORDER BY r.name, p.name;
```

- [ ] All roles have correct permissions
- [ ] No orphaned permissions

### Step 5: Start Application
```bash
# Start Next.js server
npm run start

# Or in development:
npm run dev

# Wait for server to start
```

- [ ] Server started without errors
- [ ] No TypeScript compilation errors
- [ ] API routes available

### Step 6: Health Check
```bash
# Test DRAIS connectivity
curl http://localhost:3000/api/drais/health

# Expected response:
# {"success": true, "status": "ok", "timestamp": "..."}
```

- [ ] Health check passes
- [ ] DRAIS is reachable
- [ ] Credentials are valid

---

## Testing Phase

### Functional Tests

#### 1. Schools Dashboard
```
URL: http://localhost:3000/dashboard/drais/schools

Tests:
- [ ] Page loads without errors
- [ ] Schools list displays
- [ ] Status badges show correctly
- [ ] Refresh button works
- [ ] Filter by status works
- [ ] Sort options work
- [ ] Real-time data updates visible
- [ ] No console errors
```

#### 2. School Actions
```
Tests:
- [ ] View school details works
- [ ] Suspend button disabled for suspended schools
- [ ] Activate button disabled for active schools
- [ ] Suspend shows confirmation dialog
- [ ] Suspend updates school status
- [ ] Activate updates school status
- [ ] Success toast appears after action
- [ ] Error handling works for API failures
```

#### 3. Pricing Dashboard
```
URL: http://localhost:3000/dashboard/drais/pricing

Tests:
- [ ] Page loads and shows pricing plans
- [ ] Active plans display correctly
- [ ] Inactive plans section shows (if any)
- [ ] Price calculations correct
- [ ] Create plan modal opens
- [ ] Create plan validates inputs
- [ ] Create plan saves to database
- [ ] Edit plan modal works
- [ ] Edit plan updates in DRAIS
- [ ] Delete plan deactivates correctly
```

#### 4. Activity Monitor
```
URL: http://localhost:3000/dashboard/drais/activity

Tests:
- [ ] Page loads and shows activity logs
- [ ] Time range filters work
- [ ] School filter works
- [ ] Activity correctly color-coded
- [ ] Timestamps display correctly
- [ ] Auto-refresh updates logs
- [ ] Filtering updates count
```

#### 5. API Tests
```bash
# Test schools endpoint
curl -H "Cookie: session=YOUR_SESSION" \
  http://localhost:3000/api/drais/schools

# Test pricing endpoint
curl http://localhost:3000/api/pricing

# Test health
curl http://localhost:3000/api/drais/health

# Test auth (should fail without session)
curl http://localhost:3000/api/drais/schools
# Should return 401 or redirect to login
```

Tests:
- [ ] Schools endpoint returns array
- [ ] Pricing endpoint returns array
- [ ] Health endpoint shows status
- [ ] Authentication required
- [ ] Permissions enforced

#### 6. Error Handling
```
Tests:
- [ ] Disable DRAIS temporarily
- [ ] Verify error state shows
- [ ] Retry button works
- [ ] User sees helpful error message
- [ ] Checklist provided
- [ ] Re-enable DRAIS
- [ ] Refresh recovers correctly
```

### Performance Tests

- [ ] Schools dashboard loads in < 2 seconds
- [ ] Pricing dashboard loads in < 2 seconds
- [ ] Activity monitor loads in < 2 seconds
- [ ] Auto-refresh doesn't cause lag
- [ ] Multiple rapid actions queue correctly
- [ ] No memory leaks on extended use

### Security Tests

- [ ] Non-authenticated users cannot access `/api/drais/*`
- [ ] Users without `drais.view` cannot see data
- [ ] Users without `drais.edit` cannot create pricing
- [ ] Users without `drais.control` cannot suspend schools
- [ ] API keys never appear in browser console
- [ ] API keys never sent to frontend
- [ ] All requests use HTTPS
- [ ] CORS properly restricted

---

## Post-Deployment

### Monitoring Setup
```bash
# Log aggregation
- Set up alerts for [DRAIS] errors in logs
- Monitor API response times
- Track error rates

# Metrics
- Monitor /api/drais/* endpoint latency
- Track permission check failures
- Watch for rate limiting issues
```

- [ ] Log aggregation configured
- [ ] Alert thresholds set
- [ ] Monitoring dashboard accessible
- [ ] Error rate baseline established

### Notification Configuration

If using email/Slack notifications:
```bash
# Configure admin alerts for:
- [ ] High error rates from DRAIS
- [ ] DRAIS health check failures
- [ ] Unusual suspension activity
- [ ] Pricing configuration changes
```

### Backup Verification

```bash
# Verify backup strategy
- [ ] Database backups running
- [ ] Pricing config backed up
- [ ] Recovery tested
- [ ] Restoration time acceptable
```

- [ ] Daily backups enabled
- [ ] Backup tested and verified
- [ ] Retention policy set
- [ ] Disaster recovery plan documented

---

## Rollback Plan

If deployment fails, rollback is simple since no data is stored locally:

```bash
# Stop application
pkill -f "next server" || pkill -f "npm run start"

# Rollback code (if needed)
git revert <commit-hash>
npm run build
npm run start

# NOTE: Database migrations cannot be easily rolled back
# Only rollback database if critical error in migration
psql $DATABASE_URL < /path/to/backup.sql
```

**Important:** Only rollback database if migration caused critical issues.

- [ ] Rollback procedure documented
- [ ] Backup verified and accessible
- [ ] Team trained on rollback process
- [ ] Rollback tested in dev environment

---

## Sign-Off

### QA Sign-Off
- [ ] All functional tests passed
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Security verified
- [ ] QA Lead: _____________ Date: _______

### Security Review
- [ ] API keys properly protected
- [ ] Authentication working
- [ ] Permissions enforced
- [ ] No sensitive data in logs
- [ ] Security Lead: _____________ Date: _______

### Operations Sign-Off
- [ ] Monitoring configured
- [ ] Alerts working
- [ ] Backups verified
- [ ] Runbooks updated
- [ ] Ops Lead: _____________ Date: _______

### Deployment Sign-Off
- [ ] All checklist items completed
- [ ] No blocking issues
- [ ] Team ready for deployment
- [ ] Go/No-Go: _____________ 
- [ ] Deployment Engineer: _____________ Date: _______

---

## Post-Deployment Verification (Day 1)

**Within 24 hours:**

- [ ] Check error logs - should be clean
- [ ] Verify metrics look normal
- [ ] Spot-check schools list in dashboard
- [ ] Confirm pricing displays correctly
- [ ] Review activity monitor for normal patterns
- [ ] Test suspend/activate with test school
- [ ] Verify pricing changes work end-to-end
- [ ] Confirm users can access dashboards
- [ ] Check performance metrics are acceptable
- [ ] Review backup was created

---

## Post-Deployment Verification (Week 1)

**Throughout first week:**

- [ ] Monitor error rates
- [ ] Review performance metrics
- [ ] Check for any connectivity issues
- [ ] Verify pricing updates reach DRAIS
- [ ] Confirm no unusual suspension activity
- [ ] Check user feedback for issues
- [ ] Review audit trail for anomalies
- [ ] Ensure backups running smoothly
- [ ] Verify monitoring alerts working

---

## Troubleshooting During Deployment

### Build Fails
```
Error: Cannot find module...

Solution:
1. Run: npm install
2. Run: npm run build
3. Check package.json for missing deps
```

### Migration Fails
```
Error: relation "drais_pricing_config" already exists

Solution:
- Table already created from previous run
- This is OK, can proceed
- Or drop and recreate:
  DROP TABLE IF EXISTS drais_pricing_config CASCADE;
  psql $DATABASE_URL < migrations/950_drais_pricing_config.sql
```

### DRAIS Health Check Fails
```
Error: Connection timeout

Solution:
1. Verify DRAIS_API_BASE_URL is correct
2. Verify DRAIS server is running
3. Check firewall allows outbound HTTPS
4. Ping DRAIS API: curl $DRAIS_API_BASE_URL/health
5. Verify credentials are valid
```

### Dashboard Shows "Unable to fetch"
```
Solution:
1. Check browser console for errors
2. Check user has drais.view permission
3. Check /api/drais/schools returns data
4. Verify authentication session valid
5. Check server logs for API errors
```

---

## Support Contact

For deployment support:
- **Technical Lead:** [contact]
- **DRAIS Team:** [contact]
- **Operations:** [contact]
- **Emergency:** [contact]

---

**Deployment Date:** _______________  
**Deployed By:** _______________  
**Verified By:** _______________  

---

**Last Updated:** March 29, 2026  
**Version:** 1.0.0

# DRAIS API Integration - Complete Setup Guide

## Overview

JETON is now the **MASTER CONTROL PANEL** for DRAIS. This document covers the complete architecture, setup, and deployment of the DRAIS integration layer.

### Key Principles

- ✅ **NO Database Replication** - JETON does NOT store school data locally
- ✅ **LIVE Data Fetch** - All school information is fetched in real-time from DRAIS APIs
- ✅ **Control + Visibility** - JETON sees everything and controls school activation/suspension
- ✅ **Single Source of Truth** - DRAIS remains the system of record for all school data
- ✅ **Pricing Control** - JETON controls global pricing that DRAIS consumes

---

## Architecture

### System Layers

```
┌─────────────────────────────────────────┐
│         JETON (Control Panel)           │
│  ┌─────────────────────────────────────┐│
│  │  Dashboard UI                       ││
│  │  /dashboard/drais/schools           ││
│  │  /dashboard/drais/pricing           ││
│  │  /dashboard/drais/activity          ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  API Security Layer                 ││
│  │  /api/drais/*  (proxy routes)       ││
│  │  - Authentication check             ││
│  │  - Permission validation            ││
│  │  - Error handling                   ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  DRAIS Client Library               ││
│  │  lib/draisClient.ts                 ││
│  │  - Centralized API calls            ││
│  │  - Error handling                   ││
│  │  - Connection management            ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
           ↕ (HTTPS Secure)
┌─────────────────────────────────────────┐
│         DRAIS (System of Record)        │
│  - Schools database                     │
│  - Audit logs                           │
│  - User actions                         │
│  - School data (single source of truth) │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│   JETON PostgreSQL (Minimal Storage)    │
│  - drais_pricing_config (ONLY LOCAL)    │
│  - drais_pricing_changes (audit trail)  │
│  - Authentication & sessions            │
└─────────────────────────────────────────┘
```

---

## Installation & Setup

### 1. Environment Variables

Create or update `.env.local` with DRAIS connection details:

```bash
# DRAIS API Configuration
DRAIS_API_BASE_URL=https://drais-api.example.com
DRAIS_API_KEY=your_api_key_here
DRAIS_API_SECRET=your_api_secret_here
```

**Requirements:**
- `DRAIS_API_BASE_URL`: Base URL of your DRAIS API (e.g., `https://drais.yourdomain.com`)
- `DRAIS_API_KEY`: API key for authentication
- `DRAIS_API_SECRET`: API secret for HMAC signing

### 2. Database Migration

Run the pricing configuration table creation:

```bash
npm run migrate
# or manually run:
psql $DATABASE_URL < migrations/950_drais_pricing_config.sql
```

This creates:
- `drais_pricing_config` - Active pricing plans
- `drais_pricing_changes` - Audit trail of price changes

### 3. Permission Setup

Add these permissions to your RBAC system if not already present:

```sql
INSERT INTO permissions (name, description, category) VALUES
('drais.view', 'View DRAIS schools and activity', 'DRAIS'),
('drais.edit', 'Update DRAIS schools and pricing', 'DRAIS'),
('drais.control', 'Suspend/activate schools (destructive)', 'DRAIS');
```

### 4. Assign Roles

Assign permissions to appropriate roles:

```sql
-- Admin role gets all permissions
INSERT INTO role_permissions (role_id, permission_id) 
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'admin' AND p.name LIKE 'drais.%';

-- Manager role gets view + edit
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'manager' AND p.name IN ('drais.view', 'drais.edit');

-- Viewer role gets read-only
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'viewer' AND p.name = 'drais.view';
```

---

## Usage

### Accessing the Control Panel

#### Schools Dashboard
```
/dashboard/drais/schools
```

Shows:
- Real-time list of all schools from DRAIS
- School status (active/suspended)
- Created date and last activity
- Action buttons (Suspend/Activate)
- Auto-refreshes every 15 seconds

**Features:**
- Filter by status
- Sort by name, status, or creation date
- Suspend schools (red button = destructive)
- Activate schools (green button = safe)
- View details of individual schools

#### Activity Monitor
```
/dashboard/drais/activity
```

Shows:
- Real-time audit logs from DRAIS
- What schools are doing (user actions, logins, etc.)
- Filter by time range (1 hour, 24 hours, 7 days)
- Filter by school
- Auto-refreshes every 10 seconds

#### Pricing Control
```
/dashboard/drais/pricing
```

Shows:
- All active and inactive pricing plans
- Plan names, prices, descriptions
- Edit prices and update DRAIS in real-time
- Add new pricing plans
- Delete/deactivate plans

**Power Feature:** DRAIS fetches pricing from `/api/pricing` endpoint automatically. Changes here are live immediately to all DRAIS schools.

---

## API Reference

### Server-Side: DRAIS Client (lib/draisClient.ts)

```typescript
// Schools
getSchools()              // GET all schools
getSchoolById(id)         // GET specific school
updateSchool(id, data)    // PATCH school details
suspendSchool(id)         // POST suspend
activateSchool(id)        // POST activate

// Activity Logs
getAuditLogs(query)       // GET audit logs with filtering

// Pricing
updateSchoolPricing(id, {subscription_plan, monthly_price})

// Health
healthCheck()             // Verify DRAIS connectivity
```

**Example:**
```typescript
import { getSchools, suspendSchool } from '@/lib/draisClient.ts';

const result = await getSchools();
if (result.success) {
  const schools = result.data;
  // Use schools data
}

const suspend = await suspendSchool('school-id-123');
if (suspend.success) {
  console.log(`Suspended: ${suspend.data.name}`);
}
```

### Client-Side: API Proxy Routes

All calls go through these secure proxy routes:

#### `GET /api/drais/schools`
Requires: `drais.view` permission

```javascript
const response = await fetch('/api/drais/schools?status=active');
const data = await response.json();
// Returns: { success: true, data: [...schools], timestamp }
```

#### `POST /api/drais/schools/[id]/suspend`
Requires: `drais.control` permission

```javascript
const response = await fetch(`/api/drais/schools/${id}/suspend`, {
  method: 'POST',
  credentials: 'include',
});
const result = await response.json();
```

#### `POST /api/drais/schools/[id]/activate`
Requires: `drais.control` permission

#### `GET /api/drais/audit-logs`
Requires: `drais.view` permission

```javascript
const response = await fetch('/api/drais/audit-logs?range=24h&school_id=123');
// Query params: range (1h|24h|7d), school_id (optional), limit, offset
```

#### `GET /api/drais/pricing`
Requires: `drais.view` permission

```javascript
const response = await fetch('/api/drais/pricing');
// Returns: { success: true, data: [...pricing_plans], count }
```

#### `POST /api/drais/pricing`
Requires: `drais.edit` permission

```javascript
const response = await fetch('/api/drais/pricing', {
  method: 'POST',
  body: JSON.stringify({
    plan_name: 'Professional',
    price: 299,
    currency: 'USD',
    description: 'Best for growing schools',
  }),
});
```

#### `GET /api/pricing` (PUBLIC)
**NO AUTHENTICATION REQUIRED** - This is what DRAIS fetches from

```javascript
// Available at: GET http://localhost:3000/api/pricing
const response = await fetch('http://xhaira-api.com/api/pricing');
const plans = await response.json();
// DRAIS uses this to show prices to schools
```

---

## Hooks (Frontend)

### `useDRAISSchools()`
Fetch and auto-poll schools

```javascript
const { schools, loading, error, isValidating, mutate } = useDRAISSchools();

// Auto-refreshes every 15 seconds
// Call mutate() to refresh immediately
```

### `useDRAISSchool(schoolId)`
Fetch single school

```javascript
const { school, loading, error, mutate } = useDRAISSchool('school-123');
```

### `useDRAISAuditLogs(range, schoolId)`
Fetch activity logs

```javascript
const { logs, loading, error, mutate } = useDRAISAuditLogs('24h', schoolId);
// range: '1h' | '24h' | '7d'
```

### `useDRAISPricing(includeInactive)`
Fetch pricing configuration

```javascript
const { pricing, loading, error, mutate } = useDRAISPricing(false);
```

### `useDRAISHealth()`
Check DRAIS connectivity

```javascript
const { status, isHealthy } = useDRAISHealth();
// Checks every 30 seconds
```

### `useDRAISNotifications(enabled)`
Get alerts for new schools, suspensions, etc.

```javascript
useDRAISNotifications(true);
// Shows toast notifications for:
// - New schools onboarded
// - Schools suspended
// - Schools reactivated
// Polls every 30 seconds
```

---

## Error Handling & Recovery

### Connection Failures

If DRAIS is unavailable:

1. **UI shows error state** with troubleshooting checklist
2. **Retry button** allows manual refresh
3. **Auto-fallback** for non-critical operations
4. **Toast notifications** inform users of issues

### Security Considerations

✅ **Never expose API keys in frontend** - All calls go through `/api/drais/*` proxy routes
✅ **Authentication enforced** - Every route requires valid session
✅ **Permission checks** - Different permission levels for view vs control
✅ **CORS protected** - Only from same origin
✅ **Rate limiting** - Implement server-side rate limits if needed

### Rate Limits

Current polling intervals:
- Schools list: 15 seconds
- Activity logs: 10 seconds
- Health check: 30 seconds
- Notifications: 30 seconds

Adjust these values in hook files if DRAIS requests rate limiting.

---

## Deployment Checklist

- [ ] Environment variables set (`DRAIS_API_*`)
- [ ] DRAIS API credentials verified
- [ ] Database migration run (950_drais_pricing_config.sql)
- [ ] Permissions configured in RBAC
- [ ] Roles assigned appropriately
- [ ] DRAIS API accessible from server
- [ ] Firewall rules allow HTTPS communication
- [ ] SSL certificates valid
- [ ] Test: School fetch works
- [ ] Test: Suspend/activate functions
- [ ] Test: Pricing updates live on DRAIS side
- [ ] Monitoring enabled for API errors
- [ ] Backup strategy in place

---

## Monitoring & Logging

### Key Metrics

Monitor these in your logging system:

```
[DRAIS API] GET /schools error: Connection timeout
[DRAIS Pricing] PATCH error: Duplicate plan name
[DRAIS Schools] POST /schools/[id]/suspend error: School not found
```

### Health Endpoint

Check DRAIS connectivity:

```bash
curl http://localhost:3000/api/drais/health
# Response: { success: true, status: 'ok', timestamp }
```

---

## Troubleshooting

### DRAIS Connection Failed

**Symptom:** "Unable to fetch live data from DRAIS"

**Checklist:**
1. Verify `DRAIS_API_BASE_URL` is correct
2. Verify `DRAIS_API_KEY` and `DRAIS_API_SECRET` are valid
3. Check network connectivity to DRAIS
4. Check firewall rules allow outbound HTTPS
5. Verify SSL certificates are valid
6. Check DRAIS API logs for errors

### Schools Not Updating

**Symptom:** Dashboard shows stale data

**Solution:**
1. Click "Refresh Now" button
2. Check browser console for JavaScript errors
3. Verify user has `drais.view` permission
4. Check network tab in DevTools for failed requests

### Pricing Changes Not Live on DRAIS

**Symptom:** Update price in Xhaira but DRAIS still shows old price

**Solution:**
1. Verify DRAIS is fetching from `/api/pricing` endpoint
2. Check DRAIS cache settings
3. Manually refresh DRAIS UI
4. Verify pricing update returned success from API

---

## Architecture Decisions

### Why No Local School Data Storage?

✅ Single source of truth (DRAIS)
✅ Real-time consistency guaranteed
✅ No sync issues
✅ Audit trail in DRAIS
✅ Reduced database size
✅ Simpler architecture

### Why Store Pricing Locally?

✅ JETON controls global pricing
✅ Pricing changes are central  governance
✅ DRAIS fetches on-demand from Xhaira
✅ Allows offline pricing if needed
✅ Audit trail of price changes

### Real-Time Updates

Using polling instead of WebSockets:
✅ Simpler implementation
✅ Works across all network types
✅ No persistent connections
✅ Easy to adjust intervals
✅ Lower infrastructure cost

Consider WebSockets for future if:
- Need sub-second updates
- Want to reduce polling load
- Building real-time dashboards

---

## Future Enhancements

- [ ] WebSocket integration for real-time updates
- [ ] Batch operations (suspend multiple schools)
- [ ] Advanced analytics dashboard
- [ ] Custom pricing rules per region
- [ ] School usage capacity tracking
- [ ] Automated suspension on quota exceed
- [ ] Integration with billing system
- [ ] Mobile app for on-the-go control

---

## Support

For issues or questions:

1. Check `/api/drais/health` endpoint
2. Review server logs for `[DRAIS]` entries
3. Check browser console for client errors
4. Verify all environment variables are set
5. Test API connectivity with curl

---

**Last Updated:** March 29, 2026
**Version:** 1.0.0
**Status:** Production Ready

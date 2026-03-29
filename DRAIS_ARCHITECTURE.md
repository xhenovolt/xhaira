# DRAIS Integration - Architecture Overview

## System Design Philosophy

### The Control Brain Model

JETON = **Control Brain** (makes decisions, orchestrates, governs)
DRAIS = **Body System** (executes orders, stores data, operates)

```
JETON
  ├─ Command Authority
  │   ├─ School Activation/Suspension
  │   ├─ Global Pricing Control
  │   └─ System Configuration
  ├─ Visibility
  │   ├─ Real-time School Status
  │   ├─ Activity Monitoring
  │   └─ Audit Trails
  └─ Governance
      ├─ Permission Management
      ├─ User Access Control
      └─ Change Tracking
         ↓
      DRAIS (System of Record)
         ├─ School Data
         ├─ User Records
         ├─ Transaction Logs
         └─ Audit Events
```

### Why This Architecture?

#### ✅ Single Source of Truth
- School data exists in ONE place (DRAIS)
- No data synchronization complexity
- No consistency issues
- No version conflicts

#### ✅ Real-Time Control
- Changes in JETON appear instantly wherever DRAIS serves the data
- Pricing updates live to all schools
- School suspensions immediate
- No caching/sync delays

#### ✅ Separation of Concerns
- JETON = Control/Governance
- DRAIS = Operations/Execution
- Each system has one responsibility
- Easy to scale independently

#### ✅ Minimal Data Storage
- JETON only stores what it *controls* (pricing)
- Everything else fetched live
- Smaller database
- Faster queries
- Easier to backup/restore

---

## Data Flow Diagrams

### Schools List Fetching

```
User Views /dashboard/drais/schools
           ↓
    React Component Renders
           ↓
    useDRAISSchools() Hook Triggered
           ↓
    fetch('/api/drais/schools')  [Browser]
           ↓
    /api/drais/schools/route.js  [Server]
           ↓
    requirePermission('drais.view')  [Auth Check]
           ↓
    getSchools()  [DRAIS Client]
           ↓
    fetch(DRAIS_API_BASE_URL + '/api/external/schools')
           ↓
    DRAIS API Server Response
           ↓
    Return JSON to Frontend
           ↓
    useDRAISSchools() Updates State
           ↓
    Component Re-renders with Data
```

**Timeline:** ~500-800ms (depends on DRAIS response time)
**Cache:** None - always live data
**Refresh:** Every 15 seconds automatically

### School Suspension Flow

```
User Clicks "Suspend" Button
           ↓
    Confirmation Dialog
           ↓
    fetch('/api/drais/schools/[id]/suspend', POST)
           ↓
    /api/drais/schools/[id]/suspend/route.js
           ↓
    requirePermission('drais.control')  [Permission Check]
           ↓
    suspendSchool(id)  [DRAIS Client]
           ↓
    fetch(DRAIS_API + '/api/external/schools/[id]/suspend', POST)
           ↓
    DRAIS Suspends School
    - Updates school.status = 'suspended'
    - Logs audit event
    - Returns updated school data
           ↓
    JETON Server Response
           ↓
    Toast Notification Shows
    dispatch(DRAIS_SCHOOL_SUSPENDED event)  [System Logs]
           ↓
    useDRAISSchools().mutate()  [Refresh Data]
           ↓
    Dashboard Updates
```

**Permission Required:** `drais.control` (destructive)
**Confirmation:** Required before execution
**Audit Trail:** Logged in DRAIS + JETON system events
**Revertible:** User can activate school from Xhaira

### Pricing Configuration Flow

```
Admin Updates Pricing in JETON
           ↓
    /dashboard/drais/pricing
           ↓
    Edit price in modal
           ↓
    PATCH /api/drais/pricing/[id]
           ↓
    Server updates drais_pricing_config table
           ↓
    Record price change in drais_pricing_changes
    dispatch(DRAIS_PRICING_UPDATED)
           ↓
    Return success
           ↓
    DRAIS Fetches Updated Pricing
           ↓
    fetch('/api/pricing')  [From DRAIS Server]
           ↓
    Returns active pricing plans
           ↓
    DRAIS Uses New Prices
           ↓
    Schools See Updated Pricing
```

**Storage:** Only in JETON PostgreSQL
**Endpoint:** `/api/pricing` (public, no auth)
**Refresh:** DRAIS-initiated (on-demand or polling)
**Audit:** drais_pricing_changes table tracks all changes

### Activity Monitoring Flow

```
Dashboard Shows Activity
           ↓
    useDRAISAuditLogs(range='24h')
           ↓
    fetch('/api/drais/audit-logs?range=24h')
           ↓
    /api/drais/audit-logs/route.js
           ↓
    requirePermission('drais.view')
           ↓
    Calculate date range (now - 24h to now)
           ↓
    getAuditLogs({start_date, end_date})  [DRAIS Client]
           ↓
    DRAIS Returns Audit Events
           ↓
    Server Returns to Frontend
           ↓
    Component Displays Logs
    - Filters by action type
    - Color-codes by event type
    - Shows user, timestamp, details
           ↓
    Auto-refresh every 10 seconds
```

**Source:** DRAIS audit tables (schools don't store locally)
**Filtering:** By time range (1h, 24h, 7d) and school
**Resolution:** Event-level details from DRAIS
**Real-time:** Close to real-time (10 second polling)

---

## Security Architecture

### Request Flow with Security Layers

```
Client Request
      ↓
[Layer 1] CORS Check
    - Only from same origin
    - No cross-domain access
      ↓
[Layer 2] Authentication
    - Session cookie required
    - requirePermission() checks
    - Redirects to login if needed
      ↓
[Layer 3] Authorization
    - Role-based access control
    - Permission validation
    - drais.view, drais.edit, drais.control
      ↓
[Layer 4] Business Logic
    - API route handlers
    - Validation
    - Error handling
      ↓
[Layer 5] API Client
    - DRAIS credentials injected
    - X-API-Key/X-API-Secret headers
    - HTTPS only
      ↓
[Layer 6] External TLS
    - HTTPS to DRAIS
    - Certificate validation
    - Encrypted transport
      ↓
DRAIS API Server
    - Authenticates request
    - Authorizes action
    - Executes operation
```

### API Key Management

```
Environment Variables
↓
DRAIS_API_KEY
DRAIS_API_SECRET
↓
Only loaded server-side
↓
Never exposed to frontend
↓
Never in logs/console
↓
Only used in lib/draisClient.ts
↓
Injected into HTTP headers
```

**Never exposed:** Frontend JavaScript
**Never logged:** API calls don't log credentials
**Rotated:** As per DRAIS API security policy
**Backed up:** In secure secret manager

### Data Classification

```
Public                    Internal              Confidential
├─ /api/pricing          ├─ /api/drais/health ├─ DRAIS API Keys
├─ General documentation ├─ Health metrics     ├─ Database credentials
└─ School names          ├─ Error messages    └─ Audit logs (limit access)
                         └─ Activity logs
```

---

## Scaling Considerations

### Current State (Single JETON Instance)

- Handles 1,000+ schools
- 15-second polling interval sustainable
- PostgreSQL connection pooling
- No caching needed

### Medium Scale (10,000+ schools)

**Optimizations:**
```
1. Add caching layer
   - Redis for school list
   - Cache invalidation on updates
   
2. Reduce polling frequency
   - Increase interval to 30-60 seconds
   - Implement webhook push from DRAIS
   
3. Pagination for large lists
   - Add limit/offset to school lists
   - Load on-demand instead of all at once
```

### Large Scale (100,000+ schools)

**Architecture:**

```
Load Balancer
      ↓
  Multiple JETON Instances
     ↙    ↘
Shared PostgreSQL + Cache (Redis)
      ↓
  DRAIS API (Multi-region)
```

**Changes:**
- Horizontal scaling with load balancer
- Shared cache across instances
- WebSocket for real-time updates
- Database connection pooling
- Read replicas for dashboards

---

## Integration Points

### DRAIS → JETON

DRAIS doesn't need to know about JETON for normal operations:
- DRAIS maintains complete autonomy
- DRAIS operates independently
- DRAIS APIs are unchanged

Integration:
- JETON polls DRAIS for data
- DRAIS webhook pushes (future enhancement)
- JETON doesn't replicate DRAIS data

### JETON → DRAIS

JETON calls DRAIS APIs for:
- School status checks
- Suspension/activation commands
- Activity log retrieval
- Pricing consumption

JETON controls:
- Global pricing (DRAIS consumes via `/api/pricing`)
- School activation state
- User access to schools (via pricing)

### Data Consistency

**Guaranteed:**
- Pricing updates are atomic in JETON
- School status changes reflected in DRAIS
- Activity logs are immutable in DRAIS

**Eventually Consistent:**
- JETON may be seconds behind DRAIS in activity
- Dashboard refreshes every 10-15 seconds
- Manual refresh available

---

## Error Recovery

### DRAIS Unreachable

```
Error in getSchools() → {success: false, error: "Connection failed"}
         ↓
Route handler catches → Returns 503 Service Unavailable
         ↓
Frontend receives → Handles gracefully
         ↓
ErrorFallback component displays
         ↓
Retry button available
         ↓
Dashboard shows "Unable to fetch live data"
         ↓
User given troubleshooting checklist
```

### Invalid Credentials

```
API call fails with 401/403
         ↓
DRAIS Client logs error
         ↓
Route handler returns error response
         ↓
Toast notification: "DRAIS authentication failed"
         ↓
Check credentials in .env
         ↓
Restart application
```

### Permission Denied

```
User without drais.control tries suspending school
         ↓
requirePermission('drais.control') fails
         ↓
Returns 403 Forbidden
         ↓
Frontend handles error
         ↓
Toast: "You don't have permission"
         ↓
Button disabled in UI for unpermitted users
```

### Network Timeout

```
fetch() timeout after 10 seconds
         ↓
catch block catches error
         ↓
Returns {success: false, error: "Connection timeout"}
         ↓
Frontend displays error
         ↓
Manual refresh available
         ↓
Auto-retry on next polling cycle
```

---

## Monitoring & Observability

### Metrics to Track

```
API Latency
├─ /api/drais/schools       (should be <500ms)
├─ /api/drais/audit-logs    (should be <800ms)
└─ /api/drais/pricing       (should be <300ms)

Error Rates
├─ DRAIS connection failures
├─ Permission denied errors
├─ Invalid school IDs
└─ Pricing conflicts

Usage
├─ Active concurrent users
├─ Schools managed
├─ Pricing plan changes
└─ Suspension/activation events
```

### Log Entries to Monitor

```
[DRAIS API] GET /schools error: Connection timeout
[DRAIS Pricing] PATCH error: Duplicate plan name
[DRAIS] POST /schools/[id]/suspend error: Already suspended
[DRAIS Health] API status: unreachable
```

### Alerting Thresholds

```
Warning (non-blocking):
- DRAIS API response > 2 seconds
- More than 5 consecutive failed calls
- Health check returns "unknown"

Critical (blocking):
- DRAIS unreachable for > 5 minutes
- More than 20 consecutive failed calls
- API returning 5xx errors
```

---

## Future Enhancements

### Phase 2: Real-Time Updates
```
Implement WebSocket connection from JETON to DRAIS
- Subscribe to school status changes
- Immediate update notifications
- Reduced polling overhead
```

### Phase 3: Batch Operations
```
Allow operations on multiple schools:
- Suspend/activate multiple at once
- Bulk pricing assignments
- Template-based configurations
```

### Phase 4: Analytics & Reporting
```
Dashboard showing:
- School growth trends
- Usage analytics
- Revenue tracking
- Churn analysis
```

### Phase 5: Advanced Features
```
- Regional pricing rules
- Time-based pricing
- Automated capacity management
- SLA enforcement
```

---

## Conclusion

The JETON → DRAIS architecture provides:
✅ Complete control from a central dashboard
✅ Real-time visibility into all systems
✅ Single source of truth for school data
✅ Secure, permission-based access
✅ Scalable infrastructure
✅ Easy to monitor and debug
✅ Flexible governance layer

JETON becomes the **command center** that orchestrates DRAIS as the **system of record**.

---

**Last Updated:** March 29, 2026  
**Architecture Version:** 1.0.0  
**Status:** Production Ready

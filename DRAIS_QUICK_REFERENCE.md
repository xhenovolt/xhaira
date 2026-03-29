# DRAIS Integration - Quick Reference

## 🚀 Quick Start

### 1. Set Environment Variables
```bash
DRAIS_API_BASE_URL=https://drais-api.example.com
DRAIS_API_KEY=xxx
DRAIS_API_SECRET=xxx
```

### 2. Run Migration
```bash
psql $DATABASE_URL < migrations/950_drais_pricing_config.sql
```

### 3. Access Dashboards
- Schools: `/dashboard/drais/schools`
- Pricing: `/dashboard/drais/pricing`
- Activity: `/dashboard/drais/activity`

---

## 📍 File Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| API Client | `lib/draisClient.ts` | Centralized DRAIS API calls |
| Hooks | `hooks/useDRAISSchools.js` | Data fetching with auto-polling |
| Notifications | `hooks/useDRAISNotifications.js` | Event alerts |
| Proxy Routes | `app/api/drais/*` | Server-side security layer |
| Pricing API | `app/api/pricing/` | Public endpoint for DRAIS |
| Components | `components/drais/*` | UI elements |
| Pages | `app/dashboard/drais/*` | Dashboard views |

---

## 🔌 API Endpoints (Server → Client)

### Schools
```
GET  /api/drais/schools                 - Get all schools
GET  /api/drais/schools/[id]            - Get one school
PATCH /api/drais/schools/[id]           - Update school
POST /api/drais/schools/[id]/suspend   - Suspend school ⚠️
POST /api/drais/schools/[id]/activate  - Activate school
```

### Pricing
```
GET  /api/drais/pricing              - List all pricing (auth required)
POST /api/drais/pricing              - Create plan
PATCH /api/drais/pricing/[id]        - Update plan
DELETE /api/drais/pricing/[id]       - Delete plan ⚠️
```

### Public (No Auth)
```
GET  /api/pricing                    - DRAIS fetches this
GET  /api/drais/health               - Check connectivity
GET  /api/drais/audit-logs           - Activity logs
```

---

## 🪝 Frontend Hooks

```javascript
// Fetch schools with auto-refresh every 15s
const { schools, loading, error, mutate } = useDRAISSchools();

// Fetch activity logs
const { logs, loading, error } = useDRAISAuditLogs('24h', schoolId);

// Fetch pricing plans
const { pricing, loading, error } = useDRAISPricing();

// Check DRAIS health
const { isHealthy, status } = useDRAISHealth();

// Get notifications (shows toasts)
useDRAISNotifications(true);
```

---

## 🔐 Permissions

| Permission | Level | Used For |
|-----------|-------|----------|
| `drais.view` | Read | See schools, activity, pricing |
| `drais.edit` | Write | Update schools, pricing |
| `drais.control` | Admin | Suspend/activate schools |

---

## 🎨 Components

### SchoolActionButtons
```javascript
<SchoolActionButtons
  school={school}
  onMutate={handleRefresh}
  onError={showError}
/>
```

### DRAISStatusIndicator
```javascript
<DRAISStatusIndicator />  // Shows API health
```

### ErrorFallback
```javascript
<ErrorFallback 
  error={error} 
  onRetry={handleRefresh} 
/>
```

### Pricing Modals
```javascript
<CreatePricingPlanModal onClose={} onSuccess={} />
<EditPricingPlanModal plan={} onClose={} onSuccess={} />
```

---

## 📊 Architecture

```
Frontend (React)
      ↓
Hooks (useDRAISSchools)
      ↓
Proxy Routes (/api/drais/*)
      ↓
DRAIS Client (lib/draisClient.ts)
      ↓
DRAIS API Server
```

---

## ⚡ Common Tasks

### Suspend a School
```javascript
const response = await fetch(`/api/drais/schools/${id}/suspend`, {
  method: 'POST',
  credentials: 'include',
});
```

### Update School Pricing
```javascript
const response = await fetch(`/api/drais/schools/${id}`, {
  method: 'PATCH',
  body: JSON.stringify({
    subscription_plan: 'enterprise',
    monthly_price: 300000,
  }),
});
```

### Create Pricing Plan
```javascript
const response = await fetch('/api/drais/pricing', {
  method: 'POST',
  body: JSON.stringify({
    plan_name: 'Professional',
    price: 299,
    currency: 'USD',
  }),
});
```

### Real-Time Updates
- Schools: Auto-refresh every 15 seconds
- Activity: Auto-refresh every 10 seconds
- Pricing: On-demand
- Health: Every 30 seconds

---

## 🚨 Error Codes

| Code | Meaning | Fix |
|------|---------|-----|
| 503 | DRAIS unreachable | Check connectivity, verify credentials |
| 401 | Not authenticated | Login required |
| 403 | Permission denied | Check user permissions |
| 404 | School not found | Verify school ID exists in DRAIS |
| 409 | Conflict (pricing) | Plan name already exists |

---

## 🧪 Testing

### Health Check
```bash
curl http://localhost:3000/api/drais/health
```

### Fetch Schools
```bash
curl -H "Cookie: session=xxx" http://localhost:3000/api/drais/schools
```

### Test Pricing Endpoint
```bash
curl http://localhost:3000/api/pricing
```

---

## 📝 Logging

Look for these in server logs:
```
[DRAIS API]        - API client logs
[DRAIS] GET /schools error:  - Fetch errors
[DRAIS Pricing] PATCH error: - Pricing errors
```

Browser console may show:
```
[DRAIS Schools] Fetch error: Connection failed
```

---

## ⚙️ Configuration

Adjust polling in `src/hooks/useDRAISSchools.js`:
```javascript
// Change POLLING_INTERVAL (default: 15000ms)
const POLLING_INTERVAL = 20000; // 20 seconds
```

Adjust notifications in `src/hooks/useDRAISNotifications.js`:
```javascript
// Change POLL_INTERVAL (default: 30000ms)
const POLL_INTERVAL = 60000; // 60 seconds
```

---

## 📚 Key Principles

✅ **NO local school data storage** - Everything from DRAIS
✅ **LIVE data always** - Real-time polling
✅ **JETON controls pricing** - DRAIS fetches from Jeton
✅ **Security first** - Never expose API keys in frontend
✅ **Error resilient** - Fallback UI when DRAIS down
✅ **User-friendly** - Toast notifications for all actions

---

**Last Updated:** March 29, 2026  
**Quick Reference Version:** 1.0.0

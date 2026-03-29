# DRAIS Connection Setup Guide

## Your DRAIS Credentials
```
CONTROL_API_KEY: 40d73eb668bab8307e9958c8cfff29a7a34fb9d0933587f6ce0512bb7ad58b23
CONTROL_API_SECRET: af2cee8c7d9f507808dbb1fedbc74142aa68703f28d365ee2e00f878b79cb02a2ff5845df52ffb486871eebdd3e5d424
```

## Step 1: Generate Encryption Key

The system needs a master encryption key to securely store credentials. Generate one with:

```bash
node -e "console.log('ENCRYPTION_KEY=' + require('crypto').randomBytes(32).toString('hex'))"
```

**Example output:**
```
ENCRYPTION_KEY=a3f4b8c2e1d5f9g7h2j4k6m8n0p2r4s6t8v0w2x4y6z8a0b2c4d6e8f0g2h4
```

## Step 2: Set Environment Variable

### For Development (.env.local):
```bash
# Add to .env.local
ENCRYPTION_KEY=<paste-the-key-from-step-1>
```

### For Production:
Set as environment variable in your hosting platform (Vercel, Docker, etc.)

## Step 3: Deploy Database Migration

Apply the migration to create the tables:

```bash
npm run migrate -- --target=951
# or if using psql directly:
psql $DATABASE_URL -f migrations/951_external_connections.sql
```

Verify tables were created:
```bash
psql $DATABASE_URL -c "\dt external_connections external_connection_logs"
```

## Step 4: Create DRAIS Connection

### Option A: Using the Web UI (Recommended)

1. Navigate to: **Dashboard → DRAIS Control → Integrations**
2. Click **"New Connection"**
3. Fill in the form:
   - **Name:** `DRAIS Production` (or custom name)
   - **System Type:** `DRAIS`
   - **Base URL:** `https://drais.example.com` (replace with actual DRAIS URL)
   - **API Key:** `40d73eb668bab8307e9958c8cfff29a7a34fb9d0933587f6ce0512bb7ad58b23`
   - **API Secret:** `af2cee8c7d9f507808dbb1fedbc74142aa68703f28d365ee2e00f878b79cb02a2ff5845df52ffb486871eebdd3e5d424`
   - **Set as Active:** ✓ Check this box
4. Click **"Test Connection"** to verify credentials
5. Click **"Create Connection"**

### Option B: Using Database Insert (Manual)

First, encrypt the credentials:

```bash
node -e "
const crypto = require('crypto');
const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

const apiKey = '40d73eb668bab8307e9958c8cfff29a7a34fb9d0933587f6ce0512bb7ad58b23';
const apiSecret = 'af2cee8c7d9f507808dbb1fedbc74142aa68703f28d365ee2e00f878b79cb02a2ff5845df52ffb486871eebdd3e5d424';

// Encrypt both
const keyEncrypted = iv.toString('hex') + cipher.update(apiKey, 'utf8', 'hex') + cipher.final('hex') + cipher.getAuthTag().toString('hex');
const secretEncrypted = iv.toString('hex') + cipher.update(apiSecret, 'utf8', 'hex') + cipher.final('hex') + cipher.getAuthTag().toString('hex');

console.log('api_key_encrypted:', keyEncrypted);
console.log('api_secret_encrypted:', secretEncrypted);
"
```

Then insert into database:

```sql
INSERT INTO external_connections (
  name,
  description,
  system_type,
  base_url,
  api_key_encrypted,
  api_secret_encrypted,
  is_active,
  is_verified,
  created_by
) VALUES (
  'DRAIS Production',
  'Main DRAIS control system',
  'drais',
  'https://drais.example.com',
  '<encrypted-key-from-above>',
  '<encrypted-secret-from-above>',
  true,
  false,
  (SELECT id FROM users LIMIT 1)
);
```

## Step 5: Verify Setup

1. **Check connection created:**
   ```bash
   psql $DATABASE_URL -c "SELECT id, name, is_active, is_verified FROM external_connections WHERE system_type = 'drais';"
   ```

2. **Test the system:**
   - Go to **Dashboard → DRAIS Control → Schools**
   - You should see the connection selector in the header
   - Click it to verify your active connection is shown
   - Schools data should load from DRAIS

3. **Verify audit logging:**
   - Go to **Admin → Audit Logs**
   - Filter for `CONNECTION_CREATED` events
   - Should see your connection creation logged

## Common Issues

### "ENCRYPTION_KEY not set"
- Add `ENCRYPTION_KEY` to `.env.local`
- Restart development server

### "No active DRAIS connection"
- Verify connection exists: `SELECT * FROM external_connections WHERE system_type = 'drais'`
- Check `is_active` is `true`
- Refresh page

### "Failed to decrypt credentials"
- Wrong `ENCRYPTION_KEY` set
- Generate new key and re-encrypt credentials
- Database credentials may be corrupted

### Connection test fails
- Verify base URL is correct and reachable
- Check API key/secret are valid in DRAIS system
- Ensure DRAIS API endpoint responds to `/api/control/ping`

## Security Checklist

- [ ] ENCRYPTION_KEY is 32 bytes (64 hex characters)
- [ ] ENCRYPTION_KEY is NOT in version control (only in .env.local)
- [ ] Production ENCRYPTION_KEY set in hosting environment
- [ ] Connection credentials tested and verified
- [ ] Only active connection can make external calls
- [ ] Audit logs show all connection activity

## Next Steps

After connection is working:

1. **Update remaining hooks** to use proxy:
   - `useDRAISAuditLogs`
   - `useDRAISPricing`
   - `useDRAISHealth`

2. **Add components to other pages:**
   - Add `<DRAISConnectionSelector />` to pricing and activity pages
   - Wrap pages with `<DRAISConnectionFailsafe>`

3. **Test complete workflow:**
   - Create connection
   - Switch connections
   - Verify DRAIS pages work with each connection
   - Check audit logs for activity

## Support

For issues or questions:
- Check `PHASE_2_COMPLETION_SUMMARY.md` for detailed architecture
- Review `DRAIS_INTEGRATION_GUIDE.md` for full integration details
- Check browser console for error messages
- Review server logs: `/var/log/app.log` or your hosting provider's logs

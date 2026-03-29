# 🔴 XHAIRA SYSTEM INTEGRITY AUDIT

**Date:** March 29, 2026  
**Audit Type:** Full System Audit - Database, Auth, API  
**Status:** IN PROGRESS

---

## PHASE 2 - EXPECTED STRUCTURE DERIVATION

### From Code Analysis:

#### EXPECTED: users table
Code expects (from src/lib/auth.js):
- id (uuid)
- email (varchar, unique)
- password_hash (varchar)
- name (varchar)
- username (varchar, unique, optional)  ← DERIVED IF NOT PROVIDED
- role (varchar) - DEFAULT 'user'
- is_active (bool)
- status (varchar) - 'active', 'pending', etc.
- staff_id (uuid, nullable)
- must_reset_password (bool)
- last_login (timestamp)
- last_seen (timestamp)
- last_seen_at (timestamp)
- is_online (bool)
- created_at (timestamp)
- updated_at (timestamp)

#### EXPECTED: sessions table
Code expects (from src/lib/session.js):
- id (uuid, PK)
- user_id (uuid, FK → users.id)
- token (text) - NOT session ID, separate field
- expires_at (timestamp)
- created_at (timestamp)
- last_activity (timestamp)  ← CRITICAL FOR INACTIVITY TIMEOUT
- device_name (varchar, optional)
- ip_address (varchar, optional)
- user_agent (text, optional)
- browser (varchar, optional)
- os (varchar, optional)
- inactivity_timeout_minutes (int)
- is_revoked (bool)

#### EXPECTED: audit_logs table
Code expects (from src/lib/audit.js):
- id (uuid, PK)
- user_id (uuid, FK → users.id, nullable)
- action (varchar(100))
- entity_type (varchar(100))  ← "session"
- entity_id (uuid)
- details (jsonb)
- created_at (timestamp)

Optional (not breaking):
- ip_address (varchar(45))

#### EXPECTED: roles table
Code expects (from src/lib/system-init.js):
- id (uuid, PK)
- name (varchar) ← CODE USES roles.name, NOT role_name
- description (text)
- is_system_role (bool) OR is_system (bool)
- created_at (timestamp)
- updated_at (timestamp)

#### EXPECTED: user_presence table
Code references (from src/lib/session.js):
- user_id (uuid, PK/FK)
- last_ping (timestamp)
- last_seen (timestamp)
- status (varchar)
- is_online (bool)
- updated_at (timestamp)

---

## ACTUAL DATABASE SCHEMA (From xhaira_db_schema.sql)

### Tables Present:
- ✅ accounts
- ✅ audit_logs
- ✅ budgets
- ✅ clients
- ✅ deals
- ✅ expenses
- ✅ followups
- ✅ ledger
- ✅ offerings
- ✅ payments
- ✅ permissions
- ✅ prospect_contacts
- ✅ prospects
- ✅ role_permissions
- ✅ roles
- ✅ sessions
- ✅ transfers
- ✅ user_roles
- ✅ users

### USERS TABLE (lines 440-455):
```sql
CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    CONSTRAINT users_role_check ...
);
```

**Columns Present:**
- ✅ id
- ✅ email
- ✅ password_hash
- ✅ name
- ⚠️ role (as text, not role_id)
- ✅ is_active
- ✅ last_login
- ✅ created_at
- ✅ updated_at
- ✅ status
- ❌ username (MISSING!)
- ❌ staff_id (MISSING!)
- ❌ must_reset_password (MISSING!)
- ❌ last_seen (MISSING!)
- ❌ last_seen_at (MISSING!)
- ❌ is_online (MISSING!)

### SESSIONS TABLE (lines 385-395):
```sql
CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
```

**Columns Present:**
- ✅ id
- ✅ user_id
- ✅ token
- ✅ expires_at
- ✅ ip_address
- ✅ user_agent
- ✅ created_at
- ❌ last_activity (CRITICAL MISSING!)
- ❌ device_name (MISSING!)
- ❌ browser (MISSING!)
- ❌ os (MISSING!)
- ❌ inactivity_timeout_minutes (MISSING!)
- ❌ is_revoked (MISSING!)

### AUDIT_LOGS TABLE (lines 74-83):
```sql
CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id uuid,
    details jsonb DEFAULT '{}'::jsonb,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
```

**Columns Present:**
- ✅ id
- ✅ user_id
- ✅ action
- ✅ entity_type
- ✅ entity_id
- ✅ details
- ✅ ip_address
- ✅ created_at

**Status:** MATCHES CODE EXPECTATIONS ✅

### ROLES TABLE (lines ~440):
```sql
CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
```

**Columns Present:**
- ✅ id
- ✅ name (code uses this correctly)
- ✅ description
- ✅ is_system
- ✅ created_at
- ✅ updated_at

**Status:** MATCHES CODE EXPECTATIONS ✅

---

## MISMATCH SUMMARY

### CRITICAL MISMATCHES (BREAKING):

1. **users.username MISSING**
   - Code: createUser() tries to insert username
   - Error: Column does not exist
   - Impact: Registration fails

2. **sessions.last_activity MISSING**
   - Code: getSession() expects last_activity for inactivity timeout
   - Error: Column does not exist or wrong name
   - Impact: Session timeout breaks, /api/presence/ping returns 401

3. **sessions.device_name MISSING**
   - Code: createSession() inserts device_name
   - Error: Column does not exist
   - Impact: Device tracking fails (but wrapped in try-catch)

4. **sessions.browser MISSING**
   - Code: createSession() inserts browser
   - Error: Column does not exist
   - Impact: Browser tracking fails

5. **sessions.os MISSING**
   - Code: createSession() inserts os
   - Error: Column does not exist
   - Impact: OS tracking fails

6. **sessions.inactivity_timeout_minutes MISSING**
   - Code: getSession() checks inactivity_timeout_minutes
   - Error: Column does not exist
   - Impact: Inactivity timeout logic broken

7. **sessions.is_revoked MISSING**
   - Code: getSession() checks is_revoked = false
   - Error: Column does not exist
   - Impact: Logout doesn't actually revoke sessions

### MEDIUM MISMATCHES (FUNCTIONAL):

8. **users.staff_id MISSING**
   - Code: createUser() tries to insert staff_id
   - Error: Column does not exist
   - Impact: Staff linking fails

9. **users.must_reset_password MISSING**
   - Code: createUser() tries to insert must_reset_password
   - Error: Column does not exist
   - Impact: Password reset enforcement fails

10. **users.last_seen MISSING**
    - Code: updateUserLastSeen() updates last_seen
    - Error: Column does not exist (but wrapped in try-catch)
    - Impact: Last seen tracking partially broken

11. **users.last_seen_at MISSING**
    - Code: updateUserLastSeen() updates last_seen_at
    - Error: Column does not exist
    - Impact: Activity tracking partially broken

12. **users.is_online MISSING**
    - Code: updateUserLastSeen() sets is_online = true
    - Error: Column does not exist
    - Impact: Online status tracking broken

### MISSING TABLE:

13. **user_presence TABLE MISSING**
    - Code: updateUserLastSeen() inserts into user_presence
    - Error: relation "user_presence" does not exist
    - Impact: Presence tracking completely broken

---

## NEXT PHASE: AUTO-REPAIR PLAN

(To be generated based on mismatches above)

/**
 * XHAIRA DATABASE SCHEMA RESET & RECONSTRUCTION
 * 
 * Strategy:
 * 1. Drop all existing tables (hard reset)
 * 2. Apply authoritative Jeton schema (from jeton_db_clean_schema)
 * 3. Apply only critical auth migrations (013, 015, 944, 955)
 * 4. Fix schema column naming to match application code
 * 5. Initialize base roles 
 */

-- ============================================================================
-- PHASE 1: HARD RESET - DROP ALL EXISTING TABLES
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- ============================================================================
-- PHASE 2: CORE SCHEMA - MINIMAL AUTHORITATIVE JETON SCHEMA
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ROLES: Core RBAC table
CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    name character varying(100) NOT NULL UNIQUE,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- USERS: Core user identity table
CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    email character varying(255) NOT NULL UNIQUE,
    password_hash character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['superadmin'::character varying, 'admin'::character varying, 'user'::character varying, 'viewer'::character varying, 'staff'::character varying])::text[])))
);

-- SESSIONS: Session management table
CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_activity timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- USER_ROLES: Role assignment junction table
CREATE TABLE public.user_roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_by uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT unique_user_role UNIQUE (user_id, role_id)
);

-- STAFF: Staff record table
CREATE TABLE public.staff (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    department VARCHAR(100),
    position VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ACCOUNTS: Financial accounts
CREATE TABLE public.accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    name character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    description text,
    institution character varying(255),
    account_number character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- CLIENTS: Client records
CREATE TABLE public.clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    company_name character varying(255) NOT NULL,
    contact_name character varying(255),
    email character varying(255),
    phone character varying(50),
    website character varying(500),
    industry character varying(100),
    status character varying(30) DEFAULT 'active'::character varying NOT NULL,
    created_by uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- DEALS: Deal records
CREATE TABLE public.deals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    title character varying(255) NOT NULL,
    description text,
    total_amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    created_by uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================================================
-- PHASE 3: ADD MISSING COLUMNS FOR AUTH & GOVERNANCE
-- ============================================================================

-- USERS table enhancements (from migrations 015, 944, 955)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS username VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS department VARCHAR(100),
ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS updated_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES staff(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS must_reset_password BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS authority_level INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS hierarchy_level INTEGER DEFAULT 4,
ADD COLUMN IF NOT EXISTS first_login_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS session_id UUID,
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP WITH TIME ZONE;

-- ROLES table enhancements
ALTER TABLE public.roles
ADD COLUMN IF NOT EXISTS hierarchy_level INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS authority_level INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS data_scope VARCHAR(50) DEFAULT 'OWN' CHECK (data_scope IN ('OWN', 'DEPARTMENT', 'GLOBAL')),
ADD COLUMN IF NOT EXISTS is_system_role BOOLEAN DEFAULT false;

-- ============================================================================
-- PHASE 4: CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_superadmin ON users(is_superadmin);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_staff_id ON users(staff_id);
CREATE INDEX IF NOT EXISTS idx_users_authority_level ON users(authority_level);
CREATE INDEX IF NOT EXISTS idx_users_is_online ON users(is_online);
CREATE INDEX IF NOT EXISTS idx_roles_name ON roles(name);
CREATE INDEX IF NOT EXISTS idx_roles_is_system_role ON roles(is_system_role);
CREATE INDEX IF NOT EXISTS idx_roles_hierarchy_level ON roles(hierarchy_level);
CREATE INDEX IF NOT EXISTS idx_roles_authority_level ON roles(authority_level);

-- ============================================================================
-- PHASE 5: INITIALIZE BASE ROLES  
-- ============================================================================

INSERT INTO roles (id, name, description, is_system, is_system_role, hierarchy_level, authority_level, data_scope)
VALUES
    ('10000000-0000-0000-0000-000000000001'::uuid, 'superadmin', 'Full system access - cannot be deleted or modified', true, true, 1, 100, 'GLOBAL'),
    ('10000000-0000-0000-0000-000000000002'::uuid, 'admin', 'Administrative access with ability to manage users and permissions', true, true, 2, 50, 'GLOBAL'),
    ('10000000-0000-0000-0000-000000000003'::uuid, 'staff', 'Staff member with module-specific permissions', true, true, 3, 20, 'DEPARTMENT'),
    ('10000000-0000-0000-0000-000000000004'::uuid, 'viewer', 'Read-only access to assigned modules', true, true, 4, 10, 'OWN'),
    ('10000000-0000-0000-0000-000000000005'::uuid, 'user', 'Standard user access', true, true, 4, 10, 'OWN')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- COMPLETION
-- ============================================================================

SELECT 'XHAIRA database schema reconstruction complete!' AS status;

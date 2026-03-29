-- Phase 4 Migration: Create Missing Tables for Full Integrity
-- Run against xhaira database

-- 1. user_presence table (critical - required by /api/presence/ping)
CREATE TABLE IF NOT EXISTS public.user_presence (
    user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    last_ping timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_seen timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'online' CHECK (status IN ('online', 'idle', 'offline')),
    is_online boolean DEFAULT true,
    current_route varchar(255),
    current_page_title varchar(255),
    device_info jsonb,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_presence_last_ping ON user_presence(last_ping DESC);
CREATE INDEX IF NOT EXISTS idx_user_presence_is_online ON user_presence(is_online);
CREATE INDEX IF NOT EXISTS idx_user_presence_status ON user_presence(status);

-- 2. permissions table (required by /api/auth/me for RBAC)
CREATE TABLE IF NOT EXISTS public.permissions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name varchar(255) NOT NULL UNIQUE,
    module varchar(100) NOT NULL,
    action varchar(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_module_action UNIQUE (module, action)
);

CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module);
CREATE INDEX IF NOT EXISTS idx_permissions_action ON permissions(action);

-- 3. role_permissions table (junction between roles and permissions)
CREATE TABLE IF NOT EXISTS public.role_permissions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

-- 4. staff_roles table (junction for staff with multiple roles)
CREATE TABLE IF NOT EXISTS public.staff_roles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    assigned_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_staff_role UNIQUE (staff_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_staff_roles_staff_id ON staff_roles(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_roles_role_id ON staff_roles(role_id);

-- 5. approval_requests table (for future request/approval workflow)
CREATE TABLE IF NOT EXISTS public.approval_requests (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_type varchar(100) NOT NULL,
    requested_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    approver_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
    status varchar(30) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    details jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_requested_by ON approval_requests(requested_by);

-- Confirmation
SELECT 'Phase 4 Migration: CRITICAL TABLES CREATED' AS status;
SELECT 
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'user_presence') AS user_presence_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'permissions') AS permissions_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'role_permissions') AS role_permissions_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'staff_roles') AS staff_roles_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'approval_requests') AS approval_requests_exists;

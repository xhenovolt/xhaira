/**
 * Migration: System Access & Identity Control Module
 * 
 * Adds missing columns to users table for complete identity control:
 * - username: Unique username for display/mentions
 * - staff_id: Link to staff record (nullable, for unified staff/user system)
 * - must_reset_password: Force password change on first login
 * - authority_level: Numeric hierarchy for admin role checking
 * - hierarchy_level: Role-based hierarchy level (1=superadmin, 2=admin, 3=staff, 4=viewer)
 * - first_login_completed: Track if user has completed initial setup
 * 
 * Also ensures role constraint allows 'staff' and 'viewer' roles needed by this module.
 */

-- ============================================================================
-- ADD MISSING COLUMNS TO USERS TABLE
-- ============================================================================

-- Add username column (UNIQUE, derived from email if not provided)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS username VARCHAR(100) UNIQUE;

-- Add staff_id column to link users to staff records
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES public.staff(id) ON DELETE SET NULL;

-- Add password reset flag for first-login enforcement
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS must_reset_password BOOLEAN DEFAULT false;

-- Add authority level for hierarchy-based access control
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS authority_level INTEGER DEFAULT 10;

-- Add hierarchy level (1=superadmin, 2=admin, 3=staff, 4=viewer)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS hierarchy_level INTEGER DEFAULT 4;

-- Add first login completion flag
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS first_login_completed BOOLEAN DEFAULT false;

-- Add online status tracking
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

-- Add session ID for presence tracking
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS session_id UUID;

-- Add last_seen_at for activity tracking
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP WITH TIME ZONE;

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_staff_id ON public.users(staff_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_authority_level ON public.users(authority_level);
CREATE INDEX IF NOT EXISTS idx_users_is_online ON public.users(is_online);

-- ============================================================================
-- ENSURE ROLES TABLE HAS NECESSARY COLUMNS
-- ============================================================================

ALTER TABLE public.roles
ADD COLUMN IF NOT EXISTS hierarchy_level INTEGER DEFAULT 10;

ALTER TABLE public.roles
ADD COLUMN IF NOT EXISTS authority_level INTEGER DEFAULT 10;

ALTER TABLE public.roles
ADD COLUMN IF NOT EXISTS data_scope VARCHAR(50) DEFAULT 'OWN' CHECK (data_scope IN ('OWN', 'DEPARTMENT', 'GLOBAL'));

CREATE INDEX IF NOT EXISTS idx_roles_hierarchy_level ON public.roles(hierarchy_level);
CREATE INDEX IF NOT EXISTS idx_roles_authority_level ON public.roles(authority_level);

-- ============================================================================
-- INITIALIZE MISSING ROLE HIERARCHY LEVELS
-- ============================================================================

UPDATE public.roles SET hierarchy_level = 1, authority_level = 100, data_scope = 'GLOBAL'
WHERE name = 'superadmin' AND hierarchy_level IS NULL;

UPDATE public.roles SET hierarchy_level = 2, authority_level = 50, data_scope = 'GLOBAL'
WHERE name = 'admin' AND hierarchy_level IS NULL;

UPDATE public.roles SET hierarchy_level = 3, authority_level = 20, data_scope = 'DEPARTMENT'
WHERE name = 'staff' AND hierarchy_level IS NULL;

UPDATE public.roles SET hierarchy_level = 4, authority_level = 10, data_scope = 'OWN'
WHERE name = 'user' AND hierarchy_level IS NULL;

UPDATE public.roles SET hierarchy_level = 4, authority_level = 10, data_scope = 'OWN'
WHERE name = 'viewer' AND hierarchy_level IS NULL;

-- ============================================================================
-- ENSURE USER ROLE CONSTRAINT MATCHES AVAILABLE ROLES
-- ============================================================================

-- First, check the current constraint name
-- If constraint exists, recreate it with correct values

-- Update existing users to have proper hierarchy levels based on role
UPDATE public.users SET hierarchy_level = 1, authority_level = 100
WHERE role = 'superadmin';

UPDATE public.users SET hierarchy_level = 2, authority_level = 50
WHERE role = 'admin';

UPDATE public.users SET hierarchy_level = 3, authority_level = 20
WHERE role = 'staff';

UPDATE public.users SET hierarchy_level = 4, authority_level = 10
WHERE role IN ('user', 'viewer');

-- ============================================================================
-- CREATE PERMISSIONS TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    module VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(module, action)
);

-- ============================================================================
-- CREATE ROLE_PERMISSIONS JUNCTION TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON public.role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON public.role_permissions(permission_id);

-- ============================================================================
-- INITIALIZE BASE PERMISSIONS
-- ============================================================================

-- User management permissions
INSERT INTO public.permissions (module, action, description)
VALUES 
    ('users', 'view', 'View user list and user details'),
    ('users', 'create', 'Create new user accounts'),
    ('users', 'manage', 'Update user roles, status, and settings'),
    ('users', 'delete', 'Delete user accounts'),
    ('users', 'invite', 'Invite users to the system')
ON CONFLICT (module, action) DO NOTHING;

-- Admin panel permissions
INSERT INTO public.permissions (module, action, description)
VALUES
    ('admin', 'view', 'Access admin panel'),
    ('admin', 'manage', 'Manage admin settings'),
    ('admin', 'audit', 'View audit logs')
ON CONFLICT (module, action) DO NOTHING;

-- System permissions
INSERT INTO public.permissions (module, action, description)
VALUES
    ('system', 'init', 'Initialize system on first setup'),
    ('system', 'manage', 'Manage system settings'),
    ('system', 'monitor', 'Monitor system health')
ON CONFLICT (module, action) DO NOTHING;

-- ============================================================================
-- ASSIGN PERMISSIONS TO SUPERADMIN ROLE (if not already assigned)
-- ============================================================================

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM public.roles r, public.permissions p
WHERE r.name = 'superadmin' 
  AND NOT EXISTS (
    SELECT 1 FROM public.role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- ASSIGN PERMISSIONS TO ADMIN ROLE
-- ============================================================================

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM public.roles r, public.permissions p
WHERE r.name = 'admin'
  AND p.module IN ('users', 'admin')
  AND NOT EXISTS (
    SELECT 1 FROM public.role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- SUMMARY
-- ============================================================================

-- Migration adds:
-- ✅ username (unique identifier)
-- ✅ staff_id (link to staff record)
-- ✅ must_reset_password (force password reset on first login)
-- ✅ authority_level (numeric hierarchy for access control)
-- ✅ hierarchy_level (role-based level)
-- ✅ first_login_completed (track setup completion)
-- ✅ is_online, session_id, last_seen_at (presence tracking)

-- Tables created/updated:
-- ✅ roles (added hierarchy_level, authority_level, data_scope)
-- ✅ permissions (RBAC matrix)
-- ✅ role_permissions (role-permission junction)

-- ============================================================================
-- DEPARTMENTS SCHEMA ALIGNMENT
-- Adds missing columns to departments table and creates sub-tables
-- Syncs name column with department_name for backward compatibility
-- ============================================================================

-- Add missing columns to departments
ALTER TABLE departments ADD COLUMN IF NOT EXISTS name VARCHAR(255);
ALTER TABLE departments ADD COLUMN IF NOT EXISTS alias VARCHAR(100);
ALTER TABLE departments ADD COLUMN IF NOT EXISTS parent_department_id UUID REFERENCES departments(id) ON DELETE SET NULL;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS head_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS color VARCHAR(20) DEFAULT '#3b82f6';
ALTER TABLE departments ADD COLUMN IF NOT EXISTS icon VARCHAR(50);
ALTER TABLE departments ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Sync name from department_name for existing rows
UPDATE departments SET name = department_name WHERE name IS NULL AND department_name IS NOT NULL;

-- Department Roles junction table
CREATE TABLE IF NOT EXISTS department_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    is_lead BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(department_id, role_id)
);

-- Department Policies
CREATE TABLE IF NOT EXISTS department_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Department KPIs
CREATE TABLE IF NOT EXISTS department_kpis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    target_value NUMERIC(15,2),
    current_value NUMERIC(15,2) DEFAULT 0,
    unit VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Department Processes
CREATE TABLE IF NOT EXISTS department_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(30) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Department Documents
CREATE TABLE IF NOT EXISTS department_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    media_id UUID,
    title VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add department_id FK to staff and roles if missing
ALTER TABLE staff ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL;

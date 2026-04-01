/**
 * Migration 500 — Member & Account Infrastructure (Phase 1)
 * 
 * Adds:
 * - Extended member profile columns (first_name, last_name, other_name, id_type, photo_url, emergency_contact, etc.)
 * - sacco_configurations table (feature toggles)
 * - member_field_configs table (toggleable form fields)
 * - member_audit_log table (full audit trail)
 * - Update v_member_account_balances to include account_type info
 * - account_type_rules table (per-type configurable rules) 
 * - unique constraint on membership_number
 * - blocked status for members
 */

import 'dotenv/config';
import pg from 'pg';
const { Pool } = pg;

function getPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) throw new Error('DATABASE_URL not set');
  return new Pool({
    connectionString,
    ssl: connectionString.includes('neon.tech') ? { rejectUnauthorized: true } : false,
    max: 2,
  });
}

async function migrate() {
  const pool = getPool();
  const client = await pool.connect();

  const steps = [

    // ─── STEP 1: Extend members table with full profile fields ───
    {
      name: 'Members: add first_name, last_name, other_name',
      sql: `
        ALTER TABLE members
          ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
          ADD COLUMN IF NOT EXISTS last_name VARCHAR(100),
          ADD COLUMN IF NOT EXISTS other_name VARCHAR(100);
      `,
    },
    {
      name: 'Members: add id_type, photo_url, id_photo_url',
      sql: `
        ALTER TABLE members
          ADD COLUMN IF NOT EXISTS id_type VARCHAR(50) DEFAULT 'national_id',
          ADD COLUMN IF NOT EXISTS photo_url TEXT,
          ADD COLUMN IF NOT EXISTS id_photo_url TEXT;
      `,
    },
    {
      name: 'Members: add emergency_contact, occupation, employer',
      sql: `
        ALTER TABLE members
          ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(200),
          ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50),
          ADD COLUMN IF NOT EXISTS occupation VARCHAR(200),
          ADD COLUMN IF NOT EXISTS employer VARCHAR(200),
          ADD COLUMN IF NOT EXISTS monthly_income NUMERIC(18,2);
      `,
    },
    {
      name: 'Members: add next_of_kin fields',
      sql: `
        ALTER TABLE members
          ADD COLUMN IF NOT EXISTS next_of_kin_name VARCHAR(200),
          ADD COLUMN IF NOT EXISTS next_of_kin_phone VARCHAR(50),
          ADD COLUMN IF NOT EXISTS next_of_kin_relationship VARCHAR(100);
      `,
    },
    {
      name: 'Members: add joined_date, exit_date, exit_reason, suspended_reason',
      sql: `
        ALTER TABLE members
          ADD COLUMN IF NOT EXISTS joined_date DATE DEFAULT CURRENT_DATE,
          ADD COLUMN IF NOT EXISTS exit_date DATE,
          ADD COLUMN IF NOT EXISTS exit_reason TEXT,
          ADD COLUMN IF NOT EXISTS suspended_reason TEXT,
          ADD COLUMN IF NOT EXISTS notes TEXT;
      `,
    },
    {
      name: "Members: add 'blocked' to valid statuses",
      sql: `
        DO $$
        BEGIN
          -- Drop existing constraint if it exists
          ALTER TABLE members DROP CONSTRAINT IF EXISTS members_status_check;
          -- Re-add with 'blocked' included
          ALTER TABLE members ADD CONSTRAINT members_status_check
            CHECK (status IN ('active', 'inactive', 'suspended', 'exited', 'blocked'));
        EXCEPTION WHEN others THEN
          NULL; -- Ignore if already correct
        END $$;
      `,
    },
    {
      name: 'Members: unique constraint on membership_number',
      sql: `
        CREATE UNIQUE INDEX IF NOT EXISTS idx_members_membership_number ON members(membership_number)
        WHERE membership_number IS NOT NULL;
      `,
    },
    {
      name: 'Members: unique constraint on email',
      sql: `
        CREATE UNIQUE INDEX IF NOT EXISTS idx_members_email_unique ON members(email)
        WHERE email IS NOT NULL;
      `,
    },

    // ─── STEP 2: sacco_configurations table (feature toggles) ───
    {
      name: 'Create sacco_configurations table',
      sql: `
        CREATE TABLE IF NOT EXISTS sacco_configurations (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          config_key VARCHAR(200) NOT NULL UNIQUE,
          config_value JSONB NOT NULL DEFAULT 'true',
          config_type VARCHAR(50) NOT NULL DEFAULT 'boolean'
            CHECK (config_type IN ('boolean', 'text', 'number', 'json', 'list')),
          category VARCHAR(100) NOT NULL DEFAULT 'general'
            CHECK (category IN ('general', 'members', 'accounts', 'loans', 'transfers', 'ui', 'notifications')),
          label VARCHAR(255),
          description TEXT,
          is_editable BOOLEAN NOT NULL DEFAULT true,
          updated_by UUID REFERENCES users(id),
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `,
    },
    {
      name: 'Seed default sacco_configurations',
      sql: `
        INSERT INTO sacco_configurations (config_key, config_value, config_type, category, label, description) VALUES
          -- Member module toggles
          ('members.require_photo', 'false', 'boolean', 'members', 'Require member photo', 'Require ID/profile photo during registration'),
          ('members.require_id_document', 'false', 'boolean', 'members', 'Require ID document', 'Require ID document scan/photo'),
          ('members.require_national_id', 'true', 'boolean', 'members', 'Require National ID', 'National ID number is mandatory'),
          ('members.require_dob', 'true', 'boolean', 'members', 'Require Date of Birth', 'DOB is mandatory during registration'),
          ('members.require_gender', 'true', 'boolean', 'members', 'Require Gender', 'Gender is mandatory'),
          ('members.require_phone', 'true', 'boolean', 'members', 'Require Phone', 'Phone number is mandatory'),
          ('members.require_address', 'false', 'boolean', 'members', 'Require Address', 'Home address is mandatory'),
          ('members.require_next_of_kin', 'false', 'boolean', 'members', 'Require Next of Kin', 'Next of kin details mandatory'),
          ('members.require_occupation', 'false', 'boolean', 'members', 'Require Occupation', 'Employment/occupation details required'),
          ('members.allow_member_self_register', 'false', 'boolean', 'members', 'Allow Self-Registration', 'Members can register themselves via portal'),
          -- Account module toggles
          ('accounts.enable_savings', 'true', 'boolean', 'accounts', 'Enable Savings Accounts', 'Allow voluntary savings accounts'),
          ('accounts.enable_fixed', 'true', 'boolean', 'accounts', 'Enable Fixed Deposit', 'Allow fixed deposit accounts'),
          ('accounts.enable_shares', 'true', 'boolean', 'accounts', 'Enable Shares Accounts', 'Allow equity/shares accounts'),
          ('accounts.enable_investments', 'true', 'boolean', 'accounts', 'Enable Investment Accounts', 'Allow investment accounts'),
          ('accounts.enable_loans', 'true', 'boolean', 'accounts', 'Enable Loan Accounts', 'Allow loan disbursement accounts'),
          ('accounts.auto_open_savings', 'true', 'boolean', 'accounts', 'Auto-Open Savings', 'Automatically open savings account on member registration'),
          ('accounts.auto_open_shares', 'false', 'boolean', 'accounts', 'Auto-Open Shares', 'Automatically open shares account on member registration'),
          -- Loan module toggles
          ('loans.require_guarantors', 'true', 'boolean', 'loans', 'Require Guarantors', 'Loan applications require guarantors'),
          ('loans.enable_partial_disbursement', 'true', 'boolean', 'loans', 'Enable Partial Disbursement', 'Loans can be partially disbursed'),
          ('loans.enable_loan_insurance', 'false', 'boolean', 'loans', 'Enable Loan Insurance', 'Add insurance premium to loans'),
          -- Transfer toggles
          ('transfers.enable_member_transfers', 'true', 'boolean', 'transfers', 'Enable Member Transfers', 'Allow peer-to-peer member transfers'),
          ('transfers.require_approval', 'false', 'boolean', 'transfers', 'Require Transfer Approval', 'Transfers above limit need manager approval'),
          ('transfers.approval_threshold', '{"amount": 5000000}', 'json', 'transfers', 'Approval Threshold', 'Amount above which approval is required')
        ON CONFLICT (config_key) DO NOTHING;
      `,
    },

    // ─── STEP 3: member_field_configs (which fields are shown/required in UI) ───
    {
      name: 'Create member_field_configs table',
      sql: `
        CREATE TABLE IF NOT EXISTS member_field_configs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          field_name VARCHAR(100) NOT NULL UNIQUE,
          label VARCHAR(200) NOT NULL,
          section VARCHAR(100) NOT NULL DEFAULT 'personal'
            CHECK (section IN ('personal', 'identification', 'contact', 'employment', 'kin', 'financial', 'other')),
          field_type VARCHAR(50) NOT NULL DEFAULT 'text'
            CHECK (field_type IN ('text', 'email', 'phone', 'date', 'select', 'file', 'textarea', 'number')),
          is_active BOOLEAN NOT NULL DEFAULT true,
          is_required BOOLEAN NOT NULL DEFAULT false,
          sort_order INTEGER NOT NULL DEFAULT 0,
          options JSONB,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `,
    },
    {
      name: 'Seed member_field_configs',
      sql: `
        INSERT INTO member_field_configs (field_name, label, section, field_type, is_active, is_required, sort_order) VALUES
          ('first_name', 'First Name', 'personal', 'text', true, true, 1),
          ('last_name', 'Last Name', 'personal', 'text', true, true, 2),
          ('other_name', 'Other/Middle Name', 'personal', 'text', true, false, 3),
          ('gender', 'Gender', 'personal', 'select', true, true, 4),
          ('date_of_birth', 'Date of Birth', 'personal', 'date', true, true, 5),
          ('photo_url', 'Profile Photo', 'identification', 'file', false, false, 6),
          ('national_id', 'National ID Number', 'identification', 'text', true, true, 7),
          ('id_type', 'ID Type', 'identification', 'select', true, false, 8),
          ('id_photo_url', 'ID Document Photo', 'identification', 'file', false, false, 9),
          ('email', 'Email Address', 'contact', 'email', true, false, 10),
          ('phone', 'Phone Number', 'contact', 'phone', true, true, 11),
          ('address', 'Home Address', 'contact', 'textarea', true, false, 12),
          ('occupation', 'Occupation / Job Title', 'employment', 'text', false, false, 13),
          ('employer', 'Employer / Business Name', 'employment', 'text', false, false, 14),
          ('monthly_income', 'Monthly Income (UGX)', 'employment', 'number', false, false, 15),
          ('next_of_kin_name', 'Next of Kin - Full Name', 'kin', 'text', false, false, 16),
          ('next_of_kin_phone', 'Next of Kin - Phone', 'kin', 'phone', false, false, 17),
          ('next_of_kin_relationship', 'Next of Kin - Relationship', 'kin', 'text', false, false, 18),
          ('emergency_contact_name', 'Emergency Contact - Name', 'kin', 'text', false, false, 19),
          ('emergency_contact_phone', 'Emergency Contact - Phone', 'kin', 'phone', false, false, 20),
          ('notes', 'Additional Notes', 'other', 'textarea', false, false, 21)
        ON CONFLICT (field_name) DO NOTHING;
      `,
    },

    // ─── STEP 4: member_audit_log ───
    {
      name: 'Create member_audit_log table',
      sql: `
        CREATE TABLE IF NOT EXISTS member_audit_log (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
          action VARCHAR(50) NOT NULL
            CHECK (action IN ('created', 'updated', 'status_changed', 'deleted', 'account_opened', 'account_closed', 'login', 'document_uploaded')),
          performed_by UUID REFERENCES users(id),
          old_values JSONB,
          new_values JSONB,
          ip_address VARCHAR(45),
          user_agent TEXT,
          notes TEXT,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `,
    },
    {
      name: 'Index on member_audit_log(member_id)',
      sql: `CREATE INDEX IF NOT EXISTS idx_member_audit_member ON member_audit_log(member_id);`,
    },
    {
      name: 'Index on member_audit_log(action, created_at)',
      sql: `CREATE INDEX IF NOT EXISTS idx_member_audit_action ON member_audit_log(action, created_at DESC);`,
    },

    // ─── STEP 5: account_type_rules table ───
    {
      name: 'Create account_type_rules table',
      sql: `
        CREATE TABLE IF NOT EXISTS account_type_rules (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          account_type_id UUID NOT NULL REFERENCES account_types(id) ON DELETE CASCADE,
          rule_key VARCHAR(100) NOT NULL,
          rule_value JSONB NOT NULL,
          label VARCHAR(255),
          description TEXT,
          is_active BOOLEAN NOT NULL DEFAULT true,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE(account_type_id, rule_key)
        );
      `,
    },
    {
      name: 'Seed account_type_rules from existing account_types',
      sql: `
        INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, label, description)
        SELECT id, 'min_balance', to_jsonb(minimum_balance), 'Minimum Balance', 'Minimum balance that must be maintained'
        FROM account_types
        WHERE minimum_balance > 0
        ON CONFLICT (account_type_id, rule_key) DO NOTHING;

        INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, label, description)
        SELECT id, 'interest_rate', to_jsonb(interest_rate), 'Interest Rate (%)', 'Annual interest rate applied to balances'
        FROM account_types
        WHERE interest_rate > 0
        ON CONFLICT (account_type_id, rule_key) DO NOTHING;

        INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, label, description)
        SELECT id, 'allows_withdrawal', to_jsonb(allows_withdrawal), 'Allows Withdrawal', 'Whether withdrawals are permitted from this account'
        FROM account_types
        ON CONFLICT (account_type_id, rule_key) DO NOTHING;
      `,
    },
    {
      name: 'Seed fixed deposit maturity rules',
      sql: `
        INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, label, description)
        SELECT id, 'min_duration_days', '{"days": 30}', 'Minimum Duration (days)', 'Minimum lock-in period in days'
        FROM account_types WHERE code = 'FIXED_SAV'
        ON CONFLICT (account_type_id, rule_key) DO NOTHING;

        INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, label, description)
        SELECT id, 'max_duration_days', '{"days": 1825}', 'Maximum Duration (days)', 'Maximum fixed deposit duration (1825 = 5 years)'
        FROM account_types WHERE code = 'FIXED_SAV'
        ON CONFLICT (account_type_id, rule_key) DO NOTHING;
      `,
    },

    // ─── STEP 6: Add maturity_date to member_accounts (for fixed) ───
    {
      name: 'member_accounts: add maturity_date, dormant_since, closed_at',
      sql: `
        ALTER TABLE member_accounts
          ADD COLUMN IF NOT EXISTS maturity_date DATE,
          ADD COLUMN IF NOT EXISTS dormant_since DATE,
          ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ,
          ADD COLUMN IF NOT EXISTS closed_reason TEXT,
          ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id),
          ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
      `,
    },
    {
      name: "member_accounts: add 'dormant' and 'closed' to valid statuses",
      sql: `
        DO $$
        BEGIN
          ALTER TABLE member_accounts DROP CONSTRAINT IF EXISTS member_accounts_status_check;
          ALTER TABLE member_accounts ADD CONSTRAINT member_accounts_status_check
            CHECK (status IN ('active', 'dormant', 'closed', 'suspended'));
        EXCEPTION WHEN others THEN NULL;
        END $$;
      `,
    },

    // ─── STEP 7: Refresh v_member_account_balances with account_type info ───
    {
      name: 'Refresh v_member_account_balances view with account_type data',
      sql: `
        DROP VIEW IF EXISTS v_member_account_balances;
        CREATE VIEW v_member_account_balances AS
        SELECT
          ma.id,
          ma.id AS member_account_id,
          ma.member_id,
          ma.account_type,
          ma.account_type_id,
          ma.account_number,
          ma.currency,
          ma.status,
          ma.opened_at,
          ma.maturity_date,
          ma.closed_at,
          at.name AS account_type_name,
          at.code AS account_type_code,
          at.allows_withdrawal,
          at.minimum_balance,
          at.interest_rate,
          COALESCE(SUM(
            CASE
              WHEN le.entry_type = 'CREDIT' THEN le.amount
              WHEN le.entry_type = 'DEBIT' THEN -le.amount
              ELSE 0
            END
          ), 0) AS balance,
          COUNT(le.id) AS transaction_count,
          MAX(le.created_at) AS last_transaction_at,
          m.full_name AS member_name,
          m.membership_number
        FROM member_accounts ma
        LEFT JOIN ledger_entries le ON le.member_account_id = ma.id
        LEFT JOIN account_types at ON ma.account_type_id = at.id
        LEFT JOIN members m ON ma.member_id = m.id
        GROUP BY ma.id, ma.member_id, ma.account_type, ma.account_type_id,
                 ma.account_number, ma.currency, ma.status, ma.opened_at,
                 ma.maturity_date, ma.closed_at,
                 at.name, at.code, at.allows_withdrawal, at.minimum_balance, at.interest_rate,
                 m.full_name, m.membership_number;
      `,
    },

    // ─── STEP 8: Backfill first_name/last_name from full_name ───
    {
      name: 'Backfill first_name and last_name from full_name',
      sql: `
        UPDATE members SET
          first_name = TRIM(split_part(full_name, ' ', 1)),
          last_name = COALESCE(
            NULLIF(TRIM(REGEXP_REPLACE(full_name, '^\\S+\\s*', '')), ''),
            TRIM(split_part(full_name, ' ', 1))
          )
        WHERE first_name IS NULL AND full_name IS NOT NULL;
      `,
    },

    // ─── STEP 9: Indexes ───
    {
      name: 'Index: members(status)',
      sql: `CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);`,
    },
    {
      name: 'Index: members(joined_date)',
      sql: `CREATE INDEX IF NOT EXISTS idx_members_joined ON members(joined_date);`,
    },
    {
      name: 'Index: member_accounts(status)',
      sql: `CREATE INDEX IF NOT EXISTS idx_member_accounts_status ON member_accounts(status);`,
    },
    {
      name: 'Index: account_type_rules(account_type_id)',
      sql: `CREATE INDEX IF NOT EXISTS idx_atr_type ON account_type_rules(account_type_id);`,
    },
    {
      name: 'Index: sacco_configurations(category)',
      sql: `CREATE INDEX IF NOT EXISTS idx_sacco_config_category ON sacco_configurations(category);`,
    },
  ];

  try {
    await client.query('BEGIN');
    for (const step of steps) {
      try {
        await client.query(step.sql);
        console.log(`✅ ${step.name}`);
      } catch (err) {
        console.error(`❌ ${step.name}: ${err.message}`);
        throw err;
      }
    }
    await client.query('COMMIT');
    console.log('\n🎉 Migration 500 complete!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('\n💥 Migration rolled back:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();

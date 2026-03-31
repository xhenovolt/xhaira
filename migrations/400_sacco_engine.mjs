/**
 * Migration 400 — SACCO Engine: Account Types, Rules, Guarantors, Loan Lifecycle
 *
 * Phase 1: account_types table + FK on member_accounts
 * Phase 2: sacco_rules table + seed defaults
 * Phase 3: loan_guarantors table
 * Phase 4-5: Loan lifecycle (DISBURSED status, approved_amount, disbursed_amount)
 * Phase 7: transaction_type 'transfer' support (already TEXT, no enum change needed)
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
    // ─── PHASE 1: Account Types ───
    {
      name: 'Create account_types table',
      sql: `CREATE TABLE IF NOT EXISTS account_types (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        code TEXT UNIQUE,
        description TEXT,
        allows_withdrawal BOOLEAN DEFAULT TRUE,
        minimum_balance NUMERIC DEFAULT 0,
        is_mandatory BOOLEAN DEFAULT FALSE,
        interest_rate NUMERIC DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )`,
    },
    {
      name: 'Seed default account types',
      sql: `INSERT INTO account_types (name, code, description, allows_withdrawal, minimum_balance, is_mandatory)
       VALUES
         ('Voluntary Savings', 'VOL_SAV', 'Flexible savings that can be withdrawn anytime', true, 0, false),
         ('Fixed Savings', 'FIXED_SAV', 'Locked savings required for loan eligibility', false, 0, true),
         ('Shares', 'SHARES', 'Member share capital in the SACCO', false, 0, true),
         ('Loan Account', 'LOAN_ACC', 'Account for loan disbursements and repayments', true, 0, false),
         ('Investment', 'INVEST', 'Long-term investment account', false, 0, false)
       ON CONFLICT (code) DO NOTHING`,
    },
    {
      name: 'Add account_type_id to member_accounts',
      sql: `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'member_accounts' AND column_name = 'account_type_id') THEN
          ALTER TABLE member_accounts ADD COLUMN account_type_id UUID REFERENCES account_types(id);
        END IF;
      END $$`,
    },

    // ─── PHASE 2: Rule Engine ───
    {
      name: 'Create sacco_rules table',
      sql: `CREATE TABLE IF NOT EXISTS sacco_rules (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        rule_type TEXT NOT NULL,
        rule_key TEXT NOT NULL,
        rule_value JSONB NOT NULL DEFAULT '{}',
        description TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(rule_type, rule_key)
      )`,
    },
    {
      name: 'Seed default SACCO rules',
      sql: `INSERT INTO sacco_rules (rule_type, rule_key, rule_value, description) VALUES
        ('LOAN', 'min_fixed_savings_for_loan', '{"amount": 500000}', 'Minimum fixed savings balance required to qualify for a loan'),
        ('LOAN', 'max_loan_multiplier', '{"multiplier": 3}', 'Maximum loan = fixed savings × multiplier'),
        ('LOAN', 'guarantors_required', '{"count": 2}', 'Number of guarantors required per loan application'),
        ('LOAN', 'max_active_loans', '{"count": 2}', 'Maximum active loans a member can have simultaneously'),
        ('ACCOUNT', 'min_share_balance', '{"amount": 50000}', 'Minimum shares a member must hold'),
        ('ACCOUNT', 'min_voluntary_savings', '{"amount": 0}', 'Minimum voluntary savings balance'),
        ('GUARANTOR', 'max_guarantee_percentage', '{"percentage": 50}', 'Max percentage of own savings a member can guarantee'),
        ('GUARANTOR', 'min_membership_months', '{"months": 3}', 'Minimum months of membership before one can guarantee'),
        ('TRANSFER', 'min_transfer_amount', '{"amount": 1000}', 'Minimum transfer amount between members'),
        ('TRANSFER', 'max_daily_transfers', '{"count": 5}', 'Maximum number of transfers per day per member')
      ON CONFLICT (rule_type, rule_key) DO NOTHING`,
    },

    // ─── PHASE 3: Guarantor System ───
    {
      name: 'Create loan_guarantors table',
      sql: `CREATE TABLE IF NOT EXISTS loan_guarantors (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
        guarantor_member_id UUID NOT NULL REFERENCES members(id),
        guaranteed_amount NUMERIC NOT NULL CHECK (guaranteed_amount > 0),
        status TEXT DEFAULT 'PENDING',
        responded_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(loan_id, guarantor_member_id)
      )`,
    },

    // ─── PHASE 4-5: Loan Lifecycle Upgrade ───
    {
      name: 'Add approved_amount to loans',
      sql: `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loans' AND column_name = 'approved_amount') THEN
          ALTER TABLE loans ADD COLUMN approved_amount NUMERIC;
        END IF;
      END $$`,
    },
    {
      name: 'Add disbursed_amount to loans',
      sql: `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loans' AND column_name = 'disbursed_amount') THEN
          ALTER TABLE loans ADD COLUMN disbursed_amount NUMERIC DEFAULT 0;
        END IF;
      END $$`,
    },
    {
      name: 'Add disbursed_at to loans',
      sql: `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loans' AND column_name = 'disbursed_at') THEN
          ALTER TABLE loans ADD COLUMN disbursed_at TIMESTAMP;
        END IF;
      END $$`,
    },

    // ─── PHASE 6: Cash Account (already exists as system account, ensure it is typed) ───
    {
      name: 'Create SACCO Cash account type if missing',
      sql: `INSERT INTO account_types (name, code, description, allows_withdrawal, minimum_balance, is_mandatory)
       VALUES ('Cash', 'CASH', 'Physical cash held by the SACCO', true, 0, false)
       ON CONFLICT (code) DO NOTHING`,
    },
    {
      name: 'Ensure SACCO Cash Account exists',
      sql: `INSERT INTO accounts (name, type, currency, description, is_active)
       SELECT 'SACCO Cash Account', 'system', 'UGX', 'System liquidity pool for all member transactions', true
       WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE type = 'system' AND name = 'SACCO Cash Account')`,
    },

    // ─── Index for performance ───
    {
      name: 'Index on loan_guarantors(loan_id)',
      sql: `CREATE INDEX IF NOT EXISTS idx_loan_guarantors_loan ON loan_guarantors(loan_id)`,
    },
    {
      name: 'Index on loan_guarantors(guarantor_member_id)',
      sql: `CREATE INDEX IF NOT EXISTS idx_loan_guarantors_guarantor ON loan_guarantors(guarantor_member_id)`,
    },
    {
      name: 'Index on sacco_rules(rule_type, rule_key)',
      sql: `CREATE INDEX IF NOT EXISTS idx_sacco_rules_type_key ON sacco_rules(rule_type, rule_key)`,
    },
    {
      name: 'Index on member_accounts(account_type_id)',
      sql: `CREATE INDEX IF NOT EXISTS idx_member_accounts_type ON member_accounts(account_type_id)`,
    },
  ];

  console.log('🚀 Migration 400 — SACCO Engine\n');

  for (const step of steps) {
    try {
      await client.query(step.sql);
      console.log(`  ✅ ${step.name}`);
    } catch (err) {
      console.log(`  ❌ ${step.name}: ${err.message}`);
    }
  }

  console.log('\n✅ Migration 400 complete.');
  client.release();
  await pool.end();
}

migrate().catch(e => {
  console.error('Migration failed:', e);
  process.exit(1);
});

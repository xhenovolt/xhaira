/**
 * XHAIRA — Double-Entry Ledger + Loan Engine Migration
 * 
 * Creates:
 * 1. transactions table (groups ledger entries)
 * 2. ledger_entries table (double-entry: DEBIT/CREDIT)
 * 3. ledger table (for company accounts — existing v_account_balances dependency)
 * 4. products table (SACCO financial products)
 * 5. loans table
 * 6. loan_schedules table
 * 7. v_member_account_balances view (derived from ledger)
 * 8. System cash account
 * 
 * Also:
 * - Drops member_accounts.balance column (balance derived from ledger_entries)
 * - Adds repayment_cycle to systems table for backward compat
 */

import dotenv from 'dotenv';
import pg from 'pg';
dotenv.config({ path: '.env.local' });

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
});

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ========================================================================
    // 1. TRANSACTIONS — Groups multiple ledger entries into one atomic unit
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS transactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        reference TEXT,
        description TEXT,
        transaction_type TEXT CHECK (transaction_type IN (
          'deposit', 'withdrawal', 'transfer', 'loan_disbursement',
          'loan_repayment', 'fee', 'interest', 'adjustment', 'initial_balance'
        )),
        metadata JSONB DEFAULT '{}',
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference);`);
    console.log('✅ transactions table');

    // ========================================================================
    // 2. LEDGER ENTRIES — Double-entry: every entry is DEBIT or CREDIT
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS ledger_entries (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
        account_id UUID,
        member_account_id UUID REFERENCES member_accounts(id),
        entry_type TEXT NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
        amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
        currency VARCHAR(3) NOT NULL DEFAULT 'UGX',
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tx ON ledger_entries(transaction_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_entries_account ON ledger_entries(account_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_entries_member_account ON ledger_entries(member_account_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_entries_created_at ON ledger_entries(created_at);`);
    console.log('✅ ledger_entries table');

    // ========================================================================
    // 3. LEDGER TABLE — For company accounts (v_account_balances dependency)
    //    The existing architecture expects this for accounts (bank/cash/mobile_money)
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS ledger (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
        amount NUMERIC(15,2) NOT NULL,
        currency VARCHAR(3) NOT NULL DEFAULT 'UGX',
        running_balance NUMERIC(15,2),
        source_type VARCHAR(50) NOT NULL CHECK (source_type IN (
          'payment', 'expense', 'transfer_in', 'transfer_out',
          'adjustment', 'refund', 'initial_balance',
          'loan_disbursement', 'loan_repayment', 'deposit', 'withdrawal', 'fee'
        )),
        source_id UUID,
        description TEXT NOT NULL,
        category VARCHAR(100),
        entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
        metadata JSONB DEFAULT '{}',
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_account_id ON ledger(account_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_source ON ledger(source_type, source_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_entry_date ON ledger(entry_date);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_ledger_created_at ON ledger(created_at);`);
    console.log('✅ ledger table (company accounts)');

    // ========================================================================
    // 4. v_account_balances VIEW — Company accounts balance from ledger
    // ========================================================================
    await client.query(`
      CREATE OR REPLACE VIEW v_account_balances AS
      SELECT
        a.id AS account_id,
        a.name,
        a.type,
        a.currency,
        a.is_active,
        COALESCE(SUM(l.amount), 0) AS balance,
        COUNT(l.id) AS transaction_count,
        MAX(l.entry_date) AS last_transaction_date
      FROM accounts a
      LEFT JOIN ledger l ON l.account_id = a.id
      GROUP BY a.id, a.name, a.type, a.currency, a.is_active;
    `);
    console.log('✅ v_account_balances view');

    // ========================================================================
    // 5. v_member_account_balances VIEW — Member account balance from ledger_entries
    // ========================================================================
    await client.query(`
      CREATE OR REPLACE VIEW v_member_account_balances AS
      SELECT
        ma.id AS member_account_id,
        ma.member_id,
        ma.account_type,
        ma.account_number,
        ma.currency,
        ma.status,
        ma.opened_at,
        COALESCE(SUM(
          CASE
            WHEN le.entry_type = 'CREDIT' THEN le.amount
            WHEN le.entry_type = 'DEBIT' THEN -le.amount
            ELSE 0
          END
        ), 0) AS balance,
        COUNT(le.id) AS transaction_count,
        MAX(le.created_at) AS last_transaction_at
      FROM member_accounts ma
      LEFT JOIN ledger_entries le ON le.member_account_id = ma.id
      GROUP BY ma.id, ma.member_id, ma.account_type, ma.account_number, ma.currency, ma.status, ma.opened_at;
    `);
    console.log('✅ v_member_account_balances view');

    // ========================================================================
    // 6. DROP member_accounts.balance column (balance now derived from ledger)
    //    Only drop if column exists and no non-zero balances
    // ========================================================================
    const balCheck = await client.query(
      `SELECT COUNT(*) as cnt FROM member_accounts WHERE balance != 0`
    );
    if (parseInt(balCheck.rows[0].cnt) === 0) {
      await client.query(`ALTER TABLE member_accounts DROP COLUMN IF EXISTS balance;`);
      console.log('✅ Dropped member_accounts.balance (was unused)');
    } else {
      console.log('⚠️  member_accounts.balance NOT dropped — has non-zero values. Migrate data first.');
    }

    // ========================================================================
    // 7. PRODUCTS TABLE — SACCO financial products
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        product_type TEXT NOT NULL CHECK (product_type IN ('LOAN', 'SAVINGS', 'INVESTMENT', 'INSTALLMENT', 'SERVICE', 'SHARES', 'FIXED_DEPOSIT')),
        price NUMERIC(15,2),
        currency VARCHAR(10) DEFAULT 'UGX',
        interest_rate NUMERIC(8,4),
        duration INTEGER,
        repayment_cycle TEXT CHECK (repayment_cycle IN ('DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY', NULL)),
        min_amount NUMERIC(15,2),
        max_amount NUMERIC(15,2),
        requires_approval BOOLEAN DEFAULT TRUE,
        is_active BOOLEAN DEFAULT TRUE,
        metadata JSONB DEFAULT '{}',
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_products_type ON products(product_type);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);`);
    console.log('✅ products table');

    // ========================================================================
    // 8. LOANS TABLE
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS loans (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        member_id UUID NOT NULL REFERENCES members(id),
        product_id UUID REFERENCES products(id),
        member_account_id UUID REFERENCES member_accounts(id),
        principal NUMERIC(18,2) NOT NULL CHECK (principal > 0),
        interest_rate NUMERIC(8,4) NOT NULL,
        duration INTEGER NOT NULL,
        repayment_cycle TEXT NOT NULL DEFAULT 'MONTHLY' CHECK (repayment_cycle IN ('DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY')),
        total_interest NUMERIC(18,2) NOT NULL DEFAULT 0,
        total_payable NUMERIC(18,2) NOT NULL,
        total_paid NUMERIC(18,2) NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'ACTIVE', 'COMPLETED', 'DEFAULTED', 'WRITTEN_OFF')),
        disbursement_transaction_id UUID REFERENCES transactions(id),
        approved_by UUID REFERENCES users(id),
        approved_at TIMESTAMPTZ,
        rejected_reason TEXT,
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loans_member ON loans(member_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loans_product ON loans(product_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);`);
    console.log('✅ loans table');

    // ========================================================================
    // 9. LOAN SCHEDULES TABLE
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS loan_schedules (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
        installment_number INTEGER NOT NULL,
        due_date DATE NOT NULL,
        principal_amount NUMERIC(18,2) NOT NULL,
        interest_amount NUMERIC(18,2) NOT NULL,
        total_amount NUMERIC(18,2) NOT NULL,
        paid_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'PARTIAL', 'OVERDUE')),
        paid_at TIMESTAMPTZ,
        transaction_id UUID REFERENCES transactions(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loan_schedules_loan ON loan_schedules(loan_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loan_schedules_due_date ON loan_schedules(due_date);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_loan_schedules_status ON loan_schedules(status);`);
    console.log('✅ loan_schedules table');

    // ========================================================================
    // 10. Add repayment_cycle to systems table if missing (backward compat)
    // ========================================================================
    const sysRepCycle = await client.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'systems' AND column_name = 'repayment_cycle'
    `);
    if (sysRepCycle.rows.length === 0) {
      await client.query(`ALTER TABLE systems ADD COLUMN repayment_cycle TEXT;`);
      console.log('✅ Added repayment_cycle to systems table');
    }

    // ========================================================================
    // 11. SYSTEM CASH ACCOUNT — SACCO liquidity pool
    // ========================================================================
    const sysAcct = await client.query(`SELECT id FROM accounts WHERE type = 'system' AND name = 'SACCO Cash Account'`);
    if (sysAcct.rows.length === 0) {
      await client.query(`
        INSERT INTO accounts (name, type, currency, description, is_active)
        VALUES ('SACCO Cash Account', 'system', 'UGX', 'Internal SACCO cash pool — system liquidity account', true)
      `);
      console.log('✅ Created SACCO Cash Account (system)');
    } else {
      console.log('ℹ️  SACCO Cash Account already exists');
    }

    // Add 'system' to accounts type CHECK if needed (safe — already flexible in schema)
    // The original CHECK constraint might not include 'system', but our accounts table
    // was created without a CHECK on type in the live DB, so this should work.

    // ========================================================================
    // 12. account_mutations TABLE (if missing — referenced by finance API)
    // ========================================================================
    await client.query(`
      CREATE TABLE IF NOT EXISTS account_mutations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        account_id UUID REFERENCES accounts(id),
        old_value NUMERIC(15,2),
        new_value NUMERIC(15,2),
        reason TEXT NOT NULL,
        performed_by UUID REFERENCES users(id),
        is_superadmin_only BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    console.log('✅ account_mutations table');

    await client.query('COMMIT');
    console.log('\n🎉 Migration complete — double-entry ledger + loan engine ready');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', err.message);
    throw err;
  } finally {
    client.release();
    pool.end();
  }
}

migrate();

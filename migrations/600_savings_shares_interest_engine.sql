-- =============================================================================
-- Migration 600: Savings, Shares & Interest Engine
-- Xhaira SACCO — Configurable Financial Logic Layer
-- =============================================================================
-- All financial behavior is driven by rules, not hardcoded constants.
-- This migration creates four tables and system accounts needed by the engine.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PHASE 1: Configurable Account Rule Engine
-- Per-account-type rules that override or extend base account_types fields.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS account_type_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_type_id UUID NOT NULL REFERENCES account_types(id) ON DELETE CASCADE,
    rule_key        TEXT NOT NULL,
    rule_value      JSONB NOT NULL,
    description     TEXT,
    is_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_type_id, rule_key)
);

CREATE INDEX IF NOT EXISTS idx_account_type_rules_type_id ON account_type_rules (account_type_id);
CREATE INDEX IF NOT EXISTS idx_account_type_rules_enabled  ON account_type_rules (account_type_id, is_enabled);

-- Trigger: keep updated_at fresh
CREATE OR REPLACE FUNCTION set_account_type_rules_updated_at()
RETURNS TRIGGER LANGUAGE 'plpgsql' AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;
DROP TRIGGER IF EXISTS trg_account_type_rules_updated_at ON account_type_rules;
CREATE TRIGGER trg_account_type_rules_updated_at
    BEFORE UPDATE ON account_type_rules
    FOR EACH ROW EXECUTE FUNCTION set_account_type_rules_updated_at();

-- Seed sensible default rules for each existing account type
-- VOL_SAV: voluntary savings — withdrawals allowed, 3% annual interest monthly
INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'min_balance',          '5000'::JSONB,   'Minimum balance in UGX'             FROM account_types WHERE code = 'VOL_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_rate',        '3'::JSONB,       'Annual interest rate (%)'           FROM account_types WHERE code = 'VOL_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_cycle',      '"MONTHLY"'::JSONB,'Interest calculation cycle'         FROM account_types WHERE code = 'VOL_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'withdrawal_allowed',  'true'::JSONB,    'Withdrawals permitted'               FROM account_types WHERE code = 'VOL_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'loan_eligible',       'true'::JSONB,    'Account balance counts toward loan'  FROM account_types WHERE code = 'VOL_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

-- FIXED_SAV: fixed savings — no withdrawal, 7% interest, 90-day maturity
INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'min_balance',          '50000'::JSONB,  'Minimum fixed deposit amount'        FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_rate',        '7'::JSONB,      'Annual interest rate (%)'            FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_cycle',      '"MONTHLY"'::JSONB,'Interest calculation cycle'         FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'withdrawal_allowed',  'false'::JSONB,   'No withdrawals before maturity'      FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'requires_maturity',   'true'::JSONB,    'Must mature before withdrawal'       FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'maturity_period_days','90'::JSONB,       'Maturity period in days'            FROM account_types WHERE code = 'FIXED_SAV'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

-- SHARES: equity shares — no withdrawal
INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'withdrawal_allowed',  'false'::JSONB,   'Shares cannot be withdrawn as cash'  FROM account_types WHERE code = 'SHARES'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'loan_eligible',       'true'::JSONB,    'Shares count toward loan eligibility' FROM account_types WHERE code = 'SHARES'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'dividend_eligible',   'true'::JSONB,    'Shares earn dividends'               FROM account_types WHERE code = 'SHARES'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

-- INVEST: investment — 10% interest, 365-day maturity
INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_rate',       '10'::JSONB,      'Annual return rate (%)'              FROM account_types WHERE code = 'INVEST'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'interest_cycle',     '"QUARTERLY"'::JSONB,'Interest calculation cycle'        FROM account_types WHERE code = 'INVEST'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'withdrawal_allowed', 'false'::JSONB,    'Investment locked until maturity'    FROM account_types WHERE code = 'INVEST'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'requires_maturity',  'true'::JSONB,     'Must mature before withdrawal'       FROM account_types WHERE code = 'INVEST'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

INSERT INTO account_type_rules (account_type_id, rule_key, rule_value, description)
SELECT id, 'maturity_period_days','365'::JSONB,      'Investment locked for 1 year'       FROM account_types WHERE code = 'INVEST'
ON CONFLICT (account_type_id, rule_key) DO NOTHING;

-- -----------------------------------------------------------------------------
-- PHASE 3: Interest Accruals
-- Tracks computed interest before it is posted to the ledger.
-- account_id here references member_accounts (member savings accounts)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS interest_accruals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES member_accounts(id) ON DELETE CASCADE,
    amount          NUMERIC(18,4) NOT NULL CHECK (amount >= 0),
    rate_used       NUMERIC(10,6),
    balance_at_calc NUMERIC(18,2),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING', 'APPLIED', 'REVERSED', 'FAILED')),
    applied_at      TIMESTAMPTZ,
    applied_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    transaction_id  UUID REFERENCES transactions(id) ON DELETE SET NULL,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT interest_accruals_period_check CHECK (period_end > period_start)
);

CREATE INDEX IF NOT EXISTS idx_interest_accruals_account   ON interest_accruals (account_id);
CREATE INDEX IF NOT EXISTS idx_interest_accruals_status    ON interest_accruals (status);
CREATE INDEX IF NOT EXISTS idx_interest_accruals_period    ON interest_accruals (period_start, period_end);

-- -----------------------------------------------------------------------------
-- PHASE 4: Shares System
-- Tracks member equity (share unit ownership) independently of member_accounts.
-- Shares affect loan eligibility and dividend allocation.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shares (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id       UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    units           NUMERIC(18,4) NOT NULL CHECK (units > 0),
    value_per_unit  NUMERIC(18,4) NOT NULL CHECK (value_per_unit > 0),
    total_value     NUMERIC(18,2) GENERATED ALWAYS AS (units * value_per_unit) STORED,
    transaction_id  UUID REFERENCES transactions(id) ON DELETE SET NULL,
    notes           TEXT,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shares_member ON shares (member_id);
CREATE INDEX IF NOT EXISTS idx_shares_created ON shares (created_at);

-- View: aggregate shares per member
CREATE OR REPLACE VIEW v_member_shares AS
SELECT
    m.id            AS member_id,
    m.full_name,
    m.membership_number,
    COALESCE(SUM(s.units), 0)           AS total_units,
    COALESCE(SUM(s.total_value), 0)     AS total_value,
    MIN(s.value_per_unit)               AS min_unit_price,
    MAX(s.value_per_unit)               AS max_unit_price,
    COUNT(s.id)                         AS purchase_count,
    MAX(s.created_at)                   AS last_purchase_at
FROM members m
LEFT JOIN shares s ON s.member_id = m.id
GROUP BY m.id, m.full_name, m.membership_number;

-- -----------------------------------------------------------------------------
-- PHASE 5: Dividend Engine
-- Tracks dividend distributions to members.
-- Based on shares or savings balance — method defined by SACCO rules.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dividends (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id           UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    member_account_id   UUID REFERENCES member_accounts(id) ON DELETE SET NULL,
    amount              NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    period              TEXT NOT NULL,
    basis               TEXT NOT NULL DEFAULT 'shares'
                            CHECK (basis IN ('shares', 'savings', 'equal')),
    basis_value         NUMERIC(18,4),
    transaction_id      UUID REFERENCES transactions(id) ON DELETE SET NULL,
    distribution_id     UUID,
    notes               TEXT,
    created_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dividends_member       ON dividends (member_id);
CREATE INDEX IF NOT EXISTS idx_dividends_period       ON dividends (period);
CREATE INDEX IF NOT EXISTS idx_dividends_distribution ON dividends (distribution_id);

-- -----------------------------------------------------------------------------
-- SYSTEM ACCOUNTS for Interest and Dividend postings
-- These are company-level accounts used as the corresponding debit side.
-- -----------------------------------------------------------------------------
INSERT INTO accounts (name, type, currency, description, is_active)
VALUES ('Interest Expense', 'system', 'UGX', 'SACCO interest expense — debited when member interest is posted', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO accounts (name, type, currency, description, is_active)
VALUES ('Retained Earnings', 'system', 'UGX', 'SACCO retained earnings — debited when dividends are distributed', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO accounts (name, type, currency, description, is_active)
VALUES ('Share Capital', 'system', 'UGX', 'SACCO share capital — credited when member share purchases are posted', TRUE)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- DONE
-- =============================================================================

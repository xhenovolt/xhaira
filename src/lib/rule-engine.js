/**
 * XHAIRA — SACCO Rule Engine
 *
 * Configurable rules for loans, accounts, guarantors, transfers.
 * Rules are stored in sacco_rules table as JSONB — NEVER hardcoded.
 *
 * Usage:
 *   const max = await getRule('LOAN', 'max_loan_multiplier');
 *   // → { multiplier: 3 }
 */

import { getPool } from '@/lib/db.js';

// ─── Rule CRUD ───

/**
 * Get a single rule's value
 * @returns {Object|null} The rule_value JSONB object, or null if not found/inactive
 */
export async function getRule(ruleType, ruleKey) {
  const pool = getPool();
  const result = await pool.query(
    `SELECT rule_value FROM sacco_rules WHERE rule_type = $1 AND rule_key = $2 AND is_active = true`,
    [ruleType, ruleKey]
  );
  return result.rows.length > 0 ? result.rows[0].rule_value : null;
}

/**
 * Get all rules of a given type
 */
export async function getRulesByType(ruleType) {
  const pool = getPool();
  const result = await pool.query(
    `SELECT rule_key, rule_value, description FROM sacco_rules WHERE rule_type = $1 AND is_active = true ORDER BY rule_key`,
    [ruleType]
  );
  return result.rows;
}

/**
 * Get all active rules as a flat map: { "LOAN.max_loan_multiplier": {...}, ... }
 */
export async function getAllRules() {
  const pool = getPool();
  const result = await pool.query(
    `SELECT id, rule_type, rule_key, rule_value, description, is_active, created_at, updated_at FROM sacco_rules ORDER BY rule_type, rule_key`
  );
  return result.rows;
}

/**
 * Set (upsert) a rule
 */
export async function setRule(ruleType, ruleKey, ruleValue, description) {
  const pool = getPool();
  const result = await pool.query(
    `INSERT INTO sacco_rules (rule_type, rule_key, rule_value, description)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (rule_type, rule_key) DO UPDATE SET
       rule_value = EXCLUDED.rule_value,
       description = COALESCE(EXCLUDED.description, sacco_rules.description),
       updated_at = NOW()
     RETURNING *`,
    [ruleType, ruleKey, JSON.stringify(ruleValue), description || null]
  );
  return result.rows[0];
}

// ─── Loan Eligibility Engine (Phase 8) ───

/**
 * Check full loan eligibility for a member.
 * Returns { eligible: boolean, maxLoan: number, reasons: string[], checks: Object }
 */
export async function checkLoanEligibility(memberId, requestedAmount) {
  const pool = getPool();
  const checks = {};
  const reasons = [];

  // 1. Member must be active
  const member = await pool.query(`SELECT id, status, created_at FROM members WHERE id = $1`, [memberId]);
  if (member.rows.length === 0) return { eligible: false, maxLoan: 0, reasons: ['Member not found'], checks };
  if (member.rows[0].status !== 'active') {
    reasons.push('Member is not active');
  }
  checks.member_active = member.rows[0].status === 'active';

  // 2. Fixed Savings balance check
  const fixedRule = await getRule('LOAN', 'min_fixed_savings_for_loan');
  const minFixed = fixedRule?.amount || 0;

  // Get fixed savings balance (account_type = 'fixed_deposit' or account_type_id linked to FIXED_SAV)
  const fixedBalance = await pool.query(
    `SELECT COALESCE(SUM(
       CASE WHEN le.entry_type = 'CREDIT' THEN le.amount
            WHEN le.entry_type = 'DEBIT' THEN -le.amount ELSE 0 END
     ), 0) AS balance
     FROM ledger_entries le
     JOIN member_accounts ma ON le.member_account_id = ma.id
     LEFT JOIN account_types at ON ma.account_type_id = at.id
     WHERE ma.member_id = $1
       AND (ma.account_type = 'fixed_deposit' OR at.code = 'FIXED_SAV')
       AND ma.status = 'active'`,
    [memberId]
  );
  const fixedSavings = parseFloat(fixedBalance.rows[0].balance);
  checks.fixed_savings = fixedSavings;
  checks.min_fixed_required = minFixed;

  if (fixedSavings < minFixed) {
    reasons.push(`Fixed savings (${fixedSavings.toLocaleString()}) below minimum (${minFixed.toLocaleString()})`);
  }

  // 3. Max loan multiplier
  const multiplierRule = await getRule('LOAN', 'max_loan_multiplier');
  const multiplier = multiplierRule?.multiplier || 3;
  const maxLoan = fixedSavings * multiplier;
  checks.max_loan_multiplier = multiplier;
  checks.max_eligible_amount = maxLoan;

  if (requestedAmount && requestedAmount > maxLoan) {
    reasons.push(`Requested amount (${requestedAmount.toLocaleString()}) exceeds maximum eligible (${maxLoan.toLocaleString()} = savings × ${multiplier})`);
  }

  // 4. Existing active loans check
  const maxLoansRule = await getRule('LOAN', 'max_active_loans');
  const maxActiveLoans = maxLoansRule?.count || 2;
  const activeLoans = await pool.query(
    `SELECT COUNT(*) as count FROM loans WHERE member_id = $1 AND status IN ('PENDING', 'APPROVED', 'ACTIVE')`,
    [memberId]
  );
  const activeCount = parseInt(activeLoans.rows[0].count);
  checks.active_loans = activeCount;
  checks.max_active_loans = maxActiveLoans;

  if (activeCount >= maxActiveLoans) {
    reasons.push(`Already has ${activeCount} active/pending loans (max: ${maxActiveLoans})`);
  }

  // 5. Guarantor requirement check (just reports the requirement, doesn't validate guarantors yet)
  const guarantorRule = await getRule('LOAN', 'guarantors_required');
  checks.guarantors_required = guarantorRule?.count || 0;

  return {
    eligible: reasons.length === 0,
    maxLoan,
    reasons,
    checks,
  };
}

// ─── Guarantor Validation ───

/**
 * Validate a potential guarantor for a loan.
 * Checks: is active member, meets min balance, not over-guaranteed.
 */
export async function validateGuarantor(guarantorMemberId, guaranteedAmount, loanBorrowerId) {
  const pool = getPool();
  const issues = [];

  // Cannot guarantee own loan
  if (guarantorMemberId === loanBorrowerId) {
    issues.push('Cannot guarantee your own loan');
    return { valid: false, issues };
  }

  // Must be active member
  const member = await pool.query(`SELECT id, status, created_at FROM members WHERE id = $1`, [guarantorMemberId]);
  if (member.rows.length === 0) return { valid: false, issues: ['Guarantor not a registered member'] };
  if (member.rows[0].status !== 'active') {
    issues.push('Guarantor is not an active member');
  }

  // Min membership months
  const minMonthsRule = await getRule('GUARANTOR', 'min_membership_months');
  const minMonths = minMonthsRule?.months || 0;
  if (minMonths > 0) {
    const joined = new Date(member.rows[0].created_at);
    const monthsSinceJoin = (Date.now() - joined.getTime()) / (1000 * 60 * 60 * 24 * 30);
    if (monthsSinceJoin < minMonths) {
      issues.push(`Guarantor has been a member for ${Math.floor(monthsSinceJoin)} months (min: ${minMonths})`);
    }
  }

  // Guarantor's total savings
  const savingsResult = await pool.query(
    `SELECT COALESCE(SUM(
       CASE WHEN le.entry_type = 'CREDIT' THEN le.amount
            WHEN le.entry_type = 'DEBIT' THEN -le.amount ELSE 0 END
     ), 0) AS balance
     FROM ledger_entries le
     JOIN member_accounts ma ON le.member_account_id = ma.id
     WHERE ma.member_id = $1 AND ma.status = 'active'`,
    [guarantorMemberId]
  );
  const totalSavings = parseFloat(savingsResult.rows[0].balance);

  // Max guarantee percentage of own savings
  const maxPctRule = await getRule('GUARANTOR', 'max_guarantee_percentage');
  const maxPct = maxPctRule?.percentage || 100;
  const maxGuaranteeCapacity = totalSavings * (maxPct / 100);

  // Already guaranteed amounts
  const existingGuarantees = await pool.query(
    `SELECT COALESCE(SUM(lg.guaranteed_amount), 0) as total
     FROM loan_guarantors lg
     JOIN loans l ON lg.loan_id = l.id
     WHERE lg.guarantor_member_id = $1 AND l.status IN ('PENDING', 'APPROVED', 'ACTIVE')`,
    [guarantorMemberId]
  );
  const alreadyGuaranteed = parseFloat(existingGuarantees.rows[0].total);
  const availableCapacity = maxGuaranteeCapacity - alreadyGuaranteed;

  if (guaranteedAmount > availableCapacity) {
    issues.push(
      `Guarantee of ${guaranteedAmount.toLocaleString()} exceeds capacity (${availableCapacity.toLocaleString()} available from ${maxGuaranteeCapacity.toLocaleString()} max, ${alreadyGuaranteed.toLocaleString()} already committed)`
    );
  }

  return {
    valid: issues.length === 0,
    issues,
    capacity: {
      total_savings: totalSavings,
      max_guarantee_capacity: maxGuaranteeCapacity,
      already_guaranteed: alreadyGuaranteed,
      available: availableCapacity,
    },
  };
}

// ─── Transfer Validation ───

/**
 * Validate a member-to-member transfer against SACCO rules.
 */
export async function validateTransfer(senderMemberId, receiverMemberId, senderAccountId, amount) {
  const pool = getPool();
  const issues = [];

  if (senderMemberId === receiverMemberId) {
    issues.push('Cannot transfer to yourself');
  }

  // Min transfer amount
  const minRule = await getRule('TRANSFER', 'min_transfer_amount');
  const minAmount = minRule?.amount || 0;
  if (amount < minAmount) {
    issues.push(`Amount ${amount.toLocaleString()} below minimum transfer (${minAmount.toLocaleString()})`);
  }

  // Check account withdrawal rules
  const acct = await pool.query(
    `SELECT ma.id, ma.account_type, at.allows_withdrawal, at.minimum_balance, at.name as type_name
     FROM member_accounts ma
     LEFT JOIN account_types at ON ma.account_type_id = at.id
     WHERE ma.id = $1`,
    [senderAccountId]
  );
  if (acct.rows.length > 0) {
    const a = acct.rows[0];
    if (a.allows_withdrawal === false) {
      issues.push(`Account type "${a.type_name || a.account_type}" does not allow withdrawals`);
    }

    // Check minimum balance constraint
    if (a.minimum_balance && parseFloat(a.minimum_balance) > 0) {
      const { getMemberAccountBalance } = await import('@/lib/transaction-service.js');
      const balance = await getMemberAccountBalance(senderAccountId);
      const afterTransfer = balance - amount;
      if (afterTransfer < parseFloat(a.minimum_balance)) {
        issues.push(`Transfer would bring balance below minimum (${parseFloat(a.minimum_balance).toLocaleString()})`);
      }
    }
  }

  // Daily transfer limit
  const maxDailyRule = await getRule('TRANSFER', 'max_daily_transfers');
  const maxDaily = maxDailyRule?.count || 999;
  const todayTransfers = await pool.query(
    `SELECT COUNT(*) as count FROM transactions t
     JOIN ledger_entries le ON le.transaction_id = t.id
     WHERE t.transaction_type = 'transfer'
       AND le.member_account_id IN (SELECT id FROM member_accounts WHERE member_id = $1)
       AND le.entry_type = 'DEBIT'
       AND t.created_at >= CURRENT_DATE`,
    [senderMemberId]
  );
  if (parseInt(todayTransfers.rows[0].count) >= maxDaily) {
    issues.push(`Daily transfer limit reached (${maxDaily})`);
  }

  return { valid: issues.length === 0, issues };
}

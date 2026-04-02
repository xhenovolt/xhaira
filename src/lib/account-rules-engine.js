/**
 * Account Rules Engine
 * ─────────────────────────────────────────────────────────────────────────────
 * Fetches and evaluates per-account-type configurable rules.
 * All financial behavior is driven by rules in account_type_rules —
 * nothing is hardcoded in application logic.
 *
 * Rule keys understood by the engine:
 *   min_balance           — minimum ledger balance required at all times
 *   interest_rate         — annual rate as % (e.g. 5 → 5%)
 *   interest_cycle        — 'MONTHLY' | 'QUARTERLY' | 'ANNUALLY'
 *   interest_enabled      — false to disable interest for this type
 *   withdrawal_allowed    — false to block all withdrawals
 *   requires_maturity     — true to enforce maturity_period_days before withdraw
 *   maturity_period_days  — integer days from account open date
 *   loan_eligible         — whether balance counts toward loan multiplier
 *   dividend_eligible     — whether account earns dividends
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { query } from '@/lib/db.js';

/**
 * Get all enabled rules for an account_type_id as a flat key→value map.
 * rule_value is JSONB, so primitive values come back already parsed by the pg driver.
 *
 * @param   {string}  accountTypeId
 * @returns {Promise<Record<string,any>>}
 */
export async function getAccountTypeRules(accountTypeId) {
  if (!accountTypeId) return {};

  const result = await query(
    `SELECT rule_key, rule_value
     FROM account_type_rules
     WHERE account_type_id = $1 AND is_enabled = TRUE`,
    [accountTypeId]
  );

  const rules = {};
  for (const row of result.rows) {
    rules[row.rule_key] = row.rule_value;
  }
  return rules;
}

/**
 * Load a member account with its account_type info and resolved rules.
 *
 * @param   {string} memberAccountId
 * @returns {Promise<{ memberAccount: object, accountType: object, rules: object }>}
 */
export async function getRulesForMemberAccount(memberAccountId) {
  const result = await query(
    `SELECT ma.*,
            at.id              AS at_id,
            at.name            AS at_name,
            at.code            AS at_code,
            at.allows_withdrawal AS at_allows_withdrawal,
            at.minimum_balance AS at_min_balance,
            at.interest_rate   AS at_interest_rate
     FROM member_accounts ma
     LEFT JOIN account_types at ON at.id = ma.account_type_id
     WHERE ma.id = $1`,
    [memberAccountId]
  );

  if (result.rows.length === 0) {
    throw new Error(`Member account ${memberAccountId} not found`);
  }

  const row = result.rows[0];

  const memberAccount = row;
  const accountType = {
    id:                row.at_id,
    name:              row.at_name,
    code:              row.at_code,
    allows_withdrawal: row.at_allows_withdrawal,
    minimum_balance:   parseFloat(row.at_min_balance  ?? 0),
    interest_rate:     parseFloat(row.at_interest_rate ?? 0),
  };

  const rules = await getAccountTypeRules(row.account_type_id);
  return { memberAccount, accountType, rules };
}

/**
 * Validate a proposed withdrawal against all applicable rules.
 *
 * @param   {string} memberAccountId
 * @param   {number} amount          - amount requested
 * @param   {number} currentBalance  - computed ledger balance
 * @returns {Promise<{ allowed: boolean, reason?: string }>}
 */
export async function validateWithdrawal(memberAccountId, amount, currentBalance) {
  const { rules, accountType, memberAccount } = await getRulesForMemberAccount(memberAccountId);

  // ── Rule: withdrawal_allowed ─────────────────────────────────────────────
  const withdrawalAllowed = rules.withdrawal_allowed !== undefined
    ? rules.withdrawal_allowed
    : accountType.allows_withdrawal;

  if (withdrawalAllowed === false) {
    return {
      allowed: false,
      reason:  `Withdrawals are not permitted for "${accountType.name}" accounts.`,
    };
  }

  // ── Rule: requires_maturity ──────────────────────────────────────────────
  if (rules.requires_maturity === true) {
    const maturityDays = parseInt(rules.maturity_period_days ?? 90, 10);
    const openedAt     = new Date(memberAccount.opened_at);
    const daysSinceOpen = Math.floor((Date.now() - openedAt.getTime()) / 86_400_000);

    if (daysSinceOpen < maturityDays) {
      return {
        allowed: false,
        reason:  `Account has not matured. Required: ${maturityDays} days, elapsed: ${daysSinceOpen} days.`,
      };
    }
  }

  // ── Rule: min_balance ────────────────────────────────────────────────────
  const minBalance = rules.min_balance !== undefined
    ? parseFloat(rules.min_balance)
    : parseFloat(accountType.minimum_balance ?? 0);

  if ((currentBalance - amount) < minBalance) {
    return {
      allowed: false,
      reason:  `Balance after withdrawal (${currentBalance - amount}) would be below minimum of ${minBalance}.`,
    };
  }

  // ── Sufficient funds ─────────────────────────────────────────────────────
  if (amount > currentBalance) {
    return {
      allowed: false,
      reason:  `Insufficient balance. Available: ${currentBalance}, Requested: ${amount}.`,
    };
  }

  return { allowed: true };
}

/**
 * Return a human-readable behavior summary for a member account.
 * Useful for UI previews and API responses.
 *
 * @param   {string} memberAccountId
 * @returns {Promise<object>}
 */
export async function getAccountBehavior(memberAccountId) {
  const { rules, accountType } = await getRulesForMemberAccount(memberAccountId);

  return {
    account_type_name:    accountType.name,
    account_type_code:    accountType.code,
    allows_withdrawal:    rules.withdrawal_allowed !== undefined ? rules.withdrawal_allowed : accountType.allows_withdrawal,
    min_balance:          rules.min_balance !== undefined ? parseFloat(rules.min_balance) : parseFloat(accountType.minimum_balance ?? 0),
    interest_rate:        rules.interest_rate !== undefined ? parseFloat(rules.interest_rate) : parseFloat(accountType.interest_rate ?? 0),
    interest_cycle:       rules.interest_cycle ?? 'MONTHLY',
    interest_enabled:     rules.interest_enabled !== false,
    requires_maturity:    rules.requires_maturity === true,
    maturity_period_days: parseInt(rules.maturity_period_days ?? 0, 10),
    loan_eligible:        rules.loan_eligible !== false,
    dividend_eligible:    rules.dividend_eligible === true,
  };
}

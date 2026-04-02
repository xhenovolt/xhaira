/**
 * Savings Engine
 * ─────────────────────────────────────────────────────────────────────────────
 * Rule-validated deposit and withdrawal operations for member savings accounts.
 * Every operation posts a balanced double-entry transaction to the ledger.
 *
 * ─── Deposit flow ────────────────────────────────────────────────────────────
 *   CREDIT → member_account (balance +)
 *   DEBIT  → SACCO Cash Account (system account, balance -)
 *
 * ─── Withdrawal flow ─────────────────────────────────────────────────────────
 *   DEBIT  → member_account (balance -)
 *   CREDIT → SACCO Cash Account (system account, balance +)
 *
 * Withdrawal is rejected if any configured rule is violated.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import {
  getMemberAccountBalance,
  deposit as rawDeposit,
  withdraw as rawWithdraw,
} from '@/lib/transaction-service.js';
import { validateWithdrawal } from '@/lib/account-rules-engine.js';

/**
 * Deposit funds into a member account.
 * No rule restrictions on deposits (members may always add money).
 *
 * @param {object} params
 * @param {string}  params.memberAccountId
 * @param {number}  params.amount
 * @param {string} [params.description]
 * @param {string} [params.reference]    - external reference / receipt number
 * @param {string} [params.userId]       - staff user executing the transaction
 * @returns {Promise<{ transaction, entries, balance: number }>}
 */
export async function savingsDeposit({ memberAccountId, amount, description, reference, userId }) {
  if (!memberAccountId) throw new Error('memberAccountId is required');
  if (!amount || amount <= 0) throw new Error('amount must be a positive number');

  const result = await rawDeposit({
    memberAccountId,
    amount: parseFloat(amount),
    description: description || 'Savings deposit',
    reference,
    userId,
  });

  const balance = await getMemberAccountBalance(memberAccountId);
  return { ...result, balance };
}

/**
 * Withdraw funds from a member account.
 * Enforces all configured account rules. Throws if any rule is violated.
 *
 * Pass force = true to bypass rule checks (superadmin override — use with care).
 *
 * @param {object} params
 * @param {string}  params.memberAccountId
 * @param {number}  params.amount
 * @param {string} [params.description]
 * @param {string} [params.reference]
 * @param {string} [params.userId]
 * @param {boolean}[params.force=false]  - bypass rule validation (superadmin only)
 * @returns {Promise<{ transaction, entries, balance: number }>}
 */
export async function savingsWithdraw({ memberAccountId, amount, description, reference, userId, force = false }) {
  if (!memberAccountId) throw new Error('memberAccountId is required');
  if (!amount || amount <= 0) throw new Error('amount must be a positive number');

  const currentBalance = await getMemberAccountBalance(memberAccountId);

  if (!force) {
    const validation = await validateWithdrawal(memberAccountId, parseFloat(amount), currentBalance);
    if (!validation.allowed) {
      const err = new Error(validation.reason);
      err.code  = 'RULE_VIOLATION';
      throw err;
    }
  }

  const result = await rawWithdraw({
    memberAccountId,
    amount: parseFloat(amount),
    description: description || 'Savings withdrawal',
    reference,
    userId,
  });

  const balance = await getMemberAccountBalance(memberAccountId);
  return { ...result, balance };
}

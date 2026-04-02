/**
 * Interest Engine
 * ─────────────────────────────────────────────────────────────────────────────
 * Dynamically calculates and posts interest to member accounts.
 * Rate and cycle come from account_type_rules — nothing is hardcoded.
 *
 * Two-phase process:
 *   1. accrueInterest()  — calculates amounts and creates PENDING accrual records
 *   2. applyInterest()   — posts PENDING accruals as ledger transactions
 *
 * ─── Ledger entries when interest is applied ─────────────────────────────────
 *   CREDIT → member account       (member earns interest)
 *   DEBIT  → Interest Expense     (SACCO cost account)
 *
 * Formula: balance × (rate / 100) × (days / 365)
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { query }            from '@/lib/db.js';
import { createTransaction } from '@/lib/transaction-service.js';
import { getAccountTypeRules } from '@/lib/account-rules-engine.js';

// ─── Formula ─────────────────────────────────────────────────────────────────

/**
 * Compute interest using simple interest formula.
 *
 * @param {number} balance - current account balance
 * @param {number} rate    - annual rate as percentage (5 → 5%)
 * @param {number} days    - number of days in the accrual period
 * @returns {number} interest amount (4 decimal precision)
 */
export function calculateInterest(balance, rate, days) {
  if (!balance || balance <= 0) return 0;
  if (!rate || rate <= 0)        return 0;
  if (!days || days <= 0)        return 0;
  return parseFloat((balance * (rate / 100) * (days / 365)).toFixed(4));
}

// ─── Phase 1: Accrue ─────────────────────────────────────────────────────────

/**
 * Run interest accrual for all eligible active member accounts.
 * Creates interest_accruals records with status PENDING.
 * Does NOT post to ledger — call applyInterest() to post.
 *
 * Skips accounts that already have a non-REVERSED accrual for the same period.
 *
 * @param {object}  opts
 * @param {string}  opts.periodStart  - ISO date string, e.g. '2026-04-01'
 * @param {string}  opts.periodEnd    - ISO date string, e.g. '2026-04-30'
 * @param {string} [opts.userId]      - user triggering the run
 * @returns {Promise<{ accrued: number, skipped: number, total: number, details: object[] }>}
 */
export async function accrueInterest({ periodStart, periodEnd, userId }) {
  if (!periodStart || !periodEnd) throw new Error('periodStart and periodEnd are required');

  const start = new Date(periodStart);
  const end   = new Date(periodEnd);
  if (end <= start) throw new Error('periodEnd must be after periodStart');

  const days = Math.max(1, Math.round((end - start) / 86_400_000));

  // Load all active member accounts with computed balances + base rates
  const accountsResult = await query(
    `SELECT ma.id,
            ma.member_id,
            ma.account_type_id,
            ma.currency,
            at.interest_rate  AS base_rate,
            at.name           AS account_type_name,
            at.code           AS account_type_code,
            COALESCE(SUM(
              CASE WHEN le.entry_type = 'CREDIT' THEN  le.amount
                   WHEN le.entry_type = 'DEBIT'  THEN -le.amount
                   ELSE 0 END
            ), 0) AS balance
     FROM member_accounts ma
     JOIN account_types at ON at.id = ma.account_type_id
     LEFT JOIN ledger_entries le ON le.member_account_id = ma.id
     WHERE ma.status = 'active'
     GROUP BY ma.id, ma.member_id, ma.account_type_id, ma.currency,
              at.interest_rate, at.name, at.code`
  );

  let accrued = 0;
  let skipped = 0;
  const details = [];

  for (const account of accountsResult.rows) {
    // Fetch per-type configurable rules
    const rules    = await getAccountTypeRules(account.account_type_id);
    const rate     = rules.interest_rate !== undefined
      ? parseFloat(rules.interest_rate)
      : parseFloat(account.base_rate ?? 0);

    // Honour interest_enabled = false
    if (rules.interest_enabled === false)  { skipped++; continue; }
    if (rate <= 0)                         { skipped++; continue; }

    const balance = parseFloat(account.balance);
    const amount  = calculateInterest(balance, rate, days);
    if (amount <= 0)                       { skipped++; continue; }

    // Idempotency — skip if already accrued for this period
    const existing = await query(
      `SELECT id FROM interest_accruals
       WHERE account_id = $1 AND period_start = $2 AND period_end = $3
         AND status != 'REVERSED'`,
      [account.id, periodStart, periodEnd]
    );
    if (existing.rows.length > 0) { skipped++; continue; }

    await query(
      `INSERT INTO interest_accruals
         (account_id, amount, rate_used, balance_at_calc, period_start, period_end, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'PENDING')`,
      [account.id, amount, rate, balance, periodStart, periodEnd]
    );

    accrued++;
    details.push({
      account_id:        account.id,
      account_type_name: account.account_type_name,
      balance,
      rate,
      days,
      amount,
    });
  }

  return { accrued, skipped, total: accountsResult.rows.length, details };
}

// ─── Phase 2: Apply ───────────────────────────────────────────────────────────

/**
 * Apply all PENDING interest accruals by posting double-entry transactions.
 *
 * CREDIT → member account      (interest earned)
 * DEBIT  → Interest Expense    (SACCO expense account)
 *
 * @param {object}   opts
 * @param {string}   opts.userId       - user applying interest
 * @param {string[]} [opts.accrualIds] - optional: only apply specific IDs; defaults to all PENDING
 * @returns {Promise<{ applied: number, failed: number, errors: string[] }>}
 */
export async function applyInterest({ userId, accrualIds } = {}) {
  // Resolve Interest Expense account
  const expResult = await query(
    `SELECT id FROM accounts WHERE name = 'Interest Expense' AND type = 'system' LIMIT 1`
  );
  if (expResult.rows.length === 0) {
    throw new Error('Interest Expense account not found — run migration 600_savings_shares_interest_engine.sql');
  }
  const interestExpenseAccountId = expResult.rows[0].id;

  // Build query
  let whereClause = `WHERE ia.status = 'PENDING'`;
  const params    = [];
  if (accrualIds && accrualIds.length > 0) {
    params.push(accrualIds);
    whereClause += ` AND ia.id = ANY($${params.length})`;
  }

  const accruals = await query(
    `SELECT ia.*, at.name AS account_type_name
     FROM interest_accruals ia
     JOIN member_accounts ma ON ma.id = ia.account_id
     JOIN account_types at ON at.id = ma.account_type_id
     ${whereClause}
     ORDER BY ia.created_at`,
    params
  );

  let applied = 0;
  let failed  = 0;
  const errors = [];

  for (const accrual of accruals.rows) {
    try {
      const { transaction } = await createTransaction({
        description:      `Interest: ${accrual.account_type_name} (${accrual.period_start} → ${accrual.period_end})`,
        transaction_type: 'interest',
        reference:        accrual.id,
        userId,
        metadata: {
          accrual_id:   accrual.id,
          period_start: accrual.period_start,
          period_end:   accrual.period_end,
          rate_used:    accrual.rate_used,
        },
        entries: [
          {
            member_account_id: accrual.account_id,
            type:              'CREDIT',
            amount:            parseFloat(accrual.amount),
            description:       'Interest earned',
          },
          {
            account_id:  interestExpenseAccountId,
            type:        'DEBIT',
            amount:      parseFloat(accrual.amount),
            description: 'Interest expense',
          },
        ],
      });

      await query(
        `UPDATE interest_accruals
         SET status = 'APPLIED', applied_at = NOW(), applied_by = $1, transaction_id = $2
         WHERE id = $3`,
        [userId || null, transaction.id, accrual.id]
      );

      applied++;
    } catch (err) {
      failed++;
      errors.push(`Accrual ${accrual.id}: ${err.message}`);
      await query(
        `UPDATE interest_accruals SET status = 'FAILED', notes = $1 WHERE id = $2`,
        [err.message, accrual.id]
      ).catch(() => {});
    }
  }

  return { applied, failed, errors };
}

// ─── Shares Purchase ─────────────────────────────────────────────────────────

/**
 * Record a share purchase — creates a shares row AND posts double-entry:
 *   DEBIT  → member_account (cash paid for shares)
 *   CREDIT → Share Capital  (system equity account)
 *
 * @param {object} opts
 * @param {string}  opts.memberId          - UUID of the member
 * @param {string}  opts.memberAccountId   - UUID of the member account to debit
 * @param {number}  opts.units             - number of share units purchased
 * @param {number}  opts.valuePerUnit      - price per share unit
 * @param {string} [opts.notes]
 * @param {string} [opts.userId]
 * @returns {Promise<{ share, transaction, entries }>}
 */
export async function purchaseShares({ memberId, memberAccountId, units, valuePerUnit, notes, userId }) {
  if (!memberId || !units || !valuePerUnit) {
    throw new Error('memberId, units, and valuePerUnit are required');
  }

  const totalValue = parseFloat((units * valuePerUnit).toFixed(2));

  // Resolve Share Capital account
  const capResult = await query(
    `SELECT id FROM accounts WHERE name = 'Share Capital' AND type = 'system' LIMIT 1`
  );
  if (capResult.rows.length === 0) {
    throw new Error('Share Capital account not found — run migration 600_savings_shares_interest_engine.sql');
  }
  const shareCapitalAccountId = capResult.rows[0].id;

  // Post double-entry transaction
  let transactionResult = null;
  if (memberAccountId) {
    transactionResult = await createTransaction({
      description:      `Share purchase: ${units} units @ ${valuePerUnit}`,
      transaction_type: 'adjustment',
      userId,
      metadata: { member_id: memberId, units, value_per_unit: valuePerUnit },
      entries: [
        {
          member_account_id: memberAccountId,
          type:              'DEBIT',
          amount:            totalValue,
          description:       `Share purchase payment: ${units} units`,
        },
        {
          account_id:  shareCapitalAccountId,
          type:        'CREDIT',
          amount:      totalValue,
          description: `Share capital contribution`,
        },
      ],
    });
  }

  // Record the share ownership
  const shareResult = await query(
    `INSERT INTO shares (member_id, units, value_per_unit, transaction_id, notes, created_by)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      memberId,
      parseFloat(units),
      parseFloat(valuePerUnit),
      transactionResult?.transaction?.id || null,
      notes || null,
      userId || null,
    ]
  );

  return {
    share:       shareResult.rows[0],
    transaction: transactionResult?.transaction || null,
    entries:     transactionResult?.entries || [],
  };
}

// ─── Dividend Distribution ────────────────────────────────────────────────────

/**
 * Distribute dividends to all eligible members.
 * Distribution method: 'shares' | 'savings' | 'equal'
 *
 * CREDIT → member account       (dividend received)
 * DEBIT  → Retained Earnings    (SACCO equity reduced)
 *
 * @param {object}  opts
 * @param {number}  opts.totalAmount   - total pool to distribute
 * @param {string}  opts.period        - label, e.g. '2026-Q1'
 * @param {string}  opts.basis         - 'shares' | 'savings' | 'equal'
 * @param {string}  opts.userId        - user running the distribution
 * @returns {Promise<{ distributed: number, failed: number, errors: string[], distributionId: string }>}
 */
export async function distributeDividends({ totalAmount, period, basis = 'shares', userId }) {
  if (!totalAmount || totalAmount <= 0) throw new Error('totalAmount must be positive');
  if (!period) throw new Error('period is required (e.g. 2026-Q1)');

  // Resolve Retained Earnings account
  const reResult = await query(
    `SELECT id FROM accounts WHERE name = 'Retained Earnings' AND type = 'system' LIMIT 1`
  );
  if (reResult.rows.length === 0) {
    throw new Error('Retained Earnings account not found — run migration 600_savings_shares_interest_engine.sql');
  }
  const retainedEarningsId = reResult.rows[0].id;

  const distributionId = crypto.randomUUID();

  // ── Resolve per-member basis values ──────────────────────────────────────
  let membersResult;

  if (basis === 'shares') {
    membersResult = await query(
      `SELECT vs.member_id, vs.total_value AS basis_value,
              (SELECT id FROM member_accounts ma2
               JOIN account_types at2 ON at2.id = ma2.account_type_id
               WHERE ma2.member_id = vs.member_id AND at2.code = 'VOL_SAV' AND ma2.status = 'active'
               LIMIT 1) AS member_account_id
       FROM v_member_shares vs
       WHERE vs.total_units > 0`
    );
  } else if (basis === 'savings') {
    membersResult = await query(
      `SELECT vb.member_id, vb.balance AS basis_value, vb.member_account_id
       FROM v_member_account_balances vb
       JOIN account_types at ON at.code = 'VOL_SAV'
       JOIN member_accounts ma ON ma.id = vb.member_account_id AND ma.account_type_id = at.id
       WHERE vb.status = 'active' AND vb.balance > 0`
    );
  } else {
    // equal — each active member gets the same amount
    membersResult = await query(
      `SELECT m.id AS member_id, 1 AS basis_value,
              (SELECT id FROM member_accounts ma2
               JOIN account_types at2 ON at2.id = ma2.account_type_id
               WHERE ma2.member_id = m.id AND at2.code = 'VOL_SAV' AND ma2.status = 'active'
               LIMIT 1) AS member_account_id
       FROM members m WHERE m.status = 'active'`
    );
  }

  const members        = membersResult.rows;
  const totalBasis     = members.reduce((s, m) => s + parseFloat(m.basis_value ?? 0), 0);
  if (totalBasis <= 0) throw new Error('Total basis value is zero — no eligible members');

  let distributed = 0;
  let failed      = 0;
  const errors    = [];

  for (const member of members) {
    if (!member.member_account_id) { skipped++; continue; }

    const share  = parseFloat(member.basis_value ?? 0) / totalBasis;
    const amount = parseFloat((totalAmount * share).toFixed(2));
    if (amount <= 0) continue;

    try {
      const { transaction } = await createTransaction({
        description:      `Dividend: ${period} (${basis}-based)`,
        transaction_type: 'adjustment',
        userId,
        metadata: { distribution_id: distributionId, period, basis },
        entries: [
          {
            member_account_id: member.member_account_id,
            type:              'CREDIT',
            amount,
            description:       `Dividend received — ${period}`,
          },
          {
            account_id:  retainedEarningsId,
            type:        'DEBIT',
            amount,
            description: `Dividend distribution — ${period}`,
          },
        ],
      });

      await query(
        `INSERT INTO dividends
           (member_id, member_account_id, amount, period, basis, basis_value, transaction_id, distribution_id, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          member.member_id,
          member.member_account_id,
          amount,
          period,
          basis,
          parseFloat(member.basis_value ?? 0),
          transaction.id,
          distributionId,
          userId || null,
        ]
      );

      distributed++;
    } catch (err) {
      failed++;
      errors.push(`Member ${member.member_id}: ${err.message}`);
    }
  }

  return { distributed, failed, errors, distributionId };
}

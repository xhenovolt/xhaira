/**
 * XHAIRA — Double-Entry Transaction Service
 * 
 * The ONLY way to move money in the system.
 * Every financial action creates a transaction with balanced DEBIT/CREDIT entries.
 * 
 * Rules:
 * - Total DEBITs MUST equal total CREDITs
 * - No negative amounts
 * - All referenced accounts must exist
 * - Transactions are atomic (all or nothing)
 * - Ledger entries are IMMUTABLE (never edit, only reverse)
 */

import { getPool } from '@/lib/db.js';

/**
 * Get the system cash account ID (SACCO liquidity pool)
 */
export async function getSystemAccountId(client) {
  const result = await client.query(
    `SELECT id FROM accounts WHERE type = 'system' AND name = 'SACCO Cash Account' LIMIT 1`
  );
  if (result.rows.length === 0) {
    throw new Error('System cash account not found. Run migration 300_ledger_and_loans.mjs');
  }
  return result.rows[0].id;
}

/**
 * Create a double-entry transaction.
 * 
 * @param {Object} params
 * @param {string} params.description - Human-readable description
 * @param {string} params.transaction_type - One of: deposit, withdrawal, transfer, loan_disbursement, loan_repayment, fee, interest, adjustment, initial_balance
 * @param {string} [params.reference] - External reference (receipt #, loan ID, etc.)
 * @param {Object} [params.metadata] - Additional JSON metadata
 * @param {string} params.userId - User creating the transaction
 * @param {Array<{member_account_id?: string, account_id?: string, type: 'DEBIT'|'CREDIT', amount: number, currency?: string, description?: string}>} params.entries
 * @returns {Promise<{transaction: Object, entries: Array}>}
 */
export async function createTransaction({ description, transaction_type, reference, metadata, userId, entries }) {
  // Validation
  if (!description) throw new Error('Transaction description is required');
  if (!entries || entries.length < 2) throw new Error('Transaction must have at least 2 entries');
  
  let totalDebits = 0;
  let totalCredits = 0;

  for (const entry of entries) {
    if (!entry.type || !['DEBIT', 'CREDIT'].includes(entry.type)) {
      throw new Error(`Invalid entry type: ${entry.type}. Must be DEBIT or CREDIT`);
    }
    if (!entry.amount || entry.amount <= 0) {
      throw new Error(`Invalid amount: ${entry.amount}. Must be positive`);
    }
    if (!entry.member_account_id && !entry.account_id) {
      throw new Error('Each entry must reference a member_account_id or account_id');
    }
    if (entry.type === 'DEBIT') totalDebits += entry.amount;
    if (entry.type === 'CREDIT') totalCredits += entry.amount;
  }

  // Double-entry rule: debits MUST equal credits
  if (Math.abs(totalDebits - totalCredits) > 0.001) {
    throw new Error(
      `Transaction not balanced: total DEBITs (${totalDebits}) ≠ total CREDITs (${totalCredits})`
    );
  }

  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verify all referenced accounts exist
    for (const entry of entries) {
      if (entry.member_account_id) {
        const acct = await client.query(
          `SELECT id, status FROM member_accounts WHERE id = $1`, [entry.member_account_id]
        );
        if (acct.rows.length === 0) throw new Error(`Member account ${entry.member_account_id} not found`);
        if (acct.rows[0].status === 'closed') throw new Error(`Member account ${entry.member_account_id} is closed`);
      }
      if (entry.account_id) {
        const acct = await client.query(
          `SELECT id, is_active FROM accounts WHERE id = $1`, [entry.account_id]
        );
        if (acct.rows.length === 0) throw new Error(`Account ${entry.account_id} not found`);
      }
    }

    // Create the transaction record
    const txResult = await client.query(
      `INSERT INTO transactions (description, transaction_type, reference, metadata, created_by)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [description, transaction_type || null, reference || null, JSON.stringify(metadata || {}), userId]
    );
    const transaction = txResult.rows[0];

    // Insert all ledger entries
    const insertedEntries = [];
    for (const entry of entries) {
      const entryResult = await client.query(
        `INSERT INTO ledger_entries (transaction_id, account_id, member_account_id, entry_type, amount, currency, description)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [
          transaction.id,
          entry.account_id || null,
          entry.member_account_id || null,
          entry.type,
          entry.amount,
          entry.currency || 'UGX',
          entry.description || description,
        ]
      );
      insertedEntries.push(entryResult.rows[0]);

      // Also write to company ledger table if account_id is set
      // (needed for v_account_balances view compatibility)
      if (entry.account_id) {
        const ledgerAmount = entry.type === 'CREDIT' ? entry.amount : -entry.amount;
        await client.query(
          `INSERT INTO ledger (account_id, amount, currency, source_type, source_id, description, entry_date, created_by)
           VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE, $7)`,
          [
            entry.account_id,
            ledgerAmount,
            entry.currency || 'UGX',
            transaction_type || 'adjustment',
            transaction.id,
            entry.description || description,
            userId,
          ]
        );
      }
    }

    await client.query('COMMIT');

    return { transaction, entries: insertedEntries };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Get computed balance for a member account (from ledger_entries)
 */
export async function getMemberAccountBalance(memberAccountId) {
  const pool = getPool();
  const result = await pool.query(
    `SELECT COALESCE(SUM(
       CASE WHEN entry_type = 'CREDIT' THEN amount
            WHEN entry_type = 'DEBIT' THEN -amount
            ELSE 0 END
     ), 0) AS balance
     FROM ledger_entries
     WHERE member_account_id = $1`,
    [memberAccountId]
  );
  return parseFloat(result.rows[0].balance);
}

/**
 * Deposit money into a member account (from SACCO cash)
 */
export async function deposit({ memberAccountId, amount, description, reference, userId }) {
  const pool = getPool();
  const client = await pool.connect();
  try {
    const systemAccountId = await getSystemAccountId(client);
    client.release();

    return await createTransaction({
      description: description || 'Member deposit',
      transaction_type: 'deposit',
      reference,
      userId,
      entries: [
        { member_account_id: memberAccountId, type: 'CREDIT', amount },
        { account_id: systemAccountId, type: 'DEBIT', amount },
      ],
    });
  } catch (err) {
    client.release();
    throw err;
  }
}

/**
 * Withdraw money from a member account (to SACCO cash)
 */
export async function withdraw({ memberAccountId, amount, description, reference, userId }) {
  // Check sufficient balance
  const balance = await getMemberAccountBalance(memberAccountId);
  if (balance < amount) {
    throw new Error(`Insufficient balance. Available: ${balance}, Requested: ${amount}`);
  }

  const pool = getPool();
  const client = await pool.connect();
  try {
    const systemAccountId = await getSystemAccountId(client);
    client.release();

    return await createTransaction({
      description: description || 'Member withdrawal',
      transaction_type: 'withdrawal',
      reference,
      userId,
      entries: [
        { member_account_id: memberAccountId, type: 'DEBIT', amount },
        { account_id: systemAccountId, type: 'CREDIT', amount },
      ],
    });
  } catch (err) {
    client.release();
    throw err;
  }
}

/**
 * Transfer money between member accounts (member-to-member or own accounts).
 * DEBIT → Sender account
 * CREDIT → Receiver account
 * No system account involved — pure peer-to-peer.
 */
export async function transfer({
  senderAccountId,
  receiverAccountId,
  amount,
  description,
  reference,
  userId,
}) {
  if (senderAccountId === receiverAccountId) {
    throw new Error('Cannot transfer to the same account');
  }
  if (!amount || amount <= 0) {
    throw new Error('Transfer amount must be positive');
  }

  // Check sender balance
  const senderBalance = await getMemberAccountBalance(senderAccountId);
  if (senderBalance < amount) {
    throw new Error(`Insufficient balance. Available: ${senderBalance}, Requested: ${amount}`);
  }

  return await createTransaction({
    description: description || 'Member-to-member transfer',
    transaction_type: 'transfer',
    reference,
    userId,
    entries: [
      { member_account_id: senderAccountId, type: 'DEBIT', amount, description: 'Transfer sent' },
      { member_account_id: receiverAccountId, type: 'CREDIT', amount, description: 'Transfer received' },
    ],
  });
}

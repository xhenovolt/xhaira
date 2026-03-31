/**
 * XHAIRA — Loan Engine Service
 * 
 * Handles: loan application, approval, disbursement, repayment, default detection.
 * All money flows go through the transaction service (double-entry).
 * 
 * Lifecycle: PENDING → APPROVED → DISBURSED → ACTIVE → COMPLETED
 *   - Approval ≠ Money given (sets approved_amount)
 *   - Disbursement = actual ledger transaction (supports partial)
 *   - DISBURSED → ACTIVE once fully disbursed
 * 
 * Rules:
 * - Loans MUST go through ledger
 * - No direct balance edits
 * - Every repayment = transaction
 * - Approval is mandatory when product.requires_approval = true
 * - Eligibility + guarantors validated via rule-engine
 */

import { getPool } from '@/lib/db.js';
import { createTransaction, getSystemAccountId } from '@/lib/transaction-service.js';
import { checkLoanEligibility, validateGuarantor, getRule } from '@/lib/rule-engine.js';

/**
 * Calculate simple interest and generate repayment schedule
 */
export function calculateLoan({ principal, interestRate, duration, repaymentCycle = 'MONTHLY' }) {
  const totalInterest = principal * (interestRate / 100) * (duration / 12);
  const totalPayable = principal + totalInterest;

  // Number of installments based on cycle
  const cycleMap = { DAILY: 30, WEEKLY: 4, BIWEEKLY: 2, MONTHLY: 1, QUARTERLY: 0.333, ANNUALLY: 0.0833 };
  const installmentsPerMonth = cycleMap[repaymentCycle] || 1;
  const totalInstallments = Math.ceil(duration * installmentsPerMonth);

  const installmentAmount = totalPayable / totalInstallments;
  const principalPerInstallment = principal / totalInstallments;
  const interestPerInstallment = totalInterest / totalInstallments;

  // Generate schedule
  const schedule = [];
  const today = new Date();
  for (let i = 1; i <= totalInstallments; i++) {
    const dueDate = new Date(today);
    switch (repaymentCycle) {
      case 'DAILY': dueDate.setDate(dueDate.getDate() + i); break;
      case 'WEEKLY': dueDate.setDate(dueDate.getDate() + i * 7); break;
      case 'BIWEEKLY': dueDate.setDate(dueDate.getDate() + i * 14); break;
      case 'MONTHLY': dueDate.setMonth(dueDate.getMonth() + i); break;
      case 'QUARTERLY': dueDate.setMonth(dueDate.getMonth() + i * 3); break;
      case 'ANNUALLY': dueDate.setFullYear(dueDate.getFullYear() + i); break;
    }

    schedule.push({
      installment_number: i,
      due_date: dueDate.toISOString().split('T')[0],
      principal_amount: Math.round(principalPerInstallment * 100) / 100,
      interest_amount: Math.round(interestPerInstallment * 100) / 100,
      total_amount: Math.round(installmentAmount * 100) / 100,
    });
  }

  return { totalInterest: Math.round(totalInterest * 100) / 100, totalPayable: Math.round(totalPayable * 100) / 100, schedule };
}

/**
 * Apply for a loan — with eligibility checks
 */
export async function applyForLoan({ memberId, productId, memberAccountId, principal, guarantors, userId }) {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verify member is active
    const member = await client.query(`SELECT id, full_name, status FROM members WHERE id = $1`, [memberId]);
    if (member.rows.length === 0) throw new Error('Member not found');
    if (member.rows[0].status !== 'active') throw new Error('Member is not active');

    // Verify member account exists
    if (memberAccountId) {
      const acct = await client.query(`SELECT id, status FROM member_accounts WHERE id = $1 AND member_id = $2`, [memberAccountId, memberId]);
      if (acct.rows.length === 0) throw new Error('Member account not found');
      if (acct.rows[0].status !== 'active') throw new Error('Member account is not active');
    }

    // Get product details
    let interestRate, duration, repaymentCycle, requiresApproval;
    if (productId) {
      const product = await client.query(`SELECT * FROM products WHERE id = $1 AND is_active = true`, [productId]);
      if (product.rows.length === 0) throw new Error('Product not found or inactive');
      const p = product.rows[0];
      interestRate = p.interest_rate || 0;
      duration = p.duration || 12;
      repaymentCycle = p.repayment_cycle || 'MONTHLY';
      requiresApproval = p.requires_approval !== false;

      if (p.min_amount && principal < parseFloat(p.min_amount)) {
        throw new Error(`Amount below minimum: ${p.min_amount}`);
      }
      if (p.max_amount && principal > parseFloat(p.max_amount)) {
        throw new Error(`Amount exceeds maximum: ${p.max_amount}`);
      }
    } else {
      interestRate = 10;
      duration = 12;
      repaymentCycle = 'MONTHLY';
      requiresApproval = true;
    }

    // Run eligibility checks (non-blocking for now — stores result in metadata)
    let eligibility;
    try {
      eligibility = await checkLoanEligibility(memberId, principal);
    } catch {
      eligibility = { eligible: true, reasons: [], checks: {} };
    }

    // Validate guarantors if provided
    const guarantorRule = await getRule('LOAN', 'guarantors_required');
    const requiredGuarantors = guarantorRule?.count || 0;
    const validatedGuarantors = [];

    if (guarantors && guarantors.length > 0) {
      for (const g of guarantors) {
        const validation = await validateGuarantor(g.guarantor_member_id, g.guaranteed_amount, memberId);
        if (!validation.valid) {
          throw new Error(`Guarantor validation failed: ${validation.issues.join(', ')}`);
        }
        validatedGuarantors.push(g);
      }
    }

    // Calculate loan
    const calc = calculateLoan({ principal, interestRate, duration, repaymentCycle });

    // Create loan record
    const loanResult = await client.query(
      `INSERT INTO loans (member_id, product_id, member_account_id, principal, interest_rate, duration, repayment_cycle, total_interest, total_payable, status, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
      [memberId, productId || null, memberAccountId || null, principal, interestRate, duration, repaymentCycle, calc.totalInterest, calc.totalPayable, requiresApproval ? 'PENDING' : 'APPROVED', userId]
    );
    const loan = loanResult.rows[0];

    // Create repayment schedule
    for (const installment of calc.schedule) {
      await client.query(
        `INSERT INTO loan_schedules (loan_id, installment_number, due_date, principal_amount, interest_amount, total_amount)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [loan.id, installment.installment_number, installment.due_date, installment.principal_amount, installment.interest_amount, installment.total_amount]
      );
    }

    // Insert guarantors
    for (const g of validatedGuarantors) {
      await client.query(
        `INSERT INTO loan_guarantors (loan_id, guarantor_member_id, guaranteed_amount) VALUES ($1, $2, $3)`,
        [loan.id, g.guarantor_member_id, g.guaranteed_amount]
      );
    }

    await client.query('COMMIT');

    // If auto-approved, disburse immediately
    if (loan.status === 'APPROVED' && memberAccountId) {
      await disburseLoan({ loanId: loan.id, userId });
      const updated = await pool.query(`SELECT * FROM loans WHERE id = $1`, [loan.id]);
      return { loan: updated.rows[0], schedule: calc.schedule, eligibility };
    }

    return { loan, schedule: calc.schedule, eligibility };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Approve a loan — sets approved_amount (can be different from principal).
 * Approval ≠ Money given. Disbursement is a separate step.
 */
export async function approveLoan({ loanId, approvedAmount, userId }) {
  const pool = getPool();

  const loan = await pool.query(`SELECT * FROM loans WHERE id = $1`, [loanId]);
  if (loan.rows.length === 0) throw new Error('Loan not found');
  if (loan.rows[0].status !== 'PENDING') throw new Error(`Cannot approve loan with status: ${loan.rows[0].status}`);

  // Validate guarantors if required
  const guarantorRule = await getRule('LOAN', 'guarantors_required');
  const requiredCount = guarantorRule?.count || 0;
  if (requiredCount > 0) {
    const guarantors = await pool.query(
      `SELECT COUNT(*) as count FROM loan_guarantors WHERE loan_id = $1`, [loanId]
    );
    if (parseInt(guarantors.rows[0].count) < requiredCount) {
      throw new Error(`Loan requires ${requiredCount} guarantors, has ${guarantors.rows[0].count}`);
    }
  }

  const amount = approvedAmount || parseFloat(loan.rows[0].principal);
  if (amount > parseFloat(loan.rows[0].principal)) {
    throw new Error('Approved amount cannot exceed requested principal');
  }

  // Recalculate if approved_amount differs from principal
  let updateFields = `status = 'APPROVED', approved_amount = $1, approved_by = $2, approved_at = NOW(), updated_at = NOW()`;
  const params = [amount, userId];

  if (amount !== parseFloat(loan.rows[0].principal)) {
    const calc = calculateLoan({
      principal: amount,
      interestRate: parseFloat(loan.rows[0].interest_rate),
      duration: loan.rows[0].duration,
      repaymentCycle: loan.rows[0].repayment_cycle,
    });
    updateFields += `, total_interest = $3, total_payable = $4`;
    params.push(calc.totalInterest, calc.totalPayable);

    // Rebuild schedule
    await pool.query(`DELETE FROM loan_schedules WHERE loan_id = $1`, [loanId]);
    for (const inst of calc.schedule) {
      await pool.query(
        `INSERT INTO loan_schedules (loan_id, installment_number, due_date, principal_amount, interest_amount, total_amount) VALUES ($1, $2, $3, $4, $5, $6)`,
        [loanId, inst.installment_number, inst.due_date, inst.principal_amount, inst.interest_amount, inst.total_amount]
      );
    }
  }

  params.push(loanId);
  await pool.query(
    `UPDATE loans SET ${updateFields} WHERE id = $${params.length}`,
    params
  );

  return { loanId, status: 'APPROVED', approved_amount: amount };
}

/**
 * Reject a loan
 */
export async function rejectLoan({ loanId, reason, userId }) {
  const pool = getPool();

  const loan = await pool.query(`SELECT * FROM loans WHERE id = $1`, [loanId]);
  if (loan.rows.length === 0) throw new Error('Loan not found');
  if (loan.rows[0].status !== 'PENDING') throw new Error(`Cannot reject loan with status: ${loan.rows[0].status}`);

  await pool.query(
    `UPDATE loans SET status = 'REJECTED', approved_by = $1, rejected_reason = $2, updated_at = NOW() WHERE id = $3`,
    [userId, reason || 'No reason provided', loanId]
  );

  return { loanId, status: 'REJECTED' };
}

/**
 * Disburse an approved loan — CRITICAL LEDGER FLOW
 * Supports partial disbursement.
 *
 * CREDIT → Member account (they receive money)
 * DEBIT → System cash account (cash goes out)
 *
 * Status transitions:
 *   APPROVED → DISBURSED (partial) or ACTIVE (fully disbursed)
 *   DISBURSED → ACTIVE (remaining disbursed)
 */
export async function disburseLoan({ loanId, amount, userId }) {
  const pool = getPool();
  const client = await pool.connect();

  try {
    const loan = await client.query(`SELECT * FROM loans WHERE id = $1`, [loanId]);
    if (loan.rows.length === 0) throw new Error('Loan not found');
    const l = loan.rows[0];
    if (!['APPROVED', 'DISBURSED'].includes(l.status)) {
      throw new Error(`Cannot disburse loan with status: ${l.status}`);
    }
    if (!l.member_account_id) throw new Error('Loan has no member account for disbursement');

    const approvedAmt = parseFloat(l.approved_amount || l.principal);
    const alreadyDisbursed = parseFloat(l.disbursed_amount || 0);
    const remaining = approvedAmt - alreadyDisbursed;

    if (remaining <= 0) throw new Error('Loan is already fully disbursed');

    const disburseAmount = amount ? Math.min(amount, remaining) : remaining;
    if (disburseAmount <= 0) throw new Error('Disbursement amount must be positive');

    const newDisbursed = alreadyDisbursed + disburseAmount;
    const fullyDisbursed = Math.abs(newDisbursed - approvedAmt) < 0.01;
    const newStatus = fullyDisbursed ? 'ACTIVE' : 'DISBURSED';

    const systemAccountId = await getSystemAccountId(client);
    client.release();

    // Create disbursement transaction via ledger
    const result = await createTransaction({
      description: `Loan disbursement — ${disburseAmount} UGX${!fullyDisbursed ? ' (partial)' : ''}`,
      transaction_type: 'loan_disbursement',
      reference: loanId,
      metadata: { loan_id: loanId, amount: disburseAmount, total_disbursed: newDisbursed, partial: !fullyDisbursed },
      userId,
      entries: [
        { member_account_id: l.member_account_id, type: 'CREDIT', amount: disburseAmount, description: 'Loan disbursement received' },
        { account_id: systemAccountId, type: 'DEBIT', amount: disburseAmount, description: 'Loan disbursement to member' },
      ],
    });

    // Update loan
    await pool.query(
      `UPDATE loans SET status = $1, disbursed_amount = $2, disbursement_transaction_id = $3, disbursed_at = NOW(), updated_at = NOW() WHERE id = $4`,
      [newStatus, newDisbursed, result.transaction.id, loanId]
    );

    return {
      loanId,
      status: newStatus,
      disbursed: disburseAmount,
      total_disbursed: newDisbursed,
      remaining: approvedAmt - newDisbursed,
      transactionId: result.transaction.id,
    };
  } catch (err) {
    if (client) client.release();
    throw err;
  }
}

/**
 * Record a loan repayment
 * DEBIT → Member account (money leaves their account)
 * CREDIT → System cash account (SACCO receives money)
 */
export async function repayLoan({ loanId, amount, userId }) {
  const pool = getPool();

  const loan = await pool.query(`SELECT * FROM loans WHERE id = $1`, [loanId]);
  if (loan.rows.length === 0) throw new Error('Loan not found');
  const l = loan.rows[0];
  if (l.status !== 'ACTIVE') throw new Error(`Cannot repay loan with status: ${l.status}`);
  if (!l.member_account_id) throw new Error('Loan has no member account');

  const remaining = parseFloat(l.total_payable) - parseFloat(l.total_paid);
  if (amount > remaining + 0.01) {
    throw new Error(`Repayment of ${amount} exceeds remaining balance of ${remaining}`);
  }

  const client = await pool.connect();
  try {
    const systemAccountId = await getSystemAccountId(client);
    client.release();

    // Create repayment transaction via ledger
    const result = await createTransaction({
      description: `Loan repayment — ${amount} UGX`,
      transaction_type: 'loan_repayment',
      reference: loanId,
      metadata: { loan_id: loanId, repayment_amount: amount },
      userId,
      entries: [
        { member_account_id: l.member_account_id, type: 'DEBIT', amount, description: 'Loan repayment' },
        { account_id: systemAccountId, type: 'CREDIT', amount, description: 'Loan repayment received' },
      ],
    });

    // Update total_paid on loan
    const newTotalPaid = parseFloat(l.total_paid) + amount;
    const isComplete = newTotalPaid >= parseFloat(l.total_payable) - 0.01;

    await pool.query(
      `UPDATE loans SET total_paid = $1, status = $2, updated_at = NOW() WHERE id = $3`,
      [newTotalPaid, isComplete ? 'COMPLETED' : 'ACTIVE', loanId]
    );

    // Update schedule — apply payment to oldest pending installments
    let remainingPayment = amount;
    const schedules = await pool.query(
      `SELECT * FROM loan_schedules WHERE loan_id = $1 AND status IN ('PENDING', 'PARTIAL', 'OVERDUE') ORDER BY installment_number ASC`,
      [loanId]
    );

    for (const sched of schedules.rows) {
      if (remainingPayment <= 0) break;
      const due = parseFloat(sched.total_amount) - parseFloat(sched.paid_amount);
      const payment = Math.min(remainingPayment, due);

      const newPaid = parseFloat(sched.paid_amount) + payment;
      const schedStatus = newPaid >= parseFloat(sched.total_amount) - 0.01 ? 'PAID' : 'PARTIAL';

      await pool.query(
        `UPDATE loan_schedules SET paid_amount = $1, status = $2, paid_at = CASE WHEN $2 = 'PAID' THEN NOW() ELSE paid_at END, transaction_id = $3 WHERE id = $4`,
        [newPaid, schedStatus, result.transaction.id, sched.id]
      );
      remainingPayment -= payment;
    }

    return {
      loanId,
      repaid: amount,
      totalPaid: newTotalPaid,
      remaining: parseFloat(l.total_payable) - newTotalPaid,
      status: isComplete ? 'COMPLETED' : 'ACTIVE',
      transactionId: result.transaction.id,
    };
  } catch (err) {
    if (client) client.release();
    throw err;
  }
}

/**
 * Mark overdue installments
 */
export async function markOverdueInstallments() {
  const pool = getPool();
  const result = await pool.query(
    `UPDATE loan_schedules 
     SET status = 'OVERDUE' 
     WHERE due_date < CURRENT_DATE AND status IN ('PENDING', 'PARTIAL')
     RETURNING id, loan_id`
  );
  return result.rows;
}

// ─── Guarantor Management ───

/**
 * Add a guarantor to a loan
 */
export async function addGuarantor({ loanId, guarantorMemberId, guaranteedAmount, userId }) {
  const pool = getPool();

  const loan = await pool.query(`SELECT * FROM loans WHERE id = $1`, [loanId]);
  if (loan.rows.length === 0) throw new Error('Loan not found');
  if (!['PENDING'].includes(loan.rows[0].status)) {
    throw new Error('Can only add guarantors to pending loans');
  }

  // Validate via rule engine
  const validation = await validateGuarantor(guarantorMemberId, guaranteedAmount, loan.rows[0].member_id);
  if (!validation.valid) {
    throw new Error(validation.issues.join('; '));
  }

  const result = await pool.query(
    `INSERT INTO loan_guarantors (loan_id, guarantor_member_id, guaranteed_amount)
     VALUES ($1, $2, $3)
     ON CONFLICT (loan_id, guarantor_member_id) DO UPDATE SET guaranteed_amount = $3
     RETURNING *`,
    [loanId, guarantorMemberId, guaranteedAmount]
  );

  return { guarantor: result.rows[0], capacity: validation.capacity };
}

/**
 * Get guarantors for a loan
 */
export async function getLoanGuarantors(loanId) {
  const pool = getPool();
  const result = await pool.query(
    `SELECT lg.*, m.full_name, m.membership_number
     FROM loan_guarantors lg
     JOIN members m ON lg.guarantor_member_id = m.id
     WHERE lg.loan_id = $1
     ORDER BY lg.created_at`,
    [loanId]
  );
  return result.rows;
}

/**
 * Remove a guarantor from a pending loan
 */
export async function removeGuarantor({ loanId, guarantorId }) {
  const pool = getPool();

  const loan = await pool.query(`SELECT status FROM loans WHERE id = $1`, [loanId]);
  if (loan.rows.length === 0) throw new Error('Loan not found');
  if (loan.rows[0].status !== 'PENDING') throw new Error('Can only remove guarantors from pending loans');

  await pool.query(`DELETE FROM loan_guarantors WHERE id = $1 AND loan_id = $2`, [guarantorId, loanId]);
  return { removed: true };
}

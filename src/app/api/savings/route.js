/**
 * POST /api/savings/deposit   — deposit into a member account (no rule restrictions)
 * POST /api/savings/withdraw  — withdraw from a member account (rule-validated)
 * GET  /api/savings           — list member accounts with balances + behaviors
 */

import { NextResponse }         from 'next/server';
import { requirePermission }    from '@/lib/permissions.js';
import { query }                from '@/lib/db.js';
import { savingsDeposit, savingsWithdraw } from '@/lib/savings-engine.js';
import { getAccountBehavior }   from '@/lib/account-rules-engine.js';

// ── GET — Member accounts summary ────────────────────────────────────────────
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get('member_id') || '';
    const page     = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit    = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset   = (page - 1) * limit;

    let where  = `WHERE vb.status = 'active'`;
    const args = [];

    if (memberId) {
      args.push(memberId);
      where += ` AND vb.member_id = $${args.length}`;
    }

    args.push(limit, offset);

    const [dataResult, countResult] = await Promise.all([
      query(
        `SELECT vb.*, m.full_name, m.membership_number,
                at.name AS account_type_name, at.code AS account_type_code,
                at.allows_withdrawal, at.minimum_balance
         FROM v_member_account_balances vb
         JOIN members m ON m.id = vb.member_id
         JOIN member_accounts ma ON ma.id = vb.member_account_id
         JOIN account_types at ON at.id = ma.account_type_id
         ${where}
         ORDER BY vb.balance DESC
         LIMIT $${args.length - 1} OFFSET $${args.length}`,
        args
      ),
      query(
        `SELECT COUNT(*) AS total
         FROM v_member_account_balances vb
         ${where}`,
        args.slice(0, -2)
      ),
    ]);

    const total = parseInt(countResult.rows[0]?.total ?? 0);
    return NextResponse.json({
      success: true,
      data:    dataResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Savings] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// ── POST — Deposit or withdraw ────────────────────────────────────────────────
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { action, member_account_id, amount, description, reference, force } = body;

    if (!action || !['deposit', 'withdraw'].includes(action)) {
      return NextResponse.json(
        { success: false, error: 'action must be "deposit" or "withdraw"' },
        { status: 400 }
      );
    }
    if (!member_account_id || !amount) {
      return NextResponse.json(
        { success: false, error: 'member_account_id and amount are required' },
        { status: 400 }
      );
    }
    if (parseFloat(amount) <= 0) {
      return NextResponse.json(
        { success: false, error: 'amount must be positive' },
        { status: 400 }
      );
    }

    let result;

    if (action === 'deposit') {
      result = await savingsDeposit({
        memberAccountId: member_account_id,
        amount:          parseFloat(amount),
        description,
        reference,
        userId:          perm.userId,
      });
    } else {
      // Superadmin can force-bypass rules; others cannot
      const isSuperAdmin = ['superadmin', 'admin'].includes(perm.auth?.role);
      result = await savingsWithdraw({
        memberAccountId: member_account_id,
        amount:          parseFloat(amount),
        description,
        reference,
        userId:          perm.userId,
        force:           isSuperAdmin && force === true,
      });
    }

    // Return updated behavior alongside the result
    const behavior = await getAccountBehavior(member_account_id).catch(() => null);

    return NextResponse.json({
      success:     true,
      action,
      transaction: result.transaction,
      entries:     result.entries,
      balance:     result.balance,
      behavior,
    });
  } catch (error) {
    if (error.code === 'RULE_VIOLATION') {
      return NextResponse.json({ success: false, error: error.message, code: 'RULE_VIOLATION' }, { status: 422 });
    }
    console.error('[Savings] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

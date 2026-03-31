import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/members/[id]/accounts/[accountId]/ledger — Ledger entries for a member account
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const { id, accountId } = await params;

    // Verify account belongs to member
    const account = await query(
      `SELECT ma.*, m.full_name as member_name
       FROM member_accounts ma
       JOIN members m ON m.id = ma.member_id
       WHERE ma.id = $1 AND ma.member_id = $2`,
      [accountId, id]
    );
    if (account.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Account not found for this member' }, { status: 404 });
    }

    const { searchParams } = new URL(request.url);
    const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset = (page - 1) * limit;

    const [entriesResult, countResult, balanceResult] = await Promise.all([
      query(
        `SELECT le.*, t.description as tx_description, t.transaction_type, t.reference, t.created_at as tx_date
         FROM ledger_entries le
         JOIN transactions t ON t.id = le.transaction_id
         WHERE le.member_account_id = $1
         ORDER BY le.created_at DESC
         LIMIT $2 OFFSET $3`,
        [accountId, limit, offset]
      ),
      query(
        `SELECT COUNT(*) as total FROM ledger_entries WHERE member_account_id = $1`,
        [accountId]
      ),
      query(
        `SELECT balance FROM v_member_account_balances WHERE member_account_id = $1`,
        [accountId]
      ),
    ]);

    const total = parseInt(countResult.rows[0]?.total || 0);

    return NextResponse.json({
      success: true,
      account: account.rows[0],
      balance: parseFloat(balanceResult.rows[0]?.balance || 0),
      data: entriesResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Account Ledger] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

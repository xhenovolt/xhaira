/**
 * GET  /api/shares — list all share purchases (optionally filtered by member)
 * POST /api/shares — record a share purchase + post double-entry transaction
 */

import { NextResponse }      from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { query }             from '@/lib/db.js';
import { purchaseShares }    from '@/lib/interest-engine.js';

export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get('member_id') || '';
    const page     = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit    = Math.min(200, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset   = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const args = [];

    if (memberId) {
      args.push(memberId);
      where += ` AND s.member_id = $${args.length}`;
    }

    const countArgs = [...args];
    args.push(limit, offset);

    const [dataResult, countResult, summaryResult] = await Promise.all([
      query(
        `SELECT s.*, m.full_name, m.membership_number
         FROM shares s
         JOIN members m ON m.id = s.member_id
         ${where}
         ORDER BY s.created_at DESC
         LIMIT $${args.length - 1} OFFSET $${args.length}`,
        args
      ),
      query(
        `SELECT COUNT(*) AS total FROM shares s ${where}`,
        countArgs
      ),
      query(
        `SELECT * FROM v_member_shares
         ${memberId ? 'WHERE member_id = $1' : ''}
         ORDER BY total_units DESC`,
        memberId ? [memberId] : []
      ),
    ]);

    const total = parseInt(countResult.rows[0]?.total ?? 0);
    return NextResponse.json({
      success:    true,
      data:       dataResult.rows,
      summary:    summaryResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Shares] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { member_id, member_account_id, units, value_per_unit, notes } = body;

    if (!member_id || !units || !value_per_unit) {
      return NextResponse.json(
        { success: false, error: 'member_id, units, and value_per_unit are required' },
        { status: 400 }
      );
    }
    if (parseFloat(units) <= 0 || parseFloat(value_per_unit) <= 0) {
      return NextResponse.json(
        { success: false, error: 'units and value_per_unit must be positive' },
        { status: 400 }
      );
    }

    const result = await purchaseShares({
      memberId:        member_id,
      memberAccountId: member_account_id || null,
      units:           parseFloat(units),
      valuePerUnit:    parseFloat(value_per_unit),
      notes,
      userId:          perm.userId,
    });

    return NextResponse.json({ success: true, data: result }, { status: 201 });
  } catch (error) {
    console.error('[Shares] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

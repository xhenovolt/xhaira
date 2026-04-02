/**
 * GET  /api/interest — list interest accruals (filterable)
 * POST /api/interest — run accrual job for a period
 */

import { NextResponse }      from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { query }             from '@/lib/db.js';
import { accrueInterest }    from '@/lib/interest-engine.js';

export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const status    = searchParams.get('status') || '';
    const accountId = searchParams.get('account_id') || '';
    const memberId  = searchParams.get('member_id') || '';
    const page      = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit     = Math.min(200, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset    = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const args = [];

    if (status) {
      args.push(status.toUpperCase());
      where += ` AND ia.status = $${args.length}`;
    }
    if (accountId) {
      args.push(accountId);
      where += ` AND ia.account_id = $${args.length}`;
    }
    if (memberId) {
      args.push(memberId);
      where += ` AND ma.member_id = $${args.length}`;
    }

    const countArgs = [...args];
    args.push(limit, offset);

    const [dataResult, countResult, summaryResult] = await Promise.all([
      query(
        `SELECT ia.*,
                ma.member_id,
                m.full_name,
                m.membership_number,
                at.name  AS account_type_name,
                at.code  AS account_type_code
         FROM interest_accruals ia
         JOIN member_accounts ma ON ma.id = ia.account_id
         JOIN members m  ON m.id = ma.member_id
         JOIN account_types at ON at.id = ma.account_type_id
         ${where}
         ORDER BY ia.created_at DESC
         LIMIT $${args.length - 1} OFFSET $${args.length}`,
        args
      ),
      query(
        `SELECT COUNT(*) AS total
         FROM interest_accruals ia
         JOIN member_accounts ma ON ma.id = ia.account_id
         ${where}`,
        countArgs
      ),
      query(
        `SELECT
           SUM(CASE WHEN ia.status = 'PENDING' THEN ia.amount ELSE 0 END) AS pending_total,
           SUM(CASE WHEN ia.status = 'APPLIED' THEN ia.amount ELSE 0 END) AS applied_total,
           COUNT(CASE WHEN ia.status = 'PENDING' THEN 1 END)              AS pending_count,
           COUNT(CASE WHEN ia.status = 'APPLIED' THEN 1 END)              AS applied_count
         FROM interest_accruals ia
         JOIN member_accounts ma ON ma.id = ia.account_id
         ${where}`,
        countArgs
      ),
    ]);

    const total = parseInt(countResult.rows[0]?.total ?? 0);

    return NextResponse.json({
      success:  true,
      data:     dataResult.rows,
      summary:  summaryResult.rows[0],
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Interest] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { period_start, period_end } = body;

    if (!period_start || !period_end) {
      return NextResponse.json(
        { success: false, error: 'period_start and period_end are required (YYYY-MM-DD)' },
        { status: 400 }
      );
    }

    const result = await accrueInterest({
      periodStart: period_start,
      periodEnd:   period_end,
      userId:      perm.userId,
    });

    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Interest] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

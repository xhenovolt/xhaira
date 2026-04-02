/**
 * GET  /api/dividends — list dividend records
 * POST /api/dividends — run dividend distribution for a period
 */

import { NextResponse }         from 'next/server';
import { requirePermission }    from '@/lib/permissions.js';
import { query }                from '@/lib/db.js';
import { distributeDividends }  from '@/lib/interest-engine.js';

export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const memberId       = searchParams.get('member_id') || '';
    const period         = searchParams.get('period') || '';
    const distributionId = searchParams.get('distribution_id') || '';
    const page           = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit          = Math.min(200, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset         = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const args = [];

    if (memberId) {
      args.push(memberId);
      where += ` AND d.member_id = $${args.length}`;
    }
    if (period) {
      args.push(period);
      where += ` AND d.period = $${args.length}`;
    }
    if (distributionId) {
      args.push(distributionId);
      where += ` AND d.distribution_id = $${args.length}`;
    }

    const countArgs = [...args];
    args.push(limit, offset);

    const [dataResult, countResult, summaryResult] = await Promise.all([
      query(
        `SELECT d.*, m.full_name, m.membership_number
         FROM dividends d
         JOIN members m ON m.id = d.member_id
         ${where}
         ORDER BY d.created_at DESC
         LIMIT $${args.length - 1} OFFSET $${args.length}`,
        args
      ),
      query(`SELECT COUNT(*) AS total FROM dividends d ${where}`, countArgs),
      query(
        `SELECT period, basis, SUM(amount) AS total_distributed, COUNT(*) AS member_count
         FROM dividends d
         ${where}
         GROUP BY period, basis
         ORDER BY period DESC`,
        countArgs
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
    console.error('[Dividends] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { total_amount, period, basis = 'shares' } = body;

    if (!total_amount || parseFloat(total_amount) <= 0) {
      return NextResponse.json(
        { success: false, error: 'total_amount must be a positive number' },
        { status: 400 }
      );
    }
    if (!period) {
      return NextResponse.json(
        { success: false, error: 'period is required (e.g. "2026-Q1")' },
        { status: 400 }
      );
    }
    if (!['shares', 'savings', 'equal'].includes(basis)) {
      return NextResponse.json(
        { success: false, error: 'basis must be "shares", "savings", or "equal"' },
        { status: 400 }
      );
    }

    const result = await distributeDividends({
      totalAmount: parseFloat(total_amount),
      period,
      basis,
      userId: perm.userId,
    });

    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Dividends] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';
import { applyForLoan } from '@/lib/loan-service.js';

// GET /api/loans — List loans with filters
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status') || '';
    const memberId = searchParams.get('member_id') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const params = [];

    if (status) {
      params.push(status);
      where += ` AND l.status = $${params.length}`;
    }
    if (memberId) {
      params.push(memberId);
      where += ` AND l.member_id = $${params.length}`;
    }

    const countParams = [...params];
    params.push(limit, offset);

    const [dataResult, countResult] = await Promise.all([
      query(
        `SELECT l.*, m.full_name as member_name, m.membership_number,
           p.name as product_name, p.product_type,
           ma.account_number as member_account_number,
           u.email as approved_by_email
         FROM loans l
         JOIN members m ON m.id = l.member_id
         LEFT JOIN products p ON p.id = l.product_id
         LEFT JOIN member_accounts ma ON ma.id = l.member_account_id
         LEFT JOIN users u ON u.id = l.approved_by
         ${where}
         ORDER BY l.created_at DESC
         LIMIT $${params.length - 1} OFFSET $${params.length}`,
        params
      ),
      query(`SELECT COUNT(*) as total FROM loans l ${where}`, countParams),
    ]);

    const total = parseInt(countResult.rows[0]?.total || 0);

    return NextResponse.json({
      success: true,
      data: dataResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Loans] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/loans — Apply for a loan
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { member_id, product_id, member_account_id, principal, guarantors } = body;

    if (!member_id || !principal) {
      return NextResponse.json({ success: false, error: 'member_id and principal are required' }, { status: 400 });
    }
    if (parseFloat(principal) <= 0) {
      return NextResponse.json({ success: false, error: 'Principal must be positive' }, { status: 400 });
    }

    const result = await applyForLoan({
      memberId: member_id,
      productId: product_id || null,
      memberAccountId: member_account_id || null,
      principal: parseFloat(principal),
      guarantors: guarantors || [],
      userId: perm.userId,
    });

    return NextResponse.json({ success: true, data: result }, { status: 201 });
  } catch (error) {
    console.error('[Loans] POST error:', error.message);
    const status = error.message.includes('not found') ? 404
      : error.message.includes('not active') || error.message.includes('Guarantor') ? 400
      : error.message.includes('below minimum') || error.message.includes('exceeds maximum') ? 400
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

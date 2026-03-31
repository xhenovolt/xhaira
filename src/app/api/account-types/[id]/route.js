import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/account-types/[id]
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const result = await query(`SELECT * FROM account_types WHERE id = $1`, [id]);
    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Account type not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// PUT /api/account-types/[id]
export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { name, description, allows_withdrawal, minimum_balance, is_mandatory, interest_rate } = body;

    const result = await query(
      `UPDATE account_types SET
         name = COALESCE($1, name),
         description = COALESCE($2, description),
         allows_withdrawal = COALESCE($3, allows_withdrawal),
         minimum_balance = COALESCE($4, minimum_balance),
         is_mandatory = COALESCE($5, is_mandatory),
         interest_rate = COALESCE($6, interest_rate)
       WHERE id = $7 RETURNING *`,
      [name, description, allows_withdrawal, minimum_balance, is_mandatory, interest_rate, id]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Account type not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

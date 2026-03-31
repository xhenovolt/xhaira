import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/account-types — List all account types
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const result = await query(
      `SELECT * FROM account_types ORDER BY is_mandatory DESC, name ASC`
    );

    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[Account Types] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/account-types — Create a new account type
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { name, code, description, allows_withdrawal, minimum_balance, is_mandatory, interest_rate } = body;

    if (!name || !code) {
      return NextResponse.json({ success: false, error: 'Name and code are required' }, { status: 400 });
    }

    const result = await query(
      `INSERT INTO account_types (name, code, description, allows_withdrawal, minimum_balance, is_mandatory, interest_rate)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name, code.toUpperCase(), description || null, allows_withdrawal !== false, minimum_balance || 0, is_mandatory || false, interest_rate || 0]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    if (error.message.includes('duplicate key')) {
      return NextResponse.json({ success: false, error: 'Account type code already exists' }, { status: 409 });
    }
    console.error('[Account Types] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

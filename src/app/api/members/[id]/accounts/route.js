import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/members/[id]/accounts — List accounts for a member
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    // Verify member exists
    const member = await query(`SELECT id, full_name FROM members WHERE id = $1`, [id]);
    if (member.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }

    const accounts = await query(
      `SELECT vb.* FROM v_member_account_balances vb WHERE vb.member_id = $1 ORDER BY vb.opened_at DESC`,
      [id]
    );

    return NextResponse.json({
      success: true,
      data: accounts.rows,
      member: member.rows[0],
    });
  } catch (error) {
    console.error('[Member Accounts] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/members/[id]/accounts — Open a new account for a member
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { account_type, account_type_id, currency } = body;

    const validTypes = ['savings', 'loan', 'investment', 'shares', 'fixed_deposit'];
    if (!account_type || !validTypes.includes(account_type)) {
      return NextResponse.json({
        success: false,
        error: `Invalid account type. Must be one of: ${validTypes.join(', ')}`,
      }, { status: 400 });
    }

    // Verify member exists and is active
    const member = await query(`SELECT id, full_name, status FROM members WHERE id = $1`, [id]);
    if (member.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }
    if (member.rows[0].status !== 'active') {
      return NextResponse.json({ success: false, error: 'Cannot open account for inactive member' }, { status: 400 });
    }

    // Resolve account_type_id if not provided
    let resolvedTypeId = account_type_id || null;
    if (!resolvedTypeId) {
      const typeMap = { savings: 'VOL_SAV', fixed_deposit: 'FIXED_SAV', shares: 'SHARES', loan: 'LOAN_ACC', investment: 'INVEST' };
      const code = typeMap[account_type];
      if (code) {
        const typeResult = await query(`SELECT id FROM account_types WHERE code = $1`, [code]);
        if (typeResult.rows.length > 0) resolvedTypeId = typeResult.rows[0].id;
      }
    }

    // Generate account number: ACC-TYPE-RANDOM
    const typePrefix = account_type.substring(0, 3).toUpperCase();
    const randomSuffix = Math.random().toString(36).substring(2, 8).toUpperCase();
    const account_number = `ACC-${typePrefix}-${randomSuffix}`;

    const result = await query(
      `INSERT INTO member_accounts (member_id, account_type, account_number, currency, account_type_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [id, account_type, account_number, currency || 'UGX', resolvedTypeId]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    console.error('[Member Accounts] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

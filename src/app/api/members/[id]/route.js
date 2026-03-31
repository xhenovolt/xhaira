import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/members/[id] — Get member details with accounts
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    const [memberResult, accountsResult] = await Promise.all([
      query(
        `SELECT m.*, u.name as user_name, u.email as user_email
         FROM members m
         LEFT JOIN users u ON m.user_id = u.id
         WHERE m.id = $1`,
        [id]
      ),
      query(
        `SELECT * FROM member_accounts WHERE member_id = $1 ORDER BY created_at DESC`,
        [id]
      ),
    ]);

    if (memberResult.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      data: {
        ...memberResult.rows[0],
        accounts: accountsResult.rows,
      },
    });
  } catch (error) {
    console.error('[Members] GET detail error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// PUT /api/members/[id] — Update member
export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { full_name, email, phone, national_id, gender, date_of_birth, address, status } = body;

    const validStatuses = ['active', 'inactive', 'suspended', 'exited'];
    if (status && !validStatuses.includes(status)) {
      return NextResponse.json({ success: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` }, { status: 400 });
    }

    const result = await query(
      `UPDATE members SET
         full_name = COALESCE($2, full_name),
         email = COALESCE($3, email),
         phone = COALESCE($4, phone),
         national_id = COALESCE($5, national_id),
         gender = COALESCE($6, gender),
         date_of_birth = COALESCE($7, date_of_birth),
         address = COALESCE($8, address),
         status = COALESCE($9, status),
         updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, full_name || null, email || null, phone || null, national_id || null, gender || null, date_of_birth || null, address || null, status || null]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Members] PUT error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// DELETE /api/members/[id] — Remove member (soft exit)
export async function DELETE(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    const result = await query(
      `UPDATE members SET status = 'exited', updated_at = NOW() WHERE id = $1 RETURNING id, full_name, status`,
      [id]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Members] DELETE error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

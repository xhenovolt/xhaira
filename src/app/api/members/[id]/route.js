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

// PUT /api/members/[id] — Update member (full extended profile)
export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.manage');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { id } = await params;
    const body = await request.json();

    // Get current data for audit
    const current = await query(`SELECT * FROM members WHERE id = $1`, [id]);
    if (current.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }
    const oldData = current.rows[0];

    const {
      full_name, first_name, last_name, other_name,
      email, phone, national_id, id_type, gender, date_of_birth, address,
      photo_url, id_photo_url,
      occupation, employer, monthly_income,
      emergency_contact_name, emergency_contact_phone,
      next_of_kin_name, next_of_kin_phone, next_of_kin_relationship,
      joined_date, exit_date, exit_reason, suspended_reason, notes,
      status,
    } = body;

    const validStatuses = ['active', 'inactive', 'suspended', 'exited', 'blocked'];
    if (status && !validStatuses.includes(status)) {
      return NextResponse.json({ success: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` }, { status: 400 });
    }

    // Rebuild full_name if first/last changed
    let resolvedFullName = full_name?.trim() || null;
    if (!resolvedFullName && (first_name || last_name)) {
      resolvedFullName = [first_name, other_name, last_name].filter(Boolean).join(' ').trim() || null;
    }

    const result = await query(
      `UPDATE members SET
         full_name = COALESCE($2, full_name),
         first_name = COALESCE($3, first_name),
         last_name = COALESCE($4, last_name),
         other_name = COALESCE($5, other_name),
         email = COALESCE($6, email),
         phone = COALESCE($7, phone),
         national_id = COALESCE($8, national_id),
         id_type = COALESCE($9, id_type),
         gender = COALESCE($10, gender),
         date_of_birth = COALESCE($11, date_of_birth),
         address = COALESCE($12, address),
         photo_url = COALESCE($13, photo_url),
         id_photo_url = COALESCE($14, id_photo_url),
         occupation = COALESCE($15, occupation),
         employer = COALESCE($16, employer),
         monthly_income = COALESCE($17, monthly_income),
         emergency_contact_name = COALESCE($18, emergency_contact_name),
         emergency_contact_phone = COALESCE($19, emergency_contact_phone),
         next_of_kin_name = COALESCE($20, next_of_kin_name),
         next_of_kin_phone = COALESCE($21, next_of_kin_phone),
         next_of_kin_relationship = COALESCE($22, next_of_kin_relationship),
         joined_date = COALESCE($23, joined_date),
         exit_date = COALESCE($24, exit_date),
         exit_reason = COALESCE($25, exit_reason),
         suspended_reason = COALESCE($26, suspended_reason),
         notes = COALESCE($27, notes),
         status = COALESCE($28, status),
         updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [
        id, resolvedFullName, first_name || null, last_name || null, other_name || null,
        email || null, phone || null, national_id || null, id_type || null,
        gender || null, date_of_birth || null, address || null,
        photo_url || null, id_photo_url || null,
        occupation || null, employer || null,
        monthly_income !== undefined ? parseFloat(monthly_income) : null,
        emergency_contact_name || null, emergency_contact_phone || null,
        next_of_kin_name || null, next_of_kin_phone || null, next_of_kin_relationship || null,
        joined_date || null, exit_date || null, exit_reason || null, suspended_reason || null,
        notes || null, status || null,
      ]
    );

    const member = result.rows[0];

    // Audit log
    const changedFields = {};
    const auditFields = ['full_name', 'email', 'phone', 'status', 'national_id', 'gender'];
    auditFields.forEach(f => {
      if (body[f] !== undefined && body[f] !== oldData[f]) changedFields[f] = { from: oldData[f], to: body[f] };
    });
    const action = status && status !== oldData.status ? 'status_changed' : 'updated';
    await query(
      `INSERT INTO member_audit_log (member_id, action, performed_by, old_values, new_values)
       VALUES ($1, $2, $3, $4, $5)`,
      [id, action, auth?.userId || null, JSON.stringify(changedFields), JSON.stringify(body)]
    ).catch(() => {});

    return NextResponse.json({ success: true, data: member });
  } catch (error) {
    console.error('[Members] PUT error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// DELETE /api/members/[id] — Soft exit member
export async function DELETE(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.manage');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { id } = await params;

    const result = await query(
      `UPDATE members SET status = 'exited', exit_date = CURRENT_DATE, updated_at = NOW() WHERE id = $1 RETURNING id, full_name, status`,
      [id]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Member not found' }, { status: 404 });
    }

    await query(
      `INSERT INTO member_audit_log (member_id, action, performed_by, new_values)
       VALUES ($1, 'status_changed', $2, $3)`,
      [id, auth?.userId || null, JSON.stringify({ status: 'exited' })]
    ).catch(() => {});

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Members] DELETE error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

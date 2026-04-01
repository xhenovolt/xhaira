import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/member-field-configs — List member form field configurations
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const result = await query(
      `SELECT * FROM member_field_configs ORDER BY section, sort_order, label`
    );
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// PUT /api/member-field-configs — Batch update field configs
export async function PUT(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { updates } = body; // Array of { field_name, is_active, is_required }

    if (!Array.isArray(updates)) {
      return NextResponse.json({ success: false, error: 'updates array required' }, { status: 400 });
    }

    for (const u of updates) {
      if (!u.field_name) continue;
      await query(
        `UPDATE member_field_configs SET
           is_active = COALESCE($2, is_active),
           is_required = COALESCE($3, is_required),
           label = COALESCE($4, label),
           updated_at = NOW()
         WHERE field_name = $1`,
        [u.field_name, u.is_active ?? null, u.is_required ?? null, u.label || null]
      );
    }

    const result = await query(`SELECT * FROM member_field_configs ORDER BY section, sort_order`);
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

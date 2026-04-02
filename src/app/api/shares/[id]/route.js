/**
 * GET /api/shares/[id]  — fetch a single share record
 * PUT /api/shares/[id]  — update notes only (share records are immutable otherwise)
 */

import { NextResponse }      from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { query }             from '@/lib/db.js';

export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const result = await query(
      `SELECT s.*, m.full_name, m.membership_number
       FROM shares s
       JOIN members m ON m.id = s.member_id
       WHERE s.id = $1`,
      [params.id]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Share record not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Shares] GET[id] error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { notes } = body;

    const result = await query(
      `UPDATE shares SET notes = $1 WHERE id = $2 RETURNING *`,
      [notes || null, params.id]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Share record not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Shares] PUT error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

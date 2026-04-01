import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/members/[id]/audit — Audit trail for a member
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const { searchParams } = new URL(request.url);
    const limit = Math.min(100, parseInt(searchParams.get('limit') || '50'));

    const result = await query(
      `SELECT al.*, u.name as performed_by_name, u.email as performed_by_email
       FROM member_audit_log al
       LEFT JOIN users u ON al.performed_by = u.id
       WHERE al.member_id = $1
       ORDER BY al.created_at DESC
       LIMIT $2`,
      [id, limit]
    );

    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

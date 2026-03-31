import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/members — List all SACCO members
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'members.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search') || '';
    const status = searchParams.get('status') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const params = [];

    if (search) {
      params.push(`%${search}%`);
      where += ` AND (m.full_name ILIKE $${params.length} OR m.email ILIKE $${params.length} OR m.phone ILIKE $${params.length} OR m.membership_number ILIKE $${params.length})`;
    }
    if (status) {
      params.push(status);
      where += ` AND m.status = $${params.length}`;
    }

    const countParams = [...params];
    params.push(limit, offset);

    const [dataResult, countResult] = await Promise.all([
      query(
        `SELECT m.*, u.name as user_name, u.email as user_email,
           (SELECT COUNT(*) FROM member_accounts ma WHERE ma.member_id = m.id) as account_count,
           (SELECT COALESCE(SUM(vb.balance), 0) FROM v_member_account_balances vb WHERE vb.member_id = m.id AND vb.status = 'active') as total_balance
         FROM members m
         LEFT JOIN users u ON m.user_id = u.id
         ${where}
         ORDER BY m.created_at DESC
         LIMIT $${params.length - 1} OFFSET $${params.length}`,
        params
      ),
      query(`SELECT COUNT(*) as total FROM members m ${where}`, countParams),
    ]);

    const total = parseInt(countResult.rows[0]?.total || 0);

    return NextResponse.json({
      success: true,
      data: dataResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('[Members] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/members — Register a new SACCO member
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'members.create');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const body = await request.json();
    const { full_name, email, phone, national_id, gender, date_of_birth, address, user_id } = body;

    if (!full_name || !full_name.trim()) {
      return NextResponse.json({ success: false, error: 'Full name is required' }, { status: 400 });
    }

    // Generate membership number: MBR-YYYYMMDD-XXXXX
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
    const membership_number = `MBR-${dateStr}-${randomSuffix}`;

    const result = await query(
      `INSERT INTO members (full_name, email, phone, national_id, gender, date_of_birth, address, user_id, membership_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        full_name.trim(),
        email || null,
        phone || null,
        national_id || null,
        gender || null,
        date_of_birth || null,
        address || null,
        user_id || null,
        membership_number,
      ]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    console.error('[Members] POST error:', error.message);
    if (error.message.includes('idx_members_national_id')) {
      return NextResponse.json({ success: false, error: 'A member with this National ID already exists' }, { status: 409 });
    }
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

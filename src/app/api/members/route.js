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
    const {
      // Core
      full_name, first_name, last_name, other_name, email, phone,
      national_id, id_type, gender, date_of_birth, address, user_id,
      // Extended profile
      photo_url, id_photo_url,
      occupation, employer, monthly_income,
      emergency_contact_name, emergency_contact_phone,
      next_of_kin_name, next_of_kin_phone, next_of_kin_relationship,
      joined_date, notes,
    } = body;

    // Build full_name from parts if not provided
    const resolvedFullName = full_name?.trim() ||
      [first_name, other_name, last_name].filter(Boolean).join(' ').trim();

    if (!resolvedFullName) {
      return NextResponse.json({ success: false, error: 'Full name (or first + last name) is required' }, { status: 400 });
    }

    // Generate membership number: MBR-YYYYMMDD-XXXXX
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
    const membership_number = `MBR-${dateStr}-${randomSuffix}`;

    const result = await query(
      `INSERT INTO members (
         full_name, first_name, last_name, other_name,
         email, phone, national_id, id_type, gender, date_of_birth, address,
         photo_url, id_photo_url,
         occupation, employer, monthly_income,
         emergency_contact_name, emergency_contact_phone,
         next_of_kin_name, next_of_kin_phone, next_of_kin_relationship,
         joined_date, notes, user_id, membership_number
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
         $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25
       ) RETURNING *`,
      [
        resolvedFullName,
        first_name || resolvedFullName.split(' ')[0] || null,
        last_name || resolvedFullName.split(' ').slice(1).join(' ') || null,
        other_name || null,
        email || null,
        phone || null,
        national_id || null,
        id_type || 'national_id',
        gender || null,
        date_of_birth || null,
        address || null,
        photo_url || null,
        id_photo_url || null,
        occupation || null,
        employer || null,
        monthly_income ? parseFloat(monthly_income) : null,
        emergency_contact_name || null,
        emergency_contact_phone || null,
        next_of_kin_name || null,
        next_of_kin_phone || null,
        next_of_kin_relationship || null,
        joined_date || new Date().toISOString().split('T')[0],
        notes || null,
        user_id || null,
        membership_number,
      ]
    );

    const member = result.rows[0];

    // Audit log
    await query(
      `INSERT INTO member_audit_log (member_id, action, performed_by, new_values)
       VALUES ($1, 'created', $2, $3)`,
      [member.id, auth?.userId || null, JSON.stringify({ membership_number, full_name: resolvedFullName })]
    ).catch(() => {}); // Non-blocking

    // Auto-open savings account if configured
    const autoOpenSavings = await query(
      `SELECT config_value FROM sacco_configurations WHERE config_key = 'accounts.auto_open_savings'`
    ).catch(() => ({ rows: [] }));

    if (autoOpenSavings.rows[0]?.config_value === true || autoOpenSavings.rows[0]?.config_value === 'true') {
      const volSavType = await query(
        `SELECT id FROM account_types WHERE code = 'VOL_SAV' LIMIT 1`
      ).catch(() => ({ rows: [] }));

      if (volSavType.rows.length > 0) {
        const accNum = `SAV-${membership_number.split('-').slice(-1)[0]}`;
        await query(
          `INSERT INTO member_accounts (member_id, account_type, account_type_id, account_number, currency, status, opened_at)
           VALUES ($1, 'savings', $2, $3, 'UGX', 'active', NOW())
           ON CONFLICT DO NOTHING`,
          [member.id, volSavType.rows[0].id, accNum]
        ).catch(() => {});
      }
    }

    return NextResponse.json({ success: true, data: member }, { status: 201 });
  } catch (error) {
    console.error('[Members] POST error:', error.message);
    if (error.message.includes('idx_members_national_id') || error.message.includes('idx_members_email_unique')) {
      return NextResponse.json({ success: false, error: 'A member with this National ID or email already exists' }, { status: 409 });
    }
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

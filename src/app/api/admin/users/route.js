import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission, getUserAuthorityLevel, buildAuthorityFilter } from '@/lib/permissions.js';

export async function GET(request) {
  const perm = await requirePermission(request, 'users.view');
  if (perm instanceof NextResponse) return perm;
  try {
    const { auth } = perm;

    // Hierarchy filter: viewer only sees users whose authority_level <= their own
    // Superadmin always gets authority 100 (bypasses filter entirely via 1=1).
    const viewerAuthority = auth.role === 'superadmin' ? 100 : await getUserAuthorityLevel(auth.userId);
    const { clause, params } = buildAuthorityFilter(viewerAuthority, {
      actorAuthorityCol: 'u.authority_level',
      startIdx: 1,
    });

    const result = await query(
      `SELECT u.id, u.email, u.username, u.name, u.role, u.status, u.is_active,
              u.authority_level, u.first_login_completed, u.must_reset_password,
              u.last_login, u.created_at, u.staff_id,
              s.name  AS staff_name,
              s.email AS staff_email,
              r.name  AS role_name,
              r.hierarchy_level,
              r.authority_level AS role_authority_level
         FROM users u
         LEFT JOIN staff  s ON u.staff_id = s.id
         LEFT JOIN roles  r ON u.role = r.name
        WHERE ${clause}
        ORDER BY u.created_at DESC`,
      params
    );

    // Safety valve: never silently return empty when records exist but were
    // filtered by authority. Surface a clear message instead.
    if (result.rows.length === 0 && viewerAuthority < 100) {
      const total = await query('SELECT COUNT(*) AS cnt FROM users');
      if (parseInt(total.rows[0].cnt, 10) > 0) {
        return NextResponse.json({
          success: true,
          data: [],
          restricted: true,
          message: 'Access restricted to higher authority users',
        });
      }
    }

    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[admin/users] GET error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch users' }, { status: 500 });
  }
}

/**
 * POST /api/admin/users
 * Create a new user
 * Required permission: users.create
 */
export async function POST(request) {
  const perm = await requirePermission(request, 'users.create');
  if (perm instanceof NextResponse) return perm;

  try {
    const { auth } = perm;
    const body = await request.json();

    // Validate required fields
    if (!body.email || !body.name) {
      return NextResponse.json(
        { error: 'Email and name are required' },
        { status: 400 }
      );
    }

    // Check if email already exists
    const existing = await query('SELECT id FROM users WHERE email = $1', [body.email]);
    if (existing.rows.length > 0) {
      return NextResponse.json(
        { error: 'Email already registered' },
        { status: 409 }
      );
    }

    // Prepare user data
    const { email, name, role = 'staff', status = 'pending' } = body;
    const passwordHash = require('bcryptjs').hashSync('TempPass123!', 10); // Temp password

    // Insert user
    const result = await query(
      `INSERT INTO users (email, password_hash, name, role, status, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, true, NOW(), NOW())
       RETURNING id, email, name, role, status, created_at`,
      [email, passwordHash, name, role, status]
    );

    if (result.rows.length === 0) {
      return NextResponse.json(
        { error: 'Failed to create user' },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        success: true,
        message: 'User created successfully',
        data: result.rows[0]
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[admin/users] POST error:', error);
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    );
  }
}

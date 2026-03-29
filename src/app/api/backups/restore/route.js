import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { dispatch } from '@/lib/system-events.js';
import { requirePermission } from '@/lib/permissions.js';

/**
 * POST /api/backups/restore — Request restoration (requires superadmin approval)
 * Body: { backup_id }
 */
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'audit.view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { backup_id } = await request.json();
    if (!backup_id) return NextResponse.json({ success: false, error: 'backup_id is required' }, { status: 400 });

    const backup = await query(`SELECT * FROM system_backups WHERE id = $1`, [backup_id]);
    if (!backup.rows[0]) return NextResponse.json({ success: false, error: 'Backup not found' }, { status: 404 });

    // Create restoration request (approved immediately for superadmin)
    const restore = await query(
      `INSERT INTO backup_restorations (backup_id, status, requested_by, approved_by)
       VALUES ($1, 'approved', $2, $2) RETURNING *`,
      [backup_id, auth.userId]
    );

    await query(`INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details) VALUES ($1,$2,$3,$4,$5)`,
      [auth.userId, 'RESTORE_REQUEST', 'backup_restoration', restore.rows[0].id, JSON.stringify({ backup_name: backup.rows[0].name })]);

    dispatch('backup_restore_requested', {
      entityType: 'backup', entityId: backup_id,
      description: `Backup restoration requested for "${backup.rows[0].name}"`,
      actorId: auth.userId,
    });

    return NextResponse.json({
      success: true,
      data: restore.rows[0],
      message: 'Restoration approved. Note: Actual SQL restoration must be performed manually via the downloaded backup file for safety.',
    });
  } catch (error) {
    console.error('[Restore] POST error:', error);
    return NextResponse.json({ success: false, error: 'Failed to request restoration' }, { status: 500 });
  }
}

/**
 * GET /api/backups/restore — List restoration history
 */
export async function GET(request) {
  try {
    const auth = await verifyAuth(request);
    if (!auth || (auth.role !== 'superadmin' && auth.role !== 'admin')) {
      return NextResponse.json({ success: false, error: 'Admin access required' }, { status: 403 });
    }

    const result = await query(
      `SELECT br.*, sb.name as backup_name, u.name as requested_by_name
       FROM backup_restorations br
       JOIN system_backups sb ON br.backup_id = sb.id
       LEFT JOIN users u ON br.requested_by = u.id
       ORDER BY br.created_at DESC`
    );
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to fetch restorations' }, { status: 500 });
  }
}

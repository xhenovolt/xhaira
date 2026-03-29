import { NextResponse } from 'next/server';
import { query, getPool } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { dispatch } from '@/lib/system-events.js';
import { requirePermission } from '@/lib/permissions.js';

/**
 * GET /api/backups — List all system backups
 */
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'audit.view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const result = await query(
      `SELECT sb.*, u.name as created_by_name
       FROM system_backups sb
       LEFT JOIN users u ON sb.created_by = u.id
       ORDER BY sb.created_at DESC`
    );
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[Backups] GET error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch backups' }, { status: 500 });
  }
}

/**
 * POST /api/backups — Create a new database backup
 * Dumps schema + data as SQL, optionally uploads to Cloudinary
 */
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'audit.view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const body = await request.json();
    const { name, description, backup_type, tags } = body;

    const backupName = name?.trim() || `xhaira_backup_${new Date().toISOString().slice(0, 10)}`;

    // Create backup record (in_progress)
    const backup = await query(
      `INSERT INTO system_backups (name, description, backup_type, tags, status, created_by)
       VALUES ($1, $2, $3, $4, 'in_progress', $5) RETURNING *`,
      [backupName, description || null, backup_type || 'full', tags || [], auth.userId]
    );
    const backupId = backup.rows[0].id;

    try {
      // Get all table names
      const tablesRes = await query(
        `SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename`
      );
      const tables = tablesRes.rows.map(r => r.tablename);
      let totalRows = 0;
      const sqlParts = [];

      sqlParts.push(`-- Xhaira System Backup: ${backupName}`);
      sqlParts.push(`-- Created: ${new Date().toISOString()}`);
      sqlParts.push(`-- Type: ${backup_type || 'full'}`);
      sqlParts.push(`-- Tables: ${tables.length}`);
      sqlParts.push('');

      for (const table of tables) {
        // Get schema
        if (backup_type !== 'data_only') {
          const colsRes = await query(
            `SELECT column_name, data_type, column_default, is_nullable
             FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = $1
             ORDER BY ordinal_position`, [table]
          );
          sqlParts.push(`-- Table: ${table} (${colsRes.rows.length} columns)`);
        }

        // Get data
        if (backup_type !== 'schema_only') {
          const dataRes = await query(`SELECT * FROM "${table}"`);
          totalRows += dataRes.rows.length;
          if (dataRes.rows.length > 0) {
            const cols = Object.keys(dataRes.rows[0]);
            sqlParts.push(`-- Data for ${table}: ${dataRes.rows.length} rows`);
            for (const row of dataRes.rows) {
              const vals = cols.map(c => {
                const v = row[c];
                if (v === null || v === undefined) return 'NULL';
                if (typeof v === 'number') return v;
                if (typeof v === 'boolean') return v ? 'TRUE' : 'FALSE';
                if (v instanceof Date) return `'${v.toISOString()}'`;
                if (typeof v === 'object') return `'${JSON.stringify(v).replace(/'/g, "''")}'`;
                return `'${String(v).replace(/'/g, "''")}'`;
              });
              sqlParts.push(`INSERT INTO "${table}" (${cols.map(c => `"${c}"`).join(',')}) VALUES (${vals.join(',')}) ON CONFLICT DO NOTHING;`);
            }
            sqlParts.push('');
          }
        }
      }

      const sqlContent = sqlParts.join('\n');
      const fileSize = new Blob([sqlContent]).size;

      // Try uploading to Cloudinary
      let fileUrl = null;
      let publicId = null;
      try {
        const cloudRes = await query(`SELECT * FROM cloud_accounts WHERE is_active = true ORDER BY is_primary DESC LIMIT 1`);
        const account = cloudRes.rows[0];
        if (account) {
          const { default: { v2: cloudinary } } = await import('cloudinary');
          cloudinary.config({
            cloud_name: account.cloud_name,
            api_key: account.api_key,
            api_secret: account.api_secret,
          });
          const uploadResult = await cloudinary.uploader.upload(
            `data:text/plain;base64,${Buffer.from(sqlContent).toString('base64')}`,
            { resource_type: 'raw', folder: 'xhaira/backups', public_id: backupName.replace(/[^a-zA-Z0-9_-]/g, '_') }
          );
          fileUrl = uploadResult.secure_url;
          publicId = uploadResult.public_id;
        }
      } catch (cloudErr) {
        console.error('[Backups] Cloudinary upload failed (non-fatal):', cloudErr.message);
      }

      // Update backup record
      await query(
        `UPDATE system_backups SET status = $1, file_url = $2, cloudinary_public_id = $3, file_size = $4, table_count = $5, row_count = $6 WHERE id = $7`,
        [fileUrl ? 'uploaded' : 'completed', fileUrl, publicId, fileSize, tables.length, totalRows, backupId]
      );

      await query(`INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details) VALUES ($1,$2,$3,$4,$5)`,
        [auth.userId, 'BACKUP', 'system_backup', backupId, JSON.stringify({ name: backupName, tables: tables.length, rows: totalRows })]);

      dispatch('backup_created', {
        entityType: 'backup', entityId: backupId,
        description: `System backup "${backupName}" completed (${tables.length} tables, ${totalRows.toLocaleString()} rows)`,
        actorId: auth.userId,
        metadata: { name: backupName, tables: tables.length, rows: totalRows },
      });

      return NextResponse.json({
        success: true,
        data: {
          id: backupId,
          name: backupName,
          status: fileUrl ? 'uploaded' : 'completed',
          tables: tables.length,
          rows: totalRows,
          file_size: fileSize,
          file_url: fileUrl,
        },
      }, { status: 201 });
    } catch (dumpErr) {
      await query(`UPDATE system_backups SET status = 'failed' WHERE id = $1`, [backupId]);
      throw dumpErr;
    }
  } catch (error) {
    console.error('[Backups] POST error:', error);
    return NextResponse.json({ success: false, error: 'Failed to create backup' }, { status: 500 });
  }
}

/**
 * DELETE /api/backups?id=xxx — Delete a backup
 */
export async function DELETE(request) {
  try {
    const auth = await verifyAuth(request);
    if (!auth || auth.role !== 'superadmin') {
      return NextResponse.json({ success: false, error: 'Superadmin access required' }, { status: 403 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ success: false, error: 'id required' }, { status: 400 });

    const result = await query(`DELETE FROM system_backups WHERE id = $1 RETURNING name`, [id]);
    if (!result.rows[0]) return NextResponse.json({ success: false, error: 'Backup not found' }, { status: 404 });

    await query(`INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details) VALUES ($1,$2,$3,$4,$5)`,
      [auth.userId, 'DELETE', 'system_backup', id, JSON.stringify({ name: result.rows[0].name })]);

    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to delete backup' }, { status: 500 });
  }
}

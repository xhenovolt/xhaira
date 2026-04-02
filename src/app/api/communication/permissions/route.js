import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import {
  getMediaPermissions,
  updateMediaPermission,
  getCallPermissionsForRole,
} from '@/lib/communication-utils.js';
import db from '@/lib/db.js';

/**
 * GET /api/communication/permissions
 * Get media or call permissions based on ?type= query param
 */
export async function GET(req) {
  try {
    const auth = await requirePermission(req, 'communication.view_conversations');
    if (auth.status === 403) return auth;

    const url = new URL(req.url);
    const permType = url.searchParams.get('type') || 'media';

    if (permType === 'calls') {
      const { roleId } = auth;
      const callPerms = await getCallPermissionsForRole(roleId);
      return NextResponse.json({ success: true, callPermissions: callPerms });
    }

    // Default: media permissions
    const permissions = await getMediaPermissions();
    return NextResponse.json({ success: true, mediaPermissions: permissions });
  } catch (error) {
    console.error('Error fetching permissions:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

/**
 * PUT /api/communication/permissions
 * Update media or call permissions (admin only)
 * Distinguish by presence of `fileType` (media) vs `roleId` (calls)
 */
export async function PUT(req) {
  try {
    const body = await req.json();

    // ── Call permissions ──
    if (body.roleId) {
      const auth = await requirePermission(req, 'communication.manage_call_permissions');
      if (auth.status === 403) return auth;
      const { userId } = auth;
      const { roleId, canStartAudio, canStartVideo, canRecord, maxDurationMin } = body;

      const result = await db.query(
        `INSERT INTO call_permissions (role_id, can_start_audio_calls, can_start_video_calls, can_record_calls, max_call_duration_minutes)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (role_id) DO UPDATE SET
           can_start_audio_calls = $2,
           can_start_video_calls = $3,
           can_record_calls = $4,
           max_call_duration_minutes = $5
         RETURNING *`,
        [roleId, canStartAudio ?? true, canStartVideo ?? true, canRecord ?? false, maxDurationMin]
      );

      await db.query(
        `INSERT INTO communication_audit_log (user_id, action, entity_type, entity_id, details)
         VALUES ($1, 'call_permission_updated', 'call_permission', $2, $3)`,
        [userId, roleId, JSON.stringify({ canStartAudio, canStartVideo, canRecord, maxDurationMin })]
      );

      return NextResponse.json({ success: true, callPermission: result.rows[0] });
    }

    // ── Media permissions ──
    const auth = await requirePermission(req, 'communication.manage_media_permissions');
    if (auth.status === 403) return auth;
    const { userId } = auth;
    const { fileType, allowed, maxSizeMb } = body;

    if (!fileType) {
      return NextResponse.json(
        { success: false, error: 'fileType is required' },
        { status: 400 }
      );
    }

    const result = await updateMediaPermission(fileType, allowed, maxSizeMb);

    await db.query(
      `INSERT INTO communication_audit_log (user_id, action, entity_type, entity_id, details)
       VALUES ($1, 'media_permission_updated', 'media_permission', $2, $3)`,
      [userId, fileType, JSON.stringify({ allowed, maxSizeMb })]
    );

    return NextResponse.json({ success: true, mediaPermission: result });
  } catch (error) {
    console.error('Error updating permissions:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

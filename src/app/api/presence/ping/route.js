/**
 * POST /api/presence/ping
 * Called by authenticated clients every 30 seconds.
 * Upserts user_presence row and marks user as online.
 * Optionally accepts { route, page_title } in body to track current page.
 * 
 * NOTE: Gracefully handles missing user_presence table.
 * Returns 200 even for unauthenticated requests (to avoid spam 401s from browser).
 */
import { NextResponse } from 'next/server';
import { getCurrentUser } from '@/lib/current-user';
import { query } from '@/lib/db';
import { verifyAuth } from '@/lib/auth-utils.js';

export async function POST(request) {
  try {
    const auth = await verifyAuth(request);
    
    // Allow unauthenticated pings (return 200, don't spam 401)
    // Only track if authenticated
    if (!auth) {
      return NextResponse.json({ ok: true, tracked: false }, { status: 200 });
    }

    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ ok: true, tracked: false }, { status: 200 });
    }

    let route = null;
    let page_title = null;
    let device_info = null;

    try {
      const body = await request.json();
      route = body?.route || null;
      page_title = body?.page_title || null;
      device_info = body?.device_info || null;
    } catch {
      // Body is optional
    }

    try {
      await query(
        `INSERT INTO user_presence (user_id, last_ping, last_seen, status, is_online, current_route, current_page_title, device_info)
         VALUES ($1, NOW(), NOW(), 'online', true, $2, $3, $4)
         ON CONFLICT (user_id) DO UPDATE
         SET last_ping          = NOW(),
             last_seen          = NOW(),
             status             = 'online',
             is_online          = true,
             current_route      = COALESCE($2, user_presence.current_route),
             current_page_title = COALESCE($3, user_presence.current_page_title),
             device_info        = COALESCE($4, user_presence.device_info),
             updated_at         = NOW()`,
        [user.id, route, page_title, device_info]
      );

      return NextResponse.json({ ok: true, tracked: true, status: 'online' });
    } catch (err) {
      // Handle missing table gracefully
      if (err.code === '42P01') {
        console.warn('[presence/ping] user_presence table missing (non-blocking)');
        return NextResponse.json({ ok: true, tracked: false, reason: 'table_missing' }, { status: 200 });
      }
      throw err;
    }
  } catch (err) {
    console.error('[presence/ping]', err.message);
    // Always return 200 to avoid spam 401s
    return NextResponse.json({ ok: false, tracked: false }, { status: 200 });
  }
}

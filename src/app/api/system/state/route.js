/**
 * GET /api/system/state
 *
 * Check system initialization status
 * PUBLIC endpoint - no authentication required
 *
 * Returns:
 * - initialized: boolean (system has users)
 * - userCount: number of users
 * - message: user-friendly status message
 */

import { NextResponse } from 'next/server.js';
import { getSystemState } from '@/lib/system-init.js';

export async function GET() {
  try {
    const state = await getSystemState();
    return NextResponse.json(state);
  } catch (error) {
    console.error('System state error:', error);
    return NextResponse.json(
      {
        error: 'Unable to determine system state',
        initialized: false,
      },
      { status: 500 }
    );
  }
}

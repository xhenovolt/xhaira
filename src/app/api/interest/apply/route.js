/**
 * POST /api/interest/apply
 * Apply all PENDING interest accruals — posts double-entry to the ledger.
 * Optionally pass accrual_ids[] to apply only specific records.
 */

import { NextResponse }      from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { applyInterest }     from '@/lib/interest-engine.js';

export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body        = await request.json().catch(() => ({}));
    const accrualIds  = Array.isArray(body.accrual_ids) ? body.accrual_ids : undefined;

    const result = await applyInterest({ userId: perm.userId, accrualIds });

    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Interest Apply] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

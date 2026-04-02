/**
 * GET /api/savings/accounts/[id]/behavior
 * Returns the full rule-resolved behavior for a specific member account.
 * Used by the UI to show what an account can/cannot do before an action.
 */

import { NextResponse }    from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { getAccountBehavior } from '@/lib/account-rules-engine.js';
import { getMemberAccountBalance } from '@/lib/transaction-service.js';

export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const [behavior, balance] = await Promise.all([
      getAccountBehavior(params.id),
      getMemberAccountBalance(params.id),
    ]);

    return NextResponse.json({
      success:  true,
      data:     { ...behavior, balance, member_account_id: params.id },
    });
  } catch (error) {
    if (error.message.includes('not found')) {
      return NextResponse.json({ success: false, error: error.message }, { status: 404 });
    }
    console.error('[Savings Behavior] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

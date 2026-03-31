import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { checkLoanEligibility } from '@/lib/rule-engine.js';

// GET /api/loans/eligibility?member_id=xxx&amount=1000000
// Check loan eligibility for a member before applying
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get('member_id');
    const amount = searchParams.get('amount');

    if (!memberId) {
      return NextResponse.json({ success: false, error: 'member_id is required' }, { status: 400 });
    }

    const result = await checkLoanEligibility(memberId, amount ? parseFloat(amount) : null);
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Loan Eligibility] error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

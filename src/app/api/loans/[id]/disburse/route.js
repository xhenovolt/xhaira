import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { disburseLoan } from '@/lib/loan-service.js';

// POST /api/loans/[id]/disburse
// Body (optional): { amount: number } for partial disbursement
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    let amount;
    try {
      const body = await request.json();
      amount = body.amount ? parseFloat(body.amount) : undefined;
    } catch {
      // No body = full disbursement
    }

    const result = await disburseLoan({ loanId: id, amount, userId: perm.userId });
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Loan Disburse] error:', error.message);
    const status = error.message.includes('not found') ? 404
      : error.message.includes('Cannot') || error.message.includes('no member account') || error.message.includes('fully disbursed') ? 400
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

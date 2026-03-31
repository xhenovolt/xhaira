import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { repayLoan } from '@/lib/loan-service.js';

// POST /api/loans/[id]/repay
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { amount } = body;

    if (!amount || parseFloat(amount) <= 0) {
      return NextResponse.json({ success: false, error: 'Amount must be positive' }, { status: 400 });
    }

    const result = await repayLoan({ loanId: id, amount: parseFloat(amount), userId: perm.userId });
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Loan Repay] error:', error.message);
    const status = error.message.includes('not found') ? 404
      : error.message.includes('Cannot') || error.message.includes('Insufficient') || error.message.includes('exceeds') ? 400
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

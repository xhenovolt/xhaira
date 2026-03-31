import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { rejectLoan } from '@/lib/loan-service.js';

// POST /api/loans/[id]/reject
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const result = await rejectLoan({ loanId: id, reason: body.reason, userId: perm.userId });
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Loan Reject] error:', error.message);
    const status = error.message.includes('not found') ? 404 : error.message.includes('Cannot') ? 400 : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

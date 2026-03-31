import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { approveLoan } from '@/lib/loan-service.js';

// POST /api/loans/[id]/approve
// Body (optional): { approved_amount: number }
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    let approvedAmount;
    try {
      const body = await request.json();
      approvedAmount = body.approved_amount ? parseFloat(body.approved_amount) : undefined;
    } catch {
      // No body is fine — approves full principal
    }

    const result = await approveLoan({ loanId: id, approvedAmount, userId: perm.userId });
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    console.error('[Loan Approve] error:', error.message);
    const status = error.message.includes('not found') ? 404
      : error.message.includes('Cannot') || error.message.includes('requires') || error.message.includes('exceed') ? 400
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

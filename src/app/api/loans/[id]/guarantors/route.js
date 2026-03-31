import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { getLoanGuarantors, addGuarantor, removeGuarantor } from '@/lib/loan-service.js';

// GET /api/loans/[id]/guarantors — List guarantors for a loan
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const guarantors = await getLoanGuarantors(id);
    return NextResponse.json({ success: true, data: guarantors });
  } catch (error) {
    console.error('[Guarantors] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/loans/[id]/guarantors — Add a guarantor
export async function POST(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { guarantor_member_id, guaranteed_amount } = body;

    if (!guarantor_member_id || !guaranteed_amount) {
      return NextResponse.json({
        success: false,
        error: 'guarantor_member_id and guaranteed_amount are required',
      }, { status: 400 });
    }

    const result = await addGuarantor({
      loanId: id,
      guarantorMemberId: guarantor_member_id,
      guaranteedAmount: parseFloat(guaranteed_amount),
      userId: perm.userId,
    });

    return NextResponse.json({ success: true, data: result }, { status: 201 });
  } catch (error) {
    console.error('[Guarantors] POST error:', error.message);
    const status = error.message.includes('not found') ? 404
      : error.message.includes('only add') || error.message.includes('Cannot') ? 400
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

// DELETE /api/loans/[id]/guarantors — Remove a guarantor (body: { guarantor_id })
export async function DELETE(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;
    const body = await request.json();
    const { guarantor_id } = body;

    if (!guarantor_id) {
      return NextResponse.json({ success: false, error: 'guarantor_id is required' }, { status: 400 });
    }

    const result = await removeGuarantor({ loanId: id, guarantorId: guarantor_id });
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    const status = error.message.includes('not found') ? 404 : error.message.includes('only remove') ? 400 : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

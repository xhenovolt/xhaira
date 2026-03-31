import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/loans/[id] — Loan detail with schedule, guarantors, disbursement info
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    const [loanResult, scheduleResult, guarantorResult] = await Promise.all([
      query(
        `SELECT l.*, m.full_name as member_name, m.membership_number,
           p.name as product_name, p.product_type,
           ma.account_number as member_account_number,
           u.email as approved_by_email
         FROM loans l
         JOIN members m ON m.id = l.member_id
         LEFT JOIN products p ON p.id = l.product_id
         LEFT JOIN member_accounts ma ON ma.id = l.member_account_id
         LEFT JOIN users u ON u.id = l.approved_by
         WHERE l.id = $1`,
        [id]
      ),
      query(
        `SELECT * FROM loan_schedules WHERE loan_id = $1 ORDER BY installment_number ASC`,
        [id]
      ),
      query(
        `SELECT lg.*, m.full_name, m.membership_number
         FROM loan_guarantors lg
         JOIN members m ON lg.guarantor_member_id = m.id
         WHERE lg.loan_id = $1 ORDER BY lg.created_at`,
        [id]
      ),
    ]);

    if (loanResult.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Loan not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      data: {
        ...loanResult.rows[0],
        schedule: scheduleResult.rows,
        guarantors: guarantorResult.rows,
      },
    });
  } catch (error) {
    console.error('[Loan Detail] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

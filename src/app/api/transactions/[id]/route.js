import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/transactions/[id] — Get transaction with all ledger entries
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { id } = await params;

    const [txResult, entriesResult] = await Promise.all([
      query(
        `SELECT t.*, u.email as created_by_email
         FROM transactions t
         LEFT JOIN users u ON t.created_by = u.id
         WHERE t.id = $1`,
        [id]
      ),
      query(
        `SELECT le.*, 
           ma.account_number as member_account_number, ma.account_type as member_account_type,
           a.name as account_name, a.type as system_account_type
         FROM ledger_entries le
         LEFT JOIN member_accounts ma ON le.member_account_id = ma.id
         LEFT JOIN accounts a ON le.account_id = a.id
         WHERE le.transaction_id = $1
         ORDER BY le.entry_type, le.created_at`,
        [id]
      ),
    ]);

    if (txResult.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Transaction not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      data: {
        ...txResult.rows[0],
        entries: entriesResult.rows,
      },
    });
  } catch (error) {
    console.error('[Transaction Detail] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

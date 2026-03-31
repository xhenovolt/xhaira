import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';
import { createTransaction, deposit, withdraw } from '@/lib/transaction-service.js';

// GET /api/transactions — List transactions with pagination
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type') || '';
    const memberAccountId = searchParams.get('member_account_id') || '';
    const accountId = searchParams.get('account_id') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '50')));
    const offset = (page - 1) * limit;

    let where = 'WHERE 1=1';
    const params = [];

    if (type) {
      params.push(type);
      where += ` AND t.transaction_type = $${params.length}`;
    }

    if (memberAccountId) {
      params.push(memberAccountId);
      where += ` AND t.id IN (SELECT transaction_id FROM ledger_entries WHERE member_account_id = $${params.length})`;
    }

    if (accountId) {
      params.push(accountId);
      where += ` AND t.id IN (SELECT transaction_id FROM ledger_entries WHERE account_id = $${params.length})`;
    }

    const countParams = [...params];
    params.push(limit, offset);

    const [dataResult, countResult] = await Promise.all([
      query(
        `SELECT t.*, u.email as created_by_email,
           json_agg(json_build_object(
             'id', le.id, 'entry_type', le.entry_type, 'amount', le.amount,
             'account_id', le.account_id, 'member_account_id', le.member_account_id,
             'description', le.description
           ) ORDER BY le.entry_type) as entries
         FROM transactions t
         LEFT JOIN users u ON t.created_by = u.id
         LEFT JOIN ledger_entries le ON le.transaction_id = t.id
         ${where}
         GROUP BY t.id, u.email
         ORDER BY t.created_at DESC
         LIMIT $${params.length - 1} OFFSET $${params.length}`,
        params
      ),
      query(`SELECT COUNT(*) as total FROM transactions t ${where}`, countParams),
    ]);

    return NextResponse.json({
      success: true,
      data: dataResult.rows,
      pagination: {
        page, limit,
        total: parseInt(countResult.rows[0]?.total || 0),
        totalPages: Math.ceil(parseInt(countResult.rows[0]?.total || 0) / limit),
      },
    });
  } catch (error) {
    console.error('[Transactions] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/transactions — Create a transaction (deposit, withdrawal, or custom)
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { action, member_account_id, account_id, amount, description, reference, entries, transaction_type, metadata } = body;

    if (!amount && !entries) {
      return NextResponse.json({ success: false, error: 'amount or entries required' }, { status: 400 });
    }

    let result;

    // Shorthand actions
    if (action === 'deposit') {
      if (!member_account_id || !amount) {
        return NextResponse.json({ success: false, error: 'member_account_id and amount required for deposit' }, { status: 400 });
      }
      result = await deposit({
        memberAccountId: member_account_id,
        amount: parseFloat(amount),
        description,
        reference,
        userId: perm.userId,
      });
    } else if (action === 'withdraw') {
      if (!member_account_id || !amount) {
        return NextResponse.json({ success: false, error: 'member_account_id and amount required for withdrawal' }, { status: 400 });
      }
      result = await withdraw({
        memberAccountId: member_account_id,
        amount: parseFloat(amount),
        description,
        reference,
        userId: perm.userId,
      });
    } else if (entries) {
      // Custom double-entry transaction
      result = await createTransaction({
        description: description || 'Manual transaction',
        transaction_type: transaction_type || 'adjustment',
        reference,
        metadata,
        userId: perm.userId,
        entries: entries.map(e => ({
          ...e,
          amount: parseFloat(e.amount),
        })),
      });
    } else {
      return NextResponse.json({ success: false, error: 'Specify action (deposit/withdraw) or provide entries array' }, { status: 400 });
    }

    return NextResponse.json({ success: true, data: result }, { status: 201 });
  } catch (error) {
    console.error('[Transactions] POST error:', error.message);
    const status = error.message.includes('Insufficient balance') ? 400
      : error.message.includes('not balanced') ? 400
      : error.message.includes('not found') ? 404
      : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

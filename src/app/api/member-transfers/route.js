import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';
import { transfer } from '@/lib/transaction-service.js';
import { validateTransfer } from '@/lib/rule-engine.js';

// GET /api/member-transfers — List member-to-member transfers
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get('member_id');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);
    const offset = (page - 1) * limit;

    let whereClause = `WHERE t.transaction_type = 'transfer'`;
    const params = [];

    if (memberId) {
      params.push(memberId);
      whereClause += ` AND (sender_ma.member_id = $${params.length} OR receiver_ma.member_id = $${params.length})`;
    }

    params.push(limit, offset);

    const result = await query(
      `SELECT t.id, t.reference, t.description, t.metadata, t.created_at,
              sender_le.amount,
              sender_ma.id as sender_account_id, sender_ma.account_number as sender_account,
              sender_m.id as sender_id, sender_m.full_name as sender_name,
              receiver_ma.id as receiver_account_id, receiver_ma.account_number as receiver_account,
              receiver_m.id as receiver_id, receiver_m.full_name as receiver_name
       FROM transactions t
       JOIN ledger_entries sender_le ON sender_le.transaction_id = t.id AND sender_le.entry_type = 'DEBIT' AND sender_le.member_account_id IS NOT NULL
       JOIN ledger_entries receiver_le ON receiver_le.transaction_id = t.id AND receiver_le.entry_type = 'CREDIT' AND receiver_le.member_account_id IS NOT NULL
       LEFT JOIN member_accounts sender_ma ON sender_le.member_account_id = sender_ma.id
       LEFT JOIN members sender_m ON sender_ma.member_id = sender_m.id
       LEFT JOIN member_accounts receiver_ma ON receiver_le.member_account_id = receiver_ma.id
       LEFT JOIN members receiver_m ON receiver_ma.member_id = receiver_m.id
       ${whereClause}
       ORDER BY t.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return NextResponse.json({ success: true, data: result.rows, pagination: { page, limit } });
  } catch (error) {
    console.error('[Member Transfers] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/member-transfers — Execute a member-to-member transfer
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { sender_account_id, receiver_account_id, amount, description } = body;

    if (!sender_account_id || !receiver_account_id || !amount) {
      return NextResponse.json({
        success: false,
        error: 'sender_account_id, receiver_account_id, and amount are required',
      }, { status: 400 });
    }

    const parsedAmount = parseFloat(amount);
    if (parsedAmount <= 0) {
      return NextResponse.json({ success: false, error: 'Amount must be positive' }, { status: 400 });
    }

    // Get sender + receiver member info
    const senderAcct = await query(
      `SELECT ma.member_id, m.full_name as name
       FROM member_accounts ma JOIN members m ON ma.member_id = m.id
       WHERE ma.id = $1`, [sender_account_id]
    );
    if (senderAcct.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Sender account not found' }, { status: 404 });
    }

    const receiverAcct = await query(
      `SELECT ma.member_id, m.full_name as name
       FROM member_accounts ma JOIN members m ON ma.member_id = m.id
       WHERE ma.id = $1`, [receiver_account_id]
    );
    if (receiverAcct.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Receiver account not found' }, { status: 404 });
    }

    // Validate against SACCO rules
    const validation = await validateTransfer(
      senderAcct.rows[0].member_id,
      receiverAcct.rows[0].member_id,
      sender_account_id,
      parsedAmount
    );

    if (!validation.valid) {
      return NextResponse.json({
        success: false,
        error: 'Transfer validation failed',
        details: validation.issues,
      }, { status: 400 });
    }

    const result = await transfer({
      senderAccountId: sender_account_id,
      receiverAccountId: receiver_account_id,
      amount: parsedAmount,
      description: description || `Transfer: ${senderAcct.rows[0].name} → ${receiverAcct.rows[0].name}`,
      userId: perm.userId,
    });

    return NextResponse.json({ success: true, data: result }, { status: 201 });
  } catch (error) {
    console.error('[Member Transfers] POST error:', error.message);
    const status = error.message.includes('Insufficient') || error.message.includes('same account') ? 400
      : error.message.includes('not found') ? 404 : 500;
    return NextResponse.json({ success: false, error: error.message }, { status });
  }
}

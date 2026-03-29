import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { requirePermission } from '@/lib/permissions.js';

export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;
    const { id } = await params;
    const result = await query(`SELECT * FROM v_account_balances WHERE account_id = $1`, [id]);
    if (!result.rows[0]) return NextResponse.json({ success: false, error: 'Account not found' }, { status: 404 });
    
    // Also get recent transactions
    const transactions = await query(
      `SELECT * FROM ledger WHERE account_id = $1 ORDER BY entry_date DESC, created_at DESC LIMIT 50`, [id]
    );
    
    return NextResponse.json({ success: true, data: { ...result.rows[0], transactions: transactions.rows } });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to fetch account' }, { status: 500 });
  }
}

export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.create');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;
    const { id } = await params;
    const body = await request.json();
    const fields = ['name','type','currency','description','institution','account_number','is_active','status','account_type'];
    const updates = [];
    const values = [];
    fields.forEach(f => { if (body[f] !== undefined) { values.push(body[f]); updates.push(`${f} = $${values.length}`); } });
    if (updates.length === 0) return NextResponse.json({ success: false, error: 'No fields to update' }, { status: 400 });
    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);
    const result = await query(`UPDATE accounts SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`, values);
    if (!result.rows[0]) return NextResponse.json({ success: false, error: 'Account not found' }, { status: 404 });
    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to update account' }, { status: 500 });
  }
}

export async function PATCH(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.create');
    if (perm instanceof NextResponse) return perm;
    const { id } = await params;
    const body = await request.json();
    const { action, ...updates } = body;
    
    let result;
    
    if (action === 'suspend') {
      result = await query(
        `UPDATE accounts SET status = 'suspended', updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *`,
        [id]
      );
    } else if (action === 'activate') {
      result = await query(
        `UPDATE accounts SET status = 'active', updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *`,
        [id]
      );
    } else {
      // Regular PATCH update
      const fields = Object.keys(updates);
      if (fields.length === 0) return NextResponse.json({ success: false, error: 'No fields to update' }, { status: 400 });
      const values = Object.values(updates);
      values.push(id);
      const updateStmt = fields.map((f, i) => `${f} = $${i + 1}`).join(', ');
      result = await query(
        `UPDATE accounts SET ${updateStmt}, updated_at = CURRENT_TIMESTAMP WHERE id = $${values.length} RETURNING *`,
        values
      );
    }
    
    if (!result.rows[0]) return NextResponse.json({ success: false, error: 'Account not found' }, { status: 404 });
    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to patch account: ' + error.message }, { status: 500 });
  }
}

export async function DELETE(request, { params }) {
  try {
    const perm = await requirePermission(request, 'finance.delete');
    if (perm instanceof NextResponse) return perm;
    const { id } = await params;
    
    // Check for dependencies
    const deps = await query(
      `SELECT COUNT(*) as count FROM salary_accounts WHERE account_id = $1`,
      [id]
    );
    
    if (deps.rows[0].count > 0) {
      return NextResponse.json(
        { success: false, error: 'Cannot delete account with linked salary accounts' }, 
        { status: 409 }
      );
    }
    
    // Soft delete by suspending
    const result = await query(
      `UPDATE accounts SET status = 'closed', updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *`,
      [id]
    );
    
    if (!result.rows[0]) return NextResponse.json({ success: false, error: 'Account not found' }, { status: 404 });
    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to delete account: ' + error.message }, { status: 500 });
  }
}

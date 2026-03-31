import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { requirePermission, hasPermission } from '@/lib/permissions.js';
import { sanitizeSystemDetail } from '@/lib/rbac.js';

// GET /api/products/[id]
export async function GET(request, { params }) {
  try {
    const perm = await requirePermission(request, 'products', 'view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { id } = await params;

    const [systemRes, issuesRes, changesRes, dealsRes, licensesRes] = await Promise.all([
      query(`SELECT * FROM systems WHERE id = $1`, [id]),
      query(`SELECT * FROM system_issues WHERE system_id = $1 ORDER BY reported_at DESC`, [id]),
      query(`SELECT * FROM system_changes WHERE system_id = $1 ORDER BY created_at DESC`, [id]),
      query(`
        SELECT d.*,
          COALESCE(c.company_name, d.client_name, 'Unknown') as client_label,
          COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.deal_id = d.id AND p.status = 'completed'), 0) as paid_amount,
          d.total_amount - COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.deal_id = d.id AND p.status = 'completed'), 0) as remaining_amount
        FROM deals d
        LEFT JOIN clients c ON d.client_id = c.id
        WHERE d.system_id = $1
        ORDER BY d.created_at DESC
      `, [id]),
      query(`SELECT * FROM licenses WHERE system_id = $1 ORDER BY created_at DESC`, [id]),
    ]);

    if (systemRes.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Product not found' }, { status: 404 });
    }

    const product = systemRes.rows[0];
    const deals = dealsRes.rows;
    product.total_revenue = deals.reduce((s, d) => s + parseFloat(d.total_amount || 0), 0);
    product.total_paid = deals.reduce((s, d) => s + parseFloat(d.paid_amount || 0), 0);

    let responseData = {
      ...product,
      issues: issuesRes.rows,
      changes: changesRes.rows,
      deals,
      licenses: licensesRes.rows,
    };

    // Backend enforcement: strip financial fields for users without finance.view
    const hasFinanceAccess = await hasPermission(auth.userId, 'finance', 'view', auth.role);
    if (!hasFinanceAccess) {
      responseData = sanitizeSystemDetail(responseData);
    }

    return NextResponse.json({ success: true, data: responseData });
  } catch (error) {
    console.error('[Products/id] GET error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch product' }, { status: 500 });
  }
}

// PUT /api/products/[id]
export async function PUT(request, { params }) {
  try {
    const perm = await requirePermission(request, 'products', 'edit');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { id } = await params;
    const body = await request.json();
    const {
      name, description, version, status, product_type,
      interest_rate, duration_months, min_amount, max_amount,
      requires_approval, upfront_amount, return_rate,
      billing_frequency, currency, price,
    } = body;

    const result = await query(
      `UPDATE systems SET
        name=$1, description=$2, version=$3, status=$4, product_type=COALESCE($5, product_type),
        interest_rate=$6, duration_months=$7, min_amount=$8, max_amount=$9,
        requires_approval=COALESCE($10, requires_approval), upfront_amount=$11, return_rate=$12,
        billing_frequency=$13, currency=COALESCE($14, currency), price=$15,
        updated_at=NOW()
      WHERE id=$16 RETURNING *`,
      [
        name, description || null, version || null, status || 'active', product_type || null,
        interest_rate || null, duration_months || null, min_amount || null, max_amount || null,
        requires_approval, upfront_amount || null, return_rate || null,
        billing_frequency || null, currency || null, price || null,
        id,
      ]
    );

    if (result.rows.length === 0) return NextResponse.json({ success: false, error: 'Product not found' }, { status: 404 });
    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Products/id] PUT error:', error);
    return NextResponse.json({ success: false, error: 'Failed to update product' }, { status: 500 });
  }
}

// DELETE /api/products/[id]
export async function DELETE(request, { params }) {
  try {
    const perm = await requirePermission(request, 'products', 'delete');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { id } = await params;
    await query(`DELETE FROM systems WHERE id = $1`, [id]);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('[Products/id] DELETE error:', error);
    return NextResponse.json({ success: false, error: 'Failed to delete product' }, { status: 500 });
  }
}

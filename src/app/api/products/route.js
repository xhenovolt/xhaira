import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { requirePermission, hasPermission } from '@/lib/permissions.js';
import { Events } from '@/lib/events.js';
import { sanitizeSystemRecord } from '@/lib/rbac.js';
import { validateProduct, PRODUCT_TYPE_KEYS } from '@/lib/product-types.js';

// GET /api/products
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'products', 'view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const productType = searchParams.get('product_type');

    let sql = `
      SELECT s.*,
        (SELECT COUNT(*) FROM system_issues si WHERE si.system_id = s.id) as issue_count,
        (SELECT COUNT(*) FROM system_issues si WHERE si.system_id = s.id AND si.status = 'open') as open_issues,
        (SELECT COUNT(*) FROM system_changes sc WHERE sc.system_id = s.id) as change_count,
        (SELECT COUNT(*) FROM licenses l WHERE l.system_id = s.id AND l.status = 'active') as active_licenses,
        (SELECT COUNT(*) FROM deals d WHERE d.system_id = s.id) as deal_count,
        COALESCE((SELECT SUM(d.total_amount) FROM deals d WHERE d.system_id = s.id), 0) as total_revenue
      FROM systems s
      WHERE 1=1
    `;
    const params = [];
    if (status) { params.push(status); sql += ` AND s.status = $${params.length}`; }
    if (productType && PRODUCT_TYPE_KEYS.includes(productType)) {
      params.push(productType);
      sql += ` AND s.product_type = $${params.length}`;
    }
    sql += ` ORDER BY s.created_at DESC`;

    const result = await query(sql, params);

    // Backend enforcement: strip financial fields for users without finance.view
    const hasFinanceAccess = await hasPermission(auth.userId, 'finance', 'view', auth.role);
    const data = hasFinanceAccess ? result.rows : result.rows.map(sanitizeSystemRecord);

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('[Products] GET error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch products' }, { status: 500 });
  }
}

// POST /api/products
export async function POST(request) {
  try {
    const auth = await verifyAuth(request);
    if (!auth) return NextResponse.json({ success: false, error: 'Authentication required' }, { status: 401 });

    const body = await request.json();
    const {
      name, description, version, status, product_type,
      interest_rate, duration_months, min_amount, max_amount,
      requires_approval, upfront_amount, return_rate,
      billing_frequency, currency, price,
    } = body;

    // Validate using product-types engine
    const errors = validateProduct(body);
    if (errors.length > 0) {
      return NextResponse.json({ success: false, error: errors[0], errors }, { status: 400 });
    }

    const result = await query(
      `INSERT INTO systems (
        name, description, version, status, product_type,
        interest_rate, duration_months, min_amount, max_amount,
        requires_approval, upfront_amount, return_rate,
        billing_frequency, currency, price
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
      [
        name,
        description || null,
        version || null,
        status || 'active',
        product_type || 'SERVICE',
        interest_rate || null,
        duration_months || null,
        min_amount || null,
        max_amount || null,
        requires_approval || false,
        upfront_amount || null,
        return_rate || null,
        billing_frequency || null,
        currency || 'UGX',
        price || null,
      ]
    );

    await Events.productCreated(result.rows[0].id, result.rows[0].name, product_type || 'SERVICE', auth.userId);
    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    console.error('[Products] POST error:', error);
    return NextResponse.json({ success: false, error: 'Failed to create product' }, { status: 500 });
  }
}

// DELETE /api/products?id=xxx
export async function DELETE(request) {
  try {
    const auth = await verifyAuth(request);
    if (!auth) return NextResponse.json({ success: false, error: 'Authentication required' }, { status: 401 });

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ success: false, error: 'id required' }, { status: 400 });

    await query(`DELETE FROM systems WHERE id=$1`, [id]);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('[Products] DELETE error:', error);
    return NextResponse.json({ success: false, error: 'Failed to delete product' }, { status: 500 });
  }
}

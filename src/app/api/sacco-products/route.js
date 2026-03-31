import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/sacco-products — List SACCO financial products
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'products.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type') || '';
    const active = searchParams.get('active');

    let where = 'WHERE 1=1';
    const params = [];

    if (type) {
      params.push(type);
      where += ` AND product_type = $${params.length}`;
    }
    if (active !== null && active !== '') {
      params.push(active === 'true');
      where += ` AND is_active = $${params.length}`;
    }

    const result = await query(
      `SELECT * FROM products ${where} ORDER BY created_at DESC`, params
    );

    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[SACCO Products] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/sacco-products — Create a SACCO financial product
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'products.create');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const {
      name, description, product_type, price, currency,
      interest_rate, duration, repayment_cycle,
      min_amount, max_amount, requires_approval, metadata,
    } = body;

    if (!name || !product_type) {
      return NextResponse.json({ success: false, error: 'name and product_type are required' }, { status: 400 });
    }

    const validTypes = ['LOAN', 'SAVINGS', 'INVESTMENT', 'INSTALLMENT', 'SERVICE', 'SHARES', 'FIXED_DEPOSIT'];
    if (!validTypes.includes(product_type)) {
      return NextResponse.json({
        success: false,
        error: `Invalid product_type. Must be one of: ${validTypes.join(', ')}`,
      }, { status: 400 });
    }

    const result = await query(
      `INSERT INTO products (name, description, product_type, price, currency, interest_rate, duration, repayment_cycle, min_amount, max_amount, requires_approval, metadata, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [
        name, description || null, product_type,
        price || null, currency || 'UGX',
        interest_rate || null, duration || null, repayment_cycle || null,
        min_amount || null, max_amount || null,
        requires_approval !== false,
        JSON.stringify(metadata || {}),
        perm.userId,
      ]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    console.error('[SACCO Products] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

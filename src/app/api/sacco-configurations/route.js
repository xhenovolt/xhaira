import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/sacco-configurations — List all SACCO configuration toggles
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');

    let sql = `SELECT * FROM sacco_configurations ORDER BY category, config_key`;
    const params = [];
    if (category) {
      sql = `SELECT * FROM sacco_configurations WHERE category = $1 ORDER BY config_key`;
      params.push(category);
    }

    const result = await query(sql, params);
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[Config] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/sacco-configurations — Upsert a configuration value
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const body = await request.json();
    const { config_key, config_value, label, description, config_type, category } = body;

    if (!config_key) {
      return NextResponse.json({ success: false, error: 'config_key is required' }, { status: 400 });
    }

    const result = await query(
      `INSERT INTO sacco_configurations (config_key, config_value, label, description, config_type, category, updated_by)
       VALUES ($1, $2::jsonb, $3, $4, $5, $6, $7)
       ON CONFLICT (config_key) DO UPDATE SET
         config_value = EXCLUDED.config_value,
         label = COALESCE(EXCLUDED.label, sacco_configurations.label),
         description = COALESCE(EXCLUDED.description, sacco_configurations.description),
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [
        config_key,
        JSON.stringify(config_value !== undefined ? config_value : true),
        label || null,
        description || null,
        config_type || 'boolean',
        category || 'general',
        auth?.userId || null,
      ]
    );

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('[Config] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

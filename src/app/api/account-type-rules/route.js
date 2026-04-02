/**
 * GET  /api/account-type-rules   — list all rules (optionally by account_type_id)
 * POST /api/account-type-rules   — create or upsert a rule
 */

import { NextResponse } from 'next/server';
import { query }         from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';

export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const { searchParams } = new URL(request.url);
    const accountTypeId = searchParams.get('account_type_id') || '';

    let sql    = `SELECT r.*, at.name AS account_type_name, at.code AS account_type_code
                  FROM account_type_rules r
                  JOIN account_types at ON at.id = r.account_type_id`;
    const params = [];

    if (accountTypeId) {
      params.push(accountTypeId);
      sql += ` WHERE r.account_type_id = $${params.length}`;
    }

    sql += ` ORDER BY at.name, r.rule_key`;

    const result = await query(sql, params);
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('[AccountTypeRules] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { account_type_id, rule_key, rule_value, description, is_enabled = true } = body;

    if (!account_type_id || !rule_key || rule_value === undefined) {
      return NextResponse.json(
        { success: false, error: 'account_type_id, rule_key, and rule_value are required' },
        { status: 400 }
      );
    }

    // Upsert — if rule already exists for this type+key, update it
    const result = await query(
      `INSERT INTO account_type_rules
         (account_type_id, rule_key, rule_value, description, is_enabled, created_by)
       VALUES ($1, $2, $3::JSONB, $4, $5, $6)
       ON CONFLICT (account_type_id, rule_key)
       DO UPDATE SET
         rule_value  = EXCLUDED.rule_value,
         description = COALESCE(EXCLUDED.description, account_type_rules.description),
         is_enabled  = EXCLUDED.is_enabled,
         updated_at  = NOW()
       RETURNING *`,
      [
        account_type_id,
        rule_key,
        JSON.stringify(rule_value),
        description || null,
        is_enabled,
        perm.userId || null,
      ]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    console.error('[AccountTypeRules] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

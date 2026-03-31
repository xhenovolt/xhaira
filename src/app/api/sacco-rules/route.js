import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { getAllRules, setRule } from '@/lib/rule-engine.js';

// GET /api/sacco-rules — List all SACCO rules
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'finance.view');
    if (perm instanceof NextResponse) return perm;

    const rules = await getAllRules();
    return NextResponse.json({ success: true, data: rules });
  } catch (error) {
    console.error('[SACCO Rules] GET error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/sacco-rules — Create or update a rule
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'finance.manage');
    if (perm instanceof NextResponse) return perm;

    const body = await request.json();
    const { rule_type, rule_key, rule_value, description } = body;

    if (!rule_type || !rule_key || !rule_value) {
      return NextResponse.json({
        success: false,
        error: 'rule_type, rule_key, and rule_value are required',
      }, { status: 400 });
    }

    const validTypes = ['LOAN', 'ACCOUNT', 'GUARANTOR', 'TRANSFER'];
    if (!validTypes.includes(rule_type)) {
      return NextResponse.json({
        success: false,
        error: `Invalid rule_type. Must be one of: ${validTypes.join(', ')}`,
      }, { status: 400 });
    }

    const rule = await setRule(rule_type, rule_key, rule_value, description);
    return NextResponse.json({ success: true, data: rule }, { status: 201 });
  } catch (error) {
    console.error('[SACCO Rules] POST error:', error.message);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

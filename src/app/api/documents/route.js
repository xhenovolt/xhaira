import { NextResponse } from 'next/server';
import { query } from '@/lib/db.js';
import { verifyAuth } from '@/lib/auth-utils.js';
import { requirePermission } from '@/lib/permissions.js';

// GET /api/documents — List documents with filtering
export async function GET(request) {
  try {
    const perm = await requirePermission(request, 'documents.view');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const entity_type = searchParams.get('entity_type');
    const entity_id = searchParams.get('entity_id');
    const search = searchParams.get('search');

    let sql = `SELECT * FROM documents WHERE 1=1`;
    const params = [];
    if (category) { params.push(category); sql += ` AND category = $${params.length}`; }
    if (entity_type) { params.push(entity_type); sql += ` AND entity_type = $${params.length}`; }
    if (entity_id) { params.push(entity_id); sql += ` AND entity_id = $${params.length}`; }
    if (search) { params.push(`%${search}%`); sql += ` AND (title ILIKE $${params.length} OR description ILIKE $${params.length})`; }
    sql += ` ORDER BY created_at DESC`;

    const result = await query(sql, params);

    // Category counts
    const counts = await query(`SELECT category, COUNT(*) as count FROM documents GROUP BY category`);

    return NextResponse.json({ success: true, data: result.rows, categories: counts.rows });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to fetch documents' }, { status: 500 });
  }
}

// POST /api/documents — Add document record
export async function POST(request) {
  try {
    const perm = await requirePermission(request, 'documents.manage');
    if (perm instanceof NextResponse) return perm;
    const { auth } = perm;

    const body = await request.json();
    const { title, category, entity_type, entity_id, file_url, file_name, description, tags } = body;
    if (!title) return NextResponse.json({ success: false, error: 'title required' }, { status: 400 });

    const result = await query(
      `INSERT INTO documents (title, category, entity_type, entity_id, file_url, file_name, uploaded_by, description, tags)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [title, category || 'general', entity_type || null, entity_id || null, file_url || null, file_name || null, auth.userId, description || null, tags || null]
    );

    return NextResponse.json({ success: true, data: result.rows[0] }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to add document' }, { status: 500 });
  }
}

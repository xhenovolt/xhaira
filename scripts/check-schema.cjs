const { Pool } = require('pg');
const p = new Pool({ connectionString: 'postgresql://neondb_owner:npg_HExwNUY6aVP9@ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech/jeton?sslmode=require', ssl: { rejectUnauthorized: false } });

async function main() {
  const r = await p.query("SELECT column_name FROM information_schema.columns WHERE table_name='roles' ORDER BY ordinal_position");
  console.log('ROLES COLS:', r.rows.map(x => x.column_name).join(', '));
  
  const d = await p.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name='departments'");
  console.log('DEPARTMENTS EXISTS:', d.rows.length > 0);
  
  // Check what tables were created from the migration so far  
  const t = await p.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('invoices','invoice_sequences','documents','tech_stack_entries','bug_reports','feature_requests','developer_activity','capital_allocation_rules','revenue_events','revenue_allocations','budget_targets','departments','employees','performance_metrics','knowledge_articles') ORDER BY table_name");
  console.log('NEW TABLES:', t.rows.map(x => x.table_name).join(', '));
  
  await p.end();
}
main().catch(e => { console.error(e.message); p.end(); });

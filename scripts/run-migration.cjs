const { Pool } = require('pg');
const fs = require('fs');
const pool = new Pool({ connectionString: 'postgresql://neondb_owner:npg_HExwNUY6aVP9@ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech/jeton?sslmode=require', ssl: { rejectUnauthorized: false } });

async function main() {
  const sql = fs.readFileSync('./migrations/500_invoice_and_intelligence.sql', 'utf8');
  try {
    await pool.query(sql);
    console.log('OK migration 500 applied successfully');
  } catch (e) {
    console.error('ERR:', e.message);
  } finally {
    await pool.end();
  }
}
main();

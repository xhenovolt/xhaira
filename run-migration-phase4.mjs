#!/usr/bin/env node

// Phase 4 Migration Runner - Create Missing Tables
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import pkg from 'pg';
const { Client } = pkg;

const __dirname = dirname(fileURLToPath(import.meta.url));

async function runMigration() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('✅ Connected to Xhaira database');

    // Read migration file
    const migrationSQL = readFileSync(join(__dirname, 'migrations', '001_create_missing_tables.sql'), 'utf-8');
    
    // Split into statements (simple approach - may need refinement for complex SQL)
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`\n📝 Executing ${statements.length} SQL statements...\n`);

    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];
      try {
        const result = await client.query(stmt);
        
        // Check for informational results
        if (result.rows && result.rows.length > 0) {
          console.log(`✅ Statement ${i + 1}:`);
          console.log(result.rows[0]);
        } else if (result.rowCount !== null) {
          console.log(`✅ Statement ${i + 1}: OK (${result.rowCount} rows affected)`);
        } else {
          console.log(`✅ Statement ${i + 1}: OK`);
        }
      } catch (err) {
        console.error(`❌ Statement ${i + 1} FAILED:`);
        console.error(`SQL: ${stmt.substring(0, 100)}...`);
        console.error(`Error: ${err.message}`);
        throw err;
      }
    }

    console.log('\n✅ ALL MIGRATIONS COMPLETED SUCCESSFULLY\n');

    // Verify tables exist
    console.log('🔍 Verifying created tables...\n');
    const verifySQL = `
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user_presence', 'permissions', 'role_permissions', 'staff_roles', 'approval_requests')
      ORDER BY table_name;
    `;
    
    const result = await client.query(verifySQL);
    console.log('Created tables:');
    result.rows.forEach(row => console.log(`  ✅ ${row.table_name}`));
    
    if (result.rows.length < 5) {
      console.warn(`\n⚠️  Only ${result.rows.length} of 5 tables created. Check for errors above.`);
    } else {
      console.log('\n✅ All 5 tables verified in database!');
    }

  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();

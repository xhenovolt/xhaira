#!/usr/bin/env node

/**
 * Setup User & Access Governance System
 * Runs the database migration and initializes default roles/permissions
 * Usage: node scripts/setup-governance.js
 */

import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import fs from 'fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.join(__dirname, '../.env.local');
dotenv.config({ path: envPath });

const { Pool } = pg;

async function setupGovernance() {
  const connectionString = process.env.DATABASE_URL;

  if (!connectionString) {
    console.error('❌ DATABASE_URL environment variable is not set');
    process.exit(1);
  }

  const pool = new Pool({ connectionString });

  try {
    console.log('🚀 Setting up User & Access Governance System...\n');
    const client = await pool.connect();

    try {
      // Read and execute migration
      console.log('📝 Applying database migration...');
      const migrationPath = path.join(__dirname, '../migrations/015_user_access_governance.sql');
      
      if (!fs.existsSync(migrationPath)) {
        throw new Error(
          `Migration file not found: ${migrationPath}`
        );
      }

      const migrationSQL = fs.readFileSync(migrationPath, 'utf-8');
      
      // Execute migration (split by ; to handle multiple statements)
      const statements = migrationSQL
        .split(';')
        .map((s) => s.trim())
        .filter((s) => s.length > 0 && !s.startsWith('--'));

      for (const statement of statements) {
        try {
          await client.query(statement);
        } catch (err) {
          // Ignore "already exists" errors
          if (!err.message.includes('already exists')) {
            throw err;
          }
        }
      }

      console.log('✅ Database migration applied\n');

      // Verify roles exist
      console.log('🔐 Verifying system roles...');
      const rolesResult = await client.query('SELECT COUNT(*) as count FROM roles');
      console.log(`✅ Found ${rolesResult.rows[0].count} roles\n`);

      // Verify superadmin
      console.log('👤 Verifying superadmin...');
      const superadminCheck = await client.query(
        "SELECT email, is_superadmin FROM users WHERE email = 'xhenonpro@gmail.com'"
      );

      if (superadminCheck.rowCount === 0) {
        console.log('⚠️  Superadmin user not found. Creating...');
        // Note: In production, password would be set via registration or reset flow
        const tempPassword = 'ChangeMe123!';
        
        // For this script, we'll just note that manual setup is needed
        console.log(`
📌 MANUAL SETUP REQUIRED:

  The superadmin account (xhenonpro@gmail.com) was not found in the database.
  
  Please create it using one of these methods:
  
  1. Via Registration Form:
     - Go to /register
     - Sign up with email: xhenonpro@gmail.com
     - Then run: node scripts/promote-superadmin.js
  
  2. Via Direct Database:
     - Insert user via /api/auth/register first
     - Then promote via /api/auth/promote-superadmin
  
  3. Via Manual Query (advanced):
     psql $DATABASE_URL << 'EOF'
     UPDATE users SET is_superadmin = true
     WHERE email = 'xhenonpro@gmail.com';
     
     INSERT INTO user_roles (user_id, role_id, assigned_by_id)
     SELECT u.id, r.id, u.id FROM users u, roles r
     WHERE u.email = 'xhenonpro@gmail.com' AND r.name = 'superadmin'
     ON CONFLICT DO NOTHING;
     EOF
        `);
      } else {
        console.log('✅ Superadmin verified\n');
      }

      // Summary
      console.log('📊 Governance System Status:\n');
      
      const usersCount = await client.query('SELECT COUNT(*) as count FROM users');
      const rolesCount = await client.query('SELECT COUNT(*) as count FROM roles');
      const permissionsCount = await client.query('SELECT COUNT(*) as count FROM permissions');
      const sessionsCount = await client.query('SELECT COUNT(*) as count FROM sessions');
      const auditCount = await client.query('SELECT COUNT(*) as count FROM audit_logs');

      console.log(`  Users:        ${usersCount.rows[0].count}`);
      console.log(`  Roles:        ${rolesCount.rows[0].count}`);
      console.log(`  Permissions:  ${permissionsCount.rows[0].count}`);
      console.log(`  Sessions:     ${sessionsCount.rows[0].count}`);
      console.log(`  Audit Logs:   ${auditCount.rows[0].count}\n`);

      console.log('✅ Setup Complete!\n');
      console.log('🎉 Next steps:\n');
      console.log('  1. Access admin panel: http://localhost:3000/admin/users');
      console.log('  2. Log in with superadmin account (xhenonpro@gmail.com)');
      console.log('  3. Create new users and assign roles\n');
      console.log('📖 Documentation: See ENTERPRISE_USER_GOVERNANCE_GUIDE.md\n');

    } finally {
      client.release();
    }
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

setupGovernance();

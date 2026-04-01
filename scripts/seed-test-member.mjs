/**
 * Seed test member: WEKESA MUHAMMAD
 * wekesamuhammad@gmail.com / wekesa123
 */

import 'dotenv/config';
import pg from 'pg';
const { Pool } = pg;

// Load from .env.local  
import { readFileSync } from 'fs';
try {
  const envLocal = readFileSync('.env.local', 'utf8');
  envLocal.split('\n').forEach(line => {
    const m = line.match(/^([^=]+)=(.*)$/);
    if (m) {
      const key = m[1].trim();
      const val = m[2].trim().replace(/^['"]|['"]$/g, '');
      if (!process.env[key]) process.env[key] = val;
    }
  });
} catch {}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if member already exists
    const existing = await client.query(
      'SELECT id, membership_number FROM members WHERE email = $1',
      ['wekesamuhammad@gmail.com']
    );

    if (existing.rows.length > 0) {
      console.log('✅ Test member already exists:', existing.rows[0]);
      await client.query('ROLLBACK');
      return;
    }

    // Generate membership number
    const countRes = await client.query('SELECT COUNT(*) FROM members');
    const count = parseInt(countRes.rows[0].count) + 1;
    const membership_number = `XHAIRA-${String(count).padStart(4, '0')}`;

    // Insert the test member
    const res = await client.query(`
      INSERT INTO members (
        first_name, last_name, other_name,
        full_name, email, phone,
        national_id, id_type, gender,
        date_of_birth, address, status,
        membership_number, occupation, employer,
        monthly_income, next_of_kin_name, next_of_kin_phone,
        next_of_kin_relationship, joined_date, notes
      ) VALUES (
        'WEKESA', 'MUHAMMAD', NULL,
        'WEKESA MUHAMMAD', 'wekesamuhammad@gmail.com', '+256700000001',
        'CM12345678', 'national_id', 'male',
        '1990-01-15', 'Kampala, Uganda', 'active',
        $1, 'Businessman', 'Self-Employed',
        5000000, 'FATUMA WEKESA', '+256700000002',
        'Spouse', CURRENT_DATE, 'Test member for SACCO system validation'
      )
      RETURNING id, membership_number, full_name
    `, [membership_number]);

    const member = res.rows[0];
    console.log('✅ Test member created:', member);

    // Auto-open Voluntary Savings account
    const savingsType = await client.query(
      "SELECT id, code, name FROM account_types WHERE code = 'VOL_SAV' LIMIT 1"
    );
    if (savingsType.rows.length > 0) {
      const at = savingsType.rows[0];
      const accountNum = `${at.code}-${String(member.id).slice(-8)}-01`;
      await client.query(`
        INSERT INTO member_accounts (member_id, account_type, account_number, currency, status, account_type_id)
        VALUES ($1, 'savings', $2, 'UGX', 'active', $3)
      `, [member.id, accountNum, at.id]);
      console.log(`✅ Opened ${at.name} account: ${accountNum}`);
    }

    // Open Shares account
    const sharesType = await client.query(
      "SELECT id, code, name FROM account_types WHERE code = 'SHARES' LIMIT 1"
    );
    if (sharesType.rows.length > 0) {
      const at = sharesType.rows[0];
      const accountNum = `${at.code}-${String(member.id).slice(-8)}-02`;
      await client.query(`
        INSERT INTO member_accounts (member_id, account_type, account_number, currency, status, account_type_id)
        VALUES ($1, 'shares', $2, 'UGX', 'active', $3)
      `, [member.id, accountNum, at.id]);
      console.log(`✅ Opened ${at.name} account: ${accountNum}`);
    }

    await client.query('COMMIT');
    console.log('\n🎉 WEKESA MUHAMMAD successfully registered!');
    console.log(`   Email: wekesamuhammad@gmail.com`);
    console.log(`   Membership: ${membership_number}`);
    console.log(`   Member ID: ${member.id}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

run();

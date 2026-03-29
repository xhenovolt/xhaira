#!/usr/bin/env node

/**
 * Verify Audit Logs Table
 */

import dotenv from 'dotenv';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { Pool } from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '.env.local') });

const dbUrl = process.env.DATABASE_URL;
const pool = new Pool({
  connectionString: dbUrl,
  ssl: dbUrl.includes('neon.tech') ? { rejectUnauthorized: true } : false,
});

async function verify() {
  try {
    // Check if audit_logs exists
    const tableExists = await pool.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema='public' AND table_name='audit_logs'
    `);
    console.log('Audit logs table exists:', tableExists.rows.length > 0 ? 'YES' : 'NO');

    if (tableExists.rows.length === 0) {
      console.log('Need to create audit_logs table');
      
      // Create it
      await pool.query(`
        CREATE TABLE public.audit_logs (
          id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
          action varchar(100) NOT NULL,
          entity_type varchar(100),
          entity_id uuid,
          details jsonb DEFAULT '{}',
          ip_address inet,
          created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('✅ Audit logs table created');
    } else {
      // Check columns
      const cols = await pool.query(`
        SELECT column_name FROM information_schema.columns 
        WHERE table_schema='public' AND table_name='audit_logs'
        ORDER BY ordinal_position
      `);
      console.log('Columns:', cols.rows.map(r => r.column_name).join(', '));
      
      // Try to count
      const count = await pool.query('SELECT COUNT(*) as count FROM audit_logs');
      console.log('Row count:', count.rows[0].count);
    }
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await pool.end();
  }
}

verify();

#!/usr/bin/env node

/**
 * Phase 4 Migration: Create Missing Tables
 * Run via: node scripts/create-missing-tables.js
 */

import dotenv from 'dotenv';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load .env.local
const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '..', '.env.local') });

const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
  console.error('ERROR: DATABASE_URL not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: dbUrl,
  ssl: dbUrl.includes('neon.tech') 
    ? { rejectUnauthorized: true }
    : false,
});

const tables = {
  audit_logs: `
    CREATE TABLE IF NOT EXISTS public.audit_logs (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
      action varchar(100) NOT NULL,
      entity_type varchar(100),
      entity_id uuid,
      details jsonb DEFAULT '{}',
      ip_address inet,
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `,
  
  user_presence: `
    CREATE TABLE IF NOT EXISTS public.user_presence (
      user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
      last_ping timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
      last_seen timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
      status varchar(50) DEFAULT 'online',
      is_online boolean DEFAULT true,
      current_route varchar(255),
      current_page_title varchar(255),
      device_info jsonb,
      updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `,
  
  permissions: `
    CREATE TABLE IF NOT EXISTS public.permissions (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      name varchar(255) NOT NULL UNIQUE,
      module varchar(100) NOT NULL,
      action varchar(100) NOT NULL,
      description text,
      is_system boolean DEFAULT false,
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `,
  
  role_permissions: `
    CREATE TABLE IF NOT EXISTS public.role_permissions (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
      permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `,
  
  staff_roles: `
    CREATE TABLE IF NOT EXISTS public.staff_roles (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      staff_id uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
      role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
      assigned_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `,
  
  approval_requests: `
    CREATE TABLE IF NOT EXISTS public.approval_requests (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      request_type varchar(100) NOT NULL,
      requested_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      approver_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
      status varchar(30) DEFAULT 'pending',
      details jsonb DEFAULT '{}',
      created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
      updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
    )
  `
};

async function runMigrations() {
  try {
    console.log('Starting Phase 4 migrations...\n');
    
    let created = 0;
    for (const [tableName, sql] of Object.entries(tables)) {
      try {
        await pool.query(sql);
        console.log(`OK - ${tableName}`);
        created++;
      } catch (err) {
        if (err.code === '42P07') {
          console.log(`-- ${tableName} already exists`);
        } else {
          throw err;
        }
      }
    }
    
    // Verify
    const res = await pool.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('audit_logs', 'user_presence', 'permissions', 'role_permissions', 'staff_roles', 'approval_requests')
    `);
    
    console.log(`\nResult: ${res.rows.length}/6 tables present`);
    res.rows.forEach(r => console.log(`  - ${r.table_name}`));
    
    if (res.rows.length === 6) {
      console.log('\nPhase 4 COMPLETE: All 6 missing tables created!');
      process.exit(0);
    } else {
      console.log('\nWARNING: Not all tables present');
      process.exit(1);
    }
  } catch (err) {
    console.error('Migration error:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigrations();

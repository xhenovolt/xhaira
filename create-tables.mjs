#!/usr/bin/env node

// Simplified Phase 4 Migration - Direct Table Creation
// Bypass psql entirely, use Node.js pg client

import 'dotenv/config.js';
import pkg from 'pg';
const { Client } = pkg;

async function createMissingTables() {
  if (!process.env.DATABASE_URL) {
    console.error('❌ DATABASE_URL not set');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    // Create tables one by one
    console.log('Creating user_presence...');
    await client.query(`
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
    `);
    console.log('✓ user_presence created');

    console.log('Creating permissions...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS public.permissions (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        name varchar(255) NOT NULL UNIQUE,
        module varchar(100) NOT NULL,
        action varchar(100) NOT NULL,
        description text,
        is_system boolean DEFAULT false,
        created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ permissions created');

    console.log('Creating role_permissions...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS public.role_permissions (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
        permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
        created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ role_permissions created');

    console.log('Creating staff_roles...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS public.staff_roles (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        staff_id uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
        role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
        assigned_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
        created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ staff_roles created');

    console.log('Creating approval_requests...');
    await client.query(`
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
    `);
    console.log('✓ approval_requests created');

    // Verify
    const verify = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user_presence', 'permissions', 'role_permissions', 'staff_roles', 'approval_requests')
      ORDER BY table_name
    `);

    console.log('\nTables verified:');
    verify.rows.forEach(r => console.log(`  ✓ ${r.table_name}`));
    console.log(`\nSUCCESS: ${verify.rows.length}/5 tables created`);

  } catch (err) {
    console.error('ERROR:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

createMissingTables();

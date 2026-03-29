#!/usr/bin/env node

/**
 * Seed Invoice Database with Sample Data
 * Run with: node scripts/seed-invoices.js
 */

import pg from 'pg';
import dotenv from 'dotenv';

const { Pool } = pg;
dotenv.config({ path: '.env.local' });

async function seedDatabase() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    console.log('🌱 Starting database seeding...\n');

    // Create tables if they don't exist
    console.log('📋 Creating tables...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS invoices (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          invoice_number VARCHAR(50) UNIQUE NOT NULL,
          invoice_name VARCHAR(255) NOT NULL,
          client_name VARCHAR(255) NOT NULL,
          client_email VARCHAR(255),
          client_phone VARCHAR(20),
          client_address TEXT,
          company_name VARCHAR(255) DEFAULT 'Xhenvolt Uganda SMC Limited',
          company_address VARCHAR(255) DEFAULT 'Bulubandi, Iganga, Uganda',
          company_service_type VARCHAR(255) DEFAULT 'Software Development & Digital Solutions',
          issue_date TIMESTAMP NOT NULL,
          due_date TIMESTAMP,
          subtotal DECIMAL(15, 2) NOT NULL DEFAULT 0,
          tax DECIMAL(15, 2) NOT NULL DEFAULT 0,
          discount DECIMAL(15, 2) NOT NULL DEFAULT 0,
          total DECIMAL(15, 2) NOT NULL DEFAULT 0,
          amount_paid DECIMAL(15, 2) NOT NULL DEFAULT 0,
          balance_due DECIMAL(15, 2) NOT NULL DEFAULT 0,
          status VARCHAR(20) NOT NULL DEFAULT 'draft',
          notes TEXT,
          currency VARCHAR(3) DEFAULT 'UGX',
          signed_by VARCHAR(255) DEFAULT 'HAMUZA IBRAHIM',
          signed_by_title VARCHAR(255) DEFAULT 'Chief Executive Officer (CEO)',
          payment_methods TEXT,
          payment_method_used VARCHAR(100),
          created_at TIMESTAMP NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
          
          CONSTRAINT status_check CHECK (status IN ('draft', 'sent', 'paid', 'partially_paid', 'overdue', 'cancelled')),
          CONSTRAINT amounts_valid CHECK (subtotal >= 0 AND tax >= 0 AND discount >= 0 AND total >= 0 AND amount_paid >= 0)
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS invoice_items (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
          description TEXT NOT NULL,
          quantity DECIMAL(10, 2) NOT NULL,
          unit_price DECIMAL(15, 2) NOT NULL,
          total_price DECIMAL(15, 2) NOT NULL,
          created_at TIMESTAMP NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
          
          CONSTRAINT quantity_positive CHECK (quantity > 0),
          CONSTRAINT price_non_negative CHECK (unit_price >= 0 AND total_price >= 0)
      );
    `);

    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_items ON invoice_items(invoice_id)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_items_created ON invoice_items(created_at)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_number ON invoices(invoice_number)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_status ON invoices(status)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_client ON invoices(client_name)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_invoice_created ON invoices(created_at DESC)`);

    console.log('✅ Tables created successfully\n');

    // Clear existing sample data
    console.log('🧹 Clearing existing sample data...');
    await pool.query(`DELETE FROM invoice_items WHERE invoice_id IN (SELECT id FROM invoices WHERE invoice_number LIKE 'XH/INV/%')`);
    await pool.query(`DELETE FROM invoices WHERE invoice_number LIKE 'XH/INV/%'`);
    console.log('✅ Old data cleared\n');

    // Insert invoices
    console.log('📝 Inserting sample invoices...');

    // Invoice 1: PAID
    const inv1 = await pool.query(`
      INSERT INTO invoices (
          invoice_number, invoice_name, client_name, client_email, client_phone,
          client_address, issue_date, due_date, subtotal, tax, discount, total,
          amount_paid, balance_due, status, notes, currency, payment_methods,
          payment_method_used
      ) VALUES (
          'XH/INV/2602/001', 'Software Development Invoice', 'Tech Innovations Ltd',
          'accounts@techinnovations.ug', '+256 701 234 567',
          'Plot 15, Kampala Road, Kampala, Uganda', NOW() - INTERVAL '25 days',
          NOW() - INTERVAL '3 days', 5000000.00, 500000.00, 0.00, 5500000.00,
          5500000.00, 0.00, 'paid',
          'Mobile app development complete. Deployment to production completed.',
          'UGX', '["Bank Transfer", "Mobile Money", "Cheque"]', 'Bank Transfer'
      )
      RETURNING id
    `);
    const inv1_id = inv1.rows[0].id;

    // Invoice 2: SENT
    const inv2 = await pool.query(`
      INSERT INTO invoices (
          invoice_number, invoice_name, client_name, client_email, client_phone,
          client_address, issue_date, due_date, subtotal, tax, discount, total,
          amount_paid, balance_due, status, notes, currency, payment_methods
      ) VALUES (
          'XH/INV/2602/002', 'Web Development Invoice', 'Global Solutions Inc',
          'billing@globalsolutions.com', '+256 702 345 678',
          '2847 Broadway, New York, NY 10025, USA', NOW() - INTERVAL '5 days',
          NOW() + INTERVAL '10 days', 3000000.00, 300000.00, 0.00, 3300000.00,
          0.00, 3300000.00, 'sent',
          'Website redesign and e-commerce integration. Awaiting payment.',
          'UGX', '["Bank Transfer", "Cryptocurrency", "PayPal"]'
      )
      RETURNING id
    `);
    const inv2_id = inv2.rows[0].id;

    // Invoice 3: PARTIALLY PAID
    const inv3 = await pool.query(`
      INSERT INTO invoices (
          invoice_number, invoice_name, client_name, client_email, client_phone,
          client_address, issue_date, due_date, subtotal, tax, discount, total,
          amount_paid, balance_due, status, notes, currency, payment_methods,
          payment_method_used
      ) VALUES (
          'XH/INV/2602/003', 'Consulting Services Invoice', 'Enterprise Systems Ltd',
          'finance@enterprisesystems.ug', '+256 703 456 789',
          'Innovation Hub, Nakasero, Kampala', NOW() - INTERVAL '15 days',
          NOW(), 2500000.00, 250000.00, 100000.00, 2650000.00,
          1500000.00, 1150000.00, 'partially_paid',
          'System architecture consulting and technology strategy. Partial payment received.',
          'UGX', '["Bank Transfer", "Mobile Money"]', 'Mobile Money'
      )
      RETURNING id
    `);
    const inv3_id = inv3.rows[0].id;

    // Invoice 4: DRAFT
    const inv4 = await pool.query(`
      INSERT INTO invoices (
          invoice_number, invoice_name, client_name, client_email, client_phone,
          client_address, issue_date, due_date, subtotal, tax, discount, total,
          amount_paid, balance_due, status, notes, currency, payment_methods
      ) VALUES (
          'XH/INV/2602/004', 'UI/UX Design Invoice', 'Creative Design Studio',
          'contact@creativedesign.ug', '+256 704 567 890',
          '5 Oasis Court, Kololo, Kampala', NOW(),
          NOW() + INTERVAL '30 days', 1200000.00, 120000.00, 50000.00, 1270000.00,
          0.00, 1270000.00, 'draft',
          'Complete UI/UX redesign. Draft for approval. Ready to send.',
          'UGX', '["Bank Transfer", "Mobile Money"]'
      )
      RETURNING id
    `);
    const inv4_id = inv4.rows[0].id;

    // Insert line items
    console.log('📋 Inserting line items...');

    // Items for Invoice 1
    await pool.query(`
      INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, total_price)
      VALUES 
        ($1, 'Mobile App Development - iOS & Android', 1, 4500000.00, 4500000.00),
        ($1, 'API Integration & Backend Setup', 1, 500000.00, 500000.00)
    `, [inv1_id]);

    // Items for Invoice 2
    await pool.query(`
      INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, total_price)
      VALUES 
        ($1, 'Website Design & Development', 1, 2000000.00, 2000000.00),
        ($1, 'E-Commerce Integration', 1, 1000000.00, 1000000.00)
    `, [inv2_id]);

    // Items for Invoice 3
    await pool.query(`
      INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, total_price)
      VALUES 
        ($1, 'System Architecture Consulting (40 hours)', 40, 25000.00, 1000000.00),
        ($1, 'Technology Strategy Workshop', 3, 500000.00, 1500000.00)
    `, [inv3_id]);

    // Items for Invoice 4
    await pool.query(`
      INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, total_price)
      VALUES 
        ($1, 'UI Design - 50 screens', 50, 15000.00, 750000.00),
        ($1, 'UX Research & Testing', 1, 450000.00, 450000.00)
    `, [inv4_id]);

    // Verify data
    console.log('✅ Line items inserted\n');

    const invoiceCount = await pool.query(`SELECT COUNT(*) FROM invoices`);
    const itemCount = await pool.query(`SELECT COUNT(*) FROM invoice_items`);
    const totalAmount = await pool.query(`SELECT SUM(total) as total FROM invoices`);

    console.log('📊 Database Seeding Summary:');
    console.log(`   ✅ Invoices created: ${invoiceCount.rows[0].count}`);
    console.log(`   ✅ Line items created: ${itemCount.rows[0].count}`);
    console.log(`   ✅ Total invoice value: UGX ${parseInt(totalAmount.rows[0].total || 0).toLocaleString()}`);
    console.log('\n✨ Database has been successfully seeded!\n');

    console.log('📋 Sample Invoices:');
    console.log('   1. XH/INV/2602/001 - PAID (Tech Innovations Ltd) - UGX 5,500,000');
    console.log('   2. XH/INV/2602/002 - SENT (Global Solutions Inc) - UGX 3,300,000');
    console.log('   3. XH/INV/2602/003 - PARTIALLY PAID (Enterprise Systems Ltd) - UGX 2,650,000');
    console.log('   4. XH/INV/2602/004 - DRAFT (Creative Design Studio) - UGX 1,270,000');
    console.log('\n🚀 Start your server with: npm run dev');
    console.log('🌐 Access invoices at: http://localhost:3000/invoices\n');

  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seedDatabase();

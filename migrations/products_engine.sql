-- ============================================================================
-- FINANCIAL PRODUCTS ENGINE — Migration
-- Transforms `systems` table into a unified Financial Products Engine
-- Supports: LOAN, SAVINGS, INSTALLMENT, SERVICE, INVESTMENT
-- ============================================================================
-- Safe to re-run (all statements are idempotent)

-- 1. Create product_type enum
DO $$ BEGIN
  CREATE TYPE product_type AS ENUM ('LOAN', 'SAVINGS', 'INSTALLMENT', 'SERVICE', 'INVESTMENT');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Add financial product columns to systems table
ALTER TABLE systems ADD COLUMN IF NOT EXISTS product_type product_type DEFAULT 'SERVICE';
ALTER TABLE systems ADD COLUMN IF NOT EXISTS interest_rate NUMERIC(8,4);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS duration_months INTEGER;
ALTER TABLE systems ADD COLUMN IF NOT EXISTS min_amount NUMERIC(18,2);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS max_amount NUMERIC(18,2);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN DEFAULT false;
ALTER TABLE systems ADD COLUMN IF NOT EXISTS upfront_amount NUMERIC(18,2);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS return_rate NUMERIC(8,4);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS billing_frequency VARCHAR(30);
ALTER TABLE systems ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'UGX';
ALTER TABLE systems ADD COLUMN IF NOT EXISTS price NUMERIC(18,2);

-- 3. Add index for product type filtering
CREATE INDEX IF NOT EXISTS idx_systems_product_type ON systems (product_type);

-- 4. Update existing systems to SERVICE type (they were software platforms)
UPDATE systems SET product_type = 'SERVICE' WHERE product_type IS NULL;

-- 5. Migrate data from old products table into systems (if products table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products' AND table_schema = 'public') THEN
    INSERT INTO systems (name, description, status, product_type, price, currency, created_at)
    SELECT
      p.name,
      p.description,
      COALESCE(p.status, 'active'),
      'SERVICE'::product_type,
      p.price,
      COALESCE(p.currency, 'UGX'),
      COALESCE(p.created_at, NOW())
    FROM products p
    WHERE NOT EXISTS (
      SELECT 1 FROM systems s WHERE s.name = p.name
    );

    -- Rename old products table (keep as backup)
    ALTER TABLE products RENAME TO products_legacy;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================================
-- DONE: systems table now serves as the unified Financial Products Engine
-- All existing foreign keys (deals.system_id, licenses.system_id, etc.) remain valid
-- ============================================================================

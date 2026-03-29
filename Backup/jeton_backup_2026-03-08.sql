-- Jeton Database Backup - 2026-03-08T11:48:27.193Z
-- Tables: 45

-- Table: allocations
CREATE TABLE IF NOT EXISTS allocations (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  payment_id UUID NOT NULL,
  allocation_type VARCHAR(50) NOT NULL,
  amount NUMERIC NOT NULL,
  category_id INTEGER,
  custom_category VARCHAR(100),
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Table: asset_depreciation_logs
CREATE TABLE IF NOT EXISTS asset_depreciation_logs (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  asset_id UUID NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  depreciation_amount NUMERIC NOT NULL,
  calculation_method TEXT,
  useful_life_years INTEGER,
  units_produced INTEGER,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  notes TEXT
);

-- Table: assets
CREATE TABLE IF NOT EXISTS assets (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  acquisition_source TEXT,
  acquisition_date DATE,
  acquisition_cost NUMERIC,
  current_value NUMERIC NOT NULL,
  depreciation_rate NUMERIC DEFAULT 0,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  locked BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ
);

-- Table: assets_accounting
CREATE TABLE IF NOT EXISTS assets_accounting (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  asset_type TEXT NOT NULL,
  asset_subtype TEXT,
  acquisition_cost NUMERIC NOT NULL,
  acquisition_date DATE NOT NULL,
  depreciation_method TEXT DEFAULT 'straight_line'::text NOT NULL,
  depreciation_rate NUMERIC NOT NULL,
  accumulated_depreciation NUMERIC DEFAULT 0 NOT NULL,
  current_book_value NUMERIC,
  residual_value NUMERIC,
  location TEXT,
  owner_name TEXT,
  status TEXT DEFAULT 'active'::text,
  disposal_date DATE,
  disposal_value NUMERIC,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Table: audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  actor_id UUID,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  metadata JSONB,
  ip_address TEXT,
  user_agent TEXT,
  status TEXT DEFAULT 'SUCCESS'::text,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: clients
CREATE TABLE IF NOT EXISTS clients (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_id UUID,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company_name VARCHAR(255),
  address TEXT,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  notes TEXT,
  converted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: contracts
CREATE TABLE IF NOT EXISTS contracts (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  client_id UUID NOT NULL,
  system_id UUID,
  deal_id UUID,
  installation_fee NUMERIC DEFAULT 0 NOT NULL,
  recurring_enabled BOOLEAN DEFAULT false,
  recurring_cycle VARCHAR(20),
  recurring_amount NUMERIC,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  installation_date DATE,
  terms TEXT,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: deal_sales_mapping
CREATE TABLE IF NOT EXISTS deal_sales_mapping (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  deal_id UUID NOT NULL,
  sale_id UUID NOT NULL,
  auto_created BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: deals
CREATE TABLE IF NOT EXISTS deals (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  title TEXT NOT NULL,
  client_name TEXT,
  value_estimate NUMERIC DEFAULT 0,
  stage TEXT DEFAULT 'Lead'::text,
  probability INTEGER DEFAULT 50,
  expected_close_date DATE,
  status TEXT DEFAULT 'ACTIVE'::text,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  locked BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  description TEXT,
  assigned_to UUID,
  client_id UUID,
  system_id UUID,
  prospect_id UUID
);

-- Table: expense_categories
CREATE TABLE IF NOT EXISTS expense_categories (
  id INTEGER DEFAULT nextval('expense_categories_id_seq'::regclass) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: expenses
CREATE TABLE IF NOT EXISTS expenses (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  category_id INTEGER,
  custom_category VARCHAR(100),
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  expense_date DATE DEFAULT CURRENT_DATE,
  allocation_id UUID,
  status VARCHAR(50) DEFAULT 'recorded'::character varying,
  created_by UUID,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: infrastructure
CREATE TABLE IF NOT EXISTS infrastructure (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  infrastructure_type TEXT NOT NULL,
  owner_name TEXT,
  access_level TEXT,
  risk_level TEXT,
  replacement_cost NUMERIC,
  domain_name VARCHAR(255),
  domain_registrar VARCHAR(100),
  domain_expiry_date DATE,
  domain_auto_renew BOOLEAN DEFAULT true,
  platform TEXT,
  social_handle VARCHAR(255),
  social_recovery_email VARCHAR(255),
  social_recovery_phone VARCHAR(20),
  file_location VARCHAR(500),
  version VARCHAR(50),
  status TEXT DEFAULT 'active'::text,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Table: infrastructure_audit_logs
CREATE TABLE IF NOT EXISTS infrastructure_audit_logs (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  infrastructure_id UUID NOT NULL,
  event_type TEXT,
  previous_value TEXT,
  new_value TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  notes TEXT
);

-- Table: intellectual_property
CREATE TABLE IF NOT EXISTS intellectual_property (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  ip_type TEXT NOT NULL,
  ip_subtype TEXT,
  development_cost NUMERIC NOT NULL,
  development_start_date DATE,
  development_completion_date DATE,
  valuation_estimate NUMERIC,
  valuation_basis TEXT,
  revenue_generated_lifetime NUMERIC DEFAULT 0,
  revenue_generated_monthly NUMERIC DEFAULT 0,
  clients_count INTEGER DEFAULT 0,
  monetization_model TEXT,
  ownership_percentage NUMERIC DEFAULT 100,
  owner_name TEXT,
  status TEXT DEFAULT 'active'::text,
  launch_date DATE,
  sunset_date DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Table: invoice_items
CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  invoice_id UUID NOT NULL,
  description TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  unit_price NUMERIC NOT NULL,
  total_price NUMERIC NOT NULL,
  created_at TIMESTAMP DEFAULT now() NOT NULL,
  updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- Table: invoices
CREATE TABLE IF NOT EXISTS invoices (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  invoice_number VARCHAR(50) NOT NULL,
  invoice_name VARCHAR(255) NOT NULL,
  client_name VARCHAR(255) NOT NULL,
  client_email VARCHAR(255),
  client_phone VARCHAR(20),
  client_address TEXT,
  company_name VARCHAR(255) DEFAULT 'Xhenvolt Uganda SMC Limited'::character varying,
  company_address VARCHAR(255) DEFAULT 'Bulubandi, Iganga, Uganda'::character varying,
  company_service_type VARCHAR(255) DEFAULT 'Software Development & Digital Solutions'::character varying,
  issue_date TIMESTAMP NOT NULL,
  due_date TIMESTAMP,
  subtotal NUMERIC DEFAULT 0 NOT NULL,
  tax NUMERIC DEFAULT 0 NOT NULL,
  discount NUMERIC DEFAULT 0 NOT NULL,
  total NUMERIC DEFAULT 0 NOT NULL,
  amount_paid NUMERIC DEFAULT 0 NOT NULL,
  balance_due NUMERIC DEFAULT 0 NOT NULL,
  status VARCHAR(20) DEFAULT 'draft'::character varying NOT NULL,
  notes TEXT,
  currency VARCHAR(3) DEFAULT 'UGX'::character varying,
  signed_by VARCHAR(255) DEFAULT 'HAMUZA IBRAHIM'::character varying,
  signed_by_title VARCHAR(255) DEFAULT 'Chief Executive Officer (CEO)'::character varying,
  payment_methods TEXT,
  payment_method_used VARCHAR(100),
  created_at TIMESTAMP DEFAULT now() NOT NULL,
  updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- Table: ip_valuation_logs
CREATE TABLE IF NOT EXISTS ip_valuation_logs (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  ip_id UUID NOT NULL,
  previous_valuation NUMERIC,
  new_valuation NUMERIC NOT NULL,
  valuation_basis TEXT,
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Table: liabilities
CREATE TABLE IF NOT EXISTS liabilities (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  creditor TEXT,
  principal_amount NUMERIC NOT NULL,
  outstanding_amount NUMERIC NOT NULL,
  interest_rate NUMERIC DEFAULT 0,
  due_date DATE,
  status TEXT DEFAULT 'ACTIVE'::text NOT NULL,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  locked BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ
);

-- Table: payments
CREATE TABLE IF NOT EXISTS payments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  contract_id UUID NOT NULL,
  amount_received NUMERIC NOT NULL,
  date_received TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment_method VARCHAR(50) DEFAULT 'bank_transfer'::character varying,
  allocated_amount NUMERIC DEFAULT 0,
  allocation_status VARCHAR(20) DEFAULT 'pending'::character varying,
  reference_number VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_activities
CREATE TABLE IF NOT EXISTS prospect_activities (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_id UUID NOT NULL,
  activity_type VARCHAR(50) NOT NULL,
  subject VARCHAR(255),
  description TEXT,
  outcome VARCHAR(255),
  notes TEXT,
  products_discussed ARRAY,
  objections TEXT,
  feedback TEXT,
  activity_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  duration_minutes INTEGER,
  created_by_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_conversions
CREATE TABLE IF NOT EXISTS prospect_conversions (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_id UUID NOT NULL,
  deal_id UUID,
  conversion_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  conversion_status VARCHAR(50) DEFAULT 'converted'::character varying,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_industries
CREATE TABLE IF NOT EXISTS prospect_industries (
  id INTEGER DEFAULT nextval('prospect_industries_id_seq'::regclass) NOT NULL,
  industry_name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_sources
CREATE TABLE IF NOT EXISTS prospect_sources (
  id INTEGER DEFAULT nextval('prospect_sources_id_seq'::regclass) NOT NULL,
  source_name VARCHAR(50) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_stage_history
CREATE TABLE IF NOT EXISTS prospect_stage_history (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_id UUID NOT NULL,
  previous_stage_id INTEGER,
  new_stage_id INTEGER NOT NULL,
  reason_for_change TEXT,
  changed_by_id UUID NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_stages
CREATE TABLE IF NOT EXISTS prospect_stages (
  id INTEGER DEFAULT nextval('prospect_stages_id_seq'::regclass) NOT NULL,
  stage_name VARCHAR(50) NOT NULL,
  stage_order INTEGER NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_tag_assignments
CREATE TABLE IF NOT EXISTS prospect_tag_assignments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_id UUID NOT NULL,
  tag_id INTEGER NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospect_tags
CREATE TABLE IF NOT EXISTS prospect_tags (
  id INTEGER DEFAULT nextval('prospect_tags_id_seq'::regclass) NOT NULL,
  tag_name VARCHAR(50) NOT NULL,
  color_code VARCHAR(7),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: prospects
CREATE TABLE IF NOT EXISTS prospects (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  prospect_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone_number VARCHAR(20),
  whatsapp_number VARCHAR(20),
  company_name VARCHAR(255),
  industry_id INTEGER,
  city VARCHAR(100),
  country VARCHAR(100),
  address TEXT,
  source_id INTEGER NOT NULL,
  current_stage_id INTEGER DEFAULT 1 NOT NULL,
  assigned_sales_agent_id UUID,
  created_by_id UUID NOT NULL,
  first_contacted_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ,
  next_followup_at TIMESTAMPTZ,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: revenue_records
CREATE TABLE IF NOT EXISTS revenue_records (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  deal_id UUID,
  sale_id UUID,
  type VARCHAR(20) DEFAULT 'deal'::character varying NOT NULL,
  status VARCHAR(30) DEFAULT 'open'::character varying NOT NULL,
  stage VARCHAR(80),
  title VARCHAR(255) NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  customer_email VARCHAR(255),
  amount_total NUMERIC DEFAULT 0 NOT NULL,
  amount_received NUMERIC DEFAULT 0 NOT NULL,
  amount_outstanding NUMERIC DEFAULT 0 NOT NULL,
  probability NUMERIC DEFAULT 0,
  weighted_value NUMERIC DEFAULT 0,
  expected_revenue NUMERIC DEFAULT 0,
  payment_status VARCHAR(30) DEFAULT 'Unpaid'::character varying NOT NULL,
  on_credit BOOLEAN DEFAULT false NOT NULL,
  due_date DATE,
  follow_up_at TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: sales
CREATE TABLE IF NOT EXISTS sales (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  deal_id UUID,
  salesperson_id UUID NOT NULL,
  customer_name TEXT NOT NULL,
  customer_email TEXT,
  amount NUMERIC NOT NULL,
  currency TEXT DEFAULT 'UGX'::text,
  status TEXT DEFAULT 'open'::text,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: sessions
CREATE TABLE IF NOT EXISTS sessions (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  user_id UUID NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  device_name TEXT DEFAULT 'Unknown Device'::text NOT NULL,
  browser_name TEXT,
  ip_address INET,
  user_agent TEXT,
  last_active_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  revoked_at TIMESTAMPTZ,
  revoked_reason TEXT
);

-- Table: share_allocations
CREATE TABLE IF NOT EXISTS share_allocations (
  id INTEGER DEFAULT nextval('share_allocations_id_seq'::regclass) NOT NULL,
  owner_id INTEGER NOT NULL,
  owner_name VARCHAR(255) NOT NULL,
  owner_email VARCHAR(255),
  shares_allocated BIGINT NOT NULL,
  allocation_date DATE DEFAULT CURRENT_DATE,
  vesting_start_date DATE,
  vesting_end_date DATE,
  vesting_percentage NUMERIC DEFAULT 100.00,
  notes TEXT,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: share_issuances
CREATE TABLE IF NOT EXISTS share_issuances (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  shareholder_id UUID NOT NULL,
  shares_issued BIGINT NOT NULL,
  issuance_date DATE DEFAULT CURRENT_DATE,
  vesting_start_date DATE,
  vesting_end_date DATE,
  vesting_percentage NUMERIC DEFAULT 100,
  price_per_share NUMERIC,
  total_consideration NUMERIC,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  issued_at_price NUMERIC,
  recipient_id UUID,
  recipient_type VARCHAR(50) DEFAULT 'individual'::character varying,
  issuance_reason VARCHAR(255),
  issuance_type VARCHAR(50) DEFAULT 'grant'::character varying,
  approval_status VARCHAR(50) DEFAULT 'pending'::character varying,
  confirmation_received BOOLEAN DEFAULT false,
  previous_issued_shares BIGINT DEFAULT 0,
  ownership_dilution_impact NUMERIC DEFAULT 0,
  created_by_id UUID,
  approved_by_id UUID,
  approved_at TIMESTAMP,
  issued_at TIMESTAMP,
  equity_type VARCHAR(50) DEFAULT 'PURCHASED'::character varying NOT NULL
);

-- Table: share_price_history
CREATE TABLE IF NOT EXISTS share_price_history (
  id INTEGER DEFAULT nextval('share_price_history_id_seq'::regclass) NOT NULL,
  date DATE NOT NULL,
  opening_price NUMERIC,
  closing_price NUMERIC NOT NULL,
  high_price NUMERIC,
  low_price NUMERIC,
  company_valuation NUMERIC,
  total_shares BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: share_transfers
CREATE TABLE IF NOT EXISTS share_transfers (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  from_shareholder_id UUID NOT NULL,
  to_shareholder_id UUID NOT NULL,
  shares_transferred BIGINT NOT NULL,
  transfer_price_per_share NUMERIC,
  transfer_total NUMERIC,
  transfer_type VARCHAR(50) NOT NULL,
  transfer_date DATE DEFAULT CURRENT_DATE NOT NULL,
  transfer_status VARCHAR(50) DEFAULT 'completed'::character varying NOT NULL,
  equity_type VARCHAR(50),
  shares_returned BIGINT DEFAULT 0,
  reason VARCHAR(500),
  notes TEXT,
  created_by_id UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  approved_by_id UUID,
  approved_at TIMESTAMPTZ
);

-- Table: shareholders
CREATE TABLE IF NOT EXISTS shareholders (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  user_id UUID NOT NULL,
  shares_owned BIGINT DEFAULT 0 NOT NULL,
  percentage_owned NUMERIC DEFAULT 0.0 NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: shareholdings
CREATE TABLE IF NOT EXISTS shareholdings (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  shareholder_id UUID NOT NULL,
  shareholder_name VARCHAR(255) NOT NULL,
  shareholder_email VARCHAR(255),
  shares_owned BIGINT DEFAULT 0 NOT NULL,
  share_class VARCHAR(50) DEFAULT 'Common'::character varying NOT NULL,
  equity_type VARCHAR(50) DEFAULT 'PURCHASED'::character varying NOT NULL,
  vesting_start_date DATE,
  vesting_end_date DATE,
  vesting_schedule VARCHAR(50),
  vesting_cliff_percentage NUMERIC DEFAULT 0,
  vested_shares BIGINT DEFAULT 0,
  acquisition_date DATE DEFAULT CURRENT_DATE NOT NULL,
  acquisition_price NUMERIC,
  investment_total NUMERIC,
  original_ownership_percentage NUMERIC,
  current_ownership_percentage NUMERIC,
  dilution_events_count INTEGER DEFAULT 0,
  status VARCHAR(50) DEFAULT 'active'::character varying NOT NULL,
  holder_type VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: shares
CREATE TABLE IF NOT EXISTS shares (
  id INTEGER DEFAULT nextval('shares_id_seq'::regclass) NOT NULL,
  total_shares BIGINT DEFAULT 1000000 NOT NULL,
  par_value NUMERIC DEFAULT 920000.00,
  class_type VARCHAR(50) DEFAULT 'common'::character varying,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  authorized_shares BIGINT DEFAULT 1000000 NOT NULL,
  issued_shares BIGINT DEFAULT 0 NOT NULL,
  allocated_shares BIGINT DEFAULT 0 NOT NULL
);

-- Table: shares_config
CREATE TABLE IF NOT EXISTS shares_config (
  id INTEGER DEFAULT nextval('shares_config_id_seq'::regclass) NOT NULL,
  authorized_shares BIGINT DEFAULT 1000000 NOT NULL,
  issued_shares BIGINT DEFAULT 0 NOT NULL,
  class_type VARCHAR(50) DEFAULT 'common'::character varying,
  par_value NUMERIC DEFAULT 0.0001,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'active'::character varying NOT NULL,
  company_id UUID,
  notes TEXT
);

-- Table: snapshots
CREATE TABLE IF NOT EXISTS snapshots (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  type TEXT NOT NULL,
  name TEXT,
  data JSONB NOT NULL,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: staff
CREATE TABLE IF NOT EXISTS staff (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  user_id UUID,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  position VARCHAR(100),
  department VARCHAR(100),
  hire_date DATE DEFAULT CURRENT_DATE,
  salary NUMERIC,
  status VARCHAR(50) DEFAULT 'active'::character varying,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: staff_profiles
CREATE TABLE IF NOT EXISTS staff_profiles (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  user_id UUID NOT NULL,
  department TEXT,
  title TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: users
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'FOUNDER'::text NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  full_name TEXT,
  status TEXT DEFAULT 'active'::text,
  last_login TIMESTAMPTZ,
  last_seen TIMESTAMPTZ,
  is_online BOOLEAN DEFAULT false
);

-- Table: valuation_summary
CREATE TABLE IF NOT EXISTS valuation_summary (
  id INTEGER DEFAULT nextval('valuation_summary_id_seq'::regclass) NOT NULL,
  total_assets_book_value NUMERIC,
  total_depreciation_period NUMERIC,
  total_ip_valuation NUMERIC,
  total_infrastructure_value NUMERIC,
  accounting_net_worth NUMERIC,
  strategic_company_value NUMERIC,
  calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table: vault_balances
CREATE TABLE IF NOT EXISTS vault_balances (
  id INTEGER DEFAULT nextval('vault_balances_id_seq'::regclass) NOT NULL,
  vault_type VARCHAR(50) NOT NULL,
  balance NUMERIC DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- allocations: 0 rows

-- asset_depreciation_logs: 0 rows

-- Data for: assets (10 rows)
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('dc004299-6b4a-4ea3-91b6-0e3af70fbeec', 'Hp 256 Notebook', 'Laptop', 'Purchase', '"2025-06-19T21:00:00.000Z"', '850000.00', '750000.00', '20.00', 'Hp 256 notebook Laptop with intel core i3 10th generation 256 GB SSD storage and 16GB of RAM ', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T07:35:28.569Z"', '"2025-12-30T07:35:28.569Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('db53fbc0-ac3c-4e37-b77b-1e4c7c103f97', 'Huawei Y9 Prrime 2019', 'Smartphone', 'Purchase', '"2025-08-01T21:00:00.000Z"', '300000.00', '250000.00', '20.00', 'Huawei Y9 prime 2019 with 128GB of storage and 4GB of RAM used for talking to prospects and some other issues', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T07:49:53.068Z"', '"2025-12-30T07:49:53.068Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('72302ccd-a8d4-4e92-a7cb-13de15cdc0a2', 'Professional Suit', 'Clothing', 'Purchase', '"2025-08-27T21:00:00.000Z"', '210000.00', '175000.00', '20.00', 'Gray suit for professional prospecting', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T07:53:48.626Z"', '"2025-12-30T07:53:48.626Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('d51e7554-d4dd-4504-a5da-7d2a7511c31b', 'Gray suit', 'Clothing', 'Purchase', '"2025-09-01T21:00:00.000Z"', '300000.00', '270000.00', '20.00', 'Professional suit for prospecting', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T07:56:38.940Z"', '"2025-12-30T07:56:38.940Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('58ac9974-d939-4fd4-86f5-21eed816fae0', 'DRAIS', 'Management System', 'Production', '"2025-07-01T21:00:00.000Z"', '15000000.00', '25000000.00', '0.00', 'DRAIS empowers educational institutions with intelligent automation, real-time insights, and seamless collaboration — all in one powerful platform.', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:07:33.271Z"', '"2025-12-30T08:07:33.271Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('4f249d3e-c991-450e-b844-6a005616a907', 'JETON', 'Management System', 'Production', '"2025-12-29T21:00:00.000Z"', '10000000.00', '12000000.00', '0.00', 'A Company Management & Decision Intelligence System', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:13:00.493Z"', '"2025-12-30T08:13:00.493Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('c504be1f-0a8a-4170-9bbc-4117a9f0b10a', 'XHETON', 'Management System', 'Production', '"2025-12-24T21:00:00.000Z"', '12000000.00', '15000000.00', '0.00', 'Business Management system', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:16:44.484Z"', '"2025-12-30T08:16:44.484Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('1663032e-ecfe-4f63-a108-f2b1ac8a0a2f', 'CONSTY', 'Management System', 'Production', '"2025-10-14T21:00:00.000Z"', '8000000.00', '11000000.00', '0.00', 'The most elegant construction management platform designed for modern teams. Streamline projects, empower teams, control budgets—all in one beautiful interface.', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:20:27.807Z"', '"2025-12-30T08:20:27.807Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('c8783b9e-d8bb-431f-a6e5-075d8d4ee2de', 'XHAIRA', 'Management System', 'Production', '"2025-07-23T21:00:00.000Z"', '9500000.00', '12500000.00', '0.00', 'A modern SACCO and Investment Management system', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:25:18.049Z"', '"2025-12-30T08:25:18.049Z"', FALSE, NULL);
INSERT INTO assets (id, name, category, acquisition_source, acquisition_date, acquisition_cost, current_value, depreciation_rate, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('12fe3ccf-7a6c-45e0-b2c2-b4ab61df01d0', 'Backpack', 'Equipment', 'Purchase', '"2025-07-28T21:00:00.000Z"', '55000.00', '45000.00', '0.00', 'Laptop bag for carrying laptop and other things', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2025-12-30T08:27:33.467Z"', '"2025-12-30T08:27:33.467Z"', FALSE, NULL);

-- Data for: assets_accounting (4 rows)
INSERT INTO assets_accounting (id, name, description, asset_type, asset_subtype, acquisition_cost, acquisition_date, depreciation_method, depreciation_rate, accumulated_depreciation, current_book_value, residual_value, location, owner_name, status, disposal_date, disposal_value, created_at, updated_at, created_by) VALUES ('e9251358-6029-49f1-af14-8b2b2399be6b', 'HP 256 Notebook', 'This is a laptop used for developing and maintaining the software, it features a 10th generation intel core i3 processor with 16GB of RAM and 256 GB of storage with 4hours of battery life', 'laptop', NULL, '850000.00', '"2025-05-30T21:00:00.000Z"', 'straight_line', '20.00', '0.00', '850000.00', NULL, 'Developers', NULL, 'active', NULL, NULL, '"2025-12-30T11:39:47.130Z"', '"2025-12-30T11:39:47.130Z"', NULL);
INSERT INTO assets_accounting (id, name, description, asset_type, asset_subtype, acquisition_cost, acquisition_date, depreciation_method, depreciation_rate, accumulated_depreciation, current_book_value, residual_value, location, owner_name, status, disposal_date, disposal_value, created_at, updated_at, created_by) VALUES ('1ef9bf5f-c782-406e-ba6d-047df686b991', 'Backpack', 'The backpack used for carrying laptop and all other things', 'equipment', NULL, '50000.00', '"2025-07-20T21:00:00.000Z"', 'straight_line', '20.00', '0.00', '50000.00', NULL, 'CEO Location', NULL, 'active', NULL, NULL, '"2025-12-30T12:04:19.237Z"', '"2025-12-30T12:04:19.237Z"', NULL);
INSERT INTO assets_accounting (id, name, description, asset_type, asset_subtype, acquisition_cost, acquisition_date, depreciation_method, depreciation_rate, accumulated_depreciation, current_book_value, residual_value, location, owner_name, status, disposal_date, disposal_value, created_at, updated_at, created_by) VALUES ('f63ae95e-0b9f-4dc4-a384-eaf3e5d27fac', 'Xperia 1 ii ', 'Product Profile: Sony Xperia 1 II
1. Core Specifications
Model Name: Xperia 1 II (XQ-AT51 / XQ-AT52)
Launch Date: May 2020
Operating System: Android 10 (Upgradable to Android 12)
Chipset: Qualcomm Snapdragon 865 (7nm+) | 5G Capable
Memory (RAM): 8GB or 12GB LPDDR5
Storage: 256GB UFS 3.0 (Internal) | Expandable via microSDXC up to 1TB
2. Display & Design
Screen: 6.5-inch 4K HDR OLED "CinemaWide"
Resolution: 1644 x 3840 pixels (~643 ppi)
Aspect Ratio: 21:9
Dimensions: 165.1 x 71.1 x 7.6 mm
Weight: 181.4 g
Build: Gorilla Glass 6 (Front/Back), Aluminum Frame
IP Rating: IP65/IP68 (Dust and Water Resistant)
3. Camera System (ZEISS Optics)
Rear Triple Setup:
Main: 12 MP (f/1.7, 24mm, Dual Pixel PDAF, OIS)
Telephoto: 12 MP (f/2.4, 70mm, 3x Optical Zoom, OIS)
Ultrawide: 12 MP (f/2.2, 16mm, 124° FOV)
Sensor: 3D iToF (Depth)
Front Camera: 8 MP (f/2.0, 24mm wide)
Video: 4K HDR at 24/25/30/60fps; 1080p at up to 120fps
4. Power & Connectivity
Battery: 4000 mAh (Non-removable)
Charging: 21W Wired (PD 3.0) | 11W Wireless (Qi)
Audio: 3.5mm Headphone Jack, Front-facing Stereo Speakers, Hi-Res Audio
Biometrics: Side-mounted Fingerprint Sensor
Connectivity: Wi-Fi 6, Bluetooth 5.1, NFC, USB-C 3.1', 'phone', NULL, '500000.00', '"2026-01-06T21:00:00.000Z"', 'straight_line', '20.00', '0.00', '500000.00', NULL, 'Mobile with CEO mostly ', NULL, 'active', NULL, NULL, '"2026-03-02T15:16:00.057Z"', '"2026-03-02T15:16:00.057Z"', NULL);
INSERT INTO assets_accounting (id, name, description, asset_type, asset_subtype, acquisition_cost, acquisition_date, depreciation_method, depreciation_rate, accumulated_depreciation, current_book_value, residual_value, location, owner_name, status, disposal_date, disposal_value, created_at, updated_at, created_by) VALUES ('d5f70459-06b5-4109-849d-e5fe37ac5cd8', 'Huawei Y9 Prime 2019', 'Mobile Phone used for managing company information and prospecting
', 'phone', NULL, '300000.00', '"2025-07-25T21:00:00.000Z"', 'straight_line', '20.00', '0.00', '300000.00', NULL, 'Mobile', NULL, 'disposed', '"2026-03-01T21:00:00.000Z"', NULL, '"2025-12-30T11:57:04.626Z"', '"2026-03-02T15:16:25.754Z"', NULL);

-- Data for: audit_logs (430 rows)
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c1488374-6ab5-44c8-b405-24eafd46c7e9', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'REGISTER', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:11:16.363Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('81a1702c-33f4-4e20-b9e8-9b5947df6672', NULL, 'REGISTER', 'AUTH', NULL, '{"email":"test@example.com","reason":"Unknown error"}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T15:15:18.222Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8cb1bc06-b37a-4f15-820a-55bc5560928e', NULL, 'REGISTER', 'AUTH', NULL, '{"email":"xhenonpro@gmail.com","reason":"Email already exists"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:24:53.531Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b8846a29-d72e-4501-9f6f-9bfb2cb9ed30', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:25:19.913Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('364f4403-7688-4e75-9f85-f264f6cb4f4b', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:25:22.530Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('369d45ba-bf3f-4838-86a9-06b20dfda284', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:25:23.618Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('be407bce-765b-493e-ab37-aba75df28965', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:25:40.824Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ef5e201d-1689-4e1c-975b-b9bca1b01f58', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No token provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T15:25:43.859Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2d540e4c-c7c8-4e92-9c62-f526eeb69eb9', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No token provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T15:25:47.779Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('db74fb95-2e8c-4ea1-97a9-e060f6e07d7c', '387079e4-e132-4955-9a27-df4656399c00', 'REGISTER', 'AUTH', '387079e4-e132-4955-9a27-df4656399c00', '{"email":"founder@xhenvolt.com","reason":null}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T15:36:46.821Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0b4e0de3-087a-4c4b-9315-00198715d867', NULL, 'REGISTER', 'AUTH', NULL, '{"email":"founder@xhenvolt.com","reason":"Email already exists"}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T15:37:21.641Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b90ca269-2665-4e27-a48f-f44817c7401a', '387079e4-e132-4955-9a27-df4656399c00', 'LOGIN_SUCCESS', 'AUTH', '387079e4-e132-4955-9a27-df4656399c00', '{"email":"founder@xhenvolt.com","reason":null}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T15:37:31.687Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f6468cb9-0abc-4f78-9dd4-092fcf58d702', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:50:47.734Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('04f771c5-97c1-43de-9b0b-b351a15efddf', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:50:48.788Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('40a383e9-f8a9-4a51-87fb-e02f725ba04b', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T15:50:52.235Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6a6a98de-865b-483e-81fb-035b85a4a2a5', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T16:07:01.541Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2b0565cd-8dcf-44ef-81e0-a2487867ad0d', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T16:30:29.351Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('48f3deab-6c4f-4ef0-b52b-59892f652647', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T16:30:29.352Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7686b822-07ca-48dd-a60f-03205af06318', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T16:30:36.131Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a51b96f6-c66e-4882-aa3a-0f9e3c5f6ecf', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T16:30:36.131Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dd50fff1-96cb-4a31-a46d-5daa5c776a27', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"founder@xhenvolt.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T17:09:53.942Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6f0fbb4e-6dd7-4f4d-9c75-28bafa49c475', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:10:13.021Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8a82ea88-5836-4419-bb71-c9cc6fef0f9d', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T17:10:46.726Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a2e52fc8-c130-4b9d-8f5b-ba0cf7abdf93', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-29T17:10:46.733Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0f612db6-f0e7-458e-9e2c-7b4eca33af75', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:11:01.357Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('27278bdd-d8aa-43cd-a808-00017651b147', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:57:28.835Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ee7410fb-bb5c-4abc-ae81-4e9d1b25ae1d', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:57:49.956Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0aeecb1e-533a-4a9e-9cc4-6dbc1891942f', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:57:56.528Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b14972f9-f1a4-4cd9-b952-f2c81a43e513', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T17:58:45.067Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('15eac1f1-d3fd-40b4-95f8-e7178c45194e', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T18:08:19.237Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dd20bab2-469a-412c-a1c9-a9f7628d1ff8', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T18:08:57.860Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('191b3453-7d57-46aa-bbff-f112a7a874ea', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T18:09:18.397Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bdf26b78-cb3e-411a-af7a-3eaf2b15a226', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T18:20:57.996Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2f2fbbbd-7d32-443a-826b-4aa8c0b24684', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:39:22.289Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d9609e50-4628-4926-b2af-19c18ccc7268', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:39:38.250Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('74f5d96e-3b84-4311-86ec-71ed8e8eb4a3', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:39:50.238Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8ed1c421-8a15-4f1a-909b-c1321b88c303', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:41:28.809Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('89aa542c-bc36-4a5b-94ad-5bac0a94b6a8', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-29T18:41:29.218Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('86393087-3071-4619-bce7-35ffcf4030c9', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"No token provided"}', NULL, NULL, 'FAILURE', '"2025-12-29T18:41:44.989Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('71bfeb4d-0c18-46f7-add5-19e2f1ee1221', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:42:30.457Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3ef34228-889a-4720-82c9-ec3fc3a768dd', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-29T18:42:35.817Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('90f07cc3-bed2-49a7-8d60-37600924fd7e', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No token provided"}', '41.210.141.123', 'curl/8.5.0', 'FAILURE', '"2025-12-29T18:55:00.104Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cc20fa3d-b2a1-4dc0-872f-d12e86287123', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"No token provided"}', NULL, NULL, 'FAILURE', '"2025-12-30T04:02:28.594Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('92ce1103-dd74-455c-b61d-ca3be0874d62', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T04:02:49.680Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d25a022b-e8b4-4bbf-9183-c169121ceb69', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T04:27:09.434Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cee8b077-1e5b-40c7-9613-1cafa3609bab', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T04:28:17.923Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d07f9bcd-4573-4be8-bf0b-ce8897418bbd', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T04:28:40.336Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6835a10e-5b23-4045-a81e-87526481eb5d', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonpro@gmai.com","reason":"Invalid credentials"}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T04:37:30.158Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1bc1fec3-b569-4419-ae27-10fefff3977c', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T04:37:42.740Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5a85839c-6998-4f50-9993-7d58895040f2', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T05:03:41.026Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('33b23087-4b9b-4106-8393-139f9da01403', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonpor@gmail.com","reason":"Invalid credentials"}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T07:18:41.371Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8f3c53aa-8588-4b0d-9265-25e87e188f40', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:18:50.858Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2a1057fb-52c7-467a-858b-3fdf3ae58060', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"founder@xhenvolt.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T07:23:40.130Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('aee2b05d-84a0-4eec-a2a9-94b1d9ab2c0b', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:23:56.837Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5bb35002-24b5-4c46-ab6d-da6982d35b7f', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:24:07.238Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('885194f3-116f-4934-9924-952be7f7e0d3', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:24:47.517Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1b3ef6e0-d7ab-4f61-8034-f322b7b56a22', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:25:51.178Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c0bb7291-2f5e-491b-9120-193df389ab10', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:26:27.940Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e9c41883-b830-4c4b-9c5e-30d36a394281', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '41.210.141.123', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:26:33.062Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2643941c-b269-4e20-b01e-67d731183997', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'dc004299-6b4a-4ea3-91b6-0e3af70fbeec', '{"name":"Hp 256 Notebook","value":"750000.00","category":"Laptop"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:35:28.850Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8f0b4196-0ad7-44e5-a317-e934f527faed', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'ad39607c-7b00-4be8-b24b-9eade451d80c', '{"name":"Hp 256 Notebook","value":"750000.00","category":"Laptop"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:35:31.555Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('04922844-c62e-4bae-b6e2-78565fe8b5d8', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_DELETE', 'ASSET', 'ad39607c-7b00-4be8-b24b-9eade451d80c', '{"name":"Hp 256 Notebook","value":"750000.00","category":"Laptop"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:35:46.031Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e070d352-036b-43a3-8986-b204713b1a93', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'db53fbc0-ac3c-4e37-b77b-1e4c7c103f97', '{"name":"Huawei Y9 Prrime 2019","value":"250000.00","category":"Smartphone"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:49:53.381Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2412359a-29d9-4ed2-93d0-777aa555cca4', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', '72302ccd-a8d4-4e92-a7cb-13de15cdc0a2', '{"name":"Professional Suit","value":"175000.00","category":"Clothing"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:53:48.889Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('97a0dbcd-cc14-4cba-a2d2-5d86fc99e97e', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'd51e7554-d4dd-4504-a5da-7d2a7511c31b', '{"name":"Gray suit","value":"270000.00","category":"Clothing"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T07:56:39.206Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('289df65e-c44e-49c5-b48f-b2f72156b9c0', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', '58ac9974-d939-4fd4-86f5-21eed816fae0', '{"name":"DRAIS","value":"25000000.00","category":"Management System"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:07:33.691Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bed54e2e-19ea-4236-aec4-9c376532dc37', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', '4f249d3e-c991-450e-b844-6a005616a907', '{"name":"JETON","value":"12000000.00","category":"Management System"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:13:00.754Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9e0e8b93-2e70-4587-ab27-1d2233a8d813', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'c504be1f-0a8a-4170-9bbc-4117a9f0b10a', '{"name":"XHETON","value":"15000000.00","category":"Management System"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:16:44.745Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('571455d8-2719-4471-b426-26320da2a224', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', '1663032e-ecfe-4f63-a108-f2b1ac8a0a2f', '{"name":"CONSTY","value":"11000000.00","category":"Management System"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:20:28.073Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9a96ead7-c760-4e45-a5e1-4ef059b1dd89', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', 'c8783b9e-d8bb-431f-a6e5-075d8d4ee2de', '{"name":"XHAIRA","value":"12500000.00","category":"Management System"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:25:18.326Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('01fd3bbc-71f4-4184-8544-5b3deb3917b8', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'ASSET_CREATE', 'ASSET', '12fe3ccf-7a6c-45e0-b2c2-b4ab61df01d0', '{"name":"Backpack","value":"45000.00","category":"Equipment"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2025-12-30T08:27:33.745Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9fa6d78d-b9cc-4ba8-a04a-b8797db5bbb9', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:11.228Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7ccf609a-8bb0-4739-89ab-6df4b21d611d', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:11.236Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('71f05b00-ecfb-40b7-9dac-35c1c3819301', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:20.190Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5805bd76-b2cc-4d1e-90ae-a8df73634f09', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:20.195Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ec4fa7be-348e-4b22-ad5c-bded5477299a', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:23.455Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('41f0c79a-0cea-4bf0-8687-4e5985128c0e', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T09:38:23.476Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('164e7454-cd60-47c8-99f8-b64607b78605', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T09:38:28.784Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5fa34424-a1e7-436b-ba4b-2e225d1d17d3', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T09:38:29.064Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3c5ea865-eef5-4ae9-a153-69993d65aba3', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:17:34.469Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b7282328-95a5-4327-a4e3-d17cdfaf7b8d', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:17:37.752Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c3b57bbc-b05a-49f5-82ef-151f6e02d99a', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:17:41.050Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b67f38be-a518-4467-9117-c72e9091fee8', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T10:49:50.871Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c9e0ea43-7e18-42eb-88fa-3c3169880991', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T10:49:50.883Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bdfa096d-8080-4995-81c8-4b4de7c4f849', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:49:59.168Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9db5106f-d44d-47ec-b1d1-d715559c5d3e', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:49:59.177Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('164d7ad1-6bf9-4917-9af3-c98e6659f151', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:50:03.501Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d31fe72e-4f09-4bf9-b8d9-8714f744ea80', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:50:05.656Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('93113e86-029a-45e9-ae68-ee9719bb61a0', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:51:09.495Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('50e1fd4a-eb5e-47e6-98d6-712deaa973f7', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:51:12.842Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d17a14f1-6793-49b9-9ed6-b2a8dbd96436', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.107.1 Chrome/142.0.7444.175 Electron/39.2.3 Safari/537.36', 'FAILURE', '"2025-12-30T10:51:41.311Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cdd04fa1-7db1-4072-a331-2c1a1ab96202', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:53:08.157Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('280e09b6-9400-433b-8eae-b2ab60de5918', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:53:08.162Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bc01611b-299d-4856-926d-926641509b82', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:55:47.417Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1f314058-5ab8-480e-809f-1fd98feaecdb', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T10:55:47.419Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fc8070fd-96bb-47da-9806-3f7515a6b2e9', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T11:02:04.488Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('47092af0-296c-4236-bf39-639e9cabc0cd', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T11:02:04.493Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2e7cc930-b11a-42a1-a693-7ecb0e5a107e', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T11:02:10.610Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d14de432-edf4-4bc8-b2b5-70d347b53959', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T11:02:10.614Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('88392283-b0a6-4c6e-a43d-682d1573fca9', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T11:03:06.575Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f7efde72-c8e7-4dbb-b31a-c4b8748b2709', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T11:03:06.577Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('55419fab-21bd-4b1c-9ac1-5ba3e325b643', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:29:51.986Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('56cc39bb-d8e0-4659-a055-7c775cfec66b', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:29:51.987Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2c8ce63f-70aa-4b27-aa9b-fd7c0f21ae30', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:33:36.962Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('92a3d35a-4d43-4aa4-93c3-887f0b63d45c', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:33:36.968Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cf726046-f918-4f8f-86ac-27b4f4ccb99f', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T12:34:12.962Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c8b444b2-f74d-42c5-9ca8-8aff4c65fa57', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"Invalid token"}', NULL, NULL, 'FAILURE', '"2025-12-30T12:34:12.989Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f9e3d5db-2792-4e4e-af25-79c48e9442a2', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:49:52.218Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d02b1ef6-835e-4ce7-b36e-f4f496d8c80b', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:49:52.229Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('24fbddc7-4a1b-401a-bfac-0673d4418955', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:51:33.424Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0a66eeaa-5fde-4e88-b052-497d3744d1a1', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T12:51:42.101Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0ccc5422-e2ba-4c53-91d9-dbd7e7863a31', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T16:31:59.872Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0dca334b-0d1d-4a30-9142-d9f38f1921a0', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T16:38:33.291Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b06ffa6c-04f7-4fef-bdca-ca161b640d06', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T16:56:09.015Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3467cce0-6b5f-4f0e-81c8-340548683305', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T16:56:13.377Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('20d12e16-4007-445b-9b52-004da0b865d6', NULL, 'TOKEN_VALIDATION_FAILURE', 'deal', NULL, '{}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2025-12-30T16:56:25.537Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8eed4b43-e9cc-4b4f-809f-fccef2f400b4', NULL, 'REGISTER', 'AUTH', '308ff494-7095-4ca4-b4d3-46222b52f974', '{"email":"founder@jeton.com","reason":null}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T09:56:55.195Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7bc725ea-54a1-4687-be4a-5a9508485e9c', NULL, 'LOGIN_SUCCESS', 'AUTH', '308ff494-7095-4ca4-b4d3-46222b52f974', '{"email":"founder@jeton.com","reason":null}', '::1', 'curl/8.5.0', 'SUCCESS', '"2025-12-30T09:57:23.193Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bf726c54-e2ba-4d81-a5ef-0cfa16c62f19', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '197.239.8.210', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T07:38:01.039Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('592ec813-eaf3-43f5-ae44-33aab8c906af', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T07:44:26.587Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2765f0e0-6ba5-4e99-b18a-e8cfd6344069', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T09:21:42.447Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('68150c93-f1a6-44ef-ba13-a6fcf0995416', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '197.239.9.226', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T09:36:10.105Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8414bb21-a52d-49c3-a1bf-aaa271b29e0e', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '197.239.9.226', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T09:37:34.696Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('26b06bcf-8674-401b-bc33-31da05ab583f', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '197.239.9.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-05T09:38:14.679Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6ce2bcac-ff00-4f78-9a1b-0c3b87644ee8', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '197.239.9.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-05T09:38:29.888Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5dff4b12-24fd-4b64-b0ed-2aa1d3169051', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"Xhenonpro@gmail.com","reason":"Invalid credentials"}', '197.239.9.226', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-05T09:44:29.691Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f242ddb6-c3a7-45e0-99e5-9afd6237b4b1', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '197.239.9.226', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T09:44:43.137Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d2768b08-5d7a-49cd-b807-255ee05b65a1', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '197.239.9.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-05T10:01:51.771Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3e3801b2-7d11-4d56-8eb5-656b5a33438f', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LIABILITY_CREATE', 'LIABILITY', 'cda9f45e-47fd-4dfb-a941-05386d89d621', '{"name":"SenteGo","amount":"160000.00","category":"Loan"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T16:24:25.945Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5302041d-2211-494b-9c91-3cd3a4f99598', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LIABILITY_UPDATE', 'LIABILITY', 'cda9f45e-47fd-4dfb-a941-05386d89d621', '{"name":"SenteGo","amount":"160000.00","status":"ACTIVE","category":"Loan"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T16:32:46.487Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('834faef7-360e-4cc8-a803-84f16d2dc326', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LIABILITY_CREATE', 'LIABILITY', 'e43d8392-73e5-44ae-9c16-09ad905db28c', '{"name":"Shuheebu","amount":"150000.00","category":"Payable"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T19:58:24.747Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('40c783da-1afb-4c85-9508-e3682cd97c8e', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LIABILITY_CREATE', 'LIABILITY', '2f0e1189-47e4-4200-8925-a48ffe9e42b9', '{"name":"Devo Cash","amount":"40000.00","category":"Loan"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T20:00:04.267Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('4a4d162d-3abd-40c2-a8d9-66c61264d885', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LIABILITY_CREATE', 'LIABILITY', 'ca30b54a-00af-4704-a0a6-bff90c5d5d37', '{"name":"Nile Loan","amount":"90000.00","category":"Loan"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T20:01:06.732Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('16ac4acf-cad8-48d4-a7a0-30ad03ccc751', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T22:21:31.275Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0d23e86c-19f8-48bf-b024-a230bd51b5d9', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T22:21:32.597Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('df2ba6bc-a3e3-4479-afbc-d0dde657333e', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-05T22:32:18.181Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2226e6d3-492b-49c2-a599-090819d2ec07', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T07:06:22.480Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2f44af68-188c-4e81-8567-187009449591', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T07:56:42.092Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bf8ed10a-3927-43be-adc9-9af4117085cf', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:01:50.123Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('00f32b33-6ad6-427f-873d-0330b60c1c60', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:06:28.413Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('40db7d52-6437-4e23-8611-ff1e9bdf7fe6', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:06:33.572Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1c99df3a-4001-4a30-b9cd-9af43e4b91db', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:06:37.712Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('01e5cc39-ee65-460c-9fae-10081bab1119', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:06:45.726Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('570b0c5e-09c1-4c77-8916-77b7d9a95e31', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:08:36.005Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d4f0cade-377f-43f2-97f5-c7be322dcebc', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:08:38.884Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2d77fe5f-a498-4570-83f3-994cd33069ef', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:11:18.532Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b3c2564e-5d66-45e2-b0a0-c05cd67399f0', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:11:22.120Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0b9578c2-9ebb-424a-8865-905c5a310784', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:12:46.670Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6ac55822-b08b-41b9-97e8-9792c5fe3c95', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:12:48.117Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d10d3a6f-965d-41f6-bc9b-522a82145ad1', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:15:03.351Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('729e7548-5676-499c-8af4-c2e4c552134c', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:15:06.970Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a0bb148e-b791-4235-a786-51e58f7d5628', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:15:11.702Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2ca6163c-521b-4ff2-bc89-10fa2b1437c7', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:15:22.646Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e6f4f2b9-44a9-4e2e-a7ae-1176adb1667f', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:20:02.448Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('453594fc-f653-4bd6-a5c6-2e827a14ada3', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:20:03.082Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('eec42b83-95fd-4de2-b3b2-e317410171a0', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:20:35.696Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2f2483d3-254f-4a19-9238-467ef1db6a62', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:20:40.396Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bf3c0f84-05d5-4a02-9b9a-8e1be99ce70b', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:22:42.642Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('86a59129-ebe2-40fb-b04f-728f38b225fd', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:22:48.405Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('56948b4f-4d75-4540-b3b1-f5eb09b6a919', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:23:09.157Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c04300ad-d5cd-43ac-b980-46ee8458a2ca', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:23:12.492Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fc24816c-506c-4577-93ce-e7b9e11d7a6a', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:28:59.944Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2b4c63d2-df0b-4eb4-8430-db1ea40a2326', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:29:20.104Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('142e1430-7902-4116-ae38-8800cb1a72cf', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:33:29.906Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('39cdc832-a934-446c-b750-23a6ce8ac08c', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:33:31.992Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('226aae46-1b27-434a-9f66-be6dc7dd866a', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:33:51.998Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('91e5336c-023d-494a-8037-afbe1273b0ea', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:33:52.417Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d9e15dcc-8ec6-420a-980a-ec5afc2d4f2c', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:38:22.485Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b170b24f-dc9e-4639-931a-7671cf9f46f6', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:38:46.650Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('710acd81-1858-4d8d-b5bb-c4c35a25c8e3', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:50:47.587Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('191a507e-bd79-4e1e-ab8d-0dfb168262b5', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-06T08:50:47.604Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('43a6d624-fbbc-48bb-8ef4-d9bb93d13b16', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGIN_SUCCESS', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":"xhenonpro@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T20:38:15.303Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5b317648-abad-476f-b69f-9f96cfa4c521', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T20:38:19.990Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ee5f248c-28cb-481c-b499-b3d6322762ac', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T20:38:22.010Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('113274ab-8b26-426f-a501-6cba61f2b1c1', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T20:38:22.013Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('92649dfc-315d-4d97-9b49-da934da27a22', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T20:38:22.646Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c6859724-5d7f-4ac5-ba05-4bd7bc3d7d69', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T21:00:20.937Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2526578a-b2ad-4805-9678-3b49f8976fdb', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-07T21:00:21.569Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0849c321-dd81-4c1e-bc8f-38eb195ce666', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-09T06:06:28.047Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('76c7071e-c4e2-4545-a0ed-eff65f9b14a0', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-09T06:06:35.909Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('16723a7d-3980-4a84-b57f-732f52b936e9', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-09T06:06:36.249Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('21f02d53-8a82-4917-8852-e5fa8c5155be', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'LOGOUT', 'AUTH', '9a29b37a-751e-4678-8349-a6e8d90a744d', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-09T06:06:39.396Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e976837a-fc21-44be-9b6e-1034a2989738', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:39.768Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e1e88077-63d4-4cbc-9b66-8c0ed4c34ceb', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:39.840Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('94d90fb3-95f1-40b7-b940-2a4b2b6f781a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:43.411Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6319dfcd-fca3-404c-889e-4e47e7b0a009', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:43.690Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b2313f27-dbad-4530-a864-16d3186e4700', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:50.053Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8d83c36d-2053-4404-82a0-8d37465e85d5', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:52.837Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('16174f5e-2ff2-48fd-933f-cd09120d89b7', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:53.540Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('594ed063-02cf-4a3a-9f3f-626303bb72e8', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:53.652Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('86e3fdd5-ff4a-44b8-820e-879d44eb910b', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:06:56.261Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('633e30d5-252c-47aa-a8ec-04f5e1e6a5ef', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:07:01.012Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('712be2cd-e099-47e5-a501-85ed8fec34b0', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:07:01.766Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('17abadde-e633-4ecd-8fc9-b6b319dc6e50', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:07:01.793Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('317df166-6dd2-4004-8629-efec6c9c131a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:14:30.608Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('65cd62b3-70b4-40c6-bf1e-91309a5f6adc', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:14:34.108Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6187feb8-9a70-417c-be8b-21d2fb64e8dd', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:15:49.445Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dbcd0e19-acfd-4606-af62-47312593d7e8', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:15:49.580Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d3a79976-7107-4c40-a9b5-bd23ef8f7808', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:37:31.115Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('73442d8d-752a-4fd0-9269-1e01b67b0c8e', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:43:18.853Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('638e5f2c-57de-45c1-b4bf-3e8b1cbf86dd', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-09T06:43:24.693Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2287d769-8986-4de5-9507-a104cce31629', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '102.85.9.92', 'Mozilla/5.0 (Linux; Android 12; SOG01) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-09T14:23:54.254Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c0d73123-edf2-431f-99fe-a1bb81becf9a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:21:19.077Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8670cd11-fa19-460b-8545-6eab5a272729', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:21:19.656Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('20d4250d-cd07-414c-8bd3-d89991280bc5', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:38:05.063Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7ebbe628-4f18-41de-8a60-77dda77db86f', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:38:05.612Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b89d94f2-9207-4263-a19f-5e0cf6f4c974', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:41:19.229Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0484502d-8648-49f1-a0f2-1052ea93c5df', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:41:19.231Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('06a57936-3996-49d4-97c8-c44b4d4d3fc4', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:58:08.316Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2a0a4fad-a29d-43ca-9e75-a3697005e4d1', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T02:58:09.111Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a80e3b27-fb82-46c6-9a43-dc4063fa5c7a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:17:57.554Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6dd074a1-cb13-4cce-b6f6-c62087c1eef5', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:17:57.661Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('590f21ba-e23c-4d8b-88f9-7c88bfaa4d00', NULL, 'ROUTE_DENIED', 'STAFF', NULL, '{"reason":"No token provided"}', NULL, NULL, 'FAILURE', '"2026-01-10T03:21:02.121Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('74867c35-56d8-4913-bc88-9bbab449d17b', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:31:16.870Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('32150332-9182-4cab-9228-cb79bd35fcbe', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:31:16.878Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3d04a629-25aa-4b95-8f4c-715ff64ac3ff', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '197.239.10.234', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-10T03:31:36.662Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1bf3c5fa-f3a4-4e59-a6a8-5d6d52cb61a0', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '197.239.10.234', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-10T03:31:36.669Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e61b51fa-8f8a-478f-af7f-4d2d69b73783', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:39:30.470Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('332fdbb2-cf18-415f-a599-d7ef9363d882', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T03:39:30.484Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e2e5ba92-b7ed-4e9c-b215-513bf699405f', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:03:32.402Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3177a42e-6ca6-47b1-add1-d21071c60c02', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:03:32.497Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e502af43-d812-40ae-8ce6-e305ac2b6ec4', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:06:49.340Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('930d4801-bc93-407e-9b23-25da5b69efc3', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:06:51.763Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f8aad0ee-450e-43e8-8b5b-c1ca2526811a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:10:46.593Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('489508dc-1543-4602-9ebd-6cb8988e6df3', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:10:46.902Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c4744ff5-5643-43c3-9d0d-935ace634c4d', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:15:18.192Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0c34f41d-a74e-4323-bd30-c09b06f32c4e', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:15:18.219Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ddc425c7-0280-44ad-8550-5234952b6d4a', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:17:02.021Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('85c0e575-fe19-4872-996c-840631eea502', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:17:02.325Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('82b9b40d-7369-4c74-befb-b3fc808b057b', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:18:38.480Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c610eb48-bd2f-45b7-855f-d3e7abbb6ae4', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:18:38.756Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1d3c6008-1553-4c65-8705-77c5f63ea841', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:24:41.247Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a04c1c83-38ff-427f-b8aa-a10b736169f0', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T04:24:41.525Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('178afd76-e8f6-4567-a2fd-7b2c6b55d495', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T07:48:20.077Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('96132424-860e-47f6-a590-02a73bcea531', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T07:48:20.086Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0917752a-b974-40f1-aa4a-86e5ecac7460', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T07:56:43.129Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b91c5c0f-02ca-46c2-92a8-aca231640389', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'FAILURE', '"2026-01-10T07:56:43.134Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0c241ac2-ed45-4cb6-b229-ccc7dc8a8573', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.2.191', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-11T08:24:32.241Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('af962e17-3e08-42e6-8874-f9c3891e1768', '9a29b37a-751e-4678-8349-a6e8d90a744d', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.2.191', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0', 'SUCCESS', '"2026-01-11T08:24:32.682Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('41cf99ee-b665-40c8-8806-892a88b40166', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '102.86.9.49', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-11T10:57:09.521Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8cc116b0-ec7a-4b34-8cc6-3ae7dde08158', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.9.49', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-11T10:57:11.050Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('561abdaf-032b-45f6-8fe3-f595fb87d774', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.9.49', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-11T10:57:11.494Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('326eb0d9-b695-426e-a68c-47af3bd4b418', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.10.233', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-11T11:03:06.071Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6f5d8d96-5a85-4188-bdca-0c4cb55e0a2b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '102.86.10.233', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-11T11:03:06.528Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f24663f2-3bd5-4e8f-8a72-6cb0aadaec4b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '197.239.7.177', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-13T07:23:47.410Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2fa11a6c-1880-46bb-9a47-24a39b1a041c', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '197.239.7.177', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-01-13T07:23:47.987Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e5b8c132-51c1-4065-8379-355276be8540', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '41.75.183.153', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-01-26T14:00:58.467Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6ed30711-e57f-4bbd-8878-9893b0a04e36', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.183.153', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-01-26T14:01:01.190Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cee22593-e1f3-403b-b698-87c5593b4314', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.183.153', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-01-26T14:01:01.670Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7b337ae4-3564-491c-8f9b-39edc80b833d', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonprototype@gmail.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:12:47.668Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('de514d97-e469-4a19-be12-5d3709de6e5d', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonprototype@gmail.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:12:54.825Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1d1b40eb-4c3e-4fab-9ee8-8891233106ef', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonprototype@gmail.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:13:03.851Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2c6dead4-ce60-4b01-8ce7-1c4abcbaaa1d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:13:09.841Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0f953be5-f411-4519-81c7-764d53ea713f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:13:13.314Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('73b88e09-4c5e-42f2-8224-54e43f35cb4b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:13:14.563Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dc9eb6e8-6e4e-4212-819b-44dd0a3ef8d4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:13:14.828Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c799a140-43f1-4ce4-b713-7103d1ff72b3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:13:15.079Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('65dd4673-fd55-4c9e-9142-57cdcc33ed36', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:15:05.500Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9a2de34f-a340-428d-9663-2225ca4992f3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:15:07.428Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1764399c-eb27-4c88-a356-381b87fb01fe', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGOUT', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:23:53.364Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('bcfdfeaf-4665-4d54-a6de-639d210ccb64', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:23:57.372Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f640de08-a227-405e-82de-0d4e13f9c0a9', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:23:57.917Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a841dca2-3598-4d2b-b017-f048e78a2f46', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:24:00.403Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a0cc8c83-bfe5-4a81-9d9c-aaf028347b0b', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:24:00.414Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dd8ad4ee-1ae4-451f-a5d0-e2476566aa2d', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:24:10.141Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('19437587-faf2-4110-b28c-b0445b905e3d', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:24:10.164Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('086c423c-3512-45df-a53d-0bcbbc455345', NULL, 'REGISTER', 'AUTH', NULL, '{"email":"test@user.com","reason":"Unknown error"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:28:28.575Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1a60cd2c-f038-4f8c-a0f1-b27f13099dad', NULL, 'REGISTER', 'AUTH', NULL, '{"email":"test@gmail.com","reason":"Unknown error"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:29:19.813Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d08cdbea-28c3-4e05-8cf8-e0531b499465', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'REGISTER', 'AUTH', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', '{"email":"halima@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:31:24.298Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5f4a522e-0128-4479-a536-af900fe5a320', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:31:26.639Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('035de06c-050f-4b33-8f0c-cfccbb1c6335', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:31:28.093Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dfd14065-e22b-46d3-a897-fddf3c7f8f90', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:31:28.149Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cdd7c51c-1730-4e96-95cf-9eabcec8b4ba', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:31:28.196Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e03467b1-1d41-4ef2-af82-cd32e8671fc2', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'LOGOUT', 'AUTH', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:32:12.209Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('70beda5f-59dd-450a-b77c-15964bbae842', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'LOGOUT', 'AUTH', 'ddc9e2fc-1cc8-427b-b202-915458f0f5f5', '{"email":null,"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-12T17:32:13.820Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9b2fb30a-03b2-484a-910e-143bb1a89f71', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:32:16.446Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2f98b06d-2d16-4b24-bd55-475814d38b75', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:32:17.159Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3be20044-d221-424a-9003-7a6720f2e864', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:32:18.215Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f587c903-7351-4ffe-8a35-28a12c1ac4cb', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:32:18.224Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f4db70c7-9137-4bed-a29c-bfb226f76559', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:34:24.401Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8e551349-8a39-45ce-b3c5-f6bbdfbd82a0', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:34:26.655Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('50d29d76-4a49-44e6-8a7b-4183c5b6bf44', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:41:34.711Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('709fe19f-548f-47ab-924f-eeae23efd265', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:41:35.424Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('813f4497-6b19-4dd8-aeed-1ed47ad85fe0', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:44:09.953Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ffa85d01-5477-45a8-8470-cbb5495a7eb4', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:44:09.956Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f7d7c2ed-5b3f-46e2-96c5-49a2e5d3a811', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:44:11.675Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('063a0156-3e7a-4eee-9bc2-86944a449b70', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:44:11.685Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3d757f71-1c4a-4da3-853d-611861d20ffa', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:58:36.134Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3f22ff76-2b17-4619-a8c2-b2b5c7818cda', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:58:36.125Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d4c9905c-3648-4a1d-bb85-5bb45438d6be', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:58:36.335Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7480338e-7605-482e-8345-5935aaed5616', NULL, 'ROUTE_DENIED', 'ROUTE', '/api/auth/me', '{"reason":"No session provided"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-12T17:58:36.339Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fe8913fb-49e3-4197-9bb7-b5c886e9a12b', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonprototype@gmail.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'FAILURE', '"2026-02-19T03:11:14.494Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('be5928be-9c22-4220-bb8c-e745a210643b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T03:11:23.143Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('040b2519-3fea-440f-a2e7-8def4ebe59ec', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T03:11:27.253Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('4e8d3303-633e-4df6-b2f1-f9424257c51a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T03:11:28.606Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8ed4c9f9-529b-441d-b97c-1ff4b7d2c535', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T03:11:29.899Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('714afd76-c8ac-471c-8e46-94fe4b9ae89e', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T03:11:40.625Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0e591cba-b086-4e95-b355-30c58f87923b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T04:57:54.800Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('55ff2b2d-970a-46d7-829f-f4160fac438a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T04:57:56.096Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ae9defce-064c-4409-bd2b-663e49f59e12', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T04:58:03.563Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('30823e3d-c4b2-47f6-ab9c-2a078b92e563', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T04:58:05.172Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fab15a18-390a-483b-98c7-bf551193d1a3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T05:01:13.510Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6e6b907a-4426-45aa-ba91-114e4e25a55c', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T05:01:15.220Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f2d069c4-5069-43da-a819-42545db0e876', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T05:30:34.072Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e7bdbc66-8ff8-49c8-8d0a-27aac08be053', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T05:30:35.337Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1100de95-47eb-4f38-b657-54c18bc9198d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T07:45:37.703Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fe5fdf3c-400c-4759-9107-2d807f239f5b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T07:45:38.961Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0a0d9af8-0a90-452a-9b98-dd661f4ee45a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T09:29:11.916Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('10b0f353-e054-41c3-81f4-78f20bf0299d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T09:29:23.791Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9d389a07-338a-433e-bfc1-06c64ebab346', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T09:57:44.419Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c5a1c200-7547-44a9-9525-970df903e051', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-19T09:57:45.731Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('959ff41e-a996-4a4f-bcb3-bb957ffab721', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T02:05:53.498Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cd4e2509-2bb4-496d-bbcb-f56734b04b36', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T02:05:54.853Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e41fab4b-ca0f-481c-a5d2-11138a81e9d6', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:02:17.960Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6be2707c-8977-4c05-8785-5bb300678248', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:02:19.357Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f53b54e2-0429-429c-9889-9efefeb408ab', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:03:10.718Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('0d8230c1-4735-475a-8ed5-27b6003059c5', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:03:12.062Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d9a3be03-059b-442a-ac41-0e6f3032bf24', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:16:33.816Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9609f1f2-5894-4f69-96d4-92c67c818be9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-20T13:16:35.181Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('768983a5-1f0f-405e-9db5-71b29d8c349f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T05:00:35.559Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1e9253fc-f853-4ba8-a50e-c3fbf6b4034b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T05:00:36.181Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c12465d7-75f4-40bd-a0ba-d9addddc1b92', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T05:34:13.861Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5fa5bd32-db3a-4a03-a621-471b8bd0e870', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:33:03.866Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('36cd075f-c6f8-477a-8c73-a2de5f6ff72f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:33:05.146Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('35ec24f5-a947-46c0-b085-6d0313108e54', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:56:02.212Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2c4c93b4-a508-4fdf-a28d-2ab4ac5363e9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:56:03.493Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9750adcc-1ae0-4db6-b284-ba7c2d6c7413', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:56:12.705Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('555c4560-c82a-4a8f-b01a-dcf12dae8a28', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:56:14.761Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('05baf812-3bb8-47da-9c3c-cb233d5cb96e', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:57:19.801Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f672241e-bbc8-40c3-b8f5-5261507c2fac', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:57:21.051Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('140885fa-66b1-4e4a-a4c4-82293330f403', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:57:50.770Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('fe54ba5e-a86c-4e3c-b9a8-809bcd7387d2', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:57:51.956Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b83dc2ba-c790-474e-9518-910a8ff504fc', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:57:53.593Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c7adab27-0154-49d8-a128-f225484219d5', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:58:50.675Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e0a039c0-7819-4ac7-8a4a-39cf6e5ee967', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:58:52.598Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('02c40d2a-d9b5-4bcd-99f7-602a67188060', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:59:23.130Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5b6373e3-4b9c-4f25-88fd-1e903a7baed4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:59:24.970Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('868bb73c-cc5c-4a92-bd25-d6d8a1bd2c08', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:59:57.509Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('35fdfb37-373a-42e7-a3f4-884f3d23347d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T06:59:58.770Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('48bff332-33e3-4c67-aecb-91ffb2623152', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T07:03:17.555Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('71345289-22b8-48ea-8977-f45749686010', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T07:03:22.449Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ed4665a3-3d99-4843-b0ee-310d137455ff', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T14:15:45.122Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('06d01e14-2e5c-4ce3-bd70-964973dd20f7', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0', 'SUCCESS', '"2026-02-22T14:16:08.735Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('52ec9baf-b111-4f0b-b394-8425bf031741', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:11:19.182Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a71dad06-0856-4b63-b8df-89e192085642', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:11:21.050Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a2c7c27e-8c3f-47be-bbdd-2ede9aff3a98', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:11:21.480Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c0a67bd0-90bb-491f-80f0-63d6337efd5f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:11:38.376Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e1f4ada5-eb39-422c-bff0-326886fe4ed9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:11:38.737Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('06335e3d-9f2e-476b-b8c4-6d22b81f0406', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:21:36.786Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('480d6312-81a7-4b62-925b-bed9b19b5326', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '41.75.184.3', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', 'SUCCESS', '"2026-03-02T15:21:37.210Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('839f9ed7-952a-4014-8967-a3c3458584b4', NULL, 'LOGIN_FAILURE', 'AUTH', NULL, '{"email":"xhenonprototype@gmail.com","reason":"Invalid credentials"}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'FAILURE', '"2026-03-04T14:24:51.525Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('72a5474f-4f1e-4feb-b573-bd0f0b3d4998', 'b3871542-10e2-4766-94e1-f5734398c47b', 'LOGIN_SUCCESS', 'AUTH', 'b3871542-10e2-4766-94e1-f5734398c47b', '{"email":"xhenonprototype@gmail.com","reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:25:07.754Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('81601575-f942-4197-b935-409f4a22ef65', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:25:35.113Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('71e7516d-a948-4579-ae45-8e1015eed773', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:25:37.056Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d7d41d81-9246-4ec8-8a97-8b2462102b66', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:26:37.206Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5d16d767-10f5-4f02-885c-74eb988ba21a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:26:38.539Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1c2441d1-d14f-4074-86f6-407c2193db62', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:28:23.866Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5b2e0451-f555-44f5-82a6-5c177d9e285a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:28:25.119Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('971eb1c3-1280-43e4-8bf5-2768dfe96407', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:35:51.462Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('23b4d2de-a906-40f8-924b-64bb6a703f1d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:35:52.762Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7bfc68b7-327a-4948-adef-a7cf32de3018', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:36:44.606Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8a3f272d-9f0f-4738-862b-7fe09176928d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:36:45.998Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e2a993e9-6341-4542-a1f3-ece12d4af419', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:51:27.384Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dcb172c3-6c3c-4a36-81bc-3cc854b20ee6', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:51:28.672Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8d265863-f0a3-4eb0-8c64-ce740d5ae09a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:53:10.346Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('24ce4c2f-baab-4b4d-b6de-fa957e254df4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:53:11.600Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7a2b41b8-c5ec-4d75-86b5-000f0d2a2ccf', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:53:50.063Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('21701c18-f068-4998-afff-ea3d0a1e91b6', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:53:53.687Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('637adf25-a99a-4ad7-9b4a-148a0d4a64c3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:54:18.132Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7ec989ef-ac58-4e25-984a-91cc5ae18768', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:54:19.513Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6e3490c6-c58b-4444-ad60-36a8258f63ac', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:54:22.309Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('d9a5a91b-c79b-48de-9abb-29155dc39587', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T14:54:23.626Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b8601532-703a-4042-81fa-86deccda98c7', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:10.798Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('aa31f052-9358-458c-93b2-622a75dfc801', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:10.802Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9d6fe311-b1d7-4728-9fae-f60eefad9825', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:17.992Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5d3120f3-5b95-4fb6-ac45-e51eec4b328e', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:19.255Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('206307de-ed02-4721-9e91-afec24be4477', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:24.450Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1c81f543-d345-4ed9-b500-bc45def8f25d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:25.712Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6c060b2d-dfd8-4e31-a24b-7d3fadde075f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:33.599Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('381fc0e3-63e3-4898-8e5b-0d4ece9f4ec9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:34.846Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('19b92e0e-1813-4748-90f6-dd2cf558b5f8', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:48.508Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7b6caa5b-4fb4-4f04-8f7f-62814ad11750', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:39:49.741Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('f32fff9d-94d0-4791-9ad8-8347cbfedcc5', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:40:48.400Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('916c86a9-8fde-458f-ace6-ede11ea5c806', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-04T15:40:49.631Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('acd268cc-bf27-4d1b-ade0-73338a0486cf', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:26:50.929Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('269c1fbc-a7fb-468d-aeac-738dbfa904b4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:26:52.415Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5efcdc43-9be1-4013-8634-7ca423646d56', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:26:57.792Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('22b7fe5d-38a1-47d7-81ac-e49c34589c53', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:27:07.883Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('831169f7-246c-41cf-bd94-a09568befd80', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:00.508Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('930eeaa7-9493-40cd-840d-b587adc2776e', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:04.735Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('637de323-c258-4515-9ab1-994e1f6d60ff', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:06.269Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b995d0d4-1387-455c-9cb6-48b2512395e0', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:35.692Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('329ca4f9-90cf-4d41-ab45-17bc35ffd25b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:37.539Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('92b01310-6e5b-4cea-8dc0-ae1ae6f02896', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:42.091Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a3617911-181f-4318-b543-465709b0dfae', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:28:43.832Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9d09f8f1-a64b-42af-8afe-42957e49d8f9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:29:49.411Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e14f2ac9-7d1d-4167-9a69-6ab57f1174dd', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:29:51.576Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('89b5d470-6b86-4ea8-875e-8a2c7de7bfa7', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:35:00.390Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('a8b88ed9-b72b-43dd-a4b4-0c7a38d75dd2', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:35:01.639Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ef223b4b-0c2c-4f0b-ba9f-ac277a8d030d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:41:03.823Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('da31d962-bd8e-4b84-89a0-f320245ab89b', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:41:05.117Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('9329a48d-6df9-4a82-8932-8a9387dbff64', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:41:26.822Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c0f282e7-aeb4-40d7-9c11-5930e97a6618', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:41:28.090Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e61055d1-8947-404f-9e7c-ffd775134503', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:41:56.819Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('713279fa-72d3-47f3-8209-a4ae9035c66e', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:42:02.040Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('6c695abd-71f2-4a6e-83a2-7b103baf5e30', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:42:05.316Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('8e114c75-3f22-4122-a773-cbc905c0377a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:42:06.602Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('71976c54-5276-4378-b427-6a53ddb577ac', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:43:28.654Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('ad3c4b18-e171-42c8-b88b-87d70daa23f3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:43:30.055Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5e5cc731-b43a-489e-9a95-994929661db3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:45:34.596Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5469f6a5-3381-4b0a-961d-acc793268423', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:45:35.968Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('3d243302-d79f-4459-8d34-2c6043f38a6a', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:17.571Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('785de919-9164-4caf-ab56-bc74a3623d73', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:21.124Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('87a5194c-9baf-494f-a696-425bb955a1e2', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:22.101Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('cbf36d28-42c3-42a4-90b8-63b79fe2522d', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:26.486Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('1446153e-14ca-4d7d-9793-786dace79f48', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:27.717Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2431795a-0cc0-49f9-9901-e01bffd3f0b3', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T02:47:28.976Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('5c7a4849-90a4-4974-86ac-b9c689533545', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T03:13:58.141Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('eabd5091-7f93-497e-ba41-81b9728cd842', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T03:16:30.948Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('2bd199d6-571b-4ac2-8a26-09a27b571ff9', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-05T03:16:32.356Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('11cbbde9-1d09-4272-82af-05ef7d885000', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T03:39:16.515Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('e5c7b8ad-2c05-42f0-817e-abedbd7f965f', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T03:39:23.036Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('c893d2d5-c88a-48ee-ac0f-a55c07dc93d4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T04:33:34.820Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('85dce323-e861-41ef-8853-5a5e9cca82aa', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T04:33:39.212Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('b6208788-b84a-4d9e-8e6e-5f4397fdf4fc', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T05:10:40.407Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('be5a7c04-159d-4ef4-8c54-7a1e7dcce9d4', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T05:10:44.923Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('55faa106-d4eb-4d16-bfbc-7f55717595fd', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T09:37:03.853Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('01b92cf8-6773-48f3-aef5-373f753f6500', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T09:37:15.342Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('7015d213-5c29-4c85-8831-56801130b901', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T10:55:06.608Z"');
INSERT INTO audit_logs (id, actor_id, action, entity, entity_id, metadata, ip_address, user_agent, status, created_at) VALUES ('dbfeeaff-30d8-4956-8e91-98bcdb05b8a8', 'b3871542-10e2-4766-94e1-f5734398c47b', 'PROTECTED_ROUTE_ACCESS', 'ROUTE', '/api/auth/me', '{"reason":null}', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0', 'SUCCESS', '"2026-03-08T10:55:08.529Z"');

-- clients: 0 rows

-- contracts: 0 rows

-- deal_sales_mapping: 0 rows

-- Data for: deals (7 rows)
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('b7e1013f-1366-48dc-ac17-b0e005f544b6', 'Deal Without Client', NULL, '1000000.00', 'Lead', 50, NULL, 'ACTIVE', NULL, NULL, '"2026-02-19T05:00:12.571Z"', '"2026-02-19T05:00:12.571Z"', FALSE, NULL, 'Testing without client name', NULL, NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('3128dad0-3895-4987-a5b0-8fbaab6aad17', 'Excel Islamic School Deal', 'Excel Islamic Nursary and Primary School', '2500000.00', 'Lead', 100, NULL, 'ACTIVE', NULL, NULL, '"2026-02-19T05:16:56.882Z"', '"2026-02-19T05:16:56.882Z"', FALSE, NULL, 'Set up the system for Excel Islamic nursery and primary school located at Busembatia in Bugweri district', NULL, NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('b44b2d52-ff73-417d-997c-d381c2dfaeba', 'Enterprise Software License', 'Acme Corporation', '10000000.00', 'Negotiation', 75, NULL, 'ACTIVE', NULL, NULL, '"2026-02-19T05:17:05.783Z"', '"2026-02-19T05:17:05.783Z"', FALSE, NULL, 'Large enterprise software deal', '69f28a59-c116-4486-88d0-c8b41975d3af', NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('983340db-29b7-475f-b342-186dba6b0edb', 'School System setup and integration', 'Excel Islamic Nursary And Primary School', '2500000.00', 'Won', 100, '"2025-11-30T21:00:00.000Z"', 'ACTIVE', NULL, NULL, '"2026-02-19T05:18:26.636Z"', '"2026-02-19T05:18:26.636Z"', FALSE, NULL, 'We set up the school system at excel in Busembatia', 'b3871542-10e2-4766-94e1-f5734398c47b', NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('b8f4458b-d64b-4e58-8a6c-a97fc71d396a', 'Attendance system', NULL, '2000000.00', 'Lead', 90, '"2026-03-01T21:00:00.000Z"', 'ACTIVE', NULL, NULL, '"2026-03-02T15:18:43.751Z"', '"2026-03-02T15:18:43.751Z"', FALSE, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('e30a1945-9a7e-44c8-8436-357a0e944c8d', 'DRAIS school system', NULL, '1600000.00', 'Won', 70, '"2025-07-30T21:00:00.000Z"', 'ACTIVE', NULL, NULL, '"2026-01-10T07:55:34.985Z"', '"2026-03-02T15:19:24.531Z"', FALSE, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO deals (id, title, client_name, value_estimate, stage, probability, expected_close_date, status, notes, created_by, created_at, updated_at, locked, deleted_at, description, assigned_to, client_id, system_id, prospect_id) VALUES ('865f0883-fcf7-40cf-8409-6b0ed69cb790', 'Attendance system ', NULL, '1000000.00', 'Lead', 80, '"2026-03-03T21:00:00.000Z"', 'ACTIVE', NULL, NULL, '"2026-03-02T15:21:34.176Z"', '"2026-03-02T15:21:34.176Z"', FALSE, NULL, '', '69f28a59-c116-4486-88d0-c8b41975d3af', NULL, NULL, NULL);

-- Data for: expense_categories (10 rows)
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (1, 'Operations', 'Day-to-day operational expenses', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (2, 'Salaries', 'Employee compensation', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (3, 'Software', 'Software subscriptions and licenses', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (4, 'Hardware', 'Equipment and hardware purchases', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (5, 'Marketing', 'Marketing and advertising', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (6, 'Travel', 'Travel and accommodation', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (7, 'Infrastructure', 'Hosting, servers, cloud services', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (8, 'Professional Services', 'Legal, accounting, consulting', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (9, 'Utilities', 'Office utilities', TRUE, '"2026-03-08T01:26:39.033Z"');
INSERT INTO expense_categories (id, name, description, is_system, created_at) VALUES (10, 'Other', 'Miscellaneous expenses', TRUE, '"2026-03-08T01:26:39.033Z"');

-- expenses: 0 rows

-- Data for: infrastructure (7 rows)
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('adec8161-e134-4584-836d-7dec89ddb00e', 'xhenvolt.com', 'This is the domain name for the company', 'website', 'xhenvolt', 'limited', 'medium', '2500000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2025-12-30T11:32:09.093Z"', '"2025-12-30T11:32:26.255Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('1cd237d4-092b-4c55-a19d-2e6dc315f16d', 'Flyer', 'Flyers', 'design_system', NULL, 'limited', 'low', '50000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2025-12-30T11:45:29.938Z"', '"2025-12-30T11:45:29.938Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('e030cbfb-6573-4d14-b10b-bbe12dda702e', 'Logo', 'Xhenvolt Logo', 'brand', NULL, 'limited', 'medium', '50000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2025-12-30T11:44:47.402Z"', '"2025-12-30T12:01:22.973Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('92c4797e-cd79-48a7-a6ad-df58f1d2dbd9', 'Business Cards ', 'Small cards given to prospects and other people, containing brief information about xhenvolt and contacts', 'brand', 'Xhenvolt', 'limited', 'medium', '20000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2026-01-05T15:53:02.825Z"', '"2026-01-05T15:53:02.825Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('7f5c5777-1419-4f76-b687-389a88b1818a', 'Embroided Seal', 'This is the company seal for the staff to use on crucial documents', 'other', 'Xhenvolt Admin staff', 'limited', 'medium', '50000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2026-01-05T15:54:43.630Z"', '"2026-01-05T15:54:43.630Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('55f5a6e7-980d-46f4-a573-4b5f2f0602b0', 'Company t-shirts', 'These are t-shirts worn by company members and field officers when performing xhenvolt work', 'brand', 'Company staff', 'limited', 'medium', '105000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '"2026-01-05T15:56:00.253Z"', '"2026-01-05T15:56:00.253Z"', NULL);
INSERT INTO infrastructure (id, name, description, infrastructure_type, owner_name, access_level, risk_level, replacement_cost, domain_name, domain_registrar, domain_expiry_date, domain_auto_renew, platform, social_handle, social_recovery_email, social_recovery_phone, file_location, version, status, notes, created_at, updated_at, created_by) VALUES ('c321b735-3a80-4ede-804e-f5f9298ba1fd', 'Huawei y9 prime 2019 ', 'HUAWEI Y9 PRIME 2019 with 4GB RAM and 128GB of storage, retractable pop up front camera and 4000mAh battery', 'other', 'FOUNDER', 'limited', 'medium', '180000.00', NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, 'archived', NULL, '"2026-01-06T15:10:42.220Z"', '"2026-01-10T03:09:24.040Z"', NULL);

-- infrastructure_audit_logs: 0 rows

-- Data for: intellectual_property (8 rows)
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('540575d2-5ac4-498e-a0cd-1fa1b51b42e5', 'Jeton Platform', NULL, 'software', NULL, '50000.00', NULL, NULL, '50000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'deprecated', NULL, '"2025-12-29T21:00:00.000Z"', '"2025-12-30T09:04:50.614Z"', '"2025-12-30T09:08:57.706Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('6723dd1d-acec-4ff0-b559-c458ba5b1e9a', 'DRAIS', NULL, 'software', NULL, '12000000.00', NULL, NULL, '18000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2025-12-30T11:06:13.491Z"', '"2025-12-30T11:06:13.491Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('1a94e7c5-ebfe-485d-a5a9-05db42cc8289', 'XHETON', NULL, 'software', NULL, '10000000.00', NULL, NULL, '15000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2025-12-30T11:07:19.287Z"', '"2025-12-30T11:07:19.287Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('5d60315e-98bc-4250-b3c4-582c96145a89', 'CONSTY', NULL, 'software', NULL, '12500000.00', NULL, NULL, '16000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2025-12-30T11:07:49.099Z"', '"2025-12-30T11:07:49.099Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('7c946ede-1ba6-4029-94fc-175a3c707744', 'XHAIRA', NULL, 'software', NULL, '8000000.00', NULL, NULL, '14000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2025-12-30T11:08:12.528Z"', '"2025-12-30T11:08:12.528Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('f038d2fe-d707-4564-bef7-5f754dbafbd4', 'JETON', NULL, 'software', NULL, '15000000.00', NULL, NULL, '25000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2025-12-30T11:09:20.535Z"', '"2025-12-30T16:39:56.364Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('7d8b7f4f-a351-402f-9dc2-e3ee99afec2c', 'Test IP', NULL, 'software', NULL, '25000.00', NULL, NULL, '200000.00', 'cost', '0.00', '10000.00', 0, 'license', '100.00', NULL, 'deprecated', NULL, '"2026-01-04T21:00:00.000Z"', '"2025-12-30T09:05:55.633Z"', '"2026-01-05T15:49:58.152Z"', NULL);
INSERT INTO intellectual_property (id, name, description, ip_type, ip_subtype, development_cost, development_start_date, development_completion_date, valuation_estimate, valuation_basis, revenue_generated_lifetime, revenue_generated_monthly, clients_count, monetization_model, ownership_percentage, owner_name, status, launch_date, sunset_date, created_at, updated_at, created_by) VALUES ('19e01c52-297e-4766-9a5b-47206acbc91b', 'XHENFY', NULL, 'software', NULL, '100000.00', NULL, NULL, '17000000.00', 'cost', '0.00', '0.00', 0, 'license', '100.00', NULL, 'active', NULL, NULL, '"2026-01-10T04:04:38.943Z"', '"2026-02-20T13:03:00.396Z"', NULL);

-- Data for: invoice_items (10 rows)
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('31216c54-8121-44f4-8d28-c64e5acf4bd9', 'eb5f1055-0f66-4f2b-975f-82eeddca1b1f', 'Mobile App Development - iOS & Android', '1.00', '4500000.00', '4500000.00', '"2026-02-18T11:41:35.968Z"', '"2026-02-18T11:41:35.968Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('3c19688c-1624-40e0-b0cf-88bc1db1d790', 'eb5f1055-0f66-4f2b-975f-82eeddca1b1f', 'API Integration & Backend Setup', '1.00', '500000.00', '500000.00', '"2026-02-18T11:41:35.968Z"', '"2026-02-18T11:41:35.968Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('b6dced7b-9bb5-4b6e-9aa8-6f97b3c14ea5', '97ee78f1-2adf-4505-b634-d105a56e4c8a', 'Website Design & Development', '1.00', '2000000.00', '2000000.00', '"2026-02-18T11:41:36.411Z"', '"2026-02-18T11:41:36.411Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('716357b9-6619-402a-b8f2-e36b803240ba', '97ee78f1-2adf-4505-b634-d105a56e4c8a', 'E-Commerce Integration', '1.00', '1000000.00', '1000000.00', '"2026-02-18T11:41:36.411Z"', '"2026-02-18T11:41:36.411Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('7576400a-e4ce-446d-af64-6c0e44f122c4', '12f0c2cb-a123-4782-ad41-ee2b2b5fb396', 'System Architecture Consulting (40 hours)', '40.00', '25000.00', '1000000.00', '"2026-02-18T11:41:36.665Z"', '"2026-02-18T11:41:36.665Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('b7ce2fe5-e0cb-485a-834c-6b68e1881875', '12f0c2cb-a123-4782-ad41-ee2b2b5fb396', 'Technology Strategy Workshop', '3.00', '500000.00', '1500000.00', '"2026-02-18T11:41:36.665Z"', '"2026-02-18T11:41:36.665Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('55ccd39d-5aba-42ce-baef-2f2e94d58bda', '4aadf72e-06e1-4814-bd76-809c2fb1188c', 'UI Design - 50 screens', '50.00', '15000.00', '750000.00', '"2026-02-18T11:41:36.918Z"', '"2026-02-18T11:41:36.918Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('3b386106-0c57-4fd0-92f3-f1525cdab89a', '4aadf72e-06e1-4814-bd76-809c2fb1188c', 'UX Research & Testing', '1.00', '450000.00', '450000.00', '"2026-02-18T11:41:36.918Z"', '"2026-02-18T11:41:36.918Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('4cdb27e2-2921-4472-bbc5-4d33f9ea64af', '5df60037-e573-4536-989c-e3c4fee560f6', 'DRAIS School Management System – Gold Plan (Setup & Configuration)', '1.00', '2500000.00', '2500000.00', '"2026-02-18T12:18:06.352Z"', '"2026-02-18T12:18:06.352Z"');
INSERT INTO invoice_items (id, invoice_id, description, quantity, unit_price, total_price, created_at, updated_at) VALUES ('49b7e678-0dab-41b7-ab20-7c5d59cb8849', '5df60037-e573-4536-989c-e3c4fee560f6', 'Excel School Online Presence (Website & Digital Setup)', '1.00', '450000.00', '450000.00', '"2026-02-18T12:18:06.352Z"', '"2026-02-18T12:18:06.352Z"');

-- Data for: invoices (5 rows)
INSERT INTO invoices (id, invoice_number, invoice_name, client_name, client_email, client_phone, client_address, company_name, company_address, company_service_type, issue_date, due_date, subtotal, tax, discount, total, amount_paid, balance_due, status, notes, currency, signed_by, signed_by_title, payment_methods, payment_method_used, created_at, updated_at) VALUES ('eb5f1055-0f66-4f2b-975f-82eeddca1b1f', 'XH/INV/2602/001', 'Software Development Invoice', 'Tech Innovations Ltd', 'accounts@techinnovations.ug', '+256 701 234 567', 'Plot 15, Kampala Road, Kampala, Uganda', 'Xhenvolt Uganda SMC Limited', 'Bulubandi, Iganga, Uganda', 'Software Development & Digital Solutions', '"2026-01-24T11:41:34.385Z"', '"2026-02-15T11:41:34.385Z"', '5000000.00', '500000.00', '0.00', '5500000.00', '5500000.00', '0.00', 'paid', 'Mobile app development complete. Deployment to production completed.', 'UGX', 'HAMUZA IBRAHIM', 'Chief Executive Officer (CEO)', '["Bank Transfer", "Mobile Money", "Cheque"]', 'Bank Transfer', '"2026-02-18T11:41:34.385Z"', '"2026-02-18T11:41:34.385Z"');
INSERT INTO invoices (id, invoice_number, invoice_name, client_name, client_email, client_phone, client_address, company_name, company_address, company_service_type, issue_date, due_date, subtotal, tax, discount, total, amount_paid, balance_due, status, notes, currency, signed_by, signed_by_title, payment_methods, payment_method_used, created_at, updated_at) VALUES ('97ee78f1-2adf-4505-b634-d105a56e4c8a', 'XH/INV/2602/002', 'Web Development Invoice', 'Global Solutions Inc', 'billing@globalsolutions.com', '+256 702 345 678', '2847 Broadway, New York, NY 10025, USA', 'Xhenvolt Uganda SMC Limited', 'Bulubandi, Iganga, Uganda', 'Software Development & Digital Solutions', '"2026-02-13T11:41:34.649Z"', '"2026-02-28T11:41:34.649Z"', '3000000.00', '300000.00', '0.00', '3300000.00', '0.00', '3300000.00', 'sent', 'Website redesign and e-commerce integration. Awaiting payment.', 'UGX', 'HAMUZA IBRAHIM', 'Chief Executive Officer (CEO)', '["Bank Transfer", "Cryptocurrency", "PayPal"]', NULL, '"2026-02-18T11:41:34.649Z"', '"2026-02-18T11:41:34.649Z"');
INSERT INTO invoices (id, invoice_number, invoice_name, client_name, client_email, client_phone, client_address, company_name, company_address, company_service_type, issue_date, due_date, subtotal, tax, discount, total, amount_paid, balance_due, status, notes, currency, signed_by, signed_by_title, payment_methods, payment_method_used, created_at, updated_at) VALUES ('12f0c2cb-a123-4782-ad41-ee2b2b5fb396', 'XH/INV/2602/003', 'Consulting Services Invoice', 'Enterprise Systems Ltd', 'finance@enterprisesystems.ug', '+256 703 456 789', 'Innovation Hub, Nakasero, Kampala', 'Xhenvolt Uganda SMC Limited', 'Bulubandi, Iganga, Uganda', 'Software Development & Digital Solutions', '"2026-02-03T11:41:34.891Z"', '"2026-02-18T11:41:34.891Z"', '2500000.00', '250000.00', '100000.00', '2650000.00', '1500000.00', '1150000.00', 'partially_paid', 'System architecture consulting and technology strategy. Partial payment received.', 'UGX', 'HAMUZA IBRAHIM', 'Chief Executive Officer (CEO)', '["Bank Transfer", "Mobile Money"]', 'Mobile Money', '"2026-02-18T11:41:34.891Z"', '"2026-02-18T11:41:34.891Z"');
INSERT INTO invoices (id, invoice_number, invoice_name, client_name, client_email, client_phone, client_address, company_name, company_address, company_service_type, issue_date, due_date, subtotal, tax, discount, total, amount_paid, balance_due, status, notes, currency, signed_by, signed_by_title, payment_methods, payment_method_used, created_at, updated_at) VALUES ('4aadf72e-06e1-4814-bd76-809c2fb1188c', 'XH/INV/2602/004', 'UI/UX Design Invoice', 'Creative Design Studio', 'contact@creativedesign.ug', '+256 704 567 890', '5 Oasis Court, Kololo, Kampala', 'Xhenvolt Uganda SMC Limited', 'Bulubandi, Iganga, Uganda', 'Software Development & Digital Solutions', '"2026-02-18T11:41:35.143Z"', '"2026-03-20T11:41:35.143Z"', '1200000.00', '120000.00', '50000.00', '1270000.00', '0.00', '1270000.00', 'draft', 'Complete UI/UX redesign. Draft for approval. Ready to send.', 'UGX', 'HAMUZA IBRAHIM', 'Chief Executive Officer (CEO)', '["Bank Transfer", "Mobile Money"]', NULL, '"2026-02-18T11:41:35.143Z"', '"2026-02-18T11:41:35.143Z"');
INSERT INTO invoices (id, invoice_number, invoice_name, client_name, client_email, client_phone, client_address, company_name, company_address, company_service_type, issue_date, due_date, subtotal, tax, discount, total, amount_paid, balance_due, status, notes, currency, signed_by, signed_by_title, payment_methods, payment_method_used, created_at, updated_at) VALUES ('5df60037-e573-4536-989c-e3c4fee560f6', 'XH/INV/001', 'DRAIS School Management System & Digital Setup', 'Excel Islamic Nursery and Primary School', 'admin@excelshoool.ug', '+256 701 234 567', 'Busembatia, Namutumba District, Uganda', 'Xhenvolt Uganda SMC Limited', 'Bulubandi, Iganga, Uganda', 'Software Development & Digital Solutions', '"2025-12-23T21:00:00.000Z"', '"2025-12-30T21:00:00.000Z"', '2950000.00', '0.00', '0.00', '2950000.00', '500000.00', '2450000.00', 'partially_paid', 'This invoice covers the implementation of the DRAIS School Management System and development of Excel School Online Presence, including digital platform integrations. Balance payable as per agreed milestones.', 'UGX', 'HAMUZA IBRAHIM', 'Chief Executive Officer (CEO)', '["Bank Transfer", "Mobile Money (MTN, Airtel)", "Cash"]', 'Mobile Money', '"2026-02-18T12:18:05.963Z"', '"2026-02-18T12:18:05.963Z"');

-- ip_valuation_logs: 0 rows

-- Data for: liabilities (6 rows)
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('cda9f45e-47fd-4dfb-a941-05386d89d621', 'SenteGo', 'Loan', 'SenteGo', '108200.00', '160000.00', '20.00', '"2026-01-11T21:00:00.000Z"', 'ACTIVE', '', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-05T16:24:25.537Z"', '"2026-01-05T16:32:46.087Z"', FALSE, NULL);
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('e43d8392-73e5-44ae-9c16-09ad905db28c', 'Shuheebu', 'Payable', 'Shuheebu Service', '150000.00', '150000.00', '0.00', '"2026-01-05T21:00:00.000Z"', 'ACTIVE', NULL, '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-05T19:58:24.387Z"', '"2026-01-05T19:58:24.387Z"', FALSE, NULL);
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('ca30b54a-00af-4704-a0a6-bff90c5d5d37', 'Nile Loan', 'Loan', 'Nile Loan Uganda', '61200.00', '90000.00', '20.00', '"2026-01-10T21:00:00.000Z"', 'ACTIVE', NULL, '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-05T20:01:06.315Z"', '"2026-01-05T20:01:06.315Z"', FALSE, NULL);
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('2f0e1189-47e4-4200-8925-a48ffe9e42b9', 'Devo Cash', 'Loan', 'Tajiri Tech Limited', '28000.00', '40000.00', '20.00', '"2026-01-07T21:00:00.000Z"', 'CLEARED', '', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-05T20:00:03.684Z"', '"2026-01-10T08:15:13.360Z"', FALSE, NULL);
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('2fa6a4c6-fc0d-4bac-a06a-1c0de1787e4e', 'Practico Speed', 'Emergency Loan', 'Pactico Speed', '54200.00', '80000.00', '30.00', '"2026-01-16T21:00:00.000Z"', 'ACTIVE', NULL, NULL, '"2026-01-10T08:16:33.713Z"', '"2026-01-10T08:16:33.713Z"', FALSE, NULL);
INSERT INTO liabilities (id, name, category, creditor, principal_amount, outstanding_amount, interest_rate, due_date, status, notes, created_by, created_at, updated_at, locked, deleted_at) VALUES ('3b816a44-b6f6-4d43-8b62-7abb38d8f4f4', 'Funa Loan', 'Loan', 'Funa Loan Company', '108200.00', '190000.00', '30.00', '"2026-01-19T21:00:00.000Z"', 'ACTIVE', '', NULL, '"2026-01-10T08:14:05.940Z"', '"2026-01-26T14:04:15.323Z"', FALSE, NULL);

-- payments: 0 rows

-- prospect_activities: 0 rows

-- prospect_conversions: 0 rows

-- Data for: prospect_industries (12 rows)
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (1, 'Education', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (2, 'Technology', 'Tech', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (3, 'Healthcare', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (4, 'Finance', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (5, 'Manufacturing', 'Product', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (6, 'Retail', 'Product', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (7, 'Real Estate', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (8, 'Consulting', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (9, 'Hospitality', 'Service', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (10, 'Government', 'Public', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (11, 'Non-Profit', 'Public', '"2026-02-22T05:22:31.343Z"');
INSERT INTO prospect_industries (id, industry_name, category, created_at) VALUES (12, 'Other', 'Other', '"2026-02-22T05:22:31.343Z"');

-- Data for: prospect_sources (9 rows)
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (1, 'Cold Call', 'Outbound prospecting call', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (2, 'Referral', 'Referred by existing contact', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (3, 'Event', 'Met at conference, networking event, or trade show', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (4, 'Walk-in', 'Unsolicited visit or inquiry', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (5, 'Website', 'Inbound inquiry from website', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (6, 'Social Media', 'Discovered via LinkedIn, Twitter, or other social platform', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (7, 'Email', 'Inbound email inquiry', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (8, 'Partner', 'Referred by business partner', '"2026-02-22T05:22:30.848Z"');
INSERT INTO prospect_sources (id, source_name, description, created_at) VALUES (9, 'Other', 'Other source', '"2026-02-22T05:22:30.848Z"');

-- prospect_stage_history: 0 rows

-- Data for: prospect_stages (6 rows)
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (1, 'Prospect', 1, 'Initial contact identified', '"2026-02-22T05:22:31.848Z"');
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (2, 'Contacted', 2, 'First contact made', '"2026-02-22T05:22:31.848Z"');
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (3, 'Interested', 3, 'Prospect shows interest', '"2026-02-22T05:22:31.848Z"');
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (4, 'Negotiating', 4, 'Active negotiation phase', '"2026-02-22T05:22:31.848Z"');
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (5, 'Converted', 5, 'Converted to customer', '"2026-02-22T05:22:31.848Z"');
INSERT INTO prospect_stages (id, stage_name, stage_order, description, created_at) VALUES (6, 'Lost', 6, 'Lost to competitor or disqualified', '"2026-02-22T05:22:31.848Z"');

-- prospect_tag_assignments: 0 rows

-- prospect_tags: 0 rows

-- Data for: prospects (1 rows)
INSERT INTO prospects (id, prospect_name, email, phone_number, whatsapp_number, company_name, industry_id, city, country, address, source_id, current_stage_id, assigned_sales_agent_id, created_by_id, first_contacted_at, last_activity_at, next_followup_at, status, created_at, updated_at) VALUES ('ebf40d21-5cd2-4a0f-942f-a3ea59513dcd', 'Mwondha Hassan', NULL, '0741341483', NULL, 'Hillside Ways Nursary and Primary School', NULL, NULL, NULL, NULL, 4, 1, NULL, '9a29b37a-751e-4678-8349-a6e8d90a744d', NULL, NULL, NULL, 'active', '"2026-03-05T03:27:32.882Z"', '"2026-03-05T03:27:32.882Z"');

-- revenue_records: 0 rows

-- sales: 0 rows

-- Data for: sessions (12 rows)
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('a71bf9fc-cca7-45aa-945b-dacdae8228af', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-12T09:44:43.114Z"', '"2026-01-05T09:44:43.118Z"', '"2026-01-11T08:24:32.672Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-05T15:59:20.017Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('41afadcc-de4a-4862-8d3f-8bf12537e0c2', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-01-18T10:57:09.501Z"', '"2026-01-11T10:57:09.502Z"', '"2026-01-13T07:23:47.978Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-11T10:57:09.502Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('48fa9f45-8edf-4c91-b323-3b75ffe3d5fe', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-02-02T14:00:58.445Z"', '"2026-01-26T14:00:58.447Z"', '"2026-01-26T14:01:01.659Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-26T14:00:58.447Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('81b1729b-d158-41e2-84d3-28e01d925214', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-03-11T14:25:07.180Z"', '"2026-03-04T14:25:07.312Z"', '"2026-03-08T10:58:24.412Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-03-04T14:25:07.312Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('4f5213c3-e9cc-4042-b79d-43a048252a60', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-12T22:32:17.615Z"', '"2026-01-05T22:32:17.763Z"', '"2026-01-06T07:05:34.852Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-05T22:32:17.763Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('da85023d-6597-4639-8a99-486910b2daff', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-13T07:06:22.004Z"', '"2026-01-06T07:06:22.160Z"', '"2026-01-06T08:52:48.490Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-06T07:06:22.160Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('cbd33200-665e-4140-8295-fb6d9a790369', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-12T10:01:51.762Z"', '"2026-01-05T10:01:51.763Z"', '"2026-01-06T13:38:38.709Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-05T15:59:20.017Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('1c6cb99f-fc3e-4941-9e73-c1d7be2453b1', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-02-26T03:11:22.817Z"', '"2026-02-19T03:11:22.897Z"', '"2026-02-22T07:03:21.712Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-02-19T03:11:22.897Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('c47931f3-cf02-4d2b-827a-4632267f415c', '9a29b37a-751e-4678-8349-a6e8d90a744d', '"2026-01-12T09:21:41.802Z"', '"2026-01-05T09:21:42.031Z"', '"2026-01-05T22:31:50.740Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-05T15:59:20.017Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('6e282a25-1845-4aed-bffe-6caf22aa3cf1', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-03-01T14:15:43.973Z"', '"2026-02-22T14:15:44.190Z"', '"2026-02-22T14:16:06.607Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-02-22T14:15:44.190Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('b2f92806-6b84-4a41-a2dd-1156a78330b2', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-01-16T14:23:54.231Z"', '"2026-01-09T14:23:54.232Z"', '"2026-01-09T14:30:14.736Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-01-09T14:23:54.232Z"', TRUE, NULL, NULL);
INSERT INTO sessions (id, user_id, expires_at, created_at, last_activity, device_name, browser_name, ip_address, user_agent, last_active_at, is_active, revoked_at, revoked_reason) VALUES ('88b1e77c-f101-436e-aadd-487aad6f0e50', 'b3871542-10e2-4766-94e1-f5734398c47b', '"2026-03-09T15:11:19.151Z"', '"2026-03-02T15:11:19.155Z"', '"2026-03-02T15:21:37.204Z"', 'Unknown Device', NULL, NULL, NULL, '"2026-03-02T15:11:19.155Z"', TRUE, NULL, NULL);

-- share_allocations: 0 rows

-- share_issuances: 0 rows

-- share_price_history: 0 rows

-- share_transfers: 0 rows

-- shareholders: 0 rows

-- Data for: shareholdings (1 rows)
INSERT INTO shareholdings (id, shareholder_id, shareholder_name, shareholder_email, shares_owned, share_class, equity_type, vesting_start_date, vesting_end_date, vesting_schedule, vesting_cliff_percentage, vested_shares, acquisition_date, acquisition_price, investment_total, original_ownership_percentage, current_ownership_percentage, dilution_events_count, status, holder_type, notes, created_at, updated_at) VALUES ('aa7a6082-d8aa-4b87-be30-a61464db3933', 'b3871542-10e2-4766-94e1-f5734398c47b', 'HAMUZA IBRAHIM', 'xhenonprototype@gmail.com', '200', 'Common', 'PURCHASED', NULL, NULL, NULL, '0.00', '0', '"2026-01-06T21:00:00.000Z"', '90000000.0000', '18000000000.00', '100.00', '100.00', 0, 'active', 'founder', NULL, '"2026-01-07T21:01:17.967Z"', '"2026-01-07T21:01:17.967Z"');

-- Data for: shares (4 rows)
INSERT INTO shares (id, total_shares, par_value, class_type, status, created_at, updated_at, authorized_shares, issued_shares, allocated_shares) VALUES (1, '1000000', '920000.00', 'common', 'active', '"2026-01-01T02:13:32.327Z"', '"2026-01-01T02:13:32.327Z"', '1000000', '0', '0');
INSERT INTO shares (id, total_shares, par_value, class_type, status, created_at, updated_at, authorized_shares, issued_shares, allocated_shares) VALUES (2, '1000000', '920000.00', 'common', 'active', '"2026-01-01T02:15:18.542Z"', '"2026-01-01T02:15:18.542Z"', '1000000', '0', '0');
INSERT INTO shares (id, total_shares, par_value, class_type, status, created_at, updated_at, authorized_shares, issued_shares, allocated_shares) VALUES (3, '1000000', '920000.00', 'common', 'active', '"2026-01-01T02:16:02.250Z"', '"2026-01-01T02:16:02.250Z"', '1000000', '0', '0');
INSERT INTO shares (id, total_shares, par_value, class_type, status, created_at, updated_at, authorized_shares, issued_shares, allocated_shares) VALUES (4, '1000000', '920000.00', 'common', 'active', '"2026-01-01T02:18:37.397Z"', '"2026-01-01T02:18:37.397Z"', '1000000', '0', '0');

-- Data for: shares_config (1 rows)
INSERT INTO shares_config (id, authorized_shares, issued_shares, class_type, par_value, created_at, updated_at, status, company_id, notes) VALUES (1, '10000000', '400', 'Common', '230000.0000', '"2026-01-05T13:46:45.777Z"', '"2026-01-07T18:03:06.325Z"', 'active', NULL, NULL);

-- Data for: snapshots (2 rows)
INSERT INTO snapshots (id, type, name, data, created_by, created_at) VALUES ('a98604fd-d939-488e-9f27-6c81771cb771', 'MANUAL', NULL, '{"currency":"UGX","netWorth":76280000,"wonDeals":4100000,"lostDeals":0,"totalAssets":76990000,"totalPipeline":24100000,"conversionRate":51250000,"weightedRevenue":19520000,"totalLiabilities":710000}', NULL, '"2026-03-05T02:50:55.744Z"');
INSERT INTO snapshots (id, type, name, data, created_by, created_at) VALUES ('9d5eb464-33ce-4817-9b5e-3ff7ae22e085', 'NET_WORTH', NULL, '{"currency":"UGX","netWorth":76280000,"wonDeals":4100000,"lostDeals":0,"totalAssets":76990000,"totalPipeline":24100000,"conversionRate":51250000,"weightedRevenue":19520000,"totalLiabilities":710000}', NULL, '"2026-03-05T02:51:15.781Z"');

-- staff: 0 rows

-- Data for: staff_profiles (2 rows)
INSERT INTO staff_profiles (id, user_id, department, title, phone, created_at, updated_at) VALUES ('9e63e011-2486-42ec-9671-12557913f814', 'b3871542-10e2-4766-94e1-f5734398c47b', 'Finance', NULL, NULL, '"2026-01-06T06:56:02.835Z"', '"2026-01-06T06:56:02.835Z"');
INSERT INTO staff_profiles (id, user_id, department, title, phone, created_at, updated_at) VALUES ('6fc9a4af-cc8d-47cd-a903-391ee3092852', '69f28a59-c116-4486-88d0-c8b41975d3af', NULL, NULL, NULL, '"2026-01-10T03:28:57.310Z"', '"2026-01-10T03:28:57.310Z"');

-- Data for: users (5 rows)
INSERT INTO users (id, email, password_hash, role, is_active, created_at, updated_at, full_name, status, last_login, last_seen, is_online) VALUES ('69f28a59-c116-4486-88d0-c8b41975d3af', 'xhenonproto@gmail.com', '$2b$10$3BbEhY1khG6kJKV3WfyeFO6pWOKNuLXjzstj389vGvB1QgscggQ12', 'FINANCE', TRUE, '"2026-01-10T03:28:57.243Z"', '"2026-01-10T03:28:57.243Z"', 'Test', 'active', NULL, NULL, FALSE);
INSERT INTO users (id, email, password_hash, role, is_active, created_at, updated_at, full_name, status, last_login, last_seen, is_online) VALUES ('387079e4-e132-4955-9a27-df4656399c00', 'founder@xhenvolt.com', '$2b$10$36dMz501J8Tnk/kAvcBQU..f21X0/5XU.UizsDvAep2uThIwaXUr2', 'FOUNDER', TRUE, '"2025-12-29T15:36:46.373Z"', '"2025-12-29T15:37:31.300Z"', 'founder@xhenvolt.com', 'active', NULL, NULL, FALSE);
INSERT INTO users (id, email, password_hash, role, is_active, created_at, updated_at, full_name, status, last_login, last_seen, is_online) VALUES ('9a29b37a-751e-4678-8349-a6e8d90a744d', 'xhenonpro@gmail.com', '$2b$10$t3u3dxhN4S8I9q.w96c22OA2Gd42WrU9.bBNHel3Obl44tIIEIkrO', 'FOUNDER', TRUE, '"2025-12-29T15:11:15.476Z"', '"2026-01-07T20:38:14.167Z"', 'xhenonpro@gmail.com', 'active', NULL, '"2026-01-11T08:24:32.677Z"', TRUE);
INSERT INTO users (id, email, password_hash, role, is_active, created_at, updated_at, full_name, status, last_login, last_seen, is_online) VALUES ('b3871542-10e2-4766-94e1-f5734398c47b', 'xhenonprototype@gmail.com', '$2b$10$2AodnqV3n4Dbh6JY9ysuuugfohM9jurdFO6VXF1ytRufQ0DBan5fa', 'FINANCE', TRUE, '"2026-01-06T06:56:02.395Z"', '"2026-03-04T14:25:06.971Z"', 'HAMUZA IBRAHIM', 'active', NULL, '"2026-03-08T10:58:24.812Z"', TRUE);
INSERT INTO users (id, email, password_hash, role, is_active, created_at, updated_at, full_name, status, last_login, last_seen, is_online) VALUES ('ddc9e2fc-1cc8-427b-b202-915458f0f5f5', 'halima@gmail.com', '$2b$10$TFCyZBdmOdYDMShCqkEjXepnIRMorqQ1CEoj3MG1PQiT.hySkh426', 'FOUNDER', TRUE, '"2026-02-12T17:31:23.732Z"', '"2026-02-12T17:31:23.732Z"', NULL, 'active', NULL, '"2026-02-12T17:32:11.391Z"', TRUE);

-- Data for: valuation_summary (1 rows)
INSERT INTO valuation_summary (id, total_assets_book_value, total_depreciation_period, total_ip_valuation, total_infrastructure_value, accounting_net_worth, strategic_company_value, calculated_at) VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, '"2025-12-30T08:44:44.107Z"');

-- Data for: vault_balances (4 rows)
INSERT INTO vault_balances (id, vault_type, balance, last_updated) VALUES (1, 'savings', '0.00', '"2026-03-08T01:26:39.033Z"');
INSERT INTO vault_balances (id, vault_type, balance, last_updated) VALUES (2, 'emergency', '0.00', '"2026-03-08T01:26:39.033Z"');
INSERT INTO vault_balances (id, vault_type, balance, last_updated) VALUES (3, 'investment', '0.00', '"2026-03-08T01:26:39.033Z"');
INSERT INTO vault_balances (id, vault_type, balance, last_updated) VALUES (4, 'operating', '0.00', '"2026-03-08T01:26:39.033Z"');


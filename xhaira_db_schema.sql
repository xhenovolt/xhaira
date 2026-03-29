--
-- PostgreSQL database dump
--

\restrict lX4x3Gaz4tibD3FlwzwxOFXLf2rxMDND90AEEzGrj8netAPVkwrylAHM3zOuFkp

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    description text,
    institution character varying(255),
    account_number character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT accounts_type_check CHECK (((type)::text = ANY ((ARRAY['bank'::character varying, 'cash'::character varying, 'mobile_money'::character varying, 'credit_card'::character varying, 'investment'::character varying, 'escrow'::character varying, 'other'::character varying])::text[])))
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id uuid,
    details jsonb DEFAULT '{}'::jsonb,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(100) NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    period character varying(30) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    alert_threshold numeric(5,2) DEFAULT 80.00,
    is_active boolean DEFAULT true NOT NULL,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT budgets_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT budgets_period_check CHECK (((period)::text = ANY ((ARRAY['monthly'::character varying, 'quarterly'::character varying, 'yearly'::character varying, 'custom'::character varying])::text[]))),
    CONSTRAINT valid_date_range CHECK ((end_date > start_date))
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prospect_id uuid,
    company_name character varying(255) NOT NULL,
    contact_name character varying(255),
    email character varying(255),
    phone character varying(50),
    website character varying(500),
    industry character varying(100),
    billing_address text,
    tax_id character varying(100),
    payment_terms integer DEFAULT 30,
    preferred_currency character varying(3) DEFAULT 'USD'::character varying,
    status character varying(30) DEFAULT 'active'::character varying NOT NULL,
    notes text,
    tags text[] DEFAULT '{}'::text[],
    lifetime_value numeric(15,2) DEFAULT 0,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT clients_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying, 'churned'::character varying])::text[])))
);


--
-- Name: deals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    client_id uuid NOT NULL,
    prospect_id uuid,
    offering_id uuid,
    title character varying(255) NOT NULL,
    description text,
    total_amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    start_date date,
    end_date date,
    due_date date,
    closed_at timestamp with time zone,
    invoice_number character varying(100),
    invoice_sent_at timestamp with time zone,
    invoice_pdf_url text,
    terms text,
    notes text,
    tags text[] DEFAULT '{}'::text[],
    metadata jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT deals_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'sent'::character varying, 'accepted'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'disputed'::character varying])::text[])))
);


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    category character varying(100) NOT NULL,
    subcategory character varying(100),
    vendor character varying(255),
    description text NOT NULL,
    expense_date date DEFAULT CURRENT_DATE NOT NULL,
    receipt_url text,
    is_recurring boolean DEFAULT false NOT NULL,
    recurrence_interval character varying(30),
    status character varying(30) DEFAULT 'recorded'::character varying NOT NULL,
    budget_id uuid,
    tags text[] DEFAULT '{}'::text[],
    notes text,
    ledger_entry_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT expenses_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT expenses_status_check CHECK (((status)::text = ANY ((ARRAY['recorded'::character varying, 'pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'void'::character varying])::text[])))
);


--
-- Name: followups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.followups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prospect_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    status character varying(30) DEFAULT 'scheduled'::character varying NOT NULL,
    scheduled_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    summary text,
    outcome text,
    next_action text,
    next_followup_date date,
    performed_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT followups_status_check CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'rescheduled'::character varying, 'no_show'::character varying])::text[]))),
    CONSTRAINT followups_type_check CHECK (((type)::text = ANY ((ARRAY['call'::character varying, 'email'::character varying, 'meeting'::character varying, 'demo'::character varying, 'proposal'::character varying, 'site_visit'::character varying, 'social'::character varying, 'other'::character varying])::text[])))
);


--
-- Name: ledger; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    running_balance numeric(15,2),
    source_type character varying(50) NOT NULL,
    source_id uuid,
    description text NOT NULL,
    category character varying(100),
    entry_date date DEFAULT CURRENT_DATE NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ledger_source_type_check CHECK (((source_type)::text = ANY ((ARRAY['payment'::character varying, 'expense'::character varying, 'transfer_in'::character varying, 'transfer_out'::character varying, 'adjustment'::character varying, 'refund'::character varying, 'initial_balance'::character varying])::text[])))
);


--
-- Name: offerings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offerings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    description text,
    default_price numeric(15,2),
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    unit character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT offerings_type_check CHECK (((type)::text = ANY ((ARRAY['product'::character varying, 'service'::character varying, 'subscription'::character varying, 'license'::character varying, 'consulting'::character varying, 'other'::character varying])::text[])))
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    deal_id uuid NOT NULL,
    account_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    method character varying(50),
    reference character varying(255),
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    received_at timestamp with time zone,
    notes text,
    ledger_entry_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_method_check CHECK (((method)::text = ANY ((ARRAY['bank_transfer'::character varying, 'cash'::character varying, 'check'::character varying, 'credit_card'::character varying, 'mobile_money'::character varying, 'crypto'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT payments_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'refunded'::character varying, 'partial_refund'::character varying])::text[])))
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    module character varying(100) NOT NULL,
    action character varying(100) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: prospect_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospect_contacts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prospect_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    title character varying(255),
    email character varying(255),
    phone character varying(50),
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: prospects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_name character varying(255) NOT NULL,
    contact_name character varying(255),
    email character varying(255),
    phone character varying(50),
    website character varying(500),
    industry character varying(100),
    source character varying(100),
    stage character varying(50) DEFAULT 'new'::character varying NOT NULL,
    priority character varying(20) DEFAULT 'medium'::character varying,
    estimated_value numeric(15,2),
    currency character varying(3) DEFAULT 'USD'::character varying,
    notes text,
    tags text[] DEFAULT '{}'::text[],
    next_followup_date date,
    converted_at timestamp with time zone,
    lost_reason text,
    assigned_to uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT prospects_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying])::text[]))),
    CONSTRAINT prospects_source_check CHECK (((source)::text = ANY ((ARRAY['referral'::character varying, 'cold_outreach'::character varying, 'inbound'::character varying, 'event'::character varying, 'social_media'::character varying, 'website'::character varying, 'partner'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT prospects_stage_check CHECK (((stage)::text = ANY ((ARRAY['new'::character varying, 'contacted'::character varying, 'qualified'::character varying, 'proposal'::character varying, 'negotiation'::character varying, 'won'::character varying, 'lost'::character varying, 'dormant'::character varying])::text[])))
);


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    from_account_id uuid NOT NULL,
    to_account_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    to_amount numeric(15,2),
    to_currency character varying(3),
    exchange_rate numeric(15,6),
    description text,
    reference character varying(255),
    transfer_date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(30) DEFAULT 'completed'::character varying NOT NULL,
    ledger_debit_id uuid,
    ledger_credit_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT different_accounts CHECK ((from_account_id <> to_account_id)),
    CONSTRAINT transfers_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT transfers_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'reversed'::character varying])::text[])))
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    assigned_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['superadmin'::character varying, 'admin'::character varying, 'user'::character varying, 'viewer'::character varying])::text[])))
);


--
-- Name: v_account_balances; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_account_balances AS
 SELECT a.id AS account_id,
    a.name,
    a.type,
    a.currency,
    a.is_active,
    COALESCE(sum(l.amount), (0)::numeric) AS balance,
    count(l.id) AS transaction_count,
    max(l.entry_date) AS last_transaction_date
   FROM (public.accounts a
     LEFT JOIN public.ledger l ON ((l.account_id = a.id)))
  GROUP BY a.id, a.name, a.type, a.currency, a.is_active;


--
-- Name: v_budget_utilization; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_budget_utilization AS
 SELECT b.id AS budget_id,
    b.name,
    b.category,
    b.amount AS budgeted,
    b.currency,
    b.period,
    b.start_date,
    b.end_date,
    COALESCE(sum(e.amount) FILTER (WHERE (((e.status)::text <> 'void'::text) AND ((e.status)::text <> 'rejected'::text))), (0)::numeric) AS spent,
    (b.amount - COALESCE(sum(e.amount) FILTER (WHERE (((e.status)::text <> 'void'::text) AND ((e.status)::text <> 'rejected'::text))), (0)::numeric)) AS remaining,
        CASE
            WHEN (b.amount > (0)::numeric) THEN round(((COALESCE(sum(e.amount) FILTER (WHERE (((e.status)::text <> 'void'::text) AND ((e.status)::text <> 'rejected'::text))), (0)::numeric) / b.amount) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS utilization_pct,
    b.alert_threshold,
    b.is_active
   FROM (public.budgets b
     LEFT JOIN public.expenses e ON (((e.budget_id = b.id) AND ((e.expense_date >= b.start_date) AND (e.expense_date <= b.end_date)))))
  GROUP BY b.id, b.name, b.category, b.amount, b.currency, b.period, b.start_date, b.end_date, b.alert_threshold, b.is_active;


--
-- Name: v_client_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_client_summary AS
 SELECT c.id AS client_id,
    c.company_name,
    c.status,
    count(DISTINCT d.id) AS deal_count,
    COALESCE(sum(d.total_amount), (0)::numeric) AS total_deal_value,
    COALESCE(sum(p.amount) FILTER (WHERE ((p.status)::text = 'completed'::text)), (0)::numeric) AS total_paid,
    max(p.payment_date) AS last_payment_date,
    min(d.created_at) AS first_deal_date
   FROM ((public.clients c
     LEFT JOIN public.deals d ON ((d.client_id = c.id)))
     LEFT JOIN public.payments p ON ((p.deal_id = d.id)))
  GROUP BY c.id, c.company_name, c.status;


--
-- Name: v_deal_payment_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_deal_payment_status AS
 SELECT d.id AS deal_id,
    d.title,
    d.client_id,
    d.total_amount,
    d.currency,
    d.status,
    COALESCE(sum(p.amount) FILTER (WHERE ((p.status)::text = 'completed'::text)), (0)::numeric) AS paid_amount,
    (d.total_amount - COALESCE(sum(p.amount) FILTER (WHERE ((p.status)::text = 'completed'::text)), (0)::numeric)) AS remaining_amount,
    count(p.id) FILTER (WHERE ((p.status)::text = 'completed'::text)) AS payment_count,
        CASE
            WHEN (COALESCE(sum(p.amount) FILTER (WHERE ((p.status)::text = 'completed'::text)), (0)::numeric) >= d.total_amount) THEN 'fully_paid'::text
            WHEN (COALESCE(sum(p.amount) FILTER (WHERE ((p.status)::text = 'completed'::text)), (0)::numeric) > (0)::numeric) THEN 'partially_paid'::text
            ELSE 'unpaid'::text
        END AS payment_status
   FROM (public.deals d
     LEFT JOIN public.payments p ON ((p.deal_id = d.id)))
  GROUP BY d.id, d.title, d.client_id, d.total_amount, d.currency, d.status;


--
-- Name: v_financial_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_financial_summary AS
 SELECT COALESCE(sum(amount) FILTER (WHERE (amount > (0)::numeric)), (0)::numeric) AS total_income,
    COALESCE(sum(abs(amount)) FILTER (WHERE (amount < (0)::numeric)), (0)::numeric) AS total_expenses,
    COALESCE(sum(amount), (0)::numeric) AS net_position,
    count(*) FILTER (WHERE (amount > (0)::numeric)) AS income_transactions,
    count(*) FILTER (WHERE (amount < (0)::numeric)) AS expense_transactions,
    count(*) AS total_transactions
   FROM public.ledger;


--
-- Name: v_monthly_financials; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_monthly_financials AS
 SELECT (date_trunc('month'::text, (entry_date)::timestamp with time zone))::date AS month,
    COALESCE(sum(amount) FILTER (WHERE (amount > (0)::numeric)), (0)::numeric) AS income,
    COALESCE(sum(abs(amount)) FILTER (WHERE (amount < (0)::numeric)), (0)::numeric) AS expenses,
    COALESCE(sum(amount), (0)::numeric) AS net,
    count(*) AS transaction_count
   FROM public.ledger
  GROUP BY (date_trunc('month'::text, (entry_date)::timestamp with time zone))
  ORDER BY ((date_trunc('month'::text, (entry_date)::timestamp with time zone))::date) DESC;


--
-- Name: v_prospect_pipeline; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_prospect_pipeline AS
 SELECT stage,
    count(*) AS count,
    COALESCE(sum(estimated_value), (0)::numeric) AS total_value,
    COALESCE(avg(estimated_value), (0)::numeric) AS avg_value
   FROM public.prospects
  WHERE ((stage)::text <> ALL ((ARRAY['won'::character varying, 'lost'::character varying])::text[]))
  GROUP BY stage
  ORDER BY
        CASE stage
            WHEN 'new'::text THEN 1
            WHEN 'contacted'::text THEN 2
            WHEN 'qualified'::text THEN 3
            WHEN 'proposal'::text THEN 4
            WHEN 'negotiation'::text THEN 5
            ELSE 6
        END;


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: budgets budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_pkey PRIMARY KEY (id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: clients clients_prospect_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_prospect_id_key UNIQUE (prospect_id);


--
-- Name: deals deals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: followups followups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followups
    ADD CONSTRAINT followups_pkey PRIMARY KEY (id);


--
-- Name: ledger ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger
    ADD CONSTRAINT ledger_pkey PRIMARY KEY (id);


--
-- Name: offerings offerings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offerings
    ADD CONSTRAINT offerings_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_module_action_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_module_action_key UNIQUE (module, action);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: prospect_contacts prospect_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospect_contacts
    ADD CONSTRAINT prospect_contacts_pkey PRIMARY KEY (id);


--
-- Name: prospects prospects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_role_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_permission_id_key UNIQUE (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_accounts_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_is_active ON public.accounts USING btree (is_active);


--
-- Name: idx_accounts_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_type ON public.accounts USING btree (type);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_budgets_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_category ON public.budgets USING btree (category);


--
-- Name: idx_budgets_date_range; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_date_range ON public.budgets USING btree (start_date, end_date);


--
-- Name: idx_budgets_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_is_active ON public.budgets USING btree (is_active);


--
-- Name: idx_budgets_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_period ON public.budgets USING btree (period);


--
-- Name: idx_clients_company_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_company_name ON public.clients USING btree (company_name);


--
-- Name: idx_clients_prospect_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_prospect_id ON public.clients USING btree (prospect_id);


--
-- Name: idx_clients_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_status ON public.clients USING btree (status);


--
-- Name: idx_deals_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_client_id ON public.deals USING btree (client_id);


--
-- Name: idx_deals_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_created_at ON public.deals USING btree (created_at);


--
-- Name: idx_deals_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_due_date ON public.deals USING btree (due_date);


--
-- Name: idx_deals_offering_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_offering_id ON public.deals USING btree (offering_id);


--
-- Name: idx_deals_prospect_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_prospect_id ON public.deals USING btree (prospect_id);


--
-- Name: idx_deals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_status ON public.deals USING btree (status);


--
-- Name: idx_expenses_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_account_id ON public.expenses USING btree (account_id);


--
-- Name: idx_expenses_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_budget_id ON public.expenses USING btree (budget_id);


--
-- Name: idx_expenses_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_category ON public.expenses USING btree (category);


--
-- Name: idx_expenses_expense_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_expense_date ON public.expenses USING btree (expense_date);


--
-- Name: idx_expenses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_status ON public.expenses USING btree (status);


--
-- Name: idx_followups_performed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_performed_by ON public.followups USING btree (performed_by);


--
-- Name: idx_followups_prospect_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_prospect_id ON public.followups USING btree (prospect_id);


--
-- Name: idx_followups_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_scheduled_at ON public.followups USING btree (scheduled_at);


--
-- Name: idx_followups_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_status ON public.followups USING btree (status);


--
-- Name: idx_ledger_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_account_id ON public.ledger USING btree (account_id);


--
-- Name: idx_ledger_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_category ON public.ledger USING btree (category);


--
-- Name: idx_ledger_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_created_at ON public.ledger USING btree (created_at);


--
-- Name: idx_ledger_entry_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entry_date ON public.ledger USING btree (entry_date);


--
-- Name: idx_ledger_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_source ON public.ledger USING btree (source_type, source_id);


--
-- Name: idx_offerings_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_offerings_is_active ON public.offerings USING btree (is_active);


--
-- Name: idx_offerings_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_offerings_type ON public.offerings USING btree (type);


--
-- Name: idx_payments_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_account_id ON public.payments USING btree (account_id);


--
-- Name: idx_payments_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_deal_id ON public.payments USING btree (deal_id);


--
-- Name: idx_payments_payment_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_payment_date ON public.payments USING btree (payment_date);


--
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_status ON public.payments USING btree (status);


--
-- Name: idx_prospect_contacts_prospect_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospect_contacts_prospect_id ON public.prospect_contacts USING btree (prospect_id);


--
-- Name: idx_prospects_assigned_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_assigned_to ON public.prospects USING btree (assigned_to);


--
-- Name: idx_prospects_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_created_at ON public.prospects USING btree (created_at);


--
-- Name: idx_prospects_next_followup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_next_followup ON public.prospects USING btree (next_followup_date);


--
-- Name: idx_prospects_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_priority ON public.prospects USING btree (priority);


--
-- Name: idx_prospects_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_source ON public.prospects USING btree (source);


--
-- Name: idx_prospects_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_stage ON public.prospects USING btree (stage);


--
-- Name: idx_role_permissions_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_permission ON public.role_permissions USING btree (permission_id);


--
-- Name: idx_role_permissions_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_role ON public.role_permissions USING btree (role_id);


--
-- Name: idx_sessions_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (token);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_transfers_from_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfers_from_account ON public.transfers USING btree (from_account_id);


--
-- Name: idx_transfers_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfers_status ON public.transfers USING btree (status);


--
-- Name: idx_transfers_to_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfers_to_account ON public.transfers USING btree (to_account_id);


--
-- Name: idx_transfers_transfer_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfers_transfer_date ON public.transfers USING btree (transfer_date);


--
-- Name: idx_user_roles_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_role ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_user ON public.user_roles USING btree (user_id);


--
-- Name: accounts trg_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_accounts_updated_at BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: budgets trg_budgets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_budgets_updated_at BEFORE UPDATE ON public.budgets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: clients trg_clients_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: deals trg_deals_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deals_updated_at BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: expenses trg_expenses_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_expenses_updated_at BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: followups trg_followups_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_followups_updated_at BEFORE UPDATE ON public.followups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: offerings trg_offerings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_offerings_updated_at BEFORE UPDATE ON public.offerings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: payments trg_payments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: prospect_contacts trg_prospect_contacts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prospect_contacts_updated_at BEFORE UPDATE ON public.prospect_contacts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: prospects trg_prospects_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prospects_updated_at BEFORE UPDATE ON public.prospects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: transfers trg_transfers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_transfers_updated_at BEFORE UPDATE ON public.transfers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: budgets budgets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: clients clients_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: clients clients_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects(id) ON DELETE SET NULL;


--
-- Name: deals deals_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE RESTRICT;


--
-- Name: deals deals_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: deals deals_offering_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.offerings(id) ON DELETE SET NULL;


--
-- Name: deals deals_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects(id) ON DELETE SET NULL;


--
-- Name: expenses expenses_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: expenses expenses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: expenses fk_expenses_budget; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT fk_expenses_budget FOREIGN KEY (budget_id) REFERENCES public.budgets(id) ON DELETE SET NULL;


--
-- Name: expenses fk_expenses_ledger; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT fk_expenses_ledger FOREIGN KEY (ledger_entry_id) REFERENCES public.ledger(id) ON DELETE SET NULL;


--
-- Name: payments fk_payments_ledger; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_ledger FOREIGN KEY (ledger_entry_id) REFERENCES public.ledger(id) ON DELETE SET NULL;


--
-- Name: transfers fk_transfers_ledger_credit; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_ledger_credit FOREIGN KEY (ledger_credit_id) REFERENCES public.ledger(id) ON DELETE SET NULL;


--
-- Name: transfers fk_transfers_ledger_debit; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_ledger_debit FOREIGN KEY (ledger_debit_id) REFERENCES public.ledger(id) ON DELETE SET NULL;


--
-- Name: followups followups_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followups
    ADD CONSTRAINT followups_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: followups followups_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followups
    ADD CONSTRAINT followups_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects(id) ON DELETE CASCADE;


--
-- Name: ledger ledger_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger
    ADD CONSTRAINT ledger_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: ledger ledger_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger
    ADD CONSTRAINT ledger_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: payments payments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE RESTRICT;


--
-- Name: prospect_contacts prospect_contacts_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospect_contacts
    ADD CONSTRAINT prospect_contacts_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects(id) ON DELETE CASCADE;


--
-- Name: prospects prospects_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: prospects prospects_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: transfers transfers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transfers transfers_from_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_from_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: transfers transfers_to_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_to_account_id_fkey FOREIGN KEY (to_account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict lX4x3Gaz4tibD3FlwzwxOFXLf2rxMDND90AEEzGrj8netAPVkwrylAHM3zOuFkp


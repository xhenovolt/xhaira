--
-- PostgreSQL database dump
--

\restrict 993OwflUMtH5QfspR0wsFmZSfo7Mn1gbVaJLNSJlVjfTqjAafimAaIOKKdZZZLv

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: xhenvolt
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO xhenvolt;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: xhenvolt
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: gender_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.gender_enum AS ENUM (
    'male',
    'female',
    'other'
);


ALTER TYPE public.gender_enum OWNER TO xhenvolt;

--
-- Name: lesson_type_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.lesson_type_enum AS ENUM (
    'regular',
    'revision',
    'exam',
    'practical',
    'field_trip',
    'makeup',
    'extra'
);


ALTER TYPE public.lesson_type_enum OWNER TO xhenvolt;

--
-- Name: notice_audience_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.notice_audience_enum AS ENUM (
    'all',
    'students',
    'parents',
    'teachers'
);


ALTER TYPE public.notice_audience_enum OWNER TO xhenvolt;

--
-- Name: notice_type_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.notice_type_enum AS ENUM (
    'general',
    'academic',
    'financial',
    'event'
);


ALTER TYPE public.notice_type_enum OWNER TO xhenvolt;

--
-- Name: recurrence_pattern_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.recurrence_pattern_enum AS ENUM (
    'daily',
    'weekly',
    'monthly',
    'custom'
);


ALTER TYPE public.recurrence_pattern_enum OWNER TO xhenvolt;

--
-- Name: school_status; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.school_status AS ENUM (
    'active',
    'inactive'
);


ALTER TYPE public.school_status OWNER TO xhenvolt;

--
-- Name: student_status; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.student_status AS ENUM (
    'active',
    'inactive',
    'suspended'
);


ALTER TYPE public.student_status OWNER TO xhenvolt;

--
-- Name: timetable_status_enum; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.timetable_status_enum AS ENUM (
    'scheduled',
    'ongoing',
    'completed',
    'cancelled',
    'postponed',
    'rescheduled'
);


ALTER TYPE public.timetable_status_enum OWNER TO xhenvolt;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'teacher',
    'student',
    'parent',
    'superadmin'
);


ALTER TYPE public.user_role OWNER TO xhenvolt;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: xhenvolt
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'inactive',
    'pending',
    'suspended',
    'locked'
);


ALTER TYPE public.user_status OWNER TO xhenvolt;

--
-- Name: execute_share_transfer(uuid, uuid, bigint, numeric, character varying); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.execute_share_transfer(p_from_id uuid, p_to_id uuid, p_shares_transferred bigint, p_transfer_price numeric DEFAULT NULL::numeric, p_transfer_type character varying DEFAULT 'secondary-sale'::character varying) RETURNS TABLE(success boolean, message text, from_new_balance bigint, to_new_balance bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_from_shares BIGINT;
  v_to_shares BIGINT;
  v_transfer_id UUID;
BEGIN
  -- Validate sender has enough shares
  SELECT shares_owned INTO v_from_shares
  FROM shareholdings
  WHERE shareholder_id = p_from_id AND status = 'active';
  
  IF v_from_shares < p_shares_transferred THEN
    RETURN QUERY SELECT FALSE, 'Insufficient shares to transfer', 0::BIGINT, 0::BIGINT;
    RETURN;
  END IF;
  
  -- Get recipient's current shares
  SELECT COALESCE(shares_owned, 0) INTO v_to_shares
  FROM shareholdings
  WHERE shareholder_id = p_to_id AND status = 'active';
  
  -- Update sender
  UPDATE shareholdings
  SET shares_owned = shares_owned - p_shares_transferred,
      updated_at = CURRENT_TIMESTAMP
  WHERE shareholder_id = p_from_id;
  
  -- Update or insert recipient
  INSERT INTO shareholdings (
    shareholder_id, shareholder_name, shareholder_email,
    shares_owned, acquisition_date, acquisition_price,
    holder_type, status
  )
  SELECT p_to_id, full_name, email, p_shares_transferred,
         CURRENT_DATE, p_transfer_price, 'investor', 'active'
  FROM users WHERE id = p_to_id
  ON CONFLICT (shareholder_id) DO UPDATE
  SET shares_owned = shareholdings.shares_owned + p_shares_transferred;
  
  -- Record transfer
  INSERT INTO share_transfers (
    from_shareholder_id, to_shareholder_id, shares_transferred,
    transfer_price_per_share, transfer_total, transfer_type,
    transfer_status, created_by_id
  )
  VALUES (
    p_from_id, p_to_id, p_shares_transferred,
    p_transfer_price, p_transfer_price * p_shares_transferred, p_transfer_type,
    'completed', p_from_id
  );
  
  -- Return results
  SELECT shares_owned INTO v_from_shares
  FROM shareholdings WHERE shareholder_id = p_from_id;
  
  SELECT shares_owned INTO v_to_shares
  FROM shareholdings WHERE shareholder_id = p_to_id;
  
  RETURN QUERY SELECT
    TRUE,
    format('Transferred %L shares from %s to %s', p_shares_transferred, p_from_id, p_to_id),
    v_from_shares,
    v_to_shares;
END;
$$;


ALTER FUNCTION public.execute_share_transfer(p_from_id uuid, p_to_id uuid, p_shares_transferred bigint, p_transfer_price numeric, p_transfer_type character varying) OWNER TO xhenvolt;

--
-- Name: reset_all_sequences(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.reset_all_sequences() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'
  ) LOOP
    EXECUTE 'SELECT setval(' || quote_literal(r.sequence_name) || ', (SELECT MAX(id) FROM ' || 
            REPLACE(r.sequence_name, '_id_seq', '') || '), TRUE)';
  END LOOP;
END;
$$;


ALTER FUNCTION public.reset_all_sequences() OWNER TO xhenvolt;

--
-- Name: update_balances_on_waiver(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_balances_on_waiver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.approval_status = 'approved' AND OLD.approval_status != 'approved' THEN
    -- Update allocation
    UPDATE fee_allocations
    SET 
      amount_waived = amount_waived + COALESCE(NEW.amount, (amount * NEW.percentage / 100), 0),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.allocation_id;
    
    -- Update ledger
    UPDATE fees_ledger
    SET 
      total_waived = (
        SELECT COALESCE(SUM(amount_waived), 0)
        FROM fee_allocations
        WHERE student_id = NEW.student_id
          AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
      ),
      updated_at = CURRENT_TIMESTAMP
    WHERE student_id = NEW.student_id
      AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id);
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_balances_on_waiver() OWNER TO xhenvolt;

--
-- Name: update_fees_ledger_on_payment(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_fees_ledger_on_payment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE fees_ledger
  SET 
    total_paid = (
      SELECT COALESCE(SUM(amount), 0)
      FROM fee_payments
      WHERE student_id = NEW.student_id
        AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
        AND status = 'completed'
    ),
    last_payment_date = NEW.payment_date,
    payment_status = CASE 
      WHEN (
        SELECT COALESCE(SUM(amount), 0)
        FROM fee_payments
        WHERE student_id = NEW.student_id
          AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
          AND status = 'completed'
      ) >= (
        SELECT COALESCE(SUM(amount - amount_waived), 0)
        FROM fee_allocations
        WHERE student_id = NEW.student_id
          AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
      ) THEN 'complete'
      WHEN (
        SELECT COALESCE(SUM(amount), 0)
        FROM fee_payments
        WHERE student_id = NEW.student_id
          AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
          AND status = 'completed'
      ) > 0 THEN 'partial'
      ELSE 'pending'
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE student_id = NEW.student_id
    AND term_id = (SELECT term_id FROM fee_allocations WHERE id = NEW.allocation_id)
    AND school_id = NEW.school_id;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_fees_ledger_on_payment() OWNER TO xhenvolt;

--
-- Name: update_ledger_on_payment(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_ledger_on_payment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE fees_ledger
  SET 
    total_paid = COALESCE(total_paid, 0) + NEW.amount,
    balance_outstanding = COALESCE(balance_outstanding, 0) - NEW.amount,
    last_payment_date = NEW.payment_date,
    last_updated = CURRENT_TIMESTAMP
  WHERE school_id = NEW.school_id AND student_id = NEW.student_id;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_ledger_on_payment() OWNER TO xhenvolt;

--
-- Name: update_ledger_on_waiver_approval(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_ledger_on_waiver_approval() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    UPDATE fees_ledger
    SET 
      total_waived = COALESCE(total_waived, 0) + NEW.amount_requested,
      balance_outstanding = COALESCE(balance_outstanding, 0) - NEW.amount_requested,
      last_updated = CURRENT_TIMESTAMP
    WHERE school_id = NEW.school_id AND student_id = NEW.student_id;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_ledger_on_waiver_approval() OWNER TO xhenvolt;

--
-- Name: update_payment_allocation_status(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_payment_allocation_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  p_id UUID;
  total_allocated DECIMAL(15,2);
  p_amount DECIMAL(15,2);
BEGIN
  -- Get the payment ID (handle both INSERT/UPDATE and DELETE)
  p_id := COALESCE(NEW.payment_id, OLD.payment_id);
  
  -- Calculate total allocated
  SELECT COALESCE(SUM(amount), 0) INTO total_allocated
  FROM allocations WHERE payment_id = p_id;
  
  -- Get payment amount
  SELECT amount_received INTO p_amount FROM payments WHERE id = p_id;
  
  -- Update payment allocation status
  UPDATE payments
  SET 
    allocated_amount = total_allocated,
    allocation_status = CASE
      WHEN total_allocated = 0 THEN 'pending'
      WHEN total_allocated < p_amount THEN 'partial'
      ELSE 'allocated'
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.update_payment_allocation_status() OWNER TO xhenvolt;

--
-- Name: update_share_transfers_timestamp(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_share_transfers_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_share_transfers_timestamp() OWNER TO xhenvolt;

--
-- Name: update_shareholdings_timestamp(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_shareholdings_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_shareholdings_timestamp() OWNER TO xhenvolt;

--
-- Name: update_shares_config_timestamp(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_shares_config_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_shares_config_timestamp() OWNER TO xhenvolt;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO xhenvolt;

--
-- Name: validate_allocation_amount(); Type: FUNCTION; Schema: public; Owner: xhenvolt
--

CREATE FUNCTION public.validate_allocation_amount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  p_amount DECIMAL(15,2);
  total_allocated DECIMAL(15,2);
  new_total DECIMAL(15,2);
BEGIN
  -- Get payment amount
  SELECT amount_received INTO p_amount FROM payments WHERE id = NEW.payment_id;
  
  -- Get current total allocated (excluding this allocation if UPDATE)
  SELECT COALESCE(SUM(amount), 0) INTO total_allocated
  FROM allocations 
  WHERE payment_id = NEW.payment_id AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
  
  -- Calculate new total
  new_total := total_allocated + NEW.amount;
  
  -- Validate
  IF new_total > p_amount THEN
    RAISE EXCEPTION 'Allocation would exceed payment amount. Payment: %, Current allocated: %, New allocation: %, Total would be: %',
      p_amount, total_allocated, NEW.amount, new_total;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.validate_allocation_amount() OWNER TO xhenvolt;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_years; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.academic_years (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.academic_years OWNER TO xhenvolt;

--
-- Name: academic_years_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.academic_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_years_id_seq OWNER TO xhenvolt;

--
-- Name: academic_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.academic_years_id_seq OWNED BY public.academic_years.id;


--
-- Name: assignment; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.assignment (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    class_id bigint,
    teacher_id bigint NOT NULL,
    subject_id bigint,
    title character varying(255) NOT NULL,
    description text,
    instructions text,
    total_marks numeric(5,2) DEFAULT 0 NOT NULL,
    assigned_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    due_date timestamp with time zone NOT NULL,
    attachment_url character varying(500),
    late_submission_allowed boolean DEFAULT false,
    late_penalty_percentage numeric(5,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.assignment OWNER TO xhenvolt;

--
-- Name: TABLE assignment; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.assignment IS 'Assignment management and tracking';


--
-- Name: assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignment_id_seq OWNER TO xhenvolt;

--
-- Name: assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.assignment_id_seq OWNED BY public.assignment.id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.attendance (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    user_id bigint NOT NULL,
    attendance_date date NOT NULL,
    status character varying(20) DEFAULT 'present'::character varying NOT NULL,
    notes text,
    recorded_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT attendance_status_check CHECK (((status)::text = ANY ((ARRAY['present'::character varying, 'absent'::character varying, 'late'::character varying, 'excused'::character varying, 'half_day'::character varying])::text[])))
);


ALTER TABLE public.attendance OWNER TO xhenvolt;

--
-- Name: TABLE attendance; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.attendance IS 'General attendance tracking (staff and students)';


--
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_id_seq OWNER TO xhenvolt;

--
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.attendance_id_seq OWNED BY public.attendance.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    user_id bigint NOT NULL,
    action character varying(255) NOT NULL,
    details text,
    ip_address character varying(45) DEFAULT NULL::character varying,
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.audit_log OWNER TO xhenvolt;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO xhenvolt;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    school_id bigint,
    action character varying(50) NOT NULL,
    entity_type character varying(100),
    entity_id bigint,
    old_values jsonb,
    new_values jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT valid_action_extended CHECK (((action)::text = ANY ((ARRAY['LOGIN_SUCCESS'::character varying, 'LOGIN_FAILURE'::character varying, 'LOGOUT'::character varying, 'REGISTER'::character varying, 'TOKEN_VALIDATION_FAILURE'::character varying, 'PROTECTED_ROUTE_ACCESS'::character varying, 'ROUTE_DENIED'::character varying, 'USER_CREATED'::character varying, 'USER_UPDATED'::character varying, 'USER_DELETED'::character varying, 'ROLE_CHANGED'::character varying, 'STAFF_CREATED'::character varying, 'STAFF_SUSPENDED'::character varying, 'STAFF_REACTIVATED'::character varying, 'ASSET_CREATE'::character varying, 'ASSET_CREATE_DENIED'::character varying, 'ASSET_UPDATE'::character varying, 'ASSET_UPDATE_DENIED'::character varying, 'ASSET_DELETE'::character varying, 'ASSET_DELETE_DENIED'::character varying, 'ASSET_RESTORE'::character varying, 'ASSET_LOCK'::character varying, 'ASSET_UNLOCK'::character varying, 'LIABILITY_CREATE'::character varying, 'LIABILITY_CREATE_DENIED'::character varying, 'LIABILITY_UPDATE'::character varying, 'LIABILITY_UPDATE_DENIED'::character varying, 'LIABILITY_DELETE'::character varying, 'LIABILITY_DELETE_DENIED'::character varying, 'LIABILITY_RESTORE'::character varying, 'LIABILITY_LOCK'::character varying, 'LIABILITY_UNLOCK'::character varying, 'DEAL_CREATE'::character varying, 'DEAL_CREATE_DENIED'::character varying, 'DEAL_UPDATE'::character varying, 'DEAL_UPDATE_DENIED'::character varying, 'DEAL_DELETE'::character varying, 'DEAL_DELETE_DENIED'::character varying, 'DEAL_RESTORE'::character varying, 'DEAL_LOCK'::character varying, 'DEAL_UNLOCK'::character varying, 'DEAL_STAGE_CHANGE'::character varying, 'DEAL_STAGE_CHANGE_DENIED'::character varying, 'SHARE_TRANSFER'::character varying, 'SHARE_TRANSFER_DENIED'::character varying, 'SHARE_ISSUANCE'::character varying, 'SHARE_ISSUANCE_DENIED'::character varying, 'SHARE_ISSUANCE_APPROVED'::character varying, 'SHARE_CONFIG_UPDATE'::character varying, 'SHARE_CONFIG_UPDATE_DENIED'::character varying, 'CAP_TABLE_VIEWED'::character varying, 'SHAREHOLDER_ADDED'::character varying, 'SHAREHOLDER_REMOVED'::character varying, 'VESTING_CONFIGURED'::character varying, 'VESTING_VESTED'::character varying])::text[])))
);


ALTER TABLE public.audit_logs OWNER TO xhenvolt;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO xhenvolt;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: class_subjects; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.class_subjects (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    is_optional boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.class_subjects OWNER TO xhenvolt;

--
-- Name: class_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.class_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.class_subjects_id_seq OWNER TO xhenvolt;

--
-- Name: class_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.class_subjects_id_seq OWNED BY public.class_subjects.id;


--
-- Name: classes; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.classes (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100),
    code character varying(50),
    class_level character varying(50),
    capacity integer DEFAULT 50,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    grade integer,
    level character varying(100),
    shortform character varying(50),
    curriculum character varying(100),
    class_name character varying(100),
    class_code character varying(50),
    teacher_id bigint
);


ALTER TABLE public.classes OWNER TO xhenvolt;

--
-- Name: classes_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classes_id_seq OWNER TO xhenvolt;

--
-- Name: classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.classes_id_seq OWNED BY public.classes.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    school_id bigint,
    name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(30),
    address text,
    city character varying(100),
    country character varying(100) DEFAULT 'Uganda'::character varying,
    contact_type character varying(50),
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contacts OWNER TO xhenvolt;

--
-- Name: TABLE contacts; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.contacts IS 'General contact information (supplementary to people table)';


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contacts_id_seq OWNER TO xhenvolt;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: curricula; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.curricula (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.curricula OWNER TO xhenvolt;

--
-- Name: curricula_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.curricula_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.curricula_id_seq OWNER TO xhenvolt;

--
-- Name: curricula_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.curricula_id_seq OWNED BY public.curricula.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.departments (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50),
    head_id bigint,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.departments OWNER TO xhenvolt;

--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departments_id_seq OWNER TO xhenvolt;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.documents (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    user_id bigint,
    document_type character varying(100) NOT NULL,
    title character varying(255) NOT NULL,
    file_url character varying(500),
    file_size bigint,
    content_preview text,
    status character varying(50) DEFAULT 'draft'::character varying,
    version_number integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT documents_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE public.documents OWNER TO xhenvolt;

--
-- Name: TABLE documents; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.documents IS 'Document storage and versioning';


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documents_id_seq OWNER TO xhenvolt;

--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.enrollments (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint NOT NULL,
    section_id bigint,
    term_id bigint,
    status character varying(20) DEFAULT 'enrolled'::character varying,
    enrollment_date date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT enrollments_status_check CHECK (((status)::text = ANY ((ARRAY['enrolled'::character varying, 'withdrawn'::character varying, 'transferred'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.enrollments OWNER TO xhenvolt;

--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enrollments_id_seq OWNER TO xhenvolt;

--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: exams; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.exams (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    term_id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    exam_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    duration integer NOT NULL,
    max_marks numeric(5,2) NOT NULL,
    passing_marks numeric(5,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    exam_name character varying(255),
    term character varying(50),
    year integer,
    status character varying(20) DEFAULT 'planned'::character varying
);


ALTER TABLE public.exams OWNER TO xhenvolt;

--
-- Name: exams_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.exams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exams_id_seq OWNER TO xhenvolt;

--
-- Name: exams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.exams_id_seq OWNED BY public.exams.id;


--
-- Name: expense_categories; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.expense_categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.expense_categories OWNER TO xhenvolt;

--
-- Name: expense_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.expense_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_categories_id_seq OWNER TO xhenvolt;

--
-- Name: expense_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.expense_categories_id_seq OWNED BY public.expense_categories.id;


--
-- Name: fee_allocations; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_allocations (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    fee_structure_id bigint NOT NULL,
    academic_year_id bigint,
    term_id bigint,
    amount numeric(12,2) NOT NULL,
    amount_paid numeric(12,2) DEFAULT 0.00,
    amount_waived numeric(12,2) DEFAULT 0.00,
    balance numeric(12,2) GENERATED ALWAYS AS (((amount - amount_paid) - amount_waived)) STORED,
    allocation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    due_date date,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fee_allocations OWNER TO xhenvolt;

--
-- Name: fee_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_allocations_id_seq OWNER TO xhenvolt;

--
-- Name: fee_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_allocations_id_seq OWNED BY public.fee_allocations.id;


--
-- Name: fee_categories; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_categories (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    accounting_code character varying(50),
    is_mandatory boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone
);


ALTER TABLE public.fee_categories OWNER TO xhenvolt;

--
-- Name: fee_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_categories_id_seq OWNER TO xhenvolt;

--
-- Name: fee_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_categories_id_seq OWNED BY public.fee_categories.id;


--
-- Name: fee_discounts; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_discounts (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    discount_type character varying(20) NOT NULL,
    discount_value numeric(12,2) NOT NULL,
    is_active boolean DEFAULT true,
    applicable_to_categories text,
    valid_from date,
    valid_until date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fee_discounts_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['percentage'::character varying, 'fixed_amount'::character varying])::text[]))),
    CONSTRAINT fee_discounts_discount_value_check CHECK ((discount_value > (0)::numeric))
);


ALTER TABLE public.fee_discounts OWNER TO xhenvolt;

--
-- Name: fee_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_discounts_id_seq OWNER TO xhenvolt;

--
-- Name: fee_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_discounts_id_seq OWNED BY public.fee_discounts.id;


--
-- Name: fee_invoices; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_invoices (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    invoice_number character varying(100) NOT NULL,
    invoice_date date NOT NULL,
    due_date date NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    amount_paid numeric(12,2) DEFAULT 0.00,
    status character varying(20) DEFAULT 'draft'::character varying,
    notes text,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fee_invoices_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'sent'::character varying, 'partially_paid'::character varying, 'paid'::character varying, 'overdue'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT fee_invoices_total_amount_check CHECK ((total_amount > (0)::numeric))
);


ALTER TABLE public.fee_invoices OWNER TO xhenvolt;

--
-- Name: fee_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_invoices_id_seq OWNER TO xhenvolt;

--
-- Name: fee_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_invoices_id_seq OWNED BY public.fee_invoices.id;


--
-- Name: fee_notification_queue; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_notification_queue (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    notification_type character varying(50) NOT NULL,
    entity_type character varying(50),
    entity_id bigint,
    title character varying(255),
    message text,
    is_sent boolean DEFAULT false,
    sent_at timestamp without time zone,
    delivery_attempts integer DEFAULT 0,
    last_attempt_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fee_notification_queue OWNER TO xhenvolt;

--
-- Name: fee_notification_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_notification_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_notification_queue_id_seq OWNER TO xhenvolt;

--
-- Name: fee_notification_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_notification_queue_id_seq OWNED BY public.fee_notification_queue.id;


--
-- Name: fee_payments; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_payments (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    payment_date date NOT NULL,
    reference_number character varying(100),
    notes text,
    is_verified boolean DEFAULT false,
    verified_by bigint,
    verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fee_payments_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.fee_payments OWNER TO xhenvolt;

--
-- Name: fee_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_payments_id_seq OWNER TO xhenvolt;

--
-- Name: fee_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_payments_id_seq OWNED BY public.fee_payments.id;


--
-- Name: fee_receipts; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_receipts (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    receipt_number character varying(100) NOT NULL,
    receipt_date date NOT NULL,
    amount numeric(12,2) NOT NULL,
    notes text,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fee_receipts_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.fee_receipts OWNER TO xhenvolt;

--
-- Name: fee_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_receipts_id_seq OWNER TO xhenvolt;

--
-- Name: fee_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_receipts_id_seq OWNED BY public.fee_receipts.id;


--
-- Name: fee_structures; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_structures (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    academic_year_id bigint,
    term_id bigint,
    class_id bigint,
    amount numeric(14,2) NOT NULL,
    currency character varying(10) DEFAULT 'USD'::character varying,
    due_date date,
    late_fee_amount numeric(14,2) DEFAULT NULL::numeric,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    section_id bigint,
    fee_category_id bigint
);


ALTER TABLE public.fee_structures OWNER TO xhenvolt;

--
-- Name: fee_structures_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_structures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_structures_id_seq OWNER TO xhenvolt;

--
-- Name: fee_structures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_structures_id_seq OWNED BY public.fee_structures.id;


--
-- Name: fee_waivers; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fee_waivers (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    fee_allocation_id bigint NOT NULL,
    amount_requested numeric(12,2) NOT NULL,
    reason text NOT NULL,
    requested_by bigint NOT NULL,
    requested_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'pending'::character varying,
    approved_by bigint,
    approved_at timestamp without time zone,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fee_waivers_amount_requested_check CHECK ((amount_requested > (0)::numeric)),
    CONSTRAINT fee_waivers_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.fee_waivers OWNER TO xhenvolt;

--
-- Name: fee_waivers_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fee_waivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fee_waivers_id_seq OWNER TO xhenvolt;

--
-- Name: fee_waivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fee_waivers_id_seq OWNED BY public.fee_waivers.id;


--
-- Name: fees_audit_logs; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fees_audit_logs (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_address inet
);


ALTER TABLE public.fees_audit_logs OWNER TO xhenvolt;

--
-- Name: fees_audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fees_audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fees_audit_logs_id_seq OWNER TO xhenvolt;

--
-- Name: fees_audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fees_audit_logs_id_seq OWNED BY public.fees_audit_logs.id;


--
-- Name: fees_ledger; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fees_ledger (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    student_id bigint NOT NULL,
    total_fees numeric(12,2) DEFAULT 0.00 NOT NULL,
    total_paid numeric(12,2) DEFAULT 0.00 NOT NULL,
    total_waived numeric(12,2) DEFAULT 0.00 NOT NULL,
    balance_outstanding numeric(12,2) DEFAULT 0.00 NOT NULL,
    last_payment_date timestamp without time zone,
    term_id bigint,
    academic_year_id bigint,
    payment_status character varying(50) DEFAULT 'pending'::character varying,
    class_id bigint,
    section_id bigint,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fees_ledger OWNER TO xhenvolt;

--
-- Name: fees_ledger_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fees_ledger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fees_ledger_id_seq OWNER TO xhenvolt;

--
-- Name: fees_ledger_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fees_ledger_id_seq OWNED BY public.fees_ledger.id;


--
-- Name: file_upload; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.file_upload (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    school_id bigint,
    filename character varying(500) NOT NULL,
    original_filename character varying(500),
    file_size bigint,
    mime_type character varying(100),
    file_path character varying(500),
    storage_location character varying(500),
    description text,
    is_public boolean DEFAULT false,
    download_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.file_upload OWNER TO xhenvolt;

--
-- Name: TABLE file_upload; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.file_upload IS 'Uploaded file tracking and metadata';


--
-- Name: file_upload_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.file_upload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.file_upload_id_seq OWNER TO xhenvolt;

--
-- Name: file_upload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.file_upload_id_seq OWNED BY public.file_upload.id;


--
-- Name: fingerprints; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.fingerprints (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    student_id bigint,
    staff_id bigint,
    fingerprint_data bytea NOT NULL,
    finger_position character varying(20) DEFAULT 'right_thumb'::character varying,
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fingerprints_finger_position_check CHECK (((finger_position)::text = ANY ((ARRAY['right_thumb'::character varying, 'right_index'::character varying, 'right_middle'::character varying, 'right_ring'::character varying, 'right_pinky'::character varying, 'left_thumb'::character varying, 'left_index'::character varying, 'left_middle'::character varying, 'left_ring'::character varying, 'left_pinky'::character varying])::text[])))
);


ALTER TABLE public.fingerprints OWNER TO xhenvolt;

--
-- Name: fingerprints_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.fingerprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fingerprints_id_seq OWNER TO xhenvolt;

--
-- Name: fingerprints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.fingerprints_id_seq OWNED BY public.fingerprints.id;


--
-- Name: lesson; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.lesson (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    class_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    topic character varying(255) NOT NULL,
    description text,
    learning_objectives jsonb,
    resources jsonb,
    lesson_date date NOT NULL,
    duration_minutes integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.lesson OWNER TO xhenvolt;

--
-- Name: TABLE lesson; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.lesson IS 'Lesson planning and scheduling';


--
-- Name: lesson_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.lesson_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lesson_id_seq OWNER TO xhenvolt;

--
-- Name: lesson_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.lesson_id_seq OWNED BY public.lesson.id;


--
-- Name: message; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.message (
    id bigint NOT NULL,
    sender_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    school_id bigint,
    subject character varying(255),
    body text NOT NULL,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.message OWNER TO xhenvolt;

--
-- Name: TABLE message; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.message IS 'User-to-user and system messages';


--
-- Name: message_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.message_id_seq OWNER TO xhenvolt;

--
-- Name: message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.message_id_seq OWNED BY public.message.id;


--
-- Name: notices; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.notices (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    notice_type public.notice_type_enum DEFAULT 'general'::public.notice_type_enum,
    target_audience public.notice_audience_enum DEFAULT 'all'::public.notice_audience_enum,
    start_date date,
    end_date date,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notices OWNER TO xhenvolt;

--
-- Name: notices_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.notices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notices_id_seq OWNER TO xhenvolt;

--
-- Name: notices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.notices_id_seq OWNED BY public.notices.id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    school_id bigint,
    type character varying(100) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    data jsonb,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notification OWNER TO xhenvolt;

--
-- Name: TABLE notification; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.notification IS 'System notifications and alerts for users';


--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_id_seq OWNER TO xhenvolt;

--
-- Name: notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.notification_id_seq OWNED BY public.notification.id;


--
-- Name: onboarding_steps; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.onboarding_steps (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    step_name character varying(50) NOT NULL,
    step_order integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    step_data jsonb,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT onboarding_steps_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'skipped'::character varying])::text[])))
);


ALTER TABLE public.onboarding_steps OWNER TO xhenvolt;

--
-- Name: TABLE onboarding_steps; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.onboarding_steps IS 'Tracks user onboarding progress step by step';


--
-- Name: COLUMN onboarding_steps.user_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.onboarding_steps.user_id IS 'Reference to user undergoing onboarding';


--
-- Name: COLUMN onboarding_steps.status; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.onboarding_steps.status IS 'Current status of onboarding step';


--
-- Name: COLUMN onboarding_steps.step_data; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.onboarding_steps.step_data IS 'JSON data collected during step (flexible schema)';


--
-- Name: onboarding_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.onboarding_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.onboarding_steps_id_seq OWNER TO xhenvolt;

--
-- Name: onboarding_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.onboarding_steps_id_seq OWNED BY public.onboarding_steps.id;


--
-- Name: payment_allocations; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.payment_allocations (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    fee_payment_id bigint NOT NULL,
    fee_allocation_id bigint NOT NULL,
    amount_allocated numeric(12,2) NOT NULL,
    allocation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_allocations_amount_allocated_check CHECK ((amount_allocated > (0)::numeric))
);


ALTER TABLE public.payment_allocations OWNER TO xhenvolt;

--
-- Name: payment_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.payment_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_allocations_id_seq OWNER TO xhenvolt;

--
-- Name: payment_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.payment_allocations_id_seq OWNED BY public.payment_allocations.id;


--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.payment_methods (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payment_methods OWNER TO xhenvolt;

--
-- Name: TABLE payment_methods; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.payment_methods IS 'Available payment methods (credit card, bank transfer, mobile money, etc.)';


--
-- Name: payment_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_methods_id_seq OWNER TO xhenvolt;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.payment_methods_id_seq OWNED BY public.payment_methods.id;


--
-- Name: payment_plan; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.payment_plan (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    amount_monthly numeric(10,2) DEFAULT 0,
    amount_yearly numeric(10,2) DEFAULT 0,
    currency character varying(10) DEFAULT 'UGX'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payment_plan OWNER TO xhenvolt;

--
-- Name: TABLE payment_plan; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.payment_plan IS 'Legacy payment plans table';


--
-- Name: payment_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.payment_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_plan_id_seq OWNER TO xhenvolt;

--
-- Name: payment_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.payment_plan_id_seq OWNED BY public.payment_plan.id;


--
-- Name: payment_plans; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.payment_plans (
    id bigint NOT NULL,
    plan_name character varying(100) NOT NULL,
    plan_code character varying(50) NOT NULL,
    description text,
    price_monthly numeric(10,2) DEFAULT 0.00 NOT NULL,
    price_yearly numeric(10,2) DEFAULT 0.00 NOT NULL,
    currency character varying(10) DEFAULT 'UGX'::character varying,
    trial_period_days integer DEFAULT 0,
    max_students integer,
    max_staff integer,
    max_schools integer DEFAULT 1,
    features jsonb,
    is_active boolean DEFAULT true,
    is_trial boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payment_plans OWNER TO xhenvolt;

--
-- Name: TABLE payment_plans; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.payment_plans IS 'Available subscription plans and pricing';


--
-- Name: payment_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.payment_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_plans_id_seq OWNER TO xhenvolt;

--
-- Name: payment_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.payment_plans_id_seq OWNED BY public.payment_plans.id;


--
-- Name: payment_reminder; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.payment_reminder (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint,
    reminder_date date NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    message_template character varying(500),
    sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_reminder_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'failed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.payment_reminder OWNER TO xhenvolt;

--
-- Name: TABLE payment_reminder; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.payment_reminder IS 'Payment reminders for upcoming subscription renewals';


--
-- Name: payment_reminder_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.payment_reminder_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_reminder_id_seq OWNER TO xhenvolt;

--
-- Name: payment_reminder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.payment_reminder_id_seq OWNED BY public.payment_reminder.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.people (
    id bigint NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    middle_name character varying(100) DEFAULT NULL::character varying,
    gender public.gender_enum DEFAULT 'other'::public.gender_enum,
    dob date,
    phone character varying(50) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    address text,
    photo_url character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.people OWNER TO xhenvolt;

--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.people_id_seq OWNER TO xhenvolt;

--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.people_id_seq OWNED BY public.people.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.permissions OWNER TO xhenvolt;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissions_id_seq OWNER TO xhenvolt;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: person; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.person (
    id bigint NOT NULL,
    school_id bigint,
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    phone character varying(30),
    national_id character varying(50),
    gender character varying(20),
    date_of_birth date,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.person OWNER TO xhenvolt;

--
-- Name: TABLE person; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.person IS 'Normalized person records (separate from user accounts)';


--
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_id_seq OWNER TO xhenvolt;

--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.person_id_seq OWNED BY public.person.id;


--
-- Name: quiz; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.quiz (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    class_id bigint,
    teacher_id bigint NOT NULL,
    subject_id bigint,
    title character varying(255) NOT NULL,
    description text,
    total_questions integer DEFAULT 0,
    total_marks numeric(5,2) DEFAULT 0,
    passing_percentage numeric(5,2) DEFAULT 50,
    quiz_date timestamp with time zone,
    duration_minutes integer,
    is_published boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.quiz OWNER TO xhenvolt;

--
-- Name: TABLE quiz; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.quiz IS 'Quiz and test management';


--
-- Name: quiz_attempt; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.quiz_attempt (
    id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    student_id bigint NOT NULL,
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_time timestamp with time zone,
    total_marks numeric(5,2),
    obtained_marks numeric(5,2),
    percentage numeric(5,2),
    pass boolean,
    status character varying(50) DEFAULT 'in_progress'::character varying,
    answers jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quiz_attempt_status_check CHECK (((status)::text = ANY ((ARRAY['in_progress'::character varying, 'submitted'::character varying, 'graded'::character varying, 'abandoned'::character varying])::text[])))
);


ALTER TABLE public.quiz_attempt OWNER TO xhenvolt;

--
-- Name: TABLE quiz_attempt; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.quiz_attempt IS 'Student quiz attempts and submissions';


--
-- Name: quiz_attempt_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.quiz_attempt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_attempt_id_seq OWNER TO xhenvolt;

--
-- Name: quiz_attempt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.quiz_attempt_id_seq OWNED BY public.quiz_attempt.id;


--
-- Name: quiz_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.quiz_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_id_seq OWNER TO xhenvolt;

--
-- Name: quiz_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.quiz_id_seq OWNED BY public.quiz.id;


--
-- Name: quiz_question; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.quiz_question (
    id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    question_text text NOT NULL,
    question_type character varying(50) DEFAULT 'multiple_choice'::character varying NOT NULL,
    marks numeric(5,2) DEFAULT 1,
    options jsonb,
    correct_answer text,
    question_order integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quiz_question_question_type_check CHECK (((question_type)::text = ANY ((ARRAY['multiple_choice'::character varying, 'true_false'::character varying, 'short_answer'::character varying, 'essay'::character varying])::text[])))
);


ALTER TABLE public.quiz_question OWNER TO xhenvolt;

--
-- Name: TABLE quiz_question; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.quiz_question IS 'Individual questions within a quiz';


--
-- Name: quiz_question_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.quiz_question_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_question_id_seq OWNER TO xhenvolt;

--
-- Name: quiz_question_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.quiz_question_id_seq OWNED BY public.quiz_question.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.results (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    exam_id bigint NOT NULL,
    student_id bigint NOT NULL,
    obtained_marks numeric(5,2) NOT NULL,
    grade character varying(10) DEFAULT NULL::character varying,
    remarks text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.results OWNER TO xhenvolt;

--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.results_id_seq OWNER TO xhenvolt;

--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.results_id_seq OWNED BY public.results.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.role_permissions (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    granted boolean DEFAULT true
);


ALTER TABLE public.role_permissions OWNER TO xhenvolt;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permissions_id_seq OWNER TO xhenvolt;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    description text,
    is_system_role boolean DEFAULT false,
    hierarchy_level integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.roles OWNER TO xhenvolt;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO xhenvolt;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: school_onboarding; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.school_onboarding (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    school_name_set boolean DEFAULT false,
    school_address_set boolean DEFAULT false,
    contact_info_set boolean DEFAULT false,
    location_details_set boolean DEFAULT false,
    policies_set boolean DEFAULT false,
    is_complete boolean DEFAULT false,
    completed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.school_onboarding OWNER TO xhenvolt;

--
-- Name: school_onboarding_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.school_onboarding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.school_onboarding_id_seq OWNER TO xhenvolt;

--
-- Name: school_onboarding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.school_onboarding_id_seq OWNED BY public.school_onboarding.id;


--
-- Name: school_settings; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.school_settings (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value text,
    data_type character varying(50) DEFAULT 'string'::character varying,
    description text,
    is_public boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT school_settings_data_type_check CHECK (((data_type)::text = ANY ((ARRAY['string'::character varying, 'integer'::character varying, 'boolean'::character varying, 'json'::character varying, 'text'::character varying])::text[])))
);


ALTER TABLE public.school_settings OWNER TO xhenvolt;

--
-- Name: TABLE school_settings; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.school_settings IS 'School-wide configuration and preferences (JSON-flexible)';


--
-- Name: school_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.school_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.school_settings_id_seq OWNER TO xhenvolt;

--
-- Name: school_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.school_settings_id_seq OWNED BY public.school_settings.id;


--
-- Name: schools; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.schools (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(50) NOT NULL,
    address text,
    phone character varying(50) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    website character varying(100) DEFAULT NULL::character varying,
    status public.school_status DEFAULT 'active'::public.school_status,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    city character varying(255),
    region character varying(255),
    school_type character varying(100),
    student_count integer,
    staff_count integer
);


ALTER TABLE public.schools OWNER TO xhenvolt;

--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schools_id_seq OWNER TO xhenvolt;

--
-- Name: schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.schools_id_seq OWNED BY public.schools.id;


--
-- Name: schools_test; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.schools_test (
    id bigint,
    name character varying(255),
    code character varying(50),
    address text,
    phone character varying(50),
    email character varying(100),
    website character varying(100),
    status public.school_status,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    city character varying(255),
    region character varying(255),
    school_type character varying(100),
    student_count integer,
    staff_count integer
);


ALTER TABLE public.schools_test OWNER TO xhenvolt;

--
-- Name: sections; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.sections (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    class_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    capacity integer DEFAULT 40,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sections OWNER TO xhenvolt;

--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sections_id_seq OWNER TO xhenvolt;

--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: seq_invoice_number; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.seq_invoice_number
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_invoice_number OWNER TO xhenvolt;

--
-- Name: seq_receipt_number; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.seq_receipt_number
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_receipt_number OWNER TO xhenvolt;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id bigint NOT NULL,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    stay_logged_in boolean DEFAULT false,
    is_active boolean DEFAULT true,
    logged_out_at timestamp without time zone,
    session_token character varying(500),
    school_id bigint,
    CONSTRAINT valid_expiry CHECK ((expires_at > created_at))
);


ALTER TABLE public.sessions OWNER TO xhenvolt;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.settings OWNER TO xhenvolt;

--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.settings_id_seq OWNER TO xhenvolt;

--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: shares_config; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.shares_config (
    id integer NOT NULL,
    authorized_shares bigint DEFAULT 10000000 NOT NULL,
    issued_shares bigint DEFAULT 1000000 NOT NULL,
    par_value numeric(19,4) DEFAULT 1.0000 NOT NULL,
    class_type character varying(50) DEFAULT 'Common'::character varying NOT NULL,
    company_id uuid,
    status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT authorized_gte_issued CHECK ((authorized_shares >= issued_shares)),
    CONSTRAINT positive_authorized CHECK ((authorized_shares > 0)),
    CONSTRAINT positive_issued CHECK ((issued_shares > 0)),
    CONSTRAINT positive_par CHECK ((par_value > (0)::numeric))
);


ALTER TABLE public.shares_config OWNER TO xhenvolt;

--
-- Name: share_authorization_status; Type: VIEW; Schema: public; Owner: xhenvolt
--

CREATE VIEW public.share_authorization_status AS
 SELECT authorized_shares,
    issued_shares,
    (authorized_shares - issued_shares) AS unissued_shares,
    (((((authorized_shares - issued_shares))::numeric / (authorized_shares)::numeric) * (100)::numeric))::numeric(5,2) AS pct_authorized_available,
    class_type,
    status,
    created_at,
    updated_at
   FROM public.shares_config;


ALTER VIEW public.share_authorization_status OWNER TO xhenvolt;

--
-- Name: share_issuances; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.share_issuances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    shares_issued bigint NOT NULL,
    issued_at_price numeric(19,4),
    valuation_post_issuance numeric(19,2),
    recipient_id bigint,
    recipient_type character varying(50),
    issuance_reason character varying(500),
    issuance_type character varying(50) DEFAULT 'equity'::character varying NOT NULL,
    equity_type character varying(50) DEFAULT 'PURCHASED'::character varying NOT NULL,
    approval_status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    requires_confirmation boolean DEFAULT true,
    confirmation_received boolean DEFAULT false,
    previous_issued_shares bigint,
    ownership_dilution_impact numeric(5,2),
    created_by_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    approved_by_id bigint,
    approved_at timestamp with time zone,
    issued_at timestamp with time zone,
    notes text,
    CONSTRAINT positive_issued CHECK ((shares_issued > 0)),
    CONSTRAINT positive_price CHECK (((issued_at_price IS NULL) OR (issued_at_price > (0)::numeric))),
    CONSTRAINT valid_issuance_equity_type CHECK (((equity_type)::text = ANY ((ARRAY['PURCHASED'::character varying, 'GRANTED'::character varying])::text[])))
);


ALTER TABLE public.share_issuances OWNER TO xhenvolt;

--
-- Name: share_price_history; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.share_price_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    opening_price numeric(19,4),
    high_price numeric(19,4),
    low_price numeric(19,4),
    closing_price numeric(19,4) NOT NULL,
    company_valuation numeric(19,2),
    issued_shares bigint,
    event_type character varying(50),
    event_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_closing CHECK ((closing_price > (0)::numeric)),
    CONSTRAINT valid_ohlc CHECK ((((opening_price IS NULL) OR (opening_price > (0)::numeric)) AND ((high_price IS NULL) OR (high_price > (0)::numeric)) AND ((low_price IS NULL) OR (low_price > (0)::numeric))))
);


ALTER TABLE public.share_price_history OWNER TO xhenvolt;

--
-- Name: share_transfers; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.share_transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_shareholder_id bigint NOT NULL,
    to_shareholder_id bigint NOT NULL,
    shares_transferred bigint NOT NULL,
    transfer_price_per_share numeric(19,4),
    transfer_total numeric(19,2),
    transfer_type character varying(50) NOT NULL,
    transfer_date date DEFAULT CURRENT_DATE NOT NULL,
    transfer_status character varying(50) DEFAULT 'completed'::character varying NOT NULL,
    equity_type character varying(50),
    shares_returned bigint DEFAULT 0,
    reason character varying(500),
    notes text,
    created_by_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    approved_by_id bigint,
    approved_at timestamp with time zone,
    CONSTRAINT different_parties CHECK ((from_shareholder_id <> to_shareholder_id)),
    CONSTRAINT positive_transferred CHECK ((shares_transferred > 0)),
    CONSTRAINT valid_price CHECK (((transfer_price_per_share IS NULL) OR (transfer_price_per_share > (0)::numeric))),
    CONSTRAINT valid_transfer_equity_type CHECK (((equity_type IS NULL) OR ((equity_type)::text = ANY ((ARRAY['PURCHASED'::character varying, 'GRANTED'::character varying])::text[]))))
);


ALTER TABLE public.share_transfers OWNER TO xhenvolt;

--
-- Name: shareholdings; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.shareholdings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    shareholder_id bigint NOT NULL,
    shareholder_name character varying(255) NOT NULL,
    shareholder_email character varying(255),
    shares_owned bigint DEFAULT 0 NOT NULL,
    share_class character varying(50) DEFAULT 'Common'::character varying NOT NULL,
    equity_type character varying(50) DEFAULT 'PURCHASED'::character varying NOT NULL,
    vesting_start_date date,
    vesting_end_date date,
    vesting_schedule character varying(50),
    vesting_cliff_percentage numeric(5,2) DEFAULT 0,
    vested_shares bigint DEFAULT 0,
    acquisition_date date DEFAULT CURRENT_DATE NOT NULL,
    acquisition_price numeric(19,4),
    investment_total numeric(19,2),
    original_ownership_percentage numeric(5,2),
    current_ownership_percentage numeric(5,2),
    dilution_events_count integer DEFAULT 0,
    status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    holder_type character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_shares CHECK ((shares_owned >= 0)),
    CONSTRAINT positive_vested CHECK ((vested_shares >= 0)),
    CONSTRAINT valid_equity_type CHECK (((equity_type)::text = ANY ((ARRAY['PURCHASED'::character varying, 'GRANTED'::character varying])::text[]))),
    CONSTRAINT valid_percentage CHECK (((original_ownership_percentage >= (0)::numeric) AND (original_ownership_percentage <= (100)::numeric) AND (current_ownership_percentage >= (0)::numeric) AND (current_ownership_percentage <= (100)::numeric))),
    CONSTRAINT vested_lte_owned CHECK ((vested_shares <= shares_owned))
);


ALTER TABLE public.shareholdings OWNER TO xhenvolt;

--
-- Name: shares_config_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.shares_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shares_config_id_seq OWNER TO xhenvolt;

--
-- Name: shares_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.shares_config_id_seq OWNED BY public.shares_config.id;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.staff (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    person_id bigint NOT NULL,
    staff_no character varying(50) DEFAULT NULL::character varying,
    department_id bigint,
    "position" character varying(100) DEFAULT NULL::character varying,
    hire_date date,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT staff_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'on_leave'::character varying, 'resigned'::character varying])::text[])))
);


ALTER TABLE public.staff OWNER TO xhenvolt;

--
-- Name: staff_attendance; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.staff_attendance (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    staff_id bigint NOT NULL,
    date date NOT NULL,
    status character varying(20) DEFAULT 'present'::character varying,
    notes text,
    time_in time without time zone,
    time_out time without time zone,
    method character varying(20) DEFAULT 'manual'::character varying,
    marked_by bigint,
    marked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT staff_attendance_method_check CHECK (((method)::text = ANY ((ARRAY['manual'::character varying, 'biometric'::character varying, 'qr_code'::character varying])::text[]))),
    CONSTRAINT staff_attendance_status_check CHECK (((status)::text = ANY ((ARRAY['present'::character varying, 'absent'::character varying, 'late'::character varying, 'excused'::character varying, 'sick'::character varying])::text[])))
);


ALTER TABLE public.staff_attendance OWNER TO xhenvolt;

--
-- Name: staff_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.staff_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_attendance_id_seq OWNER TO xhenvolt;

--
-- Name: staff_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.staff_attendance_id_seq OWNED BY public.staff_attendance.id;


--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_id_seq OWNER TO xhenvolt;

--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.staff_id_seq OWNED BY public.staff.id;


--
-- Name: streams; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.streams (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.streams OWNER TO xhenvolt;

--
-- Name: streams_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.streams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.streams_id_seq OWNER TO xhenvolt;

--
-- Name: streams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.streams_id_seq OWNED BY public.streams.id;


--
-- Name: student_attendance; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.student_attendance (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    student_id bigint NOT NULL,
    date date NOT NULL,
    status character varying(20) DEFAULT 'present'::character varying,
    notes text,
    time_in time without time zone,
    time_out time without time zone,
    method character varying(20) DEFAULT 'manual'::character varying,
    marked_by bigint,
    marked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT student_attendance_method_check CHECK (((method)::text = ANY ((ARRAY['manual'::character varying, 'biometric'::character varying, 'qr_code'::character varying])::text[]))),
    CONSTRAINT student_attendance_status_check CHECK (((status)::text = ANY ((ARRAY['present'::character varying, 'absent'::character varying, 'late'::character varying, 'excused'::character varying, 'sick'::character varying])::text[])))
);


ALTER TABLE public.student_attendance OWNER TO xhenvolt;

--
-- Name: student_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.student_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_attendance_id_seq OWNER TO xhenvolt;

--
-- Name: student_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.student_attendance_id_seq OWNED BY public.student_attendance.id;


--
-- Name: student_contacts; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.student_contacts (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    contact_type character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    relationship character varying(100),
    phone character varying(30),
    email character varying(255),
    address text,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT student_contacts_contact_type_check CHECK (((contact_type)::text = ANY ((ARRAY['parent'::character varying, 'guardian'::character varying, 'sibling'::character varying, 'emergency'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE public.student_contacts OWNER TO xhenvolt;

--
-- Name: TABLE student_contacts; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.student_contacts IS 'Student contact information (parents, guardians, emergency contacts)';


--
-- Name: student_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.student_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_contacts_id_seq OWNER TO xhenvolt;

--
-- Name: student_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.student_contacts_id_seq OWNED BY public.student_contacts.id;


--
-- Name: student_curriculums; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.student_curriculums (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    school_id bigint NOT NULL,
    curriculum_name character varying(255) NOT NULL,
    curriculum_code character varying(50),
    enrollment_date date DEFAULT CURRENT_DATE NOT NULL,
    completion_date date,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT student_curriculums_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'completed'::character varying, 'transferred'::character varying, 'withdrawn'::character varying])::text[])))
);


ALTER TABLE public.student_curriculums OWNER TO xhenvolt;

--
-- Name: TABLE student_curriculums; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.student_curriculums IS 'Student curriculum/program enrollment tracking';


--
-- Name: student_curriculums_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.student_curriculums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_curriculums_id_seq OWNER TO xhenvolt;

--
-- Name: student_curriculums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.student_curriculums_id_seq OWNED BY public.student_curriculums.id;


--
-- Name: student_profiles; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.student_profiles (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    school_id bigint NOT NULL,
    registration_number character varying(50),
    date_of_birth date,
    gender character varying(20),
    blood_type character varying(10),
    nationality character varying(100) DEFAULT 'Uganda'::character varying,
    id_number character varying(50),
    mother_name character varying(255),
    father_name character varying(255),
    guardian_name character varying(255),
    guardian_phone character varying(30),
    health_notes text,
    dietary_restrictions text,
    emergency_contacts jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.student_profiles OWNER TO xhenvolt;

--
-- Name: TABLE student_profiles; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.student_profiles IS 'Extended student profile information';


--
-- Name: student_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.student_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_profiles_id_seq OWNER TO xhenvolt;

--
-- Name: student_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.student_profiles_id_seq OWNED BY public.student_profiles.id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.students (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    admission_no character varying(50) NOT NULL,
    class_id bigint,
    section_id bigint,
    roll_no integer,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    dob date,
    gender public.gender_enum DEFAULT 'other'::public.gender_enum,
    phone character varying(50) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    address text,
    photo_url character varying(255) DEFAULT NULL::character varying,
    status public.student_status DEFAULT 'active'::public.student_status,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.students OWNER TO xhenvolt;

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_id_seq OWNER TO xhenvolt;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.subjects (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50),
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.subjects OWNER TO xhenvolt;

--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subjects_id_seq OWNER TO xhenvolt;

--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- Name: terms; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.terms (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    academic_year_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.terms OWNER TO xhenvolt;

--
-- Name: terms_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.terms_id_seq OWNER TO xhenvolt;

--
-- Name: terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.terms_id_seq OWNED BY public.terms.id;


--
-- Name: timetable; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.timetable (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    lesson_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    day_of_week smallint NOT NULL,
    room character varying(50) DEFAULT NULL::character varying,
    venue character varying(100) DEFAULT NULL::character varying,
    required_resources text,
    lesson_title character varying(200) DEFAULT NULL::character varying,
    lesson_description text,
    lesson_type public.lesson_type_enum DEFAULT 'regular'::public.lesson_type_enum,
    status public.timetable_status_enum DEFAULT 'scheduled'::public.timetable_status_enum,
    attendance_taken boolean DEFAULT false,
    is_recurring boolean DEFAULT false,
    recurrence_pattern public.recurrence_pattern_enum,
    recurrence_end_date date,
    recurrence_interval integer DEFAULT 1,
    recurrence_days character varying(20) DEFAULT NULL::character varying,
    parent_timetable_id bigint,
    exception_id bigint,
    notes text,
    created_by bigint,
    updated_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    CONSTRAINT timetable_day_of_week_check CHECK (((day_of_week >= 1) AND (day_of_week <= 7)))
);


ALTER TABLE public.timetable OWNER TO xhenvolt;

--
-- Name: timetable_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.timetable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.timetable_id_seq OWNER TO xhenvolt;

--
-- Name: timetable_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.timetable_id_seq OWNED BY public.timetable.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.transactions (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    user_id bigint,
    transaction_type character varying(100) NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency character varying(10) DEFAULT 'UGX'::character varying,
    status character varying(50) DEFAULT 'pending'::character varying,
    reference_number character varying(100),
    description text,
    payment_method character varying(100),
    source_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transactions_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.transactions OWNER TO xhenvolt;

--
-- Name: TABLE transactions; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.transactions IS 'Financial transaction tracking for accounting';


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO xhenvolt;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: user_payment_plans; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_payment_plans (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    billing_cycle character varying(50) DEFAULT 'monthly'::character varying,
    status character varying(50) DEFAULT 'trial'::character varying,
    start_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    end_date timestamp without time zone,
    trial_end_date timestamp without time zone,
    auto_renew boolean DEFAULT true,
    payment_method character varying(50),
    transaction_id character varying(255),
    paid_at timestamp without time zone,
    last_payment_date timestamp without time zone,
    next_payment_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_payment_plans_billing_cycle_check CHECK (((billing_cycle)::text = ANY ((ARRAY['monthly'::character varying, 'yearly'::character varying, 'trial'::character varying])::text[]))),
    CONSTRAINT user_payment_plans_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'trial'::character varying, 'expired'::character varying, 'cancelled'::character varying, 'suspended'::character varying])::text[])))
);


ALTER TABLE public.user_payment_plans OWNER TO xhenvolt;

--
-- Name: TABLE user_payment_plans; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.user_payment_plans IS 'User subscription tracking and billing information';


--
-- Name: COLUMN user_payment_plans.user_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.user_id IS 'Foreign key to users table';


--
-- Name: COLUMN user_payment_plans.plan_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.plan_id IS 'Foreign key to payment_plans table';


--
-- Name: COLUMN user_payment_plans.billing_cycle; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.billing_cycle IS 'Billing cycle: monthly, yearly, or trial';


--
-- Name: COLUMN user_payment_plans.status; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.status IS 'Status: active, trial, expired, cancelled, or suspended';


--
-- Name: COLUMN user_payment_plans.trial_end_date; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.trial_end_date IS 'When trial period ends';


--
-- Name: COLUMN user_payment_plans.auto_renew; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_payment_plans.auto_renew IS 'Whether subscription auto-renews';


--
-- Name: user_payment_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.user_payment_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_payment_plans_id_seq OWNER TO xhenvolt;

--
-- Name: user_payment_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.user_payment_plans_id_seq OWNED BY public.user_payment_plans.id;


--
-- Name: user_people; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_people (
    user_id bigint NOT NULL,
    person_id bigint NOT NULL
);


ALTER TABLE public.user_people OWNER TO xhenvolt;

--
-- Name: TABLE user_people; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.user_people IS 'Junction table for users ↔ people normalization';


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    school_id bigint,
    full_name character varying(255) DEFAULT NULL::character varying,
    phone character varying(30) DEFAULT NULL::character varying,
    address text,
    city character varying(100) DEFAULT NULL::character varying,
    country character varying(100) DEFAULT 'Uganda'::character varying,
    timezone character varying(50) DEFAULT 'Africa/Kampala'::character varying,
    language character varying(10) DEFAULT 'en'::character varying,
    avatar_url character varying(500) DEFAULT NULL::character varying,
    bio text,
    preferences jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_profiles OWNER TO xhenvolt;

--
-- Name: TABLE user_profiles; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.user_profiles IS 'Extended user profile information (1:1 with users)';


--
-- Name: COLUMN user_profiles.user_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_profiles.user_id IS 'Unique reference to user (1:1 relationship)';


--
-- Name: COLUMN user_profiles.preferences; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_profiles.preferences IS 'JSON-based user preferences (flexible schema)';


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_profiles_id_seq OWNER TO xhenvolt;

--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    school_id bigint NOT NULL,
    role_name character varying(50) NOT NULL,
    assigned_by bigint,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_primary boolean DEFAULT false
);


ALTER TABLE public.user_roles OWNER TO xhenvolt;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_id_seq OWNER TO xhenvolt;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ip_address character varying(45) DEFAULT NULL::character varying,
    user_agent text,
    device_type character varying(50) DEFAULT NULL::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.user_sessions OWNER TO xhenvolt;

--
-- Name: TABLE user_sessions; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.user_sessions IS 'Session tracking by IP, device, and activity';


--
-- Name: COLUMN user_sessions.user_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_sessions.user_id IS 'Reference to user owning the session';


--
-- Name: COLUMN user_sessions.ip_address; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_sessions.ip_address IS 'IP address of the session (for security audit)';


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_sessions_id_seq OWNER TO xhenvolt;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: user_trials; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.user_trials (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    start_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_date timestamp without time zone NOT NULL,
    status character varying(50) DEFAULT 'active'::character varying,
    trial_type character varying(50) DEFAULT '30_day_trial'::character varying,
    features_enabled jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_trials_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'expired'::character varying, 'converted'::character varying])::text[])))
);


ALTER TABLE public.user_trials OWNER TO xhenvolt;

--
-- Name: TABLE user_trials; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON TABLE public.user_trials IS 'User trial periods and activation tracking';


--
-- Name: COLUMN user_trials.user_id; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.user_id IS 'Foreign key to users table';


--
-- Name: COLUMN user_trials.start_date; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.start_date IS 'Trial start date';


--
-- Name: COLUMN user_trials.end_date; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.end_date IS 'Trial end date (30 days from start)';


--
-- Name: COLUMN user_trials.status; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.status IS 'Trial status: active, expired, or converted to paid';


--
-- Name: COLUMN user_trials.trial_type; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.trial_type IS 'Type of trial (e.g., 30_day_trial)';


--
-- Name: COLUMN user_trials.features_enabled; Type: COMMENT; Schema: public; Owner: xhenvolt
--

COMMENT ON COLUMN public.user_trials.features_enabled IS 'JSON object of enabled features during trial';


--
-- Name: user_trials_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.user_trials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_trials_id_seq OWNER TO xhenvolt;

--
-- Name: user_trials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.user_trials_id_seq OWNED BY public.user_trials.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1,
    person_id bigint NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role public.user_role DEFAULT 'student'::public.user_role,
    status public.user_status DEFAULT 'active'::public.user_status,
    email character varying(100),
    email_verified boolean DEFAULT false,
    two_factor_enabled boolean DEFAULT false,
    last_login timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    onboarding_completed boolean DEFAULT false,
    onboarding_completed_at timestamp without time zone,
    phone character varying(20),
    school_onboarded boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO xhenvolt;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO xhenvolt;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: v_invoice_summary; Type: VIEW; Schema: public; Owner: xhenvolt
--

CREATE VIEW public.v_invoice_summary AS
 SELECT school_id,
    status,
    count(*) AS invoice_count,
    sum(total_amount) AS total_amount,
    sum(amount_paid) AS total_paid,
    sum((total_amount - amount_paid)) AS outstanding
   FROM public.fee_invoices
  GROUP BY school_id, status;


ALTER VIEW public.v_invoice_summary OWNER TO xhenvolt;

--
-- Name: v_outstanding_balances; Type: VIEW; Schema: public; Owner: xhenvolt
--

CREATE VIEW public.v_outstanding_balances AS
 SELECT fl.school_id,
    fl.student_id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS student_name,
    s.admission_no,
    s.email,
    fl.balance_outstanding,
    fl.total_fees,
    fl.total_paid,
        CASE
            WHEN (fl.balance_outstanding > (0)::numeric) THEN 'Outstanding'::text
            WHEN (fl.balance_outstanding = (0)::numeric) THEN 'Paid'::text
            ELSE 'Over-paid'::text
        END AS payment_status
   FROM (public.fees_ledger fl
     LEFT JOIN public.students s ON ((fl.student_id = s.id)))
  WHERE (fl.balance_outstanding IS NOT NULL)
  ORDER BY fl.balance_outstanding DESC;


ALTER VIEW public.v_outstanding_balances OWNER TO xhenvolt;

--
-- Name: v_pending_waivers; Type: VIEW; Schema: public; Owner: xhenvolt
--

CREATE VIEW public.v_pending_waivers AS
 SELECT fw.id,
    fw.school_id,
    fw.student_id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS student_name,
    s.admission_no,
    s.email,
    fw.amount_requested,
    fw.reason,
    fw.requested_at
   FROM (public.fee_waivers fw
     LEFT JOIN public.students s ON ((fw.student_id = s.id)))
  WHERE ((fw.status)::text = 'pending'::text)
  ORDER BY fw.requested_at;


ALTER VIEW public.v_pending_waivers OWNER TO xhenvolt;

--
-- Name: vault_balances; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.vault_balances (
    id integer NOT NULL,
    vault_type character varying(50) NOT NULL,
    balance numeric(15,2) DEFAULT 0,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT vault_balances_vault_type_check CHECK (((vault_type)::text = ANY ((ARRAY['savings'::character varying, 'emergency'::character varying, 'investment'::character varying, 'operating'::character varying])::text[])))
);


ALTER TABLE public.vault_balances OWNER TO xhenvolt;

--
-- Name: vault_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.vault_balances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vault_balances_id_seq OWNER TO xhenvolt;

--
-- Name: vault_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.vault_balances_id_seq OWNED BY public.vault_balances.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: xhenvolt
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    school_id bigint DEFAULT 1 NOT NULL,
    student_id bigint NOT NULL,
    balance numeric(14,2) DEFAULT 0 NOT NULL,
    currency character varying(10) DEFAULT 'USD'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wallets OWNER TO xhenvolt;

--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: xhenvolt
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_id_seq OWNER TO xhenvolt;

--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xhenvolt
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: academic_years id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.academic_years ALTER COLUMN id SET DEFAULT nextval('public.academic_years_id_seq'::regclass);


--
-- Name: assignment id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.assignment ALTER COLUMN id SET DEFAULT nextval('public.assignment_id_seq'::regclass);


--
-- Name: attendance id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance ALTER COLUMN id SET DEFAULT nextval('public.attendance_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: class_subjects id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.class_subjects ALTER COLUMN id SET DEFAULT nextval('public.class_subjects_id_seq'::regclass);


--
-- Name: classes id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.classes ALTER COLUMN id SET DEFAULT nextval('public.classes_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: curricula id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.curricula ALTER COLUMN id SET DEFAULT nextval('public.curricula_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: exams id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams ALTER COLUMN id SET DEFAULT nextval('public.exams_id_seq'::regclass);


--
-- Name: expense_categories id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.expense_categories ALTER COLUMN id SET DEFAULT nextval('public.expense_categories_id_seq'::regclass);


--
-- Name: fee_allocations id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations ALTER COLUMN id SET DEFAULT nextval('public.fee_allocations_id_seq'::regclass);


--
-- Name: fee_categories id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_categories ALTER COLUMN id SET DEFAULT nextval('public.fee_categories_id_seq'::regclass);


--
-- Name: fee_discounts id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_discounts ALTER COLUMN id SET DEFAULT nextval('public.fee_discounts_id_seq'::regclass);


--
-- Name: fee_invoices id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices ALTER COLUMN id SET DEFAULT nextval('public.fee_invoices_id_seq'::regclass);


--
-- Name: fee_notification_queue id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_notification_queue ALTER COLUMN id SET DEFAULT nextval('public.fee_notification_queue_id_seq'::regclass);


--
-- Name: fee_payments id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments ALTER COLUMN id SET DEFAULT nextval('public.fee_payments_id_seq'::regclass);


--
-- Name: fee_receipts id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts ALTER COLUMN id SET DEFAULT nextval('public.fee_receipts_id_seq'::regclass);


--
-- Name: fee_structures id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures ALTER COLUMN id SET DEFAULT nextval('public.fee_structures_id_seq'::regclass);


--
-- Name: fee_waivers id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers ALTER COLUMN id SET DEFAULT nextval('public.fee_waivers_id_seq'::regclass);


--
-- Name: fees_audit_logs id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_audit_logs ALTER COLUMN id SET DEFAULT nextval('public.fees_audit_logs_id_seq'::regclass);


--
-- Name: fees_ledger id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_ledger ALTER COLUMN id SET DEFAULT nextval('public.fees_ledger_id_seq'::regclass);


--
-- Name: file_upload id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.file_upload ALTER COLUMN id SET DEFAULT nextval('public.file_upload_id_seq'::regclass);


--
-- Name: fingerprints id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fingerprints ALTER COLUMN id SET DEFAULT nextval('public.fingerprints_id_seq'::regclass);


--
-- Name: lesson id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson ALTER COLUMN id SET DEFAULT nextval('public.lesson_id_seq'::regclass);


--
-- Name: message id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.message ALTER COLUMN id SET DEFAULT nextval('public.message_id_seq'::regclass);


--
-- Name: notices id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notices ALTER COLUMN id SET DEFAULT nextval('public.notices_id_seq'::regclass);


--
-- Name: notification id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notification ALTER COLUMN id SET DEFAULT nextval('public.notification_id_seq'::regclass);


--
-- Name: onboarding_steps id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.onboarding_steps ALTER COLUMN id SET DEFAULT nextval('public.onboarding_steps_id_seq'::regclass);


--
-- Name: payment_allocations id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_allocations ALTER COLUMN id SET DEFAULT nextval('public.payment_allocations_id_seq'::regclass);


--
-- Name: payment_methods id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_methods ALTER COLUMN id SET DEFAULT nextval('public.payment_methods_id_seq'::regclass);


--
-- Name: payment_plan id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plan ALTER COLUMN id SET DEFAULT nextval('public.payment_plan_id_seq'::regclass);


--
-- Name: payment_plans id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plans ALTER COLUMN id SET DEFAULT nextval('public.payment_plans_id_seq'::regclass);


--
-- Name: payment_reminder id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_reminder ALTER COLUMN id SET DEFAULT nextval('public.payment_reminder_id_seq'::regclass);


--
-- Name: people id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.people ALTER COLUMN id SET DEFAULT nextval('public.people_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: person id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.person ALTER COLUMN id SET DEFAULT nextval('public.person_id_seq'::regclass);


--
-- Name: quiz id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz ALTER COLUMN id SET DEFAULT nextval('public.quiz_id_seq'::regclass);


--
-- Name: quiz_attempt id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_attempt ALTER COLUMN id SET DEFAULT nextval('public.quiz_attempt_id_seq'::regclass);


--
-- Name: quiz_question id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_question ALTER COLUMN id SET DEFAULT nextval('public.quiz_question_id_seq'::regclass);


--
-- Name: results id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.results ALTER COLUMN id SET DEFAULT nextval('public.results_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: school_onboarding id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_onboarding ALTER COLUMN id SET DEFAULT nextval('public.school_onboarding_id_seq'::regclass);


--
-- Name: school_settings id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_settings ALTER COLUMN id SET DEFAULT nextval('public.school_settings_id_seq'::regclass);


--
-- Name: schools id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.schools ALTER COLUMN id SET DEFAULT nextval('public.schools_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: shares_config id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.shares_config ALTER COLUMN id SET DEFAULT nextval('public.shares_config_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff ALTER COLUMN id SET DEFAULT nextval('public.staff_id_seq'::regclass);


--
-- Name: staff_attendance id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance ALTER COLUMN id SET DEFAULT nextval('public.staff_attendance_id_seq'::regclass);


--
-- Name: streams id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.streams ALTER COLUMN id SET DEFAULT nextval('public.streams_id_seq'::regclass);


--
-- Name: student_attendance id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance ALTER COLUMN id SET DEFAULT nextval('public.student_attendance_id_seq'::regclass);


--
-- Name: student_contacts id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_contacts ALTER COLUMN id SET DEFAULT nextval('public.student_contacts_id_seq'::regclass);


--
-- Name: student_curriculums id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_curriculums ALTER COLUMN id SET DEFAULT nextval('public.student_curriculums_id_seq'::regclass);


--
-- Name: student_profiles id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_profiles ALTER COLUMN id SET DEFAULT nextval('public.student_profiles_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- Name: terms id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.terms ALTER COLUMN id SET DEFAULT nextval('public.terms_id_seq'::regclass);


--
-- Name: timetable id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable ALTER COLUMN id SET DEFAULT nextval('public.timetable_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: user_payment_plans id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_payment_plans ALTER COLUMN id SET DEFAULT nextval('public.user_payment_plans_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: user_trials id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_trials ALTER COLUMN id SET DEFAULT nextval('public.user_trials_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vault_balances id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.vault_balances ALTER COLUMN id SET DEFAULT nextval('public.vault_balances_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Name: academic_years academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (id);


--
-- Name: assignment assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: class_subjects class_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.class_subjects
    ADD CONSTRAINT class_subjects_pkey PRIMARY KEY (id);


--
-- Name: classes classes_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_code_key UNIQUE (code);


--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: curricula curricula_name_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.curricula
    ADD CONSTRAINT curricula_name_key UNIQUE (name);


--
-- Name: curricula curricula_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.curricula
    ADD CONSTRAINT curricula_pkey PRIMARY KEY (id);


--
-- Name: departments departments_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_code_key UNIQUE (code);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (id);


--
-- Name: expense_categories expense_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT expense_categories_name_key UNIQUE (name);


--
-- Name: expense_categories expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (id);


--
-- Name: fee_allocations fee_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_pkey PRIMARY KEY (id);


--
-- Name: fee_allocations fee_allocations_school_id_student_id_fee_structure_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_school_id_student_id_fee_structure_id_key UNIQUE (school_id, student_id, fee_structure_id);


--
-- Name: fee_categories fee_categories_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_categories
    ADD CONSTRAINT fee_categories_code_key UNIQUE (code);


--
-- Name: fee_categories fee_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_categories
    ADD CONSTRAINT fee_categories_pkey PRIMARY KEY (id);


--
-- Name: fee_categories fee_categories_school_id_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_categories
    ADD CONSTRAINT fee_categories_school_id_code_key UNIQUE (school_id, code);


--
-- Name: fee_discounts fee_discounts_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_discounts
    ADD CONSTRAINT fee_discounts_code_key UNIQUE (code);


--
-- Name: fee_discounts fee_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_discounts
    ADD CONSTRAINT fee_discounts_pkey PRIMARY KEY (id);


--
-- Name: fee_discounts fee_discounts_school_id_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_discounts
    ADD CONSTRAINT fee_discounts_school_id_code_key UNIQUE (school_id, code);


--
-- Name: fee_invoices fee_invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices
    ADD CONSTRAINT fee_invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: fee_invoices fee_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices
    ADD CONSTRAINT fee_invoices_pkey PRIMARY KEY (id);


--
-- Name: fee_notification_queue fee_notification_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_notification_queue
    ADD CONSTRAINT fee_notification_queue_pkey PRIMARY KEY (id);


--
-- Name: fee_payments fee_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_pkey PRIMARY KEY (id);


--
-- Name: fee_payments fee_payments_reference_number_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_reference_number_key UNIQUE (reference_number);


--
-- Name: fee_receipts fee_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_pkey PRIMARY KEY (id);


--
-- Name: fee_receipts fee_receipts_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_receipt_number_key UNIQUE (receipt_number);


--
-- Name: fee_structures fee_structures_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fee_structures_pkey PRIMARY KEY (id);


--
-- Name: fee_waivers fee_waivers_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_pkey PRIMARY KEY (id);


--
-- Name: fees_audit_logs fees_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_audit_logs
    ADD CONSTRAINT fees_audit_logs_pkey PRIMARY KEY (id);


--
-- Name: fees_ledger fees_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_ledger
    ADD CONSTRAINT fees_ledger_pkey PRIMARY KEY (id);


--
-- Name: fees_ledger fees_ledger_school_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_ledger
    ADD CONSTRAINT fees_ledger_school_id_student_id_key UNIQUE (school_id, student_id);


--
-- Name: file_upload file_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.file_upload
    ADD CONSTRAINT file_upload_pkey PRIMARY KEY (id);


--
-- Name: fingerprints fingerprints_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fingerprints
    ADD CONSTRAINT fingerprints_pkey PRIMARY KEY (id);


--
-- Name: lesson lesson_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_pkey PRIMARY KEY (id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);


--
-- Name: notices notices_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT notices_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: onboarding_steps onboarding_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.onboarding_steps
    ADD CONSTRAINT onboarding_steps_pkey PRIMARY KEY (id);


--
-- Name: payment_allocations payment_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_allocations
    ADD CONSTRAINT payment_allocations_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_code_key UNIQUE (code);


--
-- Name: payment_methods payment_methods_name_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_name_key UNIQUE (name);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: payment_plan payment_plan_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plan
    ADD CONSTRAINT payment_plan_code_key UNIQUE (code);


--
-- Name: payment_plan payment_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plan
    ADD CONSTRAINT payment_plan_pkey PRIMARY KEY (id);


--
-- Name: payment_plans payment_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plans
    ADD CONSTRAINT payment_plans_pkey PRIMARY KEY (id);


--
-- Name: payment_plans payment_plans_plan_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plans
    ADD CONSTRAINT payment_plans_plan_code_key UNIQUE (plan_code);


--
-- Name: payment_plans payment_plans_plan_name_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_plans
    ADD CONSTRAINT payment_plans_plan_name_key UNIQUE (plan_name);


--
-- Name: payment_reminder payment_reminder_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_reminder
    ADD CONSTRAINT payment_reminder_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_slug_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_slug_key UNIQUE (slug);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: quiz_attempt quiz_attempt_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_attempt
    ADD CONSTRAINT quiz_attempt_pkey PRIMARY KEY (id);


--
-- Name: quiz quiz_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz
    ADD CONSTRAINT quiz_pkey PRIMARY KEY (id);


--
-- Name: quiz_question quiz_question_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_question
    ADD CONSTRAINT quiz_question_pkey PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: school_onboarding school_onboarding_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_onboarding
    ADD CONSTRAINT school_onboarding_pkey PRIMARY KEY (id);


--
-- Name: school_onboarding school_onboarding_school_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_onboarding
    ADD CONSTRAINT school_onboarding_school_id_key UNIQUE (school_id);


--
-- Name: school_settings school_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_pkey PRIMARY KEY (id);


--
-- Name: school_settings school_settings_school_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_school_id_key UNIQUE (school_id);


--
-- Name: schools schools_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_code_key UNIQUE (code);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_session_token_key UNIQUE (session_token);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: share_issuances share_issuances_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_issuances
    ADD CONSTRAINT share_issuances_pkey PRIMARY KEY (id);


--
-- Name: share_price_history share_price_history_date_event_type_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_price_history
    ADD CONSTRAINT share_price_history_date_event_type_key UNIQUE (date, event_type);


--
-- Name: share_price_history share_price_history_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_price_history
    ADD CONSTRAINT share_price_history_pkey PRIMARY KEY (id);


--
-- Name: share_transfers share_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_transfers
    ADD CONSTRAINT share_transfers_pkey PRIMARY KEY (id);


--
-- Name: shareholdings shareholdings_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.shareholdings
    ADD CONSTRAINT shareholdings_pkey PRIMARY KEY (id);


--
-- Name: shareholdings shareholdings_shareholder_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.shareholdings
    ADD CONSTRAINT shareholdings_shareholder_id_key UNIQUE (shareholder_id);


--
-- Name: shares_config shares_config_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.shares_config
    ADD CONSTRAINT shares_config_pkey PRIMARY KEY (id);


--
-- Name: staff_attendance staff_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance
    ADD CONSTRAINT staff_attendance_pkey PRIMARY KEY (id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: staff staff_staff_no_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_staff_no_key UNIQUE (staff_no);


--
-- Name: streams streams_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.streams
    ADD CONSTRAINT streams_pkey PRIMARY KEY (id);


--
-- Name: student_attendance student_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance
    ADD CONSTRAINT student_attendance_pkey PRIMARY KEY (id);


--
-- Name: student_contacts student_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_contacts
    ADD CONSTRAINT student_contacts_pkey PRIMARY KEY (id);


--
-- Name: student_curriculums student_curriculums_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_curriculums
    ADD CONSTRAINT student_curriculums_pkey PRIMARY KEY (id);


--
-- Name: student_profiles student_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (id);


--
-- Name: students students_admission_no_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_admission_no_key UNIQUE (admission_no);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_code_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_code_key UNIQUE (code);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: terms terms_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);


--
-- Name: timetable timetable_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT timetable_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: attendance unique_attendance; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT unique_attendance UNIQUE (school_id, user_id, attendance_date);


--
-- Name: role_permissions unique_role_permission; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id);


--
-- Name: roles unique_role_slug; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT unique_role_slug UNIQUE (slug, school_id);


--
-- Name: school_settings unique_school_setting_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT unique_school_setting_key UNIQUE (school_id, setting_key);


--
-- Name: settings unique_setting; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT unique_setting UNIQUE (setting_key, school_id);


--
-- Name: staff_attendance unique_staff_date; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance
    ADD CONSTRAINT unique_staff_date UNIQUE (staff_id, date);


--
-- Name: student_attendance unique_student_date; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance
    ADD CONSTRAINT unique_student_date UNIQUE (student_id, date);


--
-- Name: onboarding_steps unique_user_step; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.onboarding_steps
    ADD CONSTRAINT unique_user_step UNIQUE (user_id, step_name);


--
-- Name: user_payment_plans user_payment_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_payment_plans
    ADD CONSTRAINT user_payment_plans_pkey PRIMARY KEY (id);


--
-- Name: user_people user_people_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_people
    ADD CONSTRAINT user_people_pkey PRIMARY KEY (user_id, person_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_key UNIQUE (user_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_school_id_role_name_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_school_id_role_name_key UNIQUE (user_id, school_id, role_name);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_trials user_trials_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_trials
    ADD CONSTRAINT user_trials_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vault_balances vault_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.vault_balances
    ADD CONSTRAINT vault_balances_pkey PRIMARY KEY (id);


--
-- Name: vault_balances vault_balances_vault_type_key; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.vault_balances
    ADD CONSTRAINT vault_balances_vault_type_key UNIQUE (vault_type);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: idx_academic_years_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_academic_years_school ON public.academic_years USING btree (school_id);


--
-- Name: idx_allocations_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_allocations_active ON public.fee_allocations USING btree (is_active);


--
-- Name: idx_allocations_balance; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_allocations_balance ON public.fee_allocations USING btree (balance);


--
-- Name: idx_allocations_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_allocations_school ON public.fee_allocations USING btree (school_id);


--
-- Name: idx_allocations_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_allocations_student ON public.fee_allocations USING btree (student_id);


--
-- Name: idx_assignment_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_assignment_class ON public.assignment USING btree (class_id);


--
-- Name: idx_assignment_due_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_assignment_due_date ON public.assignment USING btree (due_date);


--
-- Name: idx_assignment_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_assignment_school ON public.assignment USING btree (school_id);


--
-- Name: idx_assignment_teacher; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_assignment_teacher ON public.assignment USING btree (teacher_id);


--
-- Name: idx_attendance_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_attendance_date ON public.attendance USING btree (attendance_date);


--
-- Name: idx_attendance_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_attendance_school ON public.attendance USING btree (school_id);


--
-- Name: idx_attendance_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_attendance_status ON public.attendance USING btree (status);


--
-- Name: idx_attendance_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_attendance_user ON public.attendance USING btree (user_id);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_created; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_log_created ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_log_school ON public.audit_log USING btree (school_id);


--
-- Name: idx_audit_log_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_log_user ON public.audit_log USING btree (user_id);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_logs_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_logs_school ON public.audit_logs USING btree (school_id);


--
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_audit_logs_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_class_subjects_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_class_subjects_class ON public.class_subjects USING btree (class_id);


--
-- Name: idx_class_subjects_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_class_subjects_school ON public.class_subjects USING btree (school_id);


--
-- Name: idx_class_subjects_subject; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_class_subjects_subject ON public.class_subjects USING btree (subject_id);


--
-- Name: idx_classes_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_classes_code ON public.classes USING btree (code);


--
-- Name: idx_classes_curriculum; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_classes_curriculum ON public.classes USING btree (curriculum);


--
-- Name: idx_classes_grade; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_classes_grade ON public.classes USING btree (grade);


--
-- Name: idx_classes_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_classes_school ON public.classes USING btree (school_id);


--
-- Name: idx_classes_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_classes_school_id ON public.classes USING btree (school_id);


--
-- Name: idx_contacts_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_contacts_active ON public.contacts USING btree (is_active);


--
-- Name: idx_contacts_email; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_contacts_email ON public.contacts USING btree (email);


--
-- Name: idx_contacts_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_contacts_school ON public.contacts USING btree (school_id);


--
-- Name: idx_departments_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_departments_code ON public.departments USING btree (code);


--
-- Name: idx_departments_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_departments_school ON public.departments USING btree (school_id);


--
-- Name: idx_documents_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_documents_school ON public.documents USING btree (school_id);


--
-- Name: idx_documents_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_documents_status ON public.documents USING btree (status);


--
-- Name: idx_documents_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_documents_type ON public.documents USING btree (document_type);


--
-- Name: idx_documents_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_documents_user ON public.documents USING btree (user_id);


--
-- Name: idx_enrollments_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_enrollments_class ON public.enrollments USING btree (class_id);


--
-- Name: idx_enrollments_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_enrollments_school ON public.enrollments USING btree (school_id);


--
-- Name: idx_enrollments_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_enrollments_status ON public.enrollments USING btree (status);


--
-- Name: idx_enrollments_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_enrollments_student ON public.enrollments USING btree (student_id);


--
-- Name: idx_exams_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_exams_class ON public.exams USING btree (class_id);


--
-- Name: idx_exams_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_exams_school ON public.exams USING btree (school_id);


--
-- Name: idx_exams_subject; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_exams_subject ON public.exams USING btree (subject_id);


--
-- Name: idx_exams_term; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_exams_term ON public.exams USING btree (term_id);


--
-- Name: idx_fee_allocations_academic_year_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_allocations_academic_year_id ON public.fee_allocations USING btree (academic_year_id);


--
-- Name: idx_fee_allocations_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_allocations_school_id ON public.fee_allocations USING btree (school_id);


--
-- Name: idx_fee_allocations_student_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_allocations_student_id ON public.fee_allocations USING btree (student_id);


--
-- Name: idx_fee_allocations_student_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_allocations_student_school ON public.fee_allocations USING btree (student_id, school_id);


--
-- Name: idx_fee_allocations_term_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_allocations_term_id ON public.fee_allocations USING btree (term_id);


--
-- Name: idx_fee_categories_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_categories_active ON public.fee_categories USING btree (deleted_at);


--
-- Name: idx_fee_categories_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_categories_code ON public.fee_categories USING btree (code);


--
-- Name: idx_fee_categories_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_categories_school ON public.fee_categories USING btree (school_id);


--
-- Name: idx_fee_categories_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_categories_school_id ON public.fee_categories USING btree (school_id);


--
-- Name: idx_fee_discounts_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_discounts_active ON public.fee_discounts USING btree (is_active);


--
-- Name: idx_fee_discounts_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_discounts_code ON public.fee_discounts USING btree (code);


--
-- Name: idx_fee_discounts_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_discounts_school ON public.fee_discounts USING btree (school_id);


--
-- Name: idx_fee_discounts_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_discounts_school_id ON public.fee_discounts USING btree (school_id);


--
-- Name: idx_fee_discounts_valid_dates; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_discounts_valid_dates ON public.fee_discounts USING btree (valid_from, valid_until);


--
-- Name: idx_fee_invoices_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_date ON public.fee_invoices USING btree (invoice_date);


--
-- Name: idx_fee_invoices_due_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_due_date ON public.fee_invoices USING btree (due_date);


--
-- Name: idx_fee_invoices_number; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_number ON public.fee_invoices USING btree (invoice_number);


--
-- Name: idx_fee_invoices_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_school ON public.fee_invoices USING btree (school_id);


--
-- Name: idx_fee_invoices_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_school_id ON public.fee_invoices USING btree (school_id);


--
-- Name: idx_fee_invoices_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_status ON public.fee_invoices USING btree (status);


--
-- Name: idx_fee_invoices_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_invoices_student ON public.fee_invoices USING btree (student_id);


--
-- Name: idx_fee_notifications_recipient; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_notifications_recipient ON public.fee_notification_queue USING btree (recipient_id);


--
-- Name: idx_fee_notifications_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_notifications_school ON public.fee_notification_queue USING btree (school_id);


--
-- Name: idx_fee_notifications_sent; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_notifications_sent ON public.fee_notification_queue USING btree (is_sent);


--
-- Name: idx_fee_notifications_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_notifications_type ON public.fee_notification_queue USING btree (notification_type);


--
-- Name: idx_fee_payments_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_date ON public.fee_payments USING btree (payment_date);


--
-- Name: idx_fee_payments_method; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_method ON public.fee_payments USING btree (payment_method);


--
-- Name: idx_fee_payments_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_school ON public.fee_payments USING btree (school_id);


--
-- Name: idx_fee_payments_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_school_id ON public.fee_payments USING btree (school_id);


--
-- Name: idx_fee_payments_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_student ON public.fee_payments USING btree (student_id);


--
-- Name: idx_fee_payments_student_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_student_id ON public.fee_payments USING btree (student_id);


--
-- Name: idx_fee_payments_verified; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_payments_verified ON public.fee_payments USING btree (is_verified);


--
-- Name: idx_fee_receipts_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_date ON public.fee_receipts USING btree (receipt_date);


--
-- Name: idx_fee_receipts_number; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_number ON public.fee_receipts USING btree (receipt_number);


--
-- Name: idx_fee_receipts_payment; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_payment ON public.fee_receipts USING btree (payment_id);


--
-- Name: idx_fee_receipts_payment_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_payment_id ON public.fee_receipts USING btree (payment_id);


--
-- Name: idx_fee_receipts_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_school ON public.fee_receipts USING btree (school_id);


--
-- Name: idx_fee_receipts_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_school_id ON public.fee_receipts USING btree (school_id);


--
-- Name: idx_fee_receipts_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_receipts_student ON public.fee_receipts USING btree (student_id);


--
-- Name: idx_fee_structures_academic_year_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_academic_year_id ON public.fee_structures USING btree (academic_year_id);


--
-- Name: idx_fee_structures_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_active ON public.fee_structures USING btree (is_active);


--
-- Name: idx_fee_structures_category; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_category ON public.fee_structures USING btree (fee_category_id);


--
-- Name: idx_fee_structures_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_class ON public.fee_structures USING btree (class_id);


--
-- Name: idx_fee_structures_class_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_class_id ON public.fee_structures USING btree (class_id);


--
-- Name: idx_fee_structures_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_school ON public.fee_structures USING btree (school_id);


--
-- Name: idx_fee_structures_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_school_id ON public.fee_structures USING btree (school_id);


--
-- Name: idx_fee_structures_section; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_section ON public.fee_structures USING btree (section_id);


--
-- Name: idx_fee_structures_term; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_term ON public.fee_structures USING btree (term_id);


--
-- Name: idx_fee_structures_year; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_structures_year ON public.fee_structures USING btree (academic_year_id);


--
-- Name: idx_fee_waivers_requested_at; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_requested_at ON public.fee_waivers USING btree (requested_at);


--
-- Name: idx_fee_waivers_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_school ON public.fee_waivers USING btree (school_id);


--
-- Name: idx_fee_waivers_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_school_id ON public.fee_waivers USING btree (school_id);


--
-- Name: idx_fee_waivers_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_status ON public.fee_waivers USING btree (status);


--
-- Name: idx_fee_waivers_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_student ON public.fee_waivers USING btree (student_id);


--
-- Name: idx_fee_waivers_student_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fee_waivers_student_id ON public.fee_waivers USING btree (student_id);


--
-- Name: idx_fees_audit_action; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_audit_action ON public.fees_audit_logs USING btree (action);


--
-- Name: idx_fees_audit_entity; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_audit_entity ON public.fees_audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_fees_audit_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_audit_school ON public.fees_audit_logs USING btree (school_id);


--
-- Name: idx_fees_audit_timestamp; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_audit_timestamp ON public.fees_audit_logs USING btree (changed_at);


--
-- Name: idx_fees_ledger_academic_year_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_academic_year_id ON public.fees_ledger USING btree (academic_year_id);


--
-- Name: idx_fees_ledger_balance; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_balance ON public.fees_ledger USING btree (balance_outstanding);


--
-- Name: idx_fees_ledger_class_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_class_id ON public.fees_ledger USING btree (class_id);


--
-- Name: idx_fees_ledger_outstanding; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_outstanding ON public.fees_ledger USING btree (balance_outstanding);


--
-- Name: idx_fees_ledger_payment_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_payment_status ON public.fees_ledger USING btree (payment_status);


--
-- Name: idx_fees_ledger_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_school ON public.fees_ledger USING btree (school_id);


--
-- Name: idx_fees_ledger_school_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_school_id ON public.fees_ledger USING btree (school_id);


--
-- Name: idx_fees_ledger_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_student ON public.fees_ledger USING btree (student_id);


--
-- Name: idx_fees_ledger_student_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_student_id ON public.fees_ledger USING btree (student_id);


--
-- Name: idx_fees_ledger_student_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_student_school ON public.fees_ledger USING btree (student_id, school_id);


--
-- Name: idx_fees_ledger_term_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_term_id ON public.fees_ledger USING btree (term_id);


--
-- Name: idx_fees_ledger_updated_at; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fees_ledger_updated_at ON public.fees_ledger USING btree (updated_at);


--
-- Name: idx_file_upload_created; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_file_upload_created ON public.file_upload USING btree (created_at DESC);


--
-- Name: idx_file_upload_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_file_upload_school ON public.file_upload USING btree (school_id);


--
-- Name: idx_file_upload_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_file_upload_user ON public.file_upload USING btree (user_id);


--
-- Name: idx_fingerprints_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fingerprints_school ON public.fingerprints USING btree (school_id);


--
-- Name: idx_fingerprints_staff; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fingerprints_staff ON public.fingerprints USING btree (staff_id);


--
-- Name: idx_fingerprints_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_fingerprints_student ON public.fingerprints USING btree (student_id);


--
-- Name: idx_lesson_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_lesson_date ON public.lesson USING btree (lesson_date);


--
-- Name: idx_lesson_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_lesson_school ON public.lesson USING btree (school_id);


--
-- Name: idx_lesson_teacher; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_lesson_teacher ON public.lesson USING btree (teacher_id);


--
-- Name: idx_message_created; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_message_created ON public.message USING btree (created_at DESC);


--
-- Name: idx_message_read; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_message_read ON public.message USING btree (read_at);


--
-- Name: idx_message_recipient; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_message_recipient ON public.message USING btree (recipient_id);


--
-- Name: idx_message_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_message_school ON public.message USING btree (school_id);


--
-- Name: idx_message_sender; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_message_sender ON public.message USING btree (sender_id);


--
-- Name: idx_notices_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notices_active ON public.notices USING btree (is_active);


--
-- Name: idx_notices_audience; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notices_audience ON public.notices USING btree (target_audience);


--
-- Name: idx_notices_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notices_school ON public.notices USING btree (school_id);


--
-- Name: idx_notices_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notices_type ON public.notices USING btree (notice_type);


--
-- Name: idx_notification_created; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notification_created ON public.notification USING btree (created_at DESC);


--
-- Name: idx_notification_read; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notification_read ON public.notification USING btree (read_at);


--
-- Name: idx_notification_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notification_school ON public.notification USING btree (school_id);


--
-- Name: idx_notification_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_notification_user ON public.notification USING btree (user_id);


--
-- Name: idx_onboarding_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_onboarding_status ON public.onboarding_steps USING btree (status);


--
-- Name: idx_onboarding_step_order; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_onboarding_step_order ON public.onboarding_steps USING btree (user_id, step_order);


--
-- Name: idx_onboarding_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_onboarding_user ON public.onboarding_steps USING btree (user_id);


--
-- Name: idx_onboarding_user_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_onboarding_user_status ON public.onboarding_steps USING btree (user_id, status);


--
-- Name: idx_payment_allocations_allocation; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_allocations_allocation ON public.payment_allocations USING btree (fee_allocation_id);


--
-- Name: idx_payment_allocations_payment; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_allocations_payment ON public.payment_allocations USING btree (fee_payment_id);


--
-- Name: idx_payment_allocations_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_allocations_school ON public.payment_allocations USING btree (school_id);


--
-- Name: idx_payment_methods_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_methods_active ON public.payment_methods USING btree (is_active);


--
-- Name: idx_payment_plan_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_plan_active ON public.payment_plan USING btree (is_active);


--
-- Name: idx_payment_plans_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_plans_active ON public.payment_plans USING btree (is_active);


--
-- Name: idx_payment_plans_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_plans_code ON public.payment_plans USING btree (plan_code);


--
-- Name: idx_payment_plans_trial; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_plans_trial ON public.payment_plans USING btree (is_trial);


--
-- Name: idx_payment_reminder_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_reminder_status ON public.payment_reminder USING btree (status, reminder_date);


--
-- Name: idx_payment_reminder_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_payment_reminder_user ON public.payment_reminder USING btree (user_id);


--
-- Name: idx_people_email; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_people_email ON public.people USING btree (email);


--
-- Name: idx_people_name; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_people_name ON public.people USING btree (first_name, last_name);


--
-- Name: idx_permissions_slug; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_permissions_slug ON public.permissions USING btree (slug);


--
-- Name: idx_person_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_person_active ON public.person USING btree (is_active);


--
-- Name: idx_person_email; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_person_email ON public.person USING btree (email);


--
-- Name: idx_person_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_person_school ON public.person USING btree (school_id);


--
-- Name: idx_quiz_attempt_quiz; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_attempt_quiz ON public.quiz_attempt USING btree (quiz_id);


--
-- Name: idx_quiz_attempt_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_attempt_status ON public.quiz_attempt USING btree (status);


--
-- Name: idx_quiz_attempt_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_attempt_student ON public.quiz_attempt USING btree (student_id);


--
-- Name: idx_quiz_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_date ON public.quiz USING btree (quiz_date);


--
-- Name: idx_quiz_question_quiz; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_question_quiz ON public.quiz_question USING btree (quiz_id);


--
-- Name: idx_quiz_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_school ON public.quiz USING btree (school_id);


--
-- Name: idx_quiz_teacher; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_quiz_teacher ON public.quiz USING btree (teacher_id);


--
-- Name: idx_results_exam; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_results_exam ON public.results USING btree (exam_id);


--
-- Name: idx_results_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_results_school ON public.results USING btree (school_id);


--
-- Name: idx_results_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_results_student ON public.results USING btree (student_id);


--
-- Name: idx_role_permissions_permission; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_role_permissions_permission ON public.role_permissions USING btree (permission_id);


--
-- Name: idx_role_permissions_role; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_role_permissions_role ON public.role_permissions USING btree (role_id);


--
-- Name: idx_roles_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_roles_school ON public.roles USING btree (school_id);


--
-- Name: idx_roles_slug; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_roles_slug ON public.roles USING btree (slug);


--
-- Name: idx_school_onboarding_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_school_onboarding_status ON public.school_onboarding USING btree (is_complete);


--
-- Name: idx_school_settings_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_school_settings_school ON public.school_settings USING btree (school_id);


--
-- Name: idx_schools_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_schools_code ON public.schools USING btree (code);


--
-- Name: idx_schools_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_schools_status ON public.schools USING btree (status);


--
-- Name: idx_sections_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_sections_class ON public.sections USING btree (class_id);


--
-- Name: idx_sections_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_sections_school ON public.sections USING btree (school_id);


--
-- Name: idx_sessions_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_sessions_active ON public.sessions USING btree (user_id) WHERE (is_active = true);


--
-- Name: idx_sessions_expiry; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_sessions_expiry ON public.sessions USING btree (expires_at);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_settings_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_settings_school ON public.settings USING btree (school_id);


--
-- Name: idx_share_issuances_approval_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_issuances_approval_status ON public.share_issuances USING btree (approval_status);


--
-- Name: idx_share_issuances_approved_by; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_issuances_approved_by ON public.share_issuances USING btree (approved_by_id);


--
-- Name: idx_share_issuances_created_by; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_issuances_created_by ON public.share_issuances USING btree (created_by_id);


--
-- Name: idx_share_issuances_recipient; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_issuances_recipient ON public.share_issuances USING btree (recipient_id);


--
-- Name: idx_share_price_history_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_price_history_date ON public.share_price_history USING btree (date);


--
-- Name: idx_share_price_history_event; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_share_price_history_event ON public.share_price_history USING btree (event_type, event_id);


--
-- Name: idx_shareholdings_equity_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_shareholdings_equity_type ON public.shareholdings USING btree (equity_type);


--
-- Name: idx_shareholdings_shareholder_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_shareholdings_shareholder_id ON public.shareholdings USING btree (shareholder_id);


--
-- Name: idx_shareholdings_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_shareholdings_status ON public.shareholdings USING btree (status);


--
-- Name: idx_shares_config_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_shares_config_status ON public.shares_config USING btree (status);


--
-- Name: idx_staff_attendance_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_attendance_date ON public.staff_attendance USING btree (date);


--
-- Name: idx_staff_attendance_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_attendance_school ON public.staff_attendance USING btree (school_id);


--
-- Name: idx_staff_attendance_staff; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_attendance_staff ON public.staff_attendance USING btree (staff_id);


--
-- Name: idx_staff_attendance_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_attendance_status ON public.staff_attendance USING btree (status);


--
-- Name: idx_staff_department; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_department ON public.staff USING btree (department_id);


--
-- Name: idx_staff_department_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_department_status ON public.staff USING btree (department_id, status);


--
-- Name: idx_staff_person; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_person ON public.staff USING btree (person_id);


--
-- Name: idx_staff_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_school ON public.staff USING btree (school_id);


--
-- Name: idx_staff_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_staff_status ON public.staff USING btree (status);


--
-- Name: idx_streams_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_streams_school ON public.streams USING btree (school_id);


--
-- Name: idx_student_attendance_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_attendance_date ON public.student_attendance USING btree (date);


--
-- Name: idx_student_attendance_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_attendance_school ON public.student_attendance USING btree (school_id);


--
-- Name: idx_student_attendance_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_attendance_status ON public.student_attendance USING btree (status);


--
-- Name: idx_student_attendance_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_attendance_student ON public.student_attendance USING btree (student_id);


--
-- Name: idx_student_contacts_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_contacts_student ON public.student_contacts USING btree (student_id);


--
-- Name: idx_student_contacts_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_contacts_type ON public.student_contacts USING btree (contact_type);


--
-- Name: idx_student_curriculums_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_curriculums_school ON public.student_curriculums USING btree (school_id);


--
-- Name: idx_student_curriculums_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_curriculums_status ON public.student_curriculums USING btree (status);


--
-- Name: idx_student_curriculums_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_curriculums_student ON public.student_curriculums USING btree (student_id);


--
-- Name: idx_student_profiles_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_profiles_school ON public.student_profiles USING btree (school_id);


--
-- Name: idx_student_profiles_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_student_profiles_student ON public.student_profiles USING btree (student_id);


--
-- Name: idx_students_admission_no; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_admission_no ON public.students USING btree (admission_no);


--
-- Name: idx_students_class; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_class ON public.students USING btree (class_id);


--
-- Name: idx_students_class_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_class_id ON public.students USING btree (class_id);


--
-- Name: idx_students_name; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_name ON public.students USING btree (first_name, last_name);


--
-- Name: idx_students_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_school ON public.students USING btree (school_id);


--
-- Name: idx_students_school_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_students_school_status ON public.students USING btree (school_id, status);


--
-- Name: idx_subjects_code; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_subjects_code ON public.subjects USING btree (code);


--
-- Name: idx_subjects_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_subjects_school ON public.subjects USING btree (school_id);


--
-- Name: idx_terms_academic_year; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_terms_academic_year ON public.terms USING btree (academic_year_id);


--
-- Name: idx_terms_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_terms_school ON public.terms USING btree (school_id);


--
-- Name: idx_timetable_class_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_class_date ON public.timetable USING btree (school_id, class_id, lesson_date);


--
-- Name: idx_timetable_day_time; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_day_time ON public.timetable USING btree (day_of_week, start_time);


--
-- Name: idx_timetable_recurring; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_recurring ON public.timetable USING btree (is_recurring, parent_timetable_id);


--
-- Name: idx_timetable_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_school ON public.timetable USING btree (school_id);


--
-- Name: idx_timetable_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_status ON public.timetable USING btree (status);


--
-- Name: idx_timetable_subject_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_subject_date ON public.timetable USING btree (subject_id, lesson_date);


--
-- Name: idx_timetable_teacher_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_teacher_date ON public.timetable USING btree (teacher_id, lesson_date);


--
-- Name: idx_timetable_updated; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_timetable_updated ON public.timetable USING btree (updated_at);


--
-- Name: idx_transactions_created; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_transactions_created ON public.transactions USING btree (created_at DESC);


--
-- Name: idx_transactions_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_transactions_school ON public.transactions USING btree (school_id);


--
-- Name: idx_transactions_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_transactions_status ON public.transactions USING btree (status);


--
-- Name: idx_transactions_type; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_transactions_type ON public.transactions USING btree (transaction_type);


--
-- Name: idx_transactions_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_transactions_user ON public.transactions USING btree (user_id);


--
-- Name: idx_user_payment_plans_active; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_active ON public.user_payment_plans USING btree (user_id, status);


--
-- Name: idx_user_payment_plans_dates; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_dates ON public.user_payment_plans USING btree (start_date, end_date);


--
-- Name: idx_user_payment_plans_plan_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_plan_id ON public.user_payment_plans USING btree (plan_id);


--
-- Name: idx_user_payment_plans_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_status ON public.user_payment_plans USING btree (user_id, status);


--
-- Name: idx_user_payment_plans_trial_end; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_trial_end ON public.user_payment_plans USING btree (trial_end_date);


--
-- Name: idx_user_payment_plans_user_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_payment_plans_user_id ON public.user_payment_plans USING btree (user_id);


--
-- Name: idx_user_people_person; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_people_person ON public.user_people USING btree (person_id);


--
-- Name: idx_user_profiles_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_profiles_school ON public.user_profiles USING btree (school_id);


--
-- Name: idx_user_profiles_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_profiles_user ON public.user_profiles USING btree (user_id);


--
-- Name: idx_user_roles_primary; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_roles_primary ON public.user_roles USING btree (user_id) WHERE (is_primary = true);


--
-- Name: idx_user_roles_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_roles_school ON public.user_roles USING btree (school_id, role_name);


--
-- Name: idx_user_sessions_activity; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_sessions_activity ON public.user_sessions USING btree (last_activity);


--
-- Name: idx_user_sessions_ip; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_sessions_ip ON public.user_sessions USING btree (ip_address);


--
-- Name: idx_user_sessions_user; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: idx_user_trials_end_date; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_trials_end_date ON public.user_trials USING btree (status, end_date);


--
-- Name: idx_user_trials_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_trials_status ON public.user_trials USING btree (user_id, status);


--
-- Name: idx_user_trials_user_id; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_trials_user_id ON public.user_trials USING btree (user_id);


--
-- Name: idx_user_trials_user_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_user_trials_user_status ON public.user_trials USING btree (user_id, status);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_last_activity; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_users_last_activity ON public.users USING btree (last_login);


--
-- Name: idx_users_onboarding_completed; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_users_onboarding_completed ON public.users USING btree (onboarding_completed, school_id);


--
-- Name: idx_users_school_status; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_users_school_status ON public.users USING btree (school_id, status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: idx_wallets_school; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_wallets_school ON public.wallets USING btree (school_id);


--
-- Name: idx_wallets_student; Type: INDEX; Schema: public; Owner: xhenvolt
--

CREATE INDEX idx_wallets_student ON public.wallets USING btree (student_id);


--
-- Name: shares_config shares_config_update_timestamp; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER shares_config_update_timestamp BEFORE UPDATE ON public.shares_config FOR EACH ROW EXECUTE FUNCTION public.update_shares_config_timestamp();


--
-- Name: fee_payments trg_update_ledger_on_payment; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trg_update_ledger_on_payment AFTER INSERT ON public.fee_payments FOR EACH ROW EXECUTE FUNCTION public.update_ledger_on_payment();


--
-- Name: fee_waivers trg_update_ledger_on_waiver; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trg_update_ledger_on_waiver AFTER UPDATE ON public.fee_waivers FOR EACH ROW EXECUTE FUNCTION public.update_ledger_on_waiver_approval();


--
-- Name: exams trigger_exams_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_exams_updated_at BEFORE UPDATE ON public.exams FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: people trigger_people_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_people_updated_at BEFORE UPDATE ON public.people FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: results trigger_results_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_results_updated_at BEFORE UPDATE ON public.results FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: schools trigger_schools_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_schools_updated_at BEFORE UPDATE ON public.schools FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: staff trigger_staff_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: students trigger_students_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_students_updated_at BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: timetable trigger_timetable_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_timetable_updated_at BEFORE UPDATE ON public.timetable FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users trigger_users_updated_at; Type: TRIGGER; Schema: public; Owner: xhenvolt
--

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: assignment assignment_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: assignment assignment_subject_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_subject_fk FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE SET NULL;


--
-- Name: assignment assignment_teacher_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_teacher_fk FOREIGN KEY (teacher_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_recorded_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_recorded_by_fk FOREIGN KEY (recorded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: attendance attendance_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: documents documents_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: documents documents_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_allocations fee_allocations_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: fee_allocations fee_allocations_fee_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_fee_structure_id_fkey FOREIGN KEY (fee_structure_id) REFERENCES public.fee_structures(id) ON DELETE CASCADE;


--
-- Name: fee_allocations fee_allocations_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_allocations fee_allocations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_allocations
    ADD CONSTRAINT fee_allocations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: fee_categories fee_categories_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_categories
    ADD CONSTRAINT fee_categories_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_discounts fee_discounts_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_discounts
    ADD CONSTRAINT fee_discounts_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_invoices fee_invoices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices
    ADD CONSTRAINT fee_invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_invoices fee_invoices_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices
    ADD CONSTRAINT fee_invoices_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_invoices fee_invoices_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_invoices
    ADD CONSTRAINT fee_invoices_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: fee_notification_queue fee_notification_queue_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_notification_queue
    ADD CONSTRAINT fee_notification_queue_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: fee_notification_queue fee_notification_queue_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_notification_queue
    ADD CONSTRAINT fee_notification_queue_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_payments fee_payments_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_payments fee_payments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: fee_payments fee_payments_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_receipts fee_receipts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_receipts fee_receipts_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.fee_payments(id) ON DELETE CASCADE;


--
-- Name: fee_receipts fee_receipts_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_receipts fee_receipts_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_receipts
    ADD CONSTRAINT fee_receipts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: fee_structures fee_structures_fee_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fee_structures_fee_category_id_fkey FOREIGN KEY (fee_category_id) REFERENCES public.fee_categories(id) ON DELETE SET NULL;


--
-- Name: fee_structures fee_structures_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fee_structures_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: fee_waivers fee_waivers_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_waivers fee_waivers_fee_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_fee_allocation_id_fkey FOREIGN KEY (fee_allocation_id) REFERENCES public.fee_allocations(id) ON DELETE CASCADE;


--
-- Name: fee_waivers fee_waivers_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: fee_waivers fee_waivers_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_waivers fee_waivers_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_waivers
    ADD CONSTRAINT fee_waivers_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: fees_audit_logs fees_audit_logs_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_audit_logs
    ADD CONSTRAINT fees_audit_logs_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fees_audit_logs fees_audit_logs_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_audit_logs
    ADD CONSTRAINT fees_audit_logs_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fees_ledger fees_ledger_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_ledger
    ADD CONSTRAINT fees_ledger_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fees_ledger fees_ledger_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fees_ledger
    ADD CONSTRAINT fees_ledger_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: file_upload file_upload_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.file_upload
    ADD CONSTRAINT file_upload_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: file_upload file_upload_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.file_upload
    ADD CONSTRAINT file_upload_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: academic_years fk_academic_years_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT fk_academic_years_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: audit_log fk_audit_log_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT fk_audit_log_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: audit_log fk_audit_log_user; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT fk_audit_log_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: class_subjects fk_class_subjects_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.class_subjects
    ADD CONSTRAINT fk_class_subjects_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: class_subjects fk_class_subjects_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.class_subjects
    ADD CONSTRAINT fk_class_subjects_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: class_subjects fk_class_subjects_subject; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.class_subjects
    ADD CONSTRAINT fk_class_subjects_subject FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: classes fk_classes_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT fk_classes_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: departments fk_departments_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT fk_departments_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: enrollments fk_enrollments_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_enrollments_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: enrollments fk_enrollments_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_enrollments_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: enrollments fk_enrollments_section; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_enrollments_section FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE SET NULL;


--
-- Name: enrollments fk_enrollments_student; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: enrollments fk_enrollments_term; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_enrollments_term FOREIGN KEY (term_id) REFERENCES public.terms(id) ON DELETE SET NULL;


--
-- Name: exams fk_exams_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT fk_exams_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: exams fk_exams_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT fk_exams_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: exams fk_exams_subject; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT fk_exams_subject FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: exams fk_exams_term; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT fk_exams_term FOREIGN KEY (term_id) REFERENCES public.terms(id) ON DELETE CASCADE;


--
-- Name: fee_structures fk_fee_structures_academic_year; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fk_fee_structures_academic_year FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE SET NULL;


--
-- Name: fee_structures fk_fee_structures_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fk_fee_structures_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE SET NULL;


--
-- Name: fee_structures fk_fee_structures_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fk_fee_structures_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fee_structures fk_fee_structures_term; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fee_structures
    ADD CONSTRAINT fk_fee_structures_term FOREIGN KEY (term_id) REFERENCES public.terms(id) ON DELETE SET NULL;


--
-- Name: fingerprints fk_fingerprints_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fingerprints
    ADD CONSTRAINT fk_fingerprints_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: fingerprints fk_fingerprints_staff; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fingerprints
    ADD CONSTRAINT fk_fingerprints_staff FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: fingerprints fk_fingerprints_student; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.fingerprints
    ADD CONSTRAINT fk_fingerprints_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: notices fk_notices_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_notices_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: results fk_results_exam; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_results_exam FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE CASCADE;


--
-- Name: results fk_results_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_results_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: results fk_results_student; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_results_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_role_permissions_permission; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_role_permissions_role; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: roles fk_roles_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_roles_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: sections fk_sections_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_sections_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: sections fk_sections_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_sections_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: settings fk_settings_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT fk_settings_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: staff_attendance fk_staff_attendance_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance
    ADD CONSTRAINT fk_staff_attendance_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: staff_attendance fk_staff_attendance_staff; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance
    ADD CONSTRAINT fk_staff_attendance_staff FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: staff_attendance fk_staff_attendance_user; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff_attendance
    ADD CONSTRAINT fk_staff_attendance_user FOREIGN KEY (marked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: staff fk_staff_department; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT fk_staff_department FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: staff fk_staff_person; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT fk_staff_person FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: staff fk_staff_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT fk_staff_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: streams fk_streams_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.streams
    ADD CONSTRAINT fk_streams_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: student_attendance fk_student_attendance_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance
    ADD CONSTRAINT fk_student_attendance_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: student_attendance fk_student_attendance_student; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance
    ADD CONSTRAINT fk_student_attendance_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_attendance fk_student_attendance_user; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_attendance
    ADD CONSTRAINT fk_student_attendance_user FOREIGN KEY (marked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: students fk_students_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE SET NULL;


--
-- Name: students fk_students_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: students fk_students_section; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_section FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE SET NULL;


--
-- Name: subjects fk_subjects_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT fk_subjects_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: terms fk_terms_academic_year; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.terms
    ADD CONSTRAINT fk_terms_academic_year FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: terms fk_terms_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.terms
    ADD CONSTRAINT fk_terms_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: timetable fk_timetable_class; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT fk_timetable_class FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: timetable fk_timetable_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT fk_timetable_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: timetable fk_timetable_subject; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT fk_timetable_subject FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: timetable fk_timetable_teacher; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT fk_timetable_teacher FOREIGN KEY (teacher_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: users fk_users_person; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_person FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: users fk_users_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: wallets fk_wallets_school; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_wallets_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: wallets fk_wallets_student; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_wallets_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: lesson lesson_class_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_class_fk FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: lesson lesson_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: lesson lesson_subject_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_subject_fk FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: lesson lesson_teacher_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_teacher_fk FOREIGN KEY (teacher_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: message message_recipient_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_recipient_fk FOREIGN KEY (recipient_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: message message_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: message message_sender_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_fk FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notification notification_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: notification notification_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: onboarding_steps onboarding_steps_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.onboarding_steps
    ADD CONSTRAINT onboarding_steps_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payment_allocations payment_allocations_fee_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_allocations
    ADD CONSTRAINT payment_allocations_fee_allocation_id_fkey FOREIGN KEY (fee_allocation_id) REFERENCES public.fee_allocations(id) ON DELETE CASCADE;


--
-- Name: payment_allocations payment_allocations_fee_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_allocations
    ADD CONSTRAINT payment_allocations_fee_payment_id_fkey FOREIGN KEY (fee_payment_id) REFERENCES public.fee_payments(id) ON DELETE CASCADE;


--
-- Name: payment_allocations payment_allocations_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_allocations
    ADD CONSTRAINT payment_allocations_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: payment_reminder payment_reminder_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.payment_reminder
    ADD CONSTRAINT payment_reminder_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: person person_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: quiz_attempt quiz_attempt_quiz_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_attempt
    ADD CONSTRAINT quiz_attempt_quiz_fk FOREIGN KEY (quiz_id) REFERENCES public.quiz(id) ON DELETE CASCADE;


--
-- Name: quiz_attempt quiz_attempt_student_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_attempt
    ADD CONSTRAINT quiz_attempt_student_fk FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: quiz_question quiz_question_quiz_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz_question
    ADD CONSTRAINT quiz_question_quiz_fk FOREIGN KEY (quiz_id) REFERENCES public.quiz(id) ON DELETE CASCADE;


--
-- Name: quiz quiz_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz
    ADD CONSTRAINT quiz_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: quiz quiz_subject_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz
    ADD CONSTRAINT quiz_subject_fk FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE SET NULL;


--
-- Name: quiz quiz_teacher_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.quiz
    ADD CONSTRAINT quiz_teacher_fk FOREIGN KEY (teacher_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: school_onboarding school_onboarding_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_onboarding
    ADD CONSTRAINT school_onboarding_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: school_settings school_settings_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: share_issuances share_issuances_approved_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_issuances
    ADD CONSTRAINT share_issuances_approved_by_id_fkey FOREIGN KEY (approved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: share_issuances share_issuances_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_issuances
    ADD CONSTRAINT share_issuances_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: share_issuances share_issuances_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_issuances
    ADD CONSTRAINT share_issuances_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: share_transfers share_transfers_approved_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_transfers
    ADD CONSTRAINT share_transfers_approved_by_id_fkey FOREIGN KEY (approved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: share_transfers share_transfers_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_transfers
    ADD CONSTRAINT share_transfers_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: share_transfers share_transfers_from_shareholder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_transfers
    ADD CONSTRAINT share_transfers_from_shareholder_id_fkey FOREIGN KEY (from_shareholder_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: share_transfers share_transfers_to_shareholder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.share_transfers
    ADD CONSTRAINT share_transfers_to_shareholder_id_fkey FOREIGN KEY (to_shareholder_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: shareholdings shareholdings_shareholder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.shareholdings
    ADD CONSTRAINT shareholdings_shareholder_id_fkey FOREIGN KEY (shareholder_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: student_contacts student_contacts_student_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_contacts
    ADD CONSTRAINT student_contacts_student_fk FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_curriculums student_curriculums_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_curriculums
    ADD CONSTRAINT student_curriculums_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: student_curriculums student_curriculums_student_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_curriculums
    ADD CONSTRAINT student_curriculums_student_fk FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_profiles student_profiles_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: student_profiles student_profiles_student_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_student_fk FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_payment_plans user_payment_plans_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_payment_plans
    ADD CONSTRAINT user_payment_plans_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.payment_plans(id) ON DELETE RESTRICT;


--
-- Name: user_payment_plans user_payment_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_payment_plans
    ADD CONSTRAINT user_payment_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_people user_people_person_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_people
    ADD CONSTRAINT user_people_person_fk FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: user_people user_people_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_people
    ADD CONSTRAINT user_people_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_school_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_school_fk FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE SET NULL;


--
-- Name: user_profiles user_profiles_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_trials user_trials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xhenvolt
--

ALTER TABLE ONLY public.user_trials
    ADD CONSTRAINT user_trials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: xhenvolt
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict 993OwflUMtH5QfspR0wsFmZSfo7Mn1gbVaJLNSJlVjfTqjAafimAaIOKKdZZZLv


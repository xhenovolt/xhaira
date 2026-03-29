#!/usr/bin/env python3

import os
import sys
from urllib.parse import urlparse
import json

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print("ERROR: psycopg2 not installed. Installing...")
    os.system("pip install psycopg2-binary -q")
    import psycopg2
    from psycopg2.extras import execute_values

# Parse DATABASE_URL
db_url = os.environ.get('DATABASE_URL')
if not db_url:
    print("ERROR: DATABASE_URL not set")
    sys.exit(1)

parsed = urlparse(db_url)
db_config = {
    'host': parsed.hostname,
    'port': parsed.port or 5432,
    'database': parsed.path.lstrip('/'),
    'user': parsed.username,
    'password': parsed.password,
}

print(f"Connecting to {db_config['host']}:{db_config['port']}/{db_config['database']}...")

try:
    conn = psycopg2.connect(**db_config, sslmode='require')
    cursor = conn.cursor()
    
    print("✅ Connected\n")
    
    # Create tables
    tables = {
        'user_presence': """
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
        """,
        'permissions': """
            CREATE TABLE IF NOT EXISTS public.permissions (
                id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                name varchar(255) NOT NULL UNIQUE,
                module varchar(100) NOT NULL,
                action varchar(100) NOT NULL,
                description text,
                is_system boolean DEFAULT false,
                created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
            )
        """,
        'role_permissions': """
            CREATE TABLE IF NOT EXISTS public.role_permissions (
                id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
                permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
                created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
            )
        """,
        'staff_roles': """
            CREATE TABLE IF NOT EXISTS public.staff_roles (
                id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                staff_id uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
                role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
                assigned_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
                created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
            )
        """,
        'approval_requests': """
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
        """
    }
    
    for table_name, sql in tables.items():
        try:
            cursor.execute(sql)
            conn.commit()
            print(f"✅ {table_name} created")
        except Exception as e:
            print(f"❌ {table_name} failed: {e}")
            conn.rollback()
    
    # Verify
    cursor.execute("""
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('user_presence', 'permissions', 'role_permissions', 'staff_roles', 'approval_requests')
        ORDER BY table_name
    """)
    
    tables_found = cursor.fetchall()
    print(f"\n✅ SUCCESS: {len(tables_found)}/5 tables created")
    for row in tables_found:
        print(f"   ✓ {row[0]}")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)

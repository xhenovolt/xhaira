# Shares Configuration Setup Guide

## Problem

You're getting the error: `Error: relation "shares" does not exist`

This happens because the database tables for the shares system haven't been created yet.

## Solution

There are two approaches to fix this:

### Approach 1: Initialize Fresh Database (Recommended for New Setup)

If you're setting up a fresh database, run the initialization script which creates all necessary tables including shares:

```bash
node scripts/init-db.js
```

This will create:
- ✅ All core tables (users, assets, liabilities, deals, etc.)
- ✅ Shares tables (shares, share_allocations, share_price_history)
- ✅ All other supporting tables

Then run the Phase 6 migration:

```bash
node scripts/migrate-phase6.js
```

### Approach 2: Run SQL Migrations on Existing Database

If you already have a database with tables, run the SQL migrations in order:

```bash
node scripts/run-sql-migrations.js
```

This script will run all SQL migrations in the correct order:
1. 001_create_domains.sql
2. 005_deals_to_sales_automation.sql
3. 006_pipeline_analytics.sql
4. 007_add_equity_type.sql
5. 007_update_deals_schema.sql
6. 008_corporate_equity_refactor.sql
7. 009_add_equity_type_classification.sql
8. 010_two_layer_share_model.sql

## What Tables Were Created

After running either approach above, you'll have:

### Basic Shares Tables
- **shares** - Company-level share configuration
- **share_allocations** - Share ownership records
- **share_price_history** - Historical pricing

### Corporate Equity Tables (from migration 008)
- **shares_config** - Authorized vs issued shares tracking
- **shareholdings** - Individual shareholder records with vesting
- **share_transfers** - Ownership transfer history
- **share_issuances** - New share creation events

### Enhanced Valuation Tables (from migration 010)
- **valuation_snapshots** - Investment round valuations
- **shareholdings_with_vesting** - View with vesting calculations

## Verification

To verify the shares tables were created successfully:

```bash
psql <your_database> -c "\dt shares*"
```

You should see:
```
           List of relations
 Schema |          Name          | Type  | Owner
--------+------------------------+-------+-------
 public | share_allocations      | table | user
 public | share_price_history    | table | user
 public | shares                 | table | user
 public | shareholdings          | table | user
 public | share_issuances        | table | user
 public | share_transfers        | table | user
```

## Next Steps

Once the tables are created:

1. **Configure shares** via the API:
   ```bash
   curl -X POST http://localhost:3000/api/equity/valuation \
     -H "Content-Type: application/json" \
     -d '{"authorized_shares": 1000000}'
   ```

2. **Add shareholders** using the shares library in `src/lib/shares.js`

3. **Track valuations** by recording investment rounds

## Troubleshooting

### Still getting "relation does not exist"?

1. Check that the scripts ran without errors
2. Verify DATABASE_URL is set correctly
3. Ensure you have write permissions on the database
4. Check PostgreSQL logs for any constraint violations

### Migration failed?

- Check the error message for the specific table/constraint issue
- Each migration is independent and can be debugged separately
- Look at the migration files in `/migrations` folder to understand what should be created

## Files Reference

- **Initialization**: `scripts/init-db.js` - Creates base tables
- **Phase 6 Migration**: `scripts/migrate-phase6.js` - Adds permissions system
- **SQL Migrations**: `migrations/*.sql` - Equity and domain-specific tables
- **Migration Runner**: `scripts/run-sql-migrations.js` - Runs SQL migrations in order
- **Shares Library**: `src/lib/shares.js` - Backend API for share management

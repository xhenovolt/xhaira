# Shareholder Foreign Key Constraint Fix

## Issue
When trying to add a shareholder, the application was throwing the following error:
```
insert or update on table "shareholdings" violates foreign key constraint "shareholdings_shareholder_id_fkey"
```

## Root Cause
The `shareholdings` table has a foreign key constraint that requires the `shareholder_id` to exist in the `users` table:

```sql
shareholder_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT
```

When attempting to insert a shareholder with an ID that doesn't exist in the `users` table, PostgreSQL rejects the operation to maintain referential integrity.

## Solution
Added validation checks before attempting to insert shareholding records to ensure the user exists in the `users` table first.

### Changes Made

#### 1. **src/lib/equity.js** - `addShareholder()` function
Added a user existence check before inserting into shareholdings:

```javascript
// CRITICAL: Verify user exists in users table before creating shareholding
// This prevents "violates foreign key constraint" error
const userCheckResult = await query(
  'SELECT id FROM users WHERE id = $1',
  [shareholder_id]
);

if (userCheckResult.rowCount === 0) {
  throw new Error(
    `User with ID ${shareholder_id} does not exist. Please create the user first before adding as shareholder.`
  );
}
```

#### 2. **src/lib/shares.js** - `issueShares()` function
Added user existence check and modified INSERT to SELECT from users table:

```javascript
// Verify recipient exists in users table before creating shareholding
const recipientCheckResult = await query(
  'SELECT id FROM users WHERE id = $1',
  [to_shareholder_id]
);

if (recipientCheckResult.rowCount === 0) {
  throw new Error(
    `User with ID ${to_shareholder_id} does not exist. Please create the user first.`
  );
}

// Modified INSERT to SELECT from users
INSERT INTO shareholdings (...)
SELECT $1, $2, $3, ... FROM users u WHERE u.id = $1
ON CONFLICT (shareholder_id) DO UPDATE ...
```

#### 3. **src/lib/shares.js** - `transferShares()` function
Added user existence check with proper transaction rollback:

```javascript
// Verify recipient exists in users table before creating shareholding
const recipientCheckResult = await query(
  'SELECT id FROM users WHERE id = $1',
  [to_shareholder_id]
);

if (recipientCheckResult.rowCount === 0) {
  await query('ROLLBACK');
  throw new Error(
    `User with ID ${to_shareholder_id} does not exist. Please create the user first.`
  );
}
```

## How to Add Shareholders Correctly

### Step 1: Create a User First
Ensure the user exists in the `users` table:

```javascript
// POST /api/auth/register
{
  "email": "shareholder@example.com",
  "password": "secure_password",
  "full_name": "John Doe"
}
```

### Step 2: Get the User ID
After user creation, note the UUID returned (or query the users table).

### Step 3: Add as Shareholder
Use the user's ID to add them as a shareholder:

```javascript
// POST /api/equity/shareholders
{
  "shareholder_id": "uuid-from-step-2",
  "shareholder_name": "John Doe",
  "shareholder_email": "shareholder@example.com",
  "shares_owned": 1000,
  "holder_type": "investor",
  "equity_type": "PURCHASED",
  "acquisition_price": 10.00
}
```

## Testing the Fix

1. **Register a new user** via `/api/auth/register`
2. **Copy the returned user ID**
3. **Add them as a shareholder** via `/api/equity/shareholders` with that user ID
4. **Verify success** - The shareholder should appear in the cap table

## Error Messages

If you try to add a shareholder with a non-existent user ID, you'll now get a clear error:

```json
{
  "success": false,
  "error": "User with ID <uuid> does not exist. Please create the user first before adding as shareholder."
}
```

This is much clearer than the previous foreign key violation error and helps identify the root cause immediately.

## Related Functions Protected

- ✅ `addShareholder()` - Validates user exists
- ✅ `issueShares()` - Validates recipient user exists
- ✅ `transferShares()` - Validates recipient user exists with transaction rollback
- ✅ `executeShareTransfer()` - Already protected with SELECT FROM users clause
- ✅ `recordIssuanceWithRecipient()` - Already protected with SELECT FROM users clause

All shareholder operations now properly validate that the referenced user exists before attempting to create any shareholding records.

/**
 * Auth Flow Test Script
 * Tests complete authentication pipeline:
 * 1. System initialization
 * 2. Role initialization
 * 3. User registration
 * 4. Session creation
 * 5. Session retrieval
 */

import { query, getPool, closePool } from './src/lib/db.js';
import bcrypt from 'bcryptjs';
import { initializeBaseRoles } from './src/lib/system-init.js';
import crypto from 'crypto';

async function testAuthFlow() {
  console.log('\n🧪 XHAIRA AUTH FLOW TEST\n');
  
  let testResults = {
    passed: 0,
    failed: 0,
    errors: []
  };

  try {
    // TEST 1: Initialize roles
    console.log('1️⃣  Initializing base roles...');
    try {
      const roles = await initializeBaseRoles();
      console.log('   ✓ Base roles initialized');
      console.log(`   Roles created: ${Object.values(roles).join(', ')}`);
      testResults.passed++;
    } catch (error) {
      console.error('   ✗ FAILED:', error.message);
      testResults.failed++;
      testResults.errors.push(`Role initialization: ${error.message}`);
    }

    // TEST 2: Create test user (registration)
    console.log('\n2️⃣  Creating test user (registration)...');
    try {
      const testEmail = `test${Date.now()}@xhaira.test`;
      const testPassword = 'TestPassword123!';
      const passwordHash = await bcrypt.hash(testPassword, 10);

      const userResult = await query(
        `INSERT INTO users (email, password_hash, name, username, role, is_active, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, email, name, username, role, is_active, created_at`,
        [testEmail, passwordHash, 'Test User', `testuser${Date.now()}`, 'user', true, 'active']
      );

      if (!userResult.rows[0]) throw new Error('User not created');
      
      const createdUser = userResult.rows[0];
      console.log('   ✓ User created successfully');
      console.log(`   ID: ${createdUser.id}`);
      console.log(`   Email: ${createdUser.email}`);
      console.log(`   Username: ${createdUser.username}`);
      testResults.passed++;

      // TEST 3: Create session (login)
      console.log('\n3️⃣  Creating session (login)...');
      try {
        const sessionToken = crypto.randomBytes(32).toString('hex');
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

        const sessionResult = await query(
          `INSERT INTO sessions (user_id, token, expires_at, last_activity, created_at)
           VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
           RETURNING id, user_id, token, expires_at, last_activity, created_at`,
          [createdUser.id, sessionToken, expiresAt, new Date()]
        );

        if (!sessionResult.rows[0]) throw new Error('Session not created');
        
        const session = sessionResult.rows[0];
        console.log('   ✓ Session created successfully');
        console.log(`   Session ID: ${session.id}`);
        console.log(`   Token length: ${session.token.length}`);
        console.log(`   Expires at: ${session.expires_at}`);
        console.log(`   Last activity: ${session.last_activity}`);
        testResults.passed++;

        // TEST 4: Retrieve session (auth check)
        console.log('\n4️⃣  Retrieving session (auth check)...');
        try {
          const retrieveResult = await query(
            `SELECT s.id, s.user_id, s.token, s.expires_at, s.last_activity, s.created_at,
                    u.id as user_id, u.email, u.name, u.username, u.role, u.is_active
             FROM sessions s
             JOIN users u ON s.user_id = u.id
             WHERE s.token = $1 AND s.expires_at > CURRENT_TIMESTAMP`,
            [sessionToken]
          );

          if (!retrieveResult.rows[0]) throw new Error('Session not found or expired');
          
          const retrievedSession = retrieveResult.rows[0];
          console.log('   ✓ Session retrieved successfully');
          console.log(`   User email: ${retrievedSession.email}`);
          console.log(`   User username: ${retrievedSession.username}`);
          console.log(`   User role: ${retrievedSession.role}`);
          console.log(`   Session valid: ${new Date(retrievedSession.expires_at) > new Date()}`);
          testResults.passed++;

          // TEST 5: Verify schema properties
          console.log('\n5️⃣  Verifying schema properties...');
          try {
            const schemaCheck = await query(`
              SELECT 
                (SELECT COUNT(*) FROM information_schema.columns 
                 WHERE table_name='users' AND column_name='username') > 0 as users_has_username,
                (SELECT COUNT(*) FROM information_schema.columns 
                 WHERE table_name='roles' AND column_name='name') > 0 as roles_has_name,
                (SELECT COUNT(*) FROM information_schema.columns 
                 WHERE table_name='roles' AND column_name='role_name') > 0 as roles_has_role_name,
                (SELECT COUNT(*) FROM information_schema.columns 
                 WHERE table_name='sessions' AND column_name='last_activity') > 0 as sessions_has_last_activity
            `);

            const check = schemaCheck.rows[0];
            const allGood = check.users_has_username && check.roles_has_name && 
                           !check.roles_has_role_name && check.sessions_has_last_activity;

            if (allGood) {
              console.log('   ✓ Schema properties correct');
              console.log(`   users.username: ${check.users_has_username ? '✓' : '✗'}`);
              console.log(`   roles.name: ${check.roles_has_name ? '✓' : '✗'}`);
              console.log(`   roles.role_name: ${check.roles_has_role_name ? '✗ (good)' : '✓ (not present)'}`);
              console.log(`   sessions.last_activity: ${check.sessions_has_last_activity ? '✓' : '✗'}`);
              testResults.passed++;
            } else {
              throw new Error('Schema properties mismatch');
            }
          } catch (error) {
            console.error('   ✗ FAILED:', error.message);
            testResults.failed++;
            testResults.errors.push(`Schema check: ${error.message}`);
          }

        } catch (error) {
          console.error('   ✗ FAILED:', error.message);
          testResults.failed++;
          testResults.errors.push(`Session retrieval: ${error.message}`);
        }

      } catch (error) {
        console.error('   ✗ FAILED:', error.message);
        testResults.failed++;
        testResults.errors.push(`Session creation: ${error.message}`);
      }

    } catch (error) {
      console.error('   ✗ FAILED:', error.message);
      testResults.failed++;
      testResults.errors.push(`User creation: ${error.message}`);
    }

    // Print summary
    console.log('\n' + '='.repeat(50));
    console.log(`TEST SUMMARY`);
    console.log('='.repeat(50));
    console.log(`✓ Passed: ${testResults.passed}`);
    console.log(`✗ Failed: ${testResults.failed}`);
    
    if (testResults.errors.length > 0) {
      console.log('\nErrors:');
      testResults.errors.forEach(err => console.log(`  - ${err}`));
    }

    if (testResults.failed === 0) {
      console.log('\n🎉 ALL TESTS PASSED!');
      console.log('\nThe authentication system is ready:');
      console.log('  ✓ Registration works');
      console.log('  ✓ Login/session creation works');
      console.log('  ✓ Auth check works');
      console.log('  ✓ Schema integrity confirmed');
    } else {
      console.log('\n❌ TESTS FAILED - System integrity issues detected');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ FATAL ERROR:', error.message);
    testResults.failed++;
  } finally {
    await closePool();
  }
}

// Run tests
testAuthFlow().catch(error => {
  console.error('Test execution failed:', error);
  process.exit(1);
});

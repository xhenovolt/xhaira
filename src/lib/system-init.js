/**
 * System Initialization Check
 * 
 * Determines if the Xhaira system is initialized (has at least one user)
 * and controls access based on system state.
 */

import { query } from './db.js';

/**
 * Check if system is initialized
 * System is initialized when:
 * - At least one user exists in the database
 * 
 * @returns {Promise<boolean>} True if system has users, false otherwise
 */
export async function isSystemInitialized() {
  try {
    const result = await query(
      'SELECT COUNT(*)::int as count FROM users',
      []
    );
    const userCount = result.rows[0]?.count || 0;
    return userCount > 0;
  } catch (error) {
    console.error('Error checking system initialization:', error);
    // Default to false on error (safer — don't allow registration on unknown state)
    return false;
  }
}

/**
 * Get count of users in system
 * @returns {Promise<number>} Total user count
 */
export async function getUserCount() {
  try {
    const result = await query(
      'SELECT COUNT(*)::int as count FROM users',
      []
    );
    return result.rows[0]?.count || 0;
  } catch (error) {
    console.error('Error getting user count:', error);
    return 0;
  }
}

/**
 * Check if this user should be super admin on creation
 * First user in the system automatically becomes super admin
 * 
 * @returns {Promise<boolean>} True if this should be the first user (super admin)
 */
export async function shouldBeFirstUseSuperAdmin() {
  const initialized = await isSystemInitialized();
  return !initialized; // If not initialized, this is first user
}

/**
 * Initialize core roles if they don't exist
 * Called during first user creation to ensure role system is ready
 * 
 * @returns {Promise<Object>} Object with created role IDs
 */
export async function initializeBaseRoles() {
  const roles = {
    SUPER_ADMIN: 'role_superadmin',
    ADMIN: 'role_admin',
    STAFF: 'role_staff',
  };

  try {
    // Check if roles exist
    const existing = await query(
      `SELECT id, role_name FROM roles 
       WHERE role_name IN ($1, $2, $3)`,
      ['superadmin', 'admin', 'staff']
    );

    const existingRoles = new Set(existing.rows.map(r => r.role_name));

    // Create missing roles
    if (!existingRoles.has('superadmin')) {
      await query(
        `INSERT INTO roles (id, role_name, description, is_system_role)
         VALUES ($1, $2, $3, true)`,
        [
          roles.SUPER_ADMIN,
          'superadmin',
          'System Administrator with full access and control'
        ]
      );
    }

    if (!existingRoles.has('admin')) {
      await query(
        `INSERT INTO roles (id, role_name, description, is_system_role)
         VALUES ($1, $2, $3, true)`,
        [
          roles.ADMIN,
          'admin',
          'Administrator who can manage users and system settings'
        ]
      );
    }

    if (!existingRoles.has('staff')) {
      await query(
        `INSERT INTO roles (id, role_name, description, is_system_role)
         VALUES ($1, $2, $3, true)`,
        [
          roles.STAFF,
          'staff',
          'Staff member with operational permissions'
        ]
      );
    }

    return roles;
  } catch (error) {
    console.error('Error initializing base roles:', error);
    throw error;
  }
}

/**
 * Verify system state for frontend (no auth required)
 * @returns {Promise<Object>} System state information
 */
export async function getSystemState() {
  try {
    const initialized = await isSystemInitialized();
    const userCount = await getUserCount();

    return {
      initialized,
      userCount,
      message: initialized
        ? 'System is initialized - registration is closed'
        : 'System is not initialized - public registration available'
    };
  } catch (error) {
    console.error('Error getting system state:', error);
    return {
      initialized: false,
      userCount: 0,
      error: 'Unable to determine system state'
    };
  }
}

import pg from 'pg';
import * as env from './env.js';

const { Pool } = pg;

/**
 * PostgreSQL Connection Pool
 * Supports both local development and serverless environments (Neon)
 */
let pool = null;
let poolInitAttempts = 0;

/**
 * Initialize the database connection pool
 * @returns {Pool} PostgreSQL connection pool instance
 */
function initializePool() {
  if (pool) {
    return pool;
  }

  const connectionString = env.DATABASE_URL;

  if (!connectionString) {
    throw new Error('DATABASE_URL environment variable is not set');
  }

  poolInitAttempts++;

  pool = new Pool({
    connectionString,
    // Optimized for serverless and reliability
    max: 5, // Reduced from 10 for stability
    min: 1, // Maintain minimum connection
    idleTimeoutMillis: 60000, // 60 seconds (increased)
    connectionTimeoutMillis: 10000, // 10 seconds (increased)
    maxUses: 7500, // Recycle connections
    ssl: connectionString.includes('neon.tech') || connectionString.includes('sslmode=')
      ? { rejectUnauthorized: true }
      : false,
  });

  // Handle pool errors
  pool.on('error', (error) => {
    console.error('Unexpected error on idle client', error);
    // Reset pool on error
    if (pool) {
      pool.end().catch(() => {});
      pool = null;
    }
  });

  // Handle connection errors
  pool.on('connect', () => {
    // Connection established
  });

  return pool;
}

/**
 * Get a client from the pool and execute a query with retry logic
 * @param {string} query - SQL query string
 * @param {Array} params - Query parameters (for parameterized queries)
 * @param {number} retries - Number of retries on failure
 * @returns {Promise<any>} Query result
 */
export async function query(query, params = [], retries = 2) {
  let lastError;
  
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const client = await getPool().connect();
      try {
        return await client.query(query, params);
      } finally {
        client.release();
      }
    } catch (error) {
      lastError = error;
      
      if (attempt < retries) {
        // Wait before retrying (exponential backoff)
        const delay = Math.min(1000 * Math.pow(2, attempt), 5000);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      // All retries exhausted
      throw error;
    }
  }
  
  throw lastError;
}

/**
 * Get the connection pool instance
 * Creates it if it doesn't exist
 * @returns {Pool} PostgreSQL connection pool
 */
export function getPool() {
  if (!pool) {
    initializePool();
  }
  return pool;
}

/**
 * Test the database connection
 * @returns {Promise<boolean>} true if connection successful
 */
export async function testConnection() {
  try {
    const result = await query('SELECT NOW()');
    return !!result.rows;
  } catch (error) {
    console.error('Database connection test failed:', error);
    return false;
  }
}

/**
 * Close all connections in the pool
 * Useful for cleanup during graceful shutdown
 * @returns {Promise<void>}
 */
export async function closePool() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

export default {
  query,
  getPool,
  testConnection,
  closePool,
};

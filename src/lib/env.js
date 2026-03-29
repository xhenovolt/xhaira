/**
 * Environment Variables Configuration
 * Next.js automatically loads .env.local, so these are available via process.env
 */

// Export validated environment variables
export const DATABASE_URL = process.env.DATABASE_URL || '';
export const NODE_ENV = process.env.NODE_ENV || 'development';

// Optional environment variables
export const API_URL = process.env.API_URL || 'http://localhost:3000';
export const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

/**
 * Check if running in production
 */
export const isProduction = NODE_ENV === 'production';

/**
 * Check if running in development
 */
export const isDevelopment = NODE_ENV === 'development';

/**
 * Check if running in testing
 */
export const isTesting = NODE_ENV === 'test';

// Warn about missing required variables in development
if (isDevelopment && !DATABASE_URL) {
  console.warn(
    'Warning: DATABASE_URL is not set. Database features will be unavailable.'
  );
}

export default {
  DATABASE_URL,
  NODE_ENV,
  API_URL,
  LOG_LEVEL,
  isProduction,
  isDevelopment,
  isTesting,
};
  
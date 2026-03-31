/**
 * Financial Products Engine — Product Type Definitions
 * 
 * Centralizes all product type logic, form field visibility,
 * and business rules for the SACCO & Investment Management System.
 */

export const PRODUCT_TYPES = {
  LOAN: {
    label: 'Loan',
    description: 'Interest-based lending product',
    color: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    icon: 'Banknote',
    fields: {
      interest_rate: { required: true, label: 'Interest Rate (%)', type: 'number', step: '0.01' },
      duration_months: { required: true, label: 'Duration (months)', type: 'number' },
      min_amount: { required: true, label: 'Minimum Amount', type: 'number' },
      max_amount: { required: true, label: 'Maximum Amount', type: 'number' },
      requires_approval: { required: false, label: 'Requires Approval', type: 'boolean', defaultValue: true },
      currency: { required: true, label: 'Currency', type: 'select', options: ['UGX', 'USD', 'KES', 'EUR'] },
    },
  },
  SAVINGS: {
    label: 'Savings',
    description: 'Deposit & savings account product',
    color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
    icon: 'PiggyBank',
    fields: {
      interest_rate: { required: false, label: 'Interest Rate (% p.a.)', type: 'number', step: '0.01' },
      min_amount: { required: false, label: 'Minimum Deposit', type: 'number' },
      max_amount: { required: false, label: 'Maximum Balance', type: 'number' },
      currency: { required: true, label: 'Currency', type: 'select', options: ['UGX', 'USD', 'KES', 'EUR'] },
    },
  },
  INSTALLMENT: {
    label: 'Installment',
    description: 'Purchase on credit with payment schedule',
    color: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
    icon: 'CreditCard',
    fields: {
      price: { required: true, label: 'Total Price', type: 'number' },
      upfront_amount: { required: false, label: 'Upfront Payment', type: 'number' },
      duration_months: { required: true, label: 'Installment Period (months)', type: 'number' },
      interest_rate: { required: false, label: 'Interest Rate (%)', type: 'number', step: '0.01' },
      currency: { required: true, label: 'Currency', type: 'select', options: ['UGX', 'USD', 'KES', 'EUR'] },
      requires_approval: { required: false, label: 'Requires Approval', type: 'boolean', defaultValue: false },
    },
  },
  SERVICE: {
    label: 'Service',
    description: 'One-time or recurring service product',
    color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    icon: 'Layers',
    fields: {
      price: { required: false, label: 'Price', type: 'number' },
      billing_frequency: { required: false, label: 'Billing', type: 'select', options: ['one-time', 'monthly', 'quarterly', 'annually'] },
      currency: { required: true, label: 'Currency', type: 'select', options: ['UGX', 'USD', 'KES', 'EUR'] },
    },
  },
  INVESTMENT: {
    label: 'Investment',
    description: 'Investment plan with return projections',
    color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
    icon: 'TrendingUp',
    fields: {
      min_amount: { required: true, label: 'Minimum Investment', type: 'number' },
      max_amount: { required: false, label: 'Maximum Investment', type: 'number' },
      return_rate: { required: false, label: 'Expected Return Rate (%)', type: 'number', step: '0.01' },
      duration_months: { required: false, label: 'Lock-in Period (months)', type: 'number' },
      currency: { required: true, label: 'Currency', type: 'select', options: ['UGX', 'USD', 'KES', 'EUR'] },
      requires_approval: { required: false, label: 'Requires Approval', type: 'boolean', defaultValue: true },
    },
  },
};

/** All product type keys */
export const PRODUCT_TYPE_KEYS = Object.keys(PRODUCT_TYPES);

/**
 * Get the field configuration for a given product type.
 * Returns empty object for unknown types.
 */
export function getFieldsForType(productType) {
  return PRODUCT_TYPES[productType]?.fields || {};
}

/**
 * Check if a field should be visible for a given product type.
 */
export function isFieldVisible(productType, fieldName) {
  const fields = getFieldsForType(productType);
  return fieldName in fields;
}

/**
 * Get default form values for a product type.
 */
export function getDefaultValues(productType) {
  const fields = getFieldsForType(productType);
  const defaults = { product_type: productType, currency: 'UGX' };
  for (const [key, config] of Object.entries(fields)) {
    if (config.defaultValue !== undefined) {
      defaults[key] = config.defaultValue;
    }
  }
  return defaults;
}

/**
 * Validate product data based on its type.
 * Returns array of error messages (empty = valid).
 */
export function validateProduct(data) {
  const errors = [];
  if (!data.name) errors.push('Product name is required');
  if (!data.product_type || !PRODUCT_TYPES[data.product_type]) {
    errors.push('Valid product type is required');
    return errors;
  }
  const fields = getFieldsForType(data.product_type);
  for (const [key, config] of Object.entries(fields)) {
    if (config.required && (data[key] === undefined || data[key] === null || data[key] === '')) {
      errors.push(`${config.label} is required for ${PRODUCT_TYPES[data.product_type].label} products`);
    }
  }
  return errors;
}

/**
 * Status styles for product cards
 */
export const STATUS_STYLES = {
  active: 'bg-emerald-100 text-emerald-700',
  development: 'bg-blue-100 text-blue-700',
  deprecated: 'bg-orange-100 text-orange-700',
  archived: 'bg-muted text-muted-foreground',
};

/**
 * Xhaira SACCO — UI Feature Configuration
 * 
 * Controls which modules and sections are visible in the sidebar and UI.
 * All feature flags are boolean. Set to false to hide a module entirely.
 * 
 * These are UI-level toggles — they control visibility, not data access.
 * For data access control, use the RBAC permission system.
 */

export const uiConfig = {
  // ── SACCO Core Modules ──────────────────────────────────────────────────
  enableMembers:      true,   // Member registry, profiles, KYC
  enableAccounts:     true,   // Member accounts (savings, shares, fixed deposit)
  enableTransactions: true,   // Double-entry ledger transactions
  enableLoans:        true,   // Loan applications, disbursements, repayments
  enableSavings:      true,   // Voluntary & fixed savings products
  enableShares:       true,   // Share capital management
  enableInvestments:  false,  // Investment portfolio (coming soon)
  enableTransfers:    true,   // Member-to-member transfers

  // ── Financial Reporting ─────────────────────────────────────────────────
  enableReports:      true,   // Standard financial reports
  enableFinance:      true,   // Internal company finance (ledger, accounts)

  // ── Operations ──────────────────────────────────────────────────────────
  enableActivity:     true,   // Activity log
  enableNotifications:true,   // Notification center
  enableMessages:     true,   // Internal messaging

  // ── Company Management ──────────────────────────────────────────────────
  enableStaff:        true,   // Staff & org hierarchy
  enableDocuments:    true,   // Document & knowledge base

  // ── Legacy / Non-SACCO (hidden from sidebar) ────────────────────────────
  enablePipeline:     false,  // Sales pipeline (Xhenvolt legacy)
  enableDeals:        false,  // Deal management (Xhenvolt legacy)
  enableClients:      false,  // Client management (renamed to Members)
  enablePricing:      false,  // Pricing plans (Xhenvolt legacy)
  enableDRAIS:        false,  // DRAIS school management (external system)
  enableServices:     false,  // Service catalog (Xhenvolt legacy)
  enableIntelligence: false,  // Business intelligence suite (hidden for now)

  // ── Admin ─────────────────────────────────────────────────────────────
  enableAdmin:        true,   // User & role management

  // ── Settings ──────────────────────────────────────────────────────────
  enableSettings:     true,   // System settings
};

/**
 * SACCO branding configuration
 */
export const brandConfig = {
  name:        'Xhaira',
  tagline:     'SACCO & Investment Management',
  currency:    'UGX',
  currencySymbol: 'UGX',
  locale:      'en-UG',
  dateFormat:  'DD/MM/YYYY',
};

/**
 * SACCO system terminology mapping
 * Used to normalize legacy Xhenvolt terminology to SACCO language
 */
export const terminology = {
  client:    'Member',
  clients:   'Members',
  deal:      'Loan',
  deals:     'Loans',
  sales:     'Transactions',
  revenue:   'Income',
  pipeline:  'Loan Portfolio',
  product:   'Financial Product',
  products:  'Financial Products',
};

export default uiConfig;

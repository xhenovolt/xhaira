/**
 * Navigation Configuration — XHAIRA SACCO & Investment Management
 *
 * Single Source of Truth for all navigation.
 * Sidebar reflects SACCO financial operations only.
 * Legacy Xhenvolt routes (Pipeline, Deals, Pricing) are hidden from nav.
 *
 * Feature flags: import uiConfig from '@/config/ui-config'
 * Every route here exists in /src/app/app/
 */

import {
  Home,
  DollarSign,
  Package,
  BarChart3,
  Settings,
  Shield,
  Palette,
  Type,
  Building2,
  Users,
  Activity,
  BookOpen,
  Bell,
  MessageCircle,
  CreditCard,
  Banknote,
  Wallet,
} from 'lucide-react';

/**
 * XHAIRA SACCO NAVIGATION
 * Reflects SACCO financial operations — not software sales.
 * Legacy routes (Pipeline, Deals, Pricing, DRAIS) are removed from sidebar.
 */
export const menuItems = [

  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY — Always visible
  // ═══════════════════════════════════════════════════════════════════════
  {
    label: 'Dashboard',
    href: '/app/dashboard',
    icon: Home,
    category: 'primary',
    permission: 'dashboard.view',
  },
  {
    label: 'Activity',
    href: '/app/activity',
    icon: Activity,
    category: 'primary',
    module: 'activity_logs',
    permission: 'activity_logs.view',
  },
  {
    label: 'Notifications',
    href: '/app/notifications',
    icon: Bell,
    category: 'primary',
  },
  {
    label: 'Messages',
    href: '/app/communication',
    icon: MessageCircle,
    category: 'primary',
    permission: 'communication.view',
  },

  // ═══════════════════════════════════════════════════════════════════════
  // SACCO CORE
  // ═══════════════════════════════════════════════════════════════════════

  // === MEMBERS ===
  {
    label: 'Members',
    icon: Users,
    category: 'sections',
    module: 'members',
    submenu: [
      { label: 'All Members',       href: '/app/members',             description: 'SACCO membership directory',         permission: 'members.view' },
      { label: 'Member Accounts',   href: '/app/members?tab=accounts', description: 'Savings, loans & investment accounts', permission: 'members.view' },
    ],
  },

  // === ACCOUNTS ===
  {
    label: 'Accounts',
    icon: CreditCard,
    category: 'sections',
    module: 'accounts',
    submenu: [
      { label: 'Overview',          href: '/app/accounts',           description: 'Account types & summary',             permission: 'finance.view' },
      { label: 'Account Types',     href: '/app/account-types',      description: 'Savings, shares & loan books',        permission: 'finance.view' },
      { label: 'Transactions',      href: '/app/transactions',        description: 'Double-entry ledger transactions',    permission: 'finance.view' },
      { label: 'Member Transfers',  href: '/app/member-transfers',    description: 'Peer-to-peer transfers',              permission: 'finance.view' },
    ],
  },

  // === LOANS ===
  {
    label: 'Loans',
    icon: Banknote,
    category: 'sections',
    module: 'loans',
    submenu: [
      { label: 'All Loans',         href: '/app/loans',               description: 'Loan applications & management',     permission: 'finance.view' },
      { label: 'Loan Products',     href: '/app/products?type=LOAN',  description: 'Interest-based lending products',    permission: 'products.view' },
      { label: 'Loan Rules',        href: '/app/sacco-rules',         description: 'Configurable SACCO policy engine',   permission: 'finance.manage' },
    ],
  },

  // === SAVINGS ===
  {
    label: 'Savings',
    icon: Wallet,
    category: 'sections',
    module: 'savings',
    submenu: [
      { label: 'Savings Products',  href: '/app/products?type=SAVINGS',       description: 'Voluntary & fixed savings products', permission: 'products.view' },
      { label: 'Fixed Deposits',    href: '/app/products?type=INSTALLMENT',   description: 'Fixed deposit products',             permission: 'products.view' },
    ],
  },

  // === FINANCIAL PRODUCTS ===
  {
    label: 'Products',
    icon: Package,
    category: 'sections',
    module: 'products',
    submenu: [
      { label: 'All Products',      href: '/app/products',                    description: 'Financial products catalogue',       permission: 'products.view' },
      { label: 'Loan Products',     href: '/app/products?type=LOAN',          description: 'Interest-based lending',             permission: 'products.view' },
      { label: 'Savings Products',  href: '/app/products?type=SAVINGS',       description: 'Deposit & savings products',         permission: 'products.view' },
      { label: 'Investment Products', href: '/app/products?type=INVESTMENT',  description: 'Investment plans',                   permission: 'products.view' },
    ],
  },

  // ═══════════════════════════════════════════════════════════════════════
  // FINANCE & REPORTING
  // ═══════════════════════════════════════════════════════════════════════

  // === FINANCE (Internal) ===
  {
    label: 'Finance',
    icon: DollarSign,
    category: 'sections',
    module: 'finance',
    submenu: [
      { label: 'Overview',          href: '/app/finance',              description: 'Financial dashboard',               permission: 'finance.view' },
      { label: 'Accounts',          href: '/app/finance/accounts',     description: 'Bank and cash accounts',            permission: 'accounts.view' },
      { label: 'Ledger',            href: '/app/finance/ledger',       description: 'Transaction history',               permission: 'finance.view' },
      { label: 'Expenses',          href: '/app/finance/expenses',     description: 'Track spending',                    permission: 'expenses.view' },
      { label: 'Transfers',         href: '/app/finance/transfers',    description: 'Move between accounts',             permission: 'finance.view' },
      { label: 'Budgets',           href: '/app/finance/budgets',      description: 'Spending limits & controls',        permission: 'budgets.view' },
    ],
  },

  // === REPORTS ===
  {
    label: 'Reports',
    href: '/app/reports',
    icon: BarChart3,
    category: 'sections',
    module: 'reports',
    permission: 'reports.view',
  },

  // ═══════════════════════════════════════════════════════════════════════
  // COMPANY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  // === COMPANY ===
  {
    label: 'Company',
    icon: Building2,
    category: 'sections',
    submenu: [
      { label: 'Staff',             href: '/app/staff',                description: 'Team members & hierarchy',          permission: 'staff.view' },
      { label: 'Org Hierarchy',     href: '/app/org-hierarchy',        description: 'Department & role tree',            permission: 'staff.view' },
      { label: 'Knowledge Base',    href: '/app/knowledge',            description: 'Company IP & documentation',        permission: 'knowledge.view' },
      { label: 'Documents',         href: '/app/documents',            description: 'Document center',                   permission: 'documents.view' },
      { label: 'Media',             href: '/app/media',                description: 'Files, images & documents',         permission: 'media.view' },
    ],
  },

  // === DOCS ===
  {
    label: 'Docs',
    href: '/app/docs',
    icon: BookOpen,
    category: 'sections',
    module: 'knowledge',
    permission: 'knowledge.view',
  },

  // ═══════════════════════════════════════════════════════════════════════
  // ADMINISTRATION
  // ═══════════════════════════════════════════════════════════════════════

  // === ADMIN ===
  {
    label: 'Admin',
    icon: Shield,
    category: 'sections',
    module: 'roles',
    minHierarchy: 3,
    submenu: [
      { label: 'Users',             href: '/app/admin/users',                description: 'User accounts & roles',                          permission: 'users.view' },
      { label: 'Roles',             href: '/app/admin/roles',                description: 'Manage roles & permissions',                     permission: 'roles.manage' },
      { label: 'Permission Manager', href: '/app/admin/role-permissions',    description: 'Toggle role permissions by module',              permission: 'roles.manage' },
      { label: 'Access Simulator',  href: '/app/admin/access-simulator',     description: 'Preview what a role can access',                 permission: 'roles.manage' },
      { label: 'Authority Inspector', href: '/app/admin/authority-inspector', description: 'Verify authority levels and hierarchy',         permission: 'roles.manage' },
      { label: 'Departments',       href: '/app/admin/departments',          description: 'Department management',                          permission: 'departments.view' },
      { label: 'Approvals',         href: '/app/admin/approvals',            description: 'Pending approval requests',                      permission: 'approvals.manage' },
      { label: 'Audit Logs',        href: '/app/admin/audit-logs',           description: 'System audit trail',                             permission: 'audit.view' },
      { label: 'Backups',           href: '/app/admin/backups',              description: 'System backups & restore',                       permission: 'backups.view' },
      { label: 'Identity Debug',    href: '/app/admin/debug',                description: 'User–Staff–Role integrity checker',              permission: 'users.view', minHierarchy: 1 },
    ],
  },

  // === SETTINGS ===
  {
    label: 'Settings',
    icon: Settings,
    category: 'sections',
    submenu: [
      { label: 'General',             href: '/app/settings',                  description: 'Account & preferences' },
      { label: 'Appearance',          href: '/app/settings/appearance',       icon: Palette, description: 'Colors, gradients, glass' },
      { label: 'Typography',          href: '/app/settings/typography',       icon: Type,    description: 'Font family, size & weight' },
      { label: 'Active Sessions',     href: '/app/settings/sessions',         icon: Shield,  description: 'Manage logged-in devices' },
      { label: 'SACCO Configuration', href: '/app/settings/configurations',   description: 'System-wide SACCO toggles & rules',  permission: 'finance.manage' },
      { label: 'Member Fields',       href: '/app/settings/member-fields',    description: 'Configure member profile fields',    permission: 'members.view' },
    ],
  },
];

/**
 * Quick access links for mobile bottom navigation
 */
export const quickAccessLinks = [
  { id: 'dashboard',    label: 'Dashboard',    icon: Home,     href: '/app/dashboard',    permission: 'dashboard.view' },
  { id: 'members',      label: 'Members',      icon: Users,    href: '/app/members',      permission: 'members.view' },
  { id: 'loans',        label: 'Loans',        icon: Banknote, href: '/app/loans',        permission: 'finance.view' },
  { id: 'transactions', label: 'Transactions', icon: DollarSign, href: '/app/transactions', permission: 'finance.view' },
];

/**
 * Protected routes that require authentication
 */
export const protectedRoutes = ['/app/*'];

/**
 * Settings route
 */
export const settingsRoute = {
  href: '/app/settings',
  label: 'Settings',
};

/**
 * Public routes
 */
export const publicRoutes = ['/login', '/register'];

/**
 * Get all hrefs from menu items recursively
 */
export function getAllHrefs(items = menuItems) {
  const hrefs = [];
  items.forEach((item) => {
    if (item.href) hrefs.push(item.href);
    if (item.submenu) hrefs.push(...getAllHrefs(item.submenu));
  });
  return hrefs;
}

/**
 * Find a menu item by href
 */
export function findMenuItemByHref(href, items = menuItems) {
  for (const item of items) {
    if (item.href === href) return item;
    if (item.submenu) {
      const found = findMenuItemByHref(href, item.submenu);
      if (found) return found;
    }
  }
  return null;
}

/**
 * Check if a route is active
 */
export function isRouteActive(currentPath, menuPath) {
  return currentPath === menuPath;
}

/**
 * Get parent menu items (sections with submenus)
 */
export function getParentMenuItems(items = menuItems) {
  return items.filter((item) => item.submenu && item.submenu.length > 0);
}

/**
 * Get all valid routes (flattened)
 */
export function getAllValidRoutes() {
  const routes = [];
  function traverse(items) {
    items.forEach((item) => {
      if (item.href) routes.push({ path: item.href, label: item.label, protected: item.href.startsWith('/app') });
      if (item.submenu) traverse(item.submenu);
    });
  }
  traverse(menuItems);
  return routes;
}

// ============================================================================
// ROUTE → PERMISSION MAP
// Built from menuItems at module-load time.
// Keys are exact paths; values are permission strings like 'finance.view'.
// ============================================================================

const _routePermissionMap = {};

function _buildMap(items) {
  items.forEach((item) => {
    if (item.href) {
      if (item.permission) {
        _routePermissionMap[item.href] = item.permission;
      } else if (item.module) {
        _routePermissionMap[item.href] = `${item.module}.view`;
      }
    }
    if (item.submenu) _buildMap(item.submenu);
  });
}
_buildMap(menuItems);

/**
 * Return the required permission key for a given path, or null if open to all.
 * Tries exact match first, then walks up path segments.
 *
 * @param {string} path - e.g. '/app/finance/ledger'
 * @returns {string|null} e.g. 'finance.view'
 */
export function getRoutePermission(path) {
  if (_routePermissionMap[path]) return _routePermissionMap[path];

  // Walk up: /app/finance/ledger → /app/finance → /app (stop)
  const parts = path.split('/');
  while (parts.length > 2) {
    parts.pop();
    const parent = parts.join('/');
    if (_routePermissionMap[parent]) return _routePermissionMap[parent];
  }

  return null;
}

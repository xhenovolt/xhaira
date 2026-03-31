/**
 * Navigation Configuration - XHAIRA SACCO & Investment Management
 *
 * Single Source of Truth for all navigation
 * Core model: Products → Deals → Payments → Licenses
 *
 * Every route here exists in /src/app/app/
 */

import {
  Home,
  Target,
  Briefcase,
  DollarSign,
  Package,
  BarChart3,
  Settings,
  Shield,
  Palette,
  Type,
  Monitor,
  Building2,
  Users,
  Activity,
  Layers,
  Workflow,
  PieChart,
  BookOpen,
  Wrench,
  Image,
  Calculator,
  ClipboardCheck,
  GitBranch,
  Brain,
  BoxSelect,
  FileText,
  Bug,
  Zap,
  Crown,
  Code2,
  BookMarked,
  Bell,
  MessageCircle,
  CreditCard,
  Tag,
  Grid3X3,
  Banknote,
  TrendingUp,
} from 'lucide-react';

/**
 * XHAIRA NAVIGATION
 * Products → Deals → Payments → Licenses
 */
export const menuItems = [
  // === PRIMARY ===
  {
    label: 'Dashboard',
    href: '/app/dashboard',
    icon: Home,
    category: 'primary',
    permission: 'dashboard.view',
  },
  {
    label: 'Command Center',
    href: '/app/command-center',
    icon: Zap,
    category: 'primary',
    permission: 'command_center.view',
    minHierarchy: 3,
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
    // Visible to all authenticated users — no permission required
  },
  {
    label: 'Messages',
    href: '/app/communication',
    icon: MessageCircle,
    category: 'primary',
    permission: 'communication.view',
  },

  // === PRODUCTS (Financial Products Engine) ===
  {
    label: 'Products',
    icon: Package,
    category: 'sections',
    module: 'products',
    submenu: [
      { label: 'All Products', href: '/app/products', description: 'Financial products & services', permission: 'products.view' },
      { label: 'Loan Products', href: '/app/products?type=LOAN', description: 'Interest-based lending products', permission: 'products.view' },
      { label: 'Savings Products', href: '/app/products?type=SAVINGS', description: 'Deposit & savings products', permission: 'products.view' },
      { label: 'Installment Products', href: '/app/products?type=INSTALLMENT', description: 'Purchase on credit', permission: 'products.view' },
      { label: 'Services', href: '/app/products?type=SERVICE', description: 'One-time & recurring services', permission: 'products.view' },
      { label: 'Investments', href: '/app/products?type=INVESTMENT', description: 'Investment plans', permission: 'products.view' },
      { label: 'Licenses', href: '/app/licenses', description: 'Active license registry', permission: 'licenses.view' },
      { label: 'Operations Log', href: '/app/operations', description: 'Daily workflow log', permission: 'operations.view' },
    ],
  },

  // === MEMBERS (SACCO Core) ===
  {
    label: 'Members',
    icon: Users,
    category: 'sections',
    module: 'members',
    submenu: [
      { label: 'All Members', href: '/app/members', description: 'SACCO membership directory', permission: 'members.view' },
      { label: 'Member Accounts', href: '/app/members?tab=accounts', description: 'Savings, loans & investment accounts', permission: 'members.view' },
    ],
  },

  // === LOANS (SACCO Lending) ===
  {
    label: 'Loans',
    icon: Banknote,
    category: 'sections',
    module: 'loans',
    submenu: [
      { label: 'All Loans', href: '/app/loans', description: 'Loan applications & management', permission: 'finance.view' },
      { label: 'SACCO Products', href: '/app/sacco-products', description: 'Loan & savings products', permission: 'finance.view' },
      { label: 'SACCO Rules', href: '/app/sacco-rules', description: 'Configurable policy engine', permission: 'finance.manage' },
      { label: 'Member Transfers', href: '/app/member-transfers', description: 'Peer-to-peer transfers', permission: 'finance.view' },
      { label: 'Account Types', href: '/app/account-types', description: 'Savings, shares & loan books', permission: 'finance.view' },
      { label: 'Transactions', href: '/app/transactions', description: 'Double-entry ledger transactions', permission: 'finance.view' },
    ],
  },

  // === SERVICES ===
  {
    label: 'Services',
    href: '/app/services',
    icon: Layers,
    category: 'sections',
    module: 'services',
    permission: 'services.view',
  },

  // === SALES PIPELINE ===
  {
    label: 'Pipeline',
    icon: Target,
    category: 'sections',
    module: 'pipeline',
    submenu: [
      { label: 'Pipeline Board', href: '/app/pipeline', description: 'Visual pipeline intelligence', permission: 'pipeline.view' },
      { label: 'Prospects', href: '/app/prospects', description: 'Track and qualify leads', permission: 'prospects.view' },
      { label: 'Follow-ups', href: '/app/followups', description: 'Scheduled touchpoints', permission: 'prospects.view' },
      { label: 'Clients', href: '/app/clients', description: 'Converted prospects', permission: 'clients.view' },
    ],
  },

  // === DEALS & PAYMENTS ===
  {
    label: 'Deals',
    icon: Briefcase,
    category: 'sections',
    module: 'deals',
    submenu: [
      { label: 'All Deals', href: '/app/deals', description: 'Active and completed deals', permission: 'deals.view' },
      { label: 'New Deal', href: '/app/deals/new', description: 'Record a licensing deal', permission: 'deals.create' },
      { label: 'Obligations', href: '/app/obligations', description: 'Client deliverable tracking', permission: 'obligations.view' },
      { label: 'Payments', href: '/app/payments', description: 'Payment records', permission: 'payments.view' },
      { label: 'Invoices', href: '/app/invoices', description: 'Generated invoices & PDFs', permission: 'invoices.view' },
      { label: 'Allocations', href: '/app/allocations', description: 'Money allocation tracking', permission: 'allocations.view' },
    ],
  },

  // === COMPANY ===
  {
    label: 'Company',
    icon: Building2,
    category: 'sections',
    submenu: [
      { label: 'Staff', href: '/app/staff', description: 'Team members & hierarchy', permission: 'staff.view' },
      { label: 'Org Hierarchy', href: '/app/org-hierarchy', description: 'Department & role tree', permission: 'staff.view' },
      { label: 'Control Tower', href: '/app/control-tower', description: 'Authority & structural health', permission: 'staff.view' },
      { label: 'Items', href: '/app/items', description: 'Unified assets, tools & infrastructure', permission: 'assets.view' },
      { label: 'Knowledge Base', href: '/app/knowledge', description: 'Company IP & documentation', permission: 'knowledge.view' },
      { label: 'Liabilities', href: '/app/liabilities', description: 'Obligations and debts', permission: 'finance.view' },
      { label: 'Offerings', href: '/app/offerings', description: 'Service catalog', permission: 'offerings.view' },
      { label: 'Media', href: '/app/media', description: 'Files, images & documents', permission: 'media.view' },
    ],
  },

  // === FINANCE ===
  {
    label: 'Finance',
    icon: DollarSign,
    category: 'sections',
    module: 'finance',
    submenu: [
      { label: 'Overview', href: '/app/finance', description: 'Financial dashboard', permission: 'finance.view' },
      { label: 'Accounts', href: '/app/finance/accounts', description: 'Bank and cash accounts', permission: 'accounts.view' },
      { label: 'Ledger', href: '/app/finance/ledger', description: 'Transaction history', permission: 'finance.view' },
      { label: 'Expenses', href: '/app/finance/expenses', description: 'Track spending', permission: 'expenses.view' },
      { label: 'Transfers', href: '/app/finance/transfers', description: 'Move between accounts', permission: 'finance.view' },
      { label: 'Budgets', href: '/app/finance/budgets', description: 'Spending limits', permission: 'budgets.view' },
      { label: '---', href: '#', description: '', permission: null },
      { label: 'Banking', href: '/app/finance/banking', description: 'Internal banking system', permission: 'finance.manage' },
      { label: 'Employee Loans', href: '/app/finance/loans', description: 'Peer-to-peer loans', permission: 'finance.manage' },
      { label: 'Salary Advances', href: '/app/finance/advances', description: 'Advance disbursements', permission: 'finance.manage' },
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

  // === INTELLIGENCE ===
  {
    label: 'Intelligence',
    icon: Brain,
    category: 'sections',
    module: 'intelligence',
    submenu: [
      { label: 'Dashboard', href: '/app/intelligence', description: 'Role-based intelligence overview', permission: 'intelligence.view' },
      { label: 'Tech Stacks', href: '/app/tech-intelligence', description: 'Reusable technology stacks', permission: 'systems.view' },
      { label: 'Engineering', href: '/app/engineering', description: 'Bugs, features & tech tracking', permission: 'bug_tracking.view' },
      { label: 'Issue Intelligence', href: '/app/issue-intelligence', description: 'Root causes & resolutions', permission: 'issue_intelligence.view' },
      { label: 'Financial', href: '/app/financial-intelligence', description: 'Capital allocation & revenue', permission: 'finance.view' },
      { label: 'HRM', href: '/app/hrm', description: 'Employees & departments', permission: 'hrm.view' },
      { label: 'Documents', href: '/app/documents', description: 'Document center', permission: 'documents.view' },
      { label: 'Decision Log', href: '/app/decision-log', description: 'Key decisions & rationale', permission: 'decision_logs.view' },
    ],
  },

  // === PRICING & SUBSCRIPTIONS ===
  {
    label: 'Pricing',
    icon: Tag,
    category: 'sections',
    module: 'pricing',
    submenu: [
      { label: 'Pricing Plans', href: '/app/pricing', description: 'Centralized pricing for all systems', permission: 'pricing.view' },
      { label: 'Subscriptions', href: '/app/subscriptions', description: 'Client subscription management', permission: 'subscriptions.view' },
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

  // === DRAIS CONTROL ===
  {
    label: 'DRAIS Control',
    icon: Workflow,
    category: 'sections',
    module: 'drais',
    submenu: [
      { label: 'Schools', href: '/app/dashboard/drais/schools', description: 'School management & control', permission: 'drais.view' },
      { label: 'Pricing', href: '/app/dashboard/drais/pricing', description: 'Global pricing control', permission: 'drais.view' },
      { label: 'Activity', href: '/app/dashboard/drais/activity', description: 'Real-time activity monitoring', permission: 'drais.view' },
      { label: 'Integrations', href: '/app/dashboard/integrations', description: 'External system connections', permission: 'integrations.view' },
    ],
  },

  // === ADMIN ===
  {
    label: 'Admin',
    icon: Shield,
    category: 'sections',
    module: 'roles',
    minHierarchy: 3,
    submenu: [
      { label: 'Users', href: '/app/admin/users', description: 'User accounts & roles', permission: 'users.view' },
      { label: 'Roles', href: '/app/admin/roles', description: 'Manage roles & permissions', permission: 'roles.manage' },
      { label: 'Permission Manager', href: '/app/admin/role-permissions', description: 'Toggle role permissions by module', permission: 'roles.manage' },
      { label: 'Access Simulator', href: '/app/admin/access-simulator', description: 'Preview what a role can access', permission: 'roles.manage' },
      { label: 'Authority Inspector', href: '/app/admin/authority-inspector', description: 'Verify authority levels and hierarchy enforcement', permission: 'roles.manage' },
      { label: 'Departments', href: '/app/admin/departments', description: 'Department management', permission: 'departments.view' },
      { label: 'Approvals', href: '/app/admin/approvals', description: 'Pending approval requests', permission: 'approvals.manage' },
      { label: 'Approval Pipeline', href: '/app/approval-pipeline', description: 'Visual approval workflow', permission: 'approvals.manage' },
      { label: 'Backups', href: '/app/admin/backups', description: 'System backups & restore', permission: 'backups.view' },
      { label: 'Audit Logs', href: '/app/admin/audit-logs', description: 'System audit trail', permission: 'audit.view' },
      { label: 'Identity Debug', href: '/app/admin/debug', description: 'User–Staff–Role integrity checker', permission: 'users.view', minHierarchy: 1 },
    ],
  },

  // === SETTINGS ===
  {
    label: 'Settings',
    icon: Settings,
    category: 'sections',
    // Settings visible to all authenticated users
    submenu: [
      { label: 'General', href: '/app/settings', description: 'Account & preferences' },
      { label: 'Appearance', href: '/app/settings/appearance', icon: Palette, description: 'Colors, gradients, glass' },
      { label: 'Typography', href: '/app/settings/typography', icon: Type, description: 'Font family, size & weight' },
      { label: 'Active Sessions', href: '/app/settings/sessions', icon: Shield, description: 'Manage logged-in devices' },
    ],
  },
];

/**
 * Quick access links for mobile bottom navigation
 */
export const quickAccessLinks = [
  { id: 'dashboard', label: 'Dashboard', icon: Home, href: '/app/dashboard', permission: 'dashboard.view' },
  { id: 'products', label: 'Products', icon: Package, href: '/app/products', permission: 'products.view' },
  { id: 'deals', label: 'Deals', icon: Briefcase, href: '/app/deals', permission: 'deals.view' },
  { id: 'finance', label: 'Finance', icon: DollarSign, href: '/app/finance', permission: 'finance.view' },
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

'use client';

import { usePathname } from 'next/navigation';
import { useEffect } from 'react';

/**
 * Page Title Component
 * Displays current page title and updates HTML title tag
 */
export function PageTitle() {
  const pathname = usePathname();

  // Map routes to readable titles
  const routeTitles = {
    '/app/dashboard': 'Dashboard',
    '/app/assets-accounting': 'Accounting Assets',
    '/app/intellectual-property': 'Intellectual Property',
    '/app/infrastructure': 'Infrastructure',
    '/app/liabilities': 'Liabilities',
    '/app/deals': 'Deals',
    '/app/pipeline': 'Pipeline',
    '/app/prospecting': 'Prospecting Notebook',
    '/app/prospecting/dashboard': 'Today\'s Prospecting',
    '/app/staff': 'Staff',
    '/app/audit-logs': 'Audit Logs',
    '/app/settings': 'Settings',
  };

  const pageTitle = routeTitles[pathname] || 'Xhaira';
  const fullTitle = pageTitle === 'Xhaira' ? 'Xhaira - Executive Operating System' : `${pageTitle} | Xhaira`;

  // Update HTML title
  useEffect(() => {
    document.title = fullTitle;
  }, [fullTitle]);

  if (pathname === '/' || pathname === '/login' || pathname === '/register') {
    return null;
  }

  return (
    <div className="px-6 py-3 border-b border-border bg-background">
      <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">{pageTitle}</p>
    </div>
  );
}

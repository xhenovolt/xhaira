'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { AlertTriangle, LayoutDashboard, Home, RefreshCcw } from 'lucide-react';

/**
 * Global Error Boundary
 * Catches runtime errors and displays a friendly recovery UI.
 * Must be a Client Component ("use client").
 */
export default function GlobalError({ error, reset }) {
  useEffect(() => {
    // Log error to console for debugging
    console.error('[Xhaira] Unhandled runtime error:', error);
  }, [error]);

  return (
    <html>
      <body>
        <div className="min-h-screen flex items-center justify-center bg-background px-4">
          <div className="max-w-md w-full text-center">
            {/* Icon */}
            <div className="inline-flex items-center justify-center w-16 h-16 bg-red-100 rounded-full mb-6">
              <AlertTriangle className="w-8 h-8 text-red-600" />
            </div>

            {/* Title */}
            <h1 className="text-2xl font-bold text-foreground mb-3">Something went wrong</h1>

            {/* Description */}
            <p className="text-muted-foreground mb-2 leading-relaxed">
              An unexpected error occurred. This has been logged.
            </p>

            {/* Error detail (dev-friendly but not sensitive) */}
            {error?.message && (
              <p className="text-xs font-mono text-muted-foreground bg-muted border border-border rounded-lg px-4 py-2 mb-6 text-left break-all">
                {error.message}
              </p>
            )}

            {/* Recovery actions */}
            <div className="flex flex-col sm:flex-row gap-3 justify-center mb-6">
              <button
                onClick={reset}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-primary text-primary-foreground rounded-lg font-medium text-sm hover:bg-primary/90 transition"
              >
                <RefreshCcw size={15} />
                Try Again
              </button>
              <Link
                href="/app/dashboard"
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 border border-border text-foreground rounded-lg font-medium text-sm hover:bg-muted/50 transition"
              >
                <LayoutDashboard size={15} />
                Go to Dashboard
              </Link>
              <Link
                href="/"
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 border border-border text-foreground rounded-lg font-medium text-sm hover:bg-muted/50 transition"
              >
                <Home size={15} />
                Home
              </Link>
            </div>

            <p className="text-xs text-muted-foreground">
              If this error persists, please contact your administrator.
            </p>
          </div>
        </div>
      </body>
    </html>
  );
}

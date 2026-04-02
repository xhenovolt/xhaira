'use client';

import { useEffect } from 'react';

/**
 * Root segment error boundary — rendered inside the root layout.
 * For the global catch-all (outside layout), see global-error.js.
 */
export default function Error({ error, reset }) {
  useEffect(() => {
    console.error('[Xhaira] Runtime error:', error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="max-w-md w-full text-center">
        <div className="text-5xl mb-6">⚠️</div>
        <h1 className="text-2xl font-bold text-foreground mb-3">Something went wrong</h1>
        <p className="text-muted-foreground mb-6 leading-relaxed">
          An unexpected error occurred. If this persists, contact your administrator.
        </p>
        {error?.message && (
          <pre className="text-xs font-mono text-red-400 bg-muted border border-border rounded-lg px-4 py-3 mb-6 text-left break-all whitespace-pre-wrap">
            {error.message}
          </pre>
        )}
        <div className="flex gap-3 justify-center">
          <button
            onClick={reset}
            className="px-5 py-2.5 bg-primary text-primary-foreground rounded-lg font-medium text-sm hover:bg-primary/90 transition"
          >
            Try Again
          </button>
          <a href="/app/dashboard" className="px-5 py-2.5 border border-border text-foreground rounded-lg font-medium text-sm hover:bg-muted/50 transition">
            Dashboard
          </a>
        </div>
      </div>
    </div>
  );
}

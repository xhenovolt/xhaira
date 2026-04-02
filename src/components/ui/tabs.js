'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';

// ─── Tabs ────────────────────────────────────────────────────────────────────
// Simple context-based Tabs without @radix-ui/react-tabs dep.

const TabsContext = React.createContext({ value: '', onValueChange: () => {} });

function Tabs({ value, defaultValue, onValueChange, className, children, ...props }) {
  const [internal, setInternal] = React.useState(defaultValue ?? '');
  const isControlled = value !== undefined;
  const current = isControlled ? value : internal;
  const setCurrent = isControlled ? onValueChange : setInternal;
  return (
    <TabsContext.Provider value={{ value: current, onValueChange: setCurrent }}>
      <div className={cn('', className)} {...props}>
        {children}
      </div>
    </TabsContext.Provider>
  );
}

function TabsList({ className, ...props }) {
  return (
    <div
      role="tablist"
      className={cn(
        'inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground',
        className
      )}
      {...props}
    />
  );
}

function TabsTrigger({ className, value, children, ...props }) {
  const { value: current, onValueChange } = React.useContext(TabsContext);
  const isActive = current === value;
  return (
    <button
      type="button"
      role="tab"
      aria-selected={isActive}
      onClick={() => onValueChange(value)}
      className={cn(
        'inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
        isActive ? 'bg-background text-foreground shadow' : '',
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}

function TabsContent({ className, value, children, ...props }) {
  const { value: current } = React.useContext(TabsContext);
  if (current !== value) return null;
  return (
    <div
      role="tabpanel"
      className={cn(
        'mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export { Tabs, TabsList, TabsTrigger, TabsContent };

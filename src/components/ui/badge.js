'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';

const variantStyles = {
  default: 'bg-primary border-primary text-primary-foreground',
  destructive: 'bg-destructive border-destructive text-destructive-foreground',
  outline: 'text-foreground',
  secondary: 'bg-secondary border-transparent text-secondary-foreground',
};

const Badge = React.forwardRef(function Badge({ className, variant = 'default', ...props }, ref) {
  return (
    <div
      ref={ref}
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
        variantStyles[variant] || variantStyles.default,
        className
      )}
      {...props}
    />
  );
});
Badge.displayName = 'Badge';

export { Badge };

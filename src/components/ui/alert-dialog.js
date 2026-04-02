'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';

// ─── AlertDialog ────────────────────────────────────────────────────────────
// Simple modal-based implementation without @radix-ui/react-alert-dialog dep.

const AlertDialogContext = React.createContext({ open: false, onOpenChange: () => {} });

function AlertDialog({ open, onOpenChange, children, defaultOpen = false }) {
  const [internalOpen, setInternalOpen] = React.useState(defaultOpen);
  const isControlled = open !== undefined;
  const isOpen = isControlled ? open : internalOpen;
  const setOpen = isControlled ? onOpenChange : setInternalOpen;
  return (
    <AlertDialogContext.Provider value={{ open: isOpen, onOpenChange: setOpen }}>
      {children}
    </AlertDialogContext.Provider>
  );
}

function AlertDialogTrigger({ asChild, children, ...props }) {
  const { onOpenChange } = React.useContext(AlertDialogContext);
  if (asChild && React.isValidElement(children)) {
    return React.cloneElement(children, {
      ...props,
      onClick: (e) => {
        children.props.onClick?.(e);
        onOpenChange(true);
      },
    });
  }
  return (
    <button type="button" onClick={() => onOpenChange(true)} {...props}>
      {children}
    </button>
  );
}

function AlertDialogPortal({ children }) {
  return children;
}

function AlertDialogOverlay({ className, ...props }) {
  return (
    <div
      className={cn('fixed inset-0 z-50 bg-black/80', className)}
      {...props}
    />
  );
}

function AlertDialogContent({ className, children, ...props }) {
  const { open } = React.useContext(AlertDialogContext);
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <AlertDialogOverlay />
      <div
        role="alertdialog"
        aria-modal="true"
        className={cn(
          'relative z-50 grid w-full max-w-lg gap-4 border bg-background p-6 shadow-lg sm:rounded-lg',
          className
        )}
        {...props}
      >
        {children}
      </div>
    </div>
  );
}

function AlertDialogHeader({ className, ...props }) {
  return (
    <div className={cn('flex flex-col space-y-2 text-center sm:text-left', className)} {...props} />
  );
}

function AlertDialogFooter({ className, ...props }) {
  return (
    <div
      className={cn('flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2', className)}
      {...props}
    />
  );
}

function AlertDialogTitle({ className, ...props }) {
  return <h2 className={cn('text-lg font-semibold', className)} {...props} />;
}

function AlertDialogDescription({ className, ...props }) {
  return (
    <p className={cn('text-sm text-muted-foreground', className)} {...props} />
  );
}

function AlertDialogAction({ className, onClick, ...props }) {
  const { onOpenChange } = React.useContext(AlertDialogContext);
  return (
    <button
      type="button"
      className={cn(
        'inline-flex h-9 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90',
        className
      )}
      onClick={(e) => {
        onClick?.(e);
        onOpenChange(false);
      }}
      {...props}
    />
  );
}

function AlertDialogCancel({ className, onClick, ...props }) {
  const { onOpenChange } = React.useContext(AlertDialogContext);
  return (
    <button
      type="button"
      className={cn(
        'inline-flex h-9 items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent mt-2 sm:mt-0',
        className
      )}
      onClick={(e) => {
        onClick?.(e);
        onOpenChange(false);
      }}
      {...props}
    />
  );
}

export {
  AlertDialog,
  AlertDialogPortal,
  AlertDialogOverlay,
  AlertDialogTrigger,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogFooter,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogAction,
  AlertDialogCancel,
};

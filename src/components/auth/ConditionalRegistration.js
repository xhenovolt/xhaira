'use client';

/**
 * Conditional Registration Page
 * Shows:
 * - Open registration form if system not initialized
 * - Locked message if system initialized
 */

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, CheckCircle } from 'lucide-react';

export function ConditionalRegistrationPage() {
  const [systemState, setSystemState] = useState(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const checkSystemState = async () => {
      try {
        const res = await fetch('/api/system/state');
        const data = await res.json();
        setSystemState(data);

        // If system is initialized and user tries to access register page,
        // redirect to login after brief delay
        if (data.initialized) {
          setTimeout(() => {
            router.push('/login');
          }, 2000);
        }
      } catch (error) {
        console.error('Error checking system state:', error);
      } finally {
        setLoading(false);
      }
    };

    checkSystemState();
  }, [router]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-muted-foreground">Loading...</div>
      </div>
    );
  }

  if (systemState?.initialized) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-background to-muted p-4">
        <div className="max-w-md text-center">
          <Lock className="mx-auto mb-4 text-amber-500" size={64} />
          <h1 className="text-3xl font-bold text-foreground mb-2">
            Registration Closed
          </h1>
          <p className="text-muted-foreground mb-4">
            Xhaira registration is only available during initial setup. User
            accounts are now created exclusively by administrators.
          </p>
          <p className="text-sm text-muted-foreground mb-6">
            Contact your administrator at <strong>admin@xhaira.app</strong> to
            request access to the system.
          </p>
          <a
            href="/login"
            className="inline-block px-6 py-2 bg-primary text-primary-foreground rounded hover:bg-primary/90 transition"
          >
            Go to Login
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-background to-muted p-4">
      <div className="max-w-md w-full text-center">
        <CheckCircle className="mx-auto mb-4 text-emerald-500" size={64} />
        <h1 className="text-3xl font-bold text-foreground mb-2">
          System Registration Open
        </h1>
        <p className="text-muted-foreground mb-6">
          Xhaira is ready for initial setup. Create your admin account below.
        </p>
        {/* Registration form will be rendered by parent */}
        {/* This component just handles the conditional display */}
      </div>
    </div>
  );
}

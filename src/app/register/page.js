/**
 * Register Page - System Access & Identity Control
 * 
 * PHASE 5: Disable Frontend Registration
 * 
 * Conditional display based on system state:
 * - System NOT initialized: Show registration form for first user
 * - System initialized: Show locked message redirecting to login
 */

'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, CheckCircle } from 'lucide-react';
import RegisterForm from '@/components/auth/RegisterForm';
import AnimatedAuthBackground from '@/components/auth/AnimatedAuthBackground';

export default function RegisterPage() {
  const [systemState, setSystemState] = useState(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const checkSystemState = async () => {
      try {
        const res = await fetch('/api/system/state');
        const data = await res.json();
        setSystemState(data);

        // If system is initialized, redirect to login after brief delay
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
      <div className="relative min-h-screen flex items-center justify-center px-4 py-12">
        <AnimatedAuthBackground />
        <div className="relative z-10 text-muted-foreground">Loading...</div>
      </div>
    );
  }

  // System is initialized — show locked registration message
  if (systemState?.initialized) {
    return (
      <div className="relative min-h-screen flex items-center justify-center px-4 py-12">
        <AnimatedAuthBackground />

        <div className="w-full max-w-md relative z-10">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center mb-4">
              <svg className="w-16 h-16 text-amber-500" viewBox="0 0 120 120" fill="currentColor">
                <circle cx="60" cy="60" r="55" opacity="0.1" />
                <text x="60" y="75" fontSize="48" fontWeight="bold" textAnchor="middle" fill="currentColor">X</text>
              </svg>
            </div>
            <Lock className="mx-auto mb-4 text-amber-500" size={48} />
            <h1 className="text-3xl font-bold text-foreground mb-2">Registration Closed</h1>
            <p className="text-muted-foreground">
              Xhaira registration is only available during initial setup. Ask your SACCO administrator for access.
            </p>
          </div>

          <div className="backdrop-blur-xl bg-white/90 dark:bg-white/[0.07] border border-border dark:border-white/[0.12] rounded-2xl shadow-2xl shadow-gray-200/50 dark:shadow-black/20 p-8 text-center space-y-4">
            <p className="text-sm text-muted-foreground">
              User accounts are now created exclusively by administrators.
            </p>
            <p className="text-sm text-muted-foreground">
              Contact your administrator to request access to the system.
            </p>
            <a
              href="/login"
              className="inline-block mt-4 px-5 py-2.5 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity"
            >
              Go to Login
            </a>
          </div>
        </div>
      </div>
    );
  }

  // System is NOT initialized — show registration form
  return (
    <div className="relative min-h-screen flex items-center justify-center px-4 py-12">
      <AnimatedAuthBackground />

      <div className="w-full max-w-md relative z-10">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center mb-4">
            <svg className="w-16 h-16 text-emerald-500" viewBox="0 0 120 120" fill="currentColor">
              <circle cx="60" cy="60" r="55" opacity="0.1" />
              <text x="60" y="75" fontSize="48" fontWeight="bold" textAnchor="middle" fill="currentColor">X</text>
            </svg>
          </div>
          <CheckCircle className="mx-auto mb-4 text-emerald-500" size={48} />
          <h1 className="text-3xl font-bold text-foreground mb-2">System Registration Open</h1>
          <p className="text-muted-foreground">Create your initial admin account for Xhaira</p>
        </div>

        {/* Registration Form Card */}
        <div className="backdrop-blur-xl bg-white/90 dark:bg-white/[0.07] border border-border dark:border-white/[0.12] rounded-2xl shadow-2xl shadow-gray-200/50 dark:shadow-black/20 p-8">
          <RegisterForm />
        </div>
      </div>
    </div>
  );
}

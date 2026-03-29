/**
 * Login Page - Futuristic Glassmorphism Design
 * User authentication interface
 */

import LoginForm from '@/components/auth/LoginForm';
import AnimatedAuthBackground from '@/components/auth/AnimatedAuthBackground';

export const metadata = {
  title: 'Sign In - Xhaira SACCO & Investment Management',
  description: 'Sign in to Xhaira, a SACCO and Investment Management System. Manage members, loans, savings, and investments securely.',
};

export default function LoginPage() {
  return (
    <div className="relative min-h-screen flex items-center justify-center px-4 py-12">
      <AnimatedAuthBackground />
      
      <div className="w-full max-w-md relative z-10">
        {/* Logo & Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center mb-4">
            <svg className="w-16 h-16 text-primary" viewBox="0 0 120 120" fill="currentColor">
              <circle cx="60" cy="60" r="55" opacity="0.1"/>
              <text x="60" y="75" fontSize="48" fontWeight="bold" textAnchor="middle" fill="currentColor">X</text>
            </svg>
          </div>
          <h1 className="text-3xl font-bold text-foreground mb-2">
            Welcome Back
          </h1>
          <p className="text-muted-foreground">
            Sign in to your Xhaira account
          </p>
        </div>

        {/* Glassmorphism Card */}
        <div className="backdrop-blur-xl bg-white/90 dark:bg-white/[0.07] border border-border dark:border-white/[0.12] rounded-2xl shadow-2xl shadow-gray-200/50 dark:shadow-black/20 p-8">
          <LoginForm />
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-sm text-muted-foreground">
          <p>
            Protected by enterprise-grade security
          </p>
        </div>
      </div>
    </div>
  );
}

/**
 * Login Page - Futuristic Glassmorphism Design
 * User authentication interface
 */

import LoginForm from '@/components/auth/LoginForm';
import AnimatedAuthBackground from '@/components/auth/AnimatedAuthBackground';

export const metadata = {
  title: 'Sign In - Xhaira',
  description: 'Sign in to your Xhaira account',
};

export default function LoginPage() {
  return (
    <div className="relative min-h-screen flex items-center justify-center px-4 py-12">
      <AnimatedAuthBackground />
      
      <div className="w-full max-w-md relative z-10">
        {/* Logo & Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 shadow-lg shadow-blue-500/25 mb-4">
            <span className="text-2xl font-bold text-white">J</span>
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

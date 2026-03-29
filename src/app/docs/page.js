import Link from 'next/link';
import { BookOpen, Users, DollarSign, BarChart3, Shield, Zap, ArrowRight, Clock } from 'lucide-react';

export const metadata = { 
  title: 'Xhaira SACCO & Investment Management - Documentation',
  description: 'Complete documentation for Xhaira SACCO management system. Learn how to manage members, loans, savings, and investments.'
};

const sections = [
  {
    icon: Zap,
    title: 'Getting Started',
    description: 'Set up Xhaira in minutes. Learn core concepts and start managing your SACCO.',
    links: [
      { label: 'Quick Start', href: '/docs/getting-started' },
      { label: 'SACCO Concepts', href: '/docs/concepts' },
    ],
    color: 'text-blue-600',
    bg: 'bg-blue-50',
  },
  {
    icon: Users,
    title: 'Member Management',
    description: 'Onboard and manage SACCO members. Track member accounts, contributions, and participation.',
    links: [
      { label: 'Member Onboarding', href: '/docs/members' },
      { label: 'Member Portal', href: '/docs/member-portal' },
    ],
    color: 'text-green-600',
    bg: 'bg-green-50',
  },
  {
    icon: DollarSign,
    title: 'Loan Management',
    description: 'Create loan products, process applications, manage repayments, and track loan portfolios.',
    links: [
      { label: 'Loan Products', href: '/docs/loans' },
      { label: 'Disbursement & Repayment', href: '/docs/repayment' },
    ],
    color: 'text-purple-600',
    bg: 'bg-purple-50',
  },
  {
    icon: BarChart3,
    title: 'Reports & Analytics',
    description: 'Generate reports on member accounts, loan performance, savings, and investment returns.',
    links: [
      { label: 'Reports', href: '/docs/reports' },
      { label: 'Analytics Dashboard', href: '/docs/analytics' },
    ],
    color: 'text-orange-600',
    bg: 'bg-orange-50',
  },
  {
    icon: Shield,
    title: 'Security & Users',
    description: 'Role-based access control, user management, and complete audit logging for compliance.',
    links: [
      { label: 'User Management', href: '/docs/users' },
      { label: 'Security & RBAC', href: '/docs/security' },
    ],
    color: 'text-red-600',
    bg: 'bg-red-50',
  },
  {
    icon: BookOpen,
    title: 'API Reference',
    description: 'Integrate with Xhaira via our REST API. Build custom integrations and automate workflows.',
    links: [
      { label: 'API Reference', href: '/docs/api' },
      { label: 'Automation', href: '/docs/automation' },
    ],
    color: 'text-teal-600',
    bg: 'bg-teal-50',
  },
];

export default function DocsPage() {
  return (
    <div className="max-w-4xl">
      {/* Header */}
      <div className="mb-10">
        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-3">
          <BookOpen size={14} />
          <span>Documentation</span>
        </div>
        <h1 className="text-4xl font-bold text-foreground mb-4">Xhaira Documentation</h1>
        <p className="text-lg text-muted-foreground leading-relaxed max-w-2xl">
          Xhaira is a comprehensive SACCO and Investment Management System. Learn how to manage members,
          loans, savings, and investments with complete transparency and security.
        </p>
      </div>

      {/* Quick links */}
      <div className="flex flex-wrap gap-3 mb-10">
        <Link href="/docs/getting-started" className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition">
          <Zap size={15} />
          Quick Start
          <ArrowRight size={14} />
        </Link>
        <Link href="/docs/concepts" className="flex items-center gap-2 px-4 py-2 border border-border text-foreground rounded-lg text-sm font-medium hover:bg-muted/50 transition">
          Core Concepts
        </Link>
        <Link href="/docs/modules" className="flex items-center gap-2 px-4 py-2 border border-border text-foreground rounded-lg text-sm font-medium hover:bg-muted/50 transition">
          Module Overview
        </Link>
      </div>

      {/* What is Xhaira */}
      <div className="p-6 bg-muted/30 border border-border rounded-xl mb-10">
        <h2 className="font-semibold text-foreground mb-3">What is Xhaira?</h2>
        <p className="text-muted-foreground text-sm leading-relaxed">
          Xhaira is a <strong className="text-foreground">SACCO & Investment Management System</strong> — a comprehensive platform that enables Savings and Credit Cooperative Organizations to manage members, loans, savings, and investments in a secure, transparent, and efficient manner.
        </p>
        <div className="mt-4 grid sm:grid-cols-3 gap-3">
          {[
            { label: 'Core Platform', value: 'Members → Loans → Savings → Investments' },
            { label: 'Built for', value: 'SACCOs, cooperatives, financial institutions' },
            { label: 'Tech Stack', value: 'Next.js · PostgreSQL · Role-based access' },
          ].map(({ label, value }) => (
            <div key={label} className="text-sm">
              <p className="text-muted-foreground">{label}</p>
              <p className="font-medium text-foreground">{value}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Section grid */}
      <div className="grid sm:grid-cols-2 gap-6">
        {sections.map((section) => {
          const Icon = section.icon;
          return (
            <div key={section.title} className="border border-border rounded-xl p-6 hover:border-primary/40 transition-colors">
              <div className={`inline-flex items-center justify-center w-10 h-10 ${section.bg} rounded-lg mb-4`}>
                <Icon className={`w-5 h-5 ${section.color}`} />
              </div>
              <h3 className="font-semibold text-foreground mb-2">{section.title}</h3>
              <p className="text-sm text-muted-foreground mb-4 leading-relaxed">{section.description}</p>
              <div className="space-y-1">
                {section.links.map(({ label, href }) => (
                  <Link key={href} href={href} className="flex items-center gap-1.5 text-sm text-primary hover:underline">
                    <ArrowRight size={12} />
                    {label}
                  </Link>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <div className="mt-12 pt-8 border-t border-border text-center">
        <p className="text-sm text-muted-foreground">
          Need help? Contact support or{' '}
          <Link href="/app/dashboard" className="text-primary hover:underline">go to the dashboard</Link>.
        </p>
      </div>
    </div>
  );
}

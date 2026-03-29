'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { TrendingUp, PieChart, BarChart3, Zap, Shield, Users, LayoutDashboard, LogOut } from 'lucide-react';

export default function Home() {
  const [authUser, setAuthUser] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);

  useEffect(() => {
    fetch('/api/auth/me', { credentials: 'include' })
      .then(r => r.ok ? r.json() : null)
      .then(data => { setAuthUser(data?.user || null); })
      .catch(() => setAuthUser(null))
      .finally(() => setAuthLoading(false));
  }, []);

  const handleLogout = async () => {
    await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' });
    setAuthUser(null);
  };
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="fixed top-0 w-full bg-background/80 backdrop-blur-md border-b border-border z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="text-2xl font-bold text-primary">Xhaira</div>
          <div className="flex items-center gap-3">
            <Link href="/docs" className="px-4 py-2 text-foreground hover:text-primary transition text-sm">Docs</Link>
            {authLoading ? (
              <div className="w-24 h-9 bg-muted rounded-lg animate-pulse" />
            ) : authUser ? (
              <>
                <span className="text-sm text-muted-foreground hidden sm:block">
                  Hello, {authUser.name || authUser.full_name || authUser.email?.split('@')[0]}
                </span>
                <Link href="/app/dashboard" className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition text-sm font-medium">
                  <LayoutDashboard size={16} />
                  Dashboard
                </Link>
                <button onClick={handleLogout} className="flex items-center gap-1 px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition">
                  <LogOut size={15} />
                  <span className="hidden sm:block">Logout</span>
                </button>
              </>
            ) : (
              <>
                <Link href="/login" className="px-4 py-2 text-foreground hover:text-primary transition text-sm">Sign In</Link>
                <Link href="/register" className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition text-sm font-medium">Get Started</Link>
              </>
            )}
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="text-center"
        >
          <h1 className="text-5xl md:text-6xl font-bold text-foreground mb-6 leading-tight">
            SACCO & Investment Management System
          </h1>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto mb-8 leading-relaxed">
            Xhaira empowers Savings and Credit Cooperative Organizations with intelligent tools to manage members, loans, savings, and investments. Secure, transparent, and built for growth.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/register" className="px-8 py-3 bg-primary text-primary-foreground rounded-lg font-semibold hover:bg-primary/90 transition flex items-center justify-center gap-2">
              <Zap size={20} />
              Get Started with Xhaira
            </Link>
            <Link href="/login" className="px-8 py-3 border border-border text-foreground rounded-lg font-semibold hover:bg-surface-50 transition">
              Sign In to Account
            </Link>
          </div>
        </motion.div>
      </section>

      {/* Value Proposition */}
      <section className="bg-surface-50 py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-foreground text-center mb-16">
            Comprehensive SACCO Management
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: Users,
                title: "Member Management",
                description: "Track and manage SACCO members with complete profiles, membership history, and contribution records. Enable secure member self-service access."
              },
              {
                icon: BarChart3,
                title: "Loan Administration",
                description: "Manage custom loan products with flexible terms, interest calculations, and repayment schedules. Automated ledger posting and payment tracking."
              },
              {
                icon: TrendingUp,
                title: "Investment Tracking",
                description: "Monitor member investments and savings accounts with real-time balance calculations. Track returns and ensure transparency across all portfolios."
              }
            ].map((item, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.2 }}
                className="bg-background border border-border rounded-xl p-8"
              >
                <item.icon size={40} className="text-primary mb-4" />
                <h3 className="text-xl font-semibold text-foreground mb-3">{item.title}</h3>
                <p className="text-muted-foreground">{item.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Deal Pipeline Section */}
      <section className="py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
            >
              <h2 className="text-4xl font-bold text-foreground mb-6">
                Secure Ledger & Transparency
              </h2>
              <p className="text-lg text-muted-foreground mb-6">
                Every transaction is recorded with complete audit trails. Members can view their accounts in real-time, and administrators have full visibility into SACCO operations.
              </p>
              <ul className="space-y-4">
                {[
                  "Complete member account ledgers",
                  "Real-time balance updates",
                  "Transparent loan approval workflows",
                  "Member access to transaction history",
                  "Compliance-ready audit trails"
                ].map((item, idx) => (
                  <li key={idx} className="flex gap-3">
                    <span className="text-primary font-bold">✓</span>
                    <span className="text-foreground">{item}</span>
                  </li>
                ))}
              </ul>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="bg-surface-50 rounded-xl p-8 border border-border"
            >
              <div className="space-y-4">
                <div className="text-center pb-4 border-b border-border">
                  <p className="text-sm text-muted-foreground">Total Member Savings</p>
                  <p className="text-3xl font-bold text-foreground">UGX 125.4M</p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-muted-foreground">Active Members</p>
                    <p className="text-xl font-bold text-primary">248</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Outstanding Loans</p>
                    <p className="text-xl font-bold text-primary">UGX 78.5M</p>
                  </div>
                </div>
                <div className="space-y-2 pt-4">
                  {['Savings Accounts', 'Active Loans', 'Investments'].map((stage) => (
                    <div key={stage} className="text-xs">
                      <div className="flex justify-between mb-1">
                        <span className="text-muted-foreground">{stage}</span>
                        <span className="font-semibold text-foreground">100%</span>
                      </div>
                      <div className="w-full bg-surface-200 rounded-full h-2">
                        <div className="bg-primary h-2 rounded-full" style={{width: '85%'}}></div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Key Features */}
      <section className="bg-surface-50 py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-foreground text-center mb-16">
            Enterprise-Grade Capabilities
          </h2>
          <div className="grid md:grid-cols-2 gap-8">
            {[
              {
                icon: Shield,
                title: "Security & Compliance",
                features: [
                  "Enterprise-grade encryption",
                  "Role-based access control",
                  "Complete audit logging",
                  "GDPR-ready compliance"
                ]
              },
              {
                icon: BarChart3,
                title: "Advanced Reporting",
                features: [
                  "Member financial reports",
                  "Loan portfolio analytics",
                  "Investment performance tracking",
                  "Customizable dashboards"
                ]
              }
            ].map((item, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.2 }}
                className="bg-background border border-border rounded-xl p-8"
              >
                <item.icon size={40} className="text-primary mb-4" />
                <h3 className="text-xl font-semibold text-foreground mb-6">{item.title}</h3>
                <ul className="space-y-3">
                  {item.features.map((feature, fidx) => (
                    <li key={fidx} className="flex gap-3 text-muted-foreground">
                      <span className="text-primary font-bold">→</span>
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Dashboard Overview */}
      <section className="py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-foreground text-center mb-6">
            SACCO Analytics at a Glance
          </h2>
          <p className="text-xl text-muted-foreground text-center max-w-3xl mx-auto mb-12">
            Real-time visibility into your SACCO's financial health, member engagement, and portfolio performance.
          </p>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            className="bg-surface-50 rounded-xl border border-border p-8 md:p-12"
          >
            <div className="grid md:grid-cols-4 gap-6 mb-8">
              {[
                { label: "Total Members", value: "248", color: "text-blue-600" },
                { label: "Total Savings", value: "UGX 125M", color: "text-green-600" },
                { label: "Outstanding Loans", value: "UGX 78M", color: "text-orange-600" },
                { label: "Loan Recovery Rate", value: "96.2%", color: "text-primary" }
              ].map((metric, idx) => (
                <div key={idx} className="text-center">
                  <p className="text-sm text-muted-foreground mb-2">{metric.label}</p>
                  <p className={`text-2xl font-bold ${metric.color}`}>{metric.value}</p>
                </div>
              ))}
            </div>
            <div className="text-center">
              <p className="text-sm text-muted-foreground">All metrics updated in real-time</p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-r from-primary to-primary/80 py-20 px-4 text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
        >
          <h2 className="text-4xl font-bold text-primary-foreground mb-6">
            Empower Your SACCO with Xhaira
          </h2>
          <p className="text-lg text-primary-foreground/90 max-w-2xl mx-auto mb-8">
            Join SACCOs across the region using Xhaira to manage thousands of members and billions in accumulated savings and investments.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            {authUser ? (
              <Link href="/app/dashboard" className="flex items-center justify-center gap-2 px-8 py-4 bg-primary-foreground text-primary rounded-lg font-bold hover:bg-surface-50 transition">
                <LayoutDashboard size={20} />
                Go to Dashboard
              </Link>
            ) : (
              <>
                <Link href="/register" className="px-8 py-4 bg-primary-foreground text-primary rounded-lg font-bold hover:bg-surface-50 transition">
                  Create Free Account
                </Link>
                <Link href="/login" className="px-8 py-4 border-2 border-primary-foreground text-primary-foreground rounded-lg font-bold hover:bg-primary-foreground/10 transition">
                  Sign In
                </Link>
              </>
            )}
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="bg-surface-50 border-t border-border py-12 px-4">
        <div className="max-w-6xl mx-auto text-center">
          <p className="text-muted-foreground mb-4">
            Xhaira - Enterprise Financial Intelligence
          </p>
          <p className="text-sm text-muted-foreground">
            © {new Date().getFullYear()} Xhaira. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}

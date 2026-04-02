'use client';

/**
 * Xhaira SACCO Dashboard
 * ─────────────────────────────────────────────────────────────────────────────
 * Role-based SACCO dashboard showing member stats, loan portfolio,
 * savings/shares summary, financial overview, recent transactions.
 *
 * Widgets are permission-gated. All data fetches are safe (no crashes).
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { useEffect, useState } from 'react';
import {
  Users, DollarSign, TrendingUp, ArrowDownRight, ArrowUpRight,
  Wallet, Activity, Shield, UserCheck, CreditCard, Banknote,
  PieChart, BarChart3, Clock, CheckCircle, AlertTriangle,
} from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { formatCurrency } from '@/lib/format-currency';
import { usePermissions } from '@/components/providers/PermissionProvider';
import Link from 'next/link';

// ─── Helpers ────────────────────────────────────────────────────────────────

function fmt(n, currency = 'UGX') {
  if (n === null || n === undefined) return formatCurrency(0, currency);
  const num = parseFloat(n);
  if (num >= 1_000_000_000) return `${currency} ${(num / 1_000_000_000).toFixed(1)}B`;
  if (num >= 1_000_000)     return `${currency} ${(num / 1_000_000).toFixed(1)}M`;
  if (num >= 1_000)         return `${currency} ${(num / 1_000).toFixed(1)}K`;
  return formatCurrency(num, currency);
}

// ─── Reusable Components ─────────────────────────────────────────────────────

function StatCard({ title, value, subtitle, icon: Icon, color = 'blue', href }) {
  const colors = {
    blue:   'from-blue-500 to-blue-600',
    green:  'from-emerald-500 to-emerald-600',
    purple: 'from-purple-500 to-purple-600',
    orange: 'from-orange-500 to-orange-600',
    rose:   'from-rose-500 to-rose-600',
    cyan:   'from-cyan-500 to-cyan-600',
    amber:  'from-amber-500 to-amber-600',
    indigo: 'from-indigo-500 to-indigo-600',
  };
  const inner = (
    <div className={`bg-gradient-to-br ${colors[color]} rounded-xl p-5 text-white shadow-lg h-full`}>
      <div className="flex items-center justify-between mb-3">
        <Icon className="w-5 h-5 opacity-80" />
      </div>
      <div className="text-2xl font-bold">{value}</div>
      <div className="text-sm font-medium mt-1">{title}</div>
      {subtitle && <div className="text-xs opacity-75 mt-1">{subtitle}</div>}
    </div>
  );
  return href ? (
    <Link href={href} className="block hover:opacity-90 transition">{inner}</Link>
  ) : inner;
}

function SectionCard({ title, href, linkLabel, children, icon: Icon }) {
  return (
    <div className="bg-card rounded-xl border border-border p-5">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-foreground flex items-center gap-2">
          {Icon && <Icon className="w-4 h-4 text-muted-foreground" />}
          {title}
        </h2>
        {href && (
          <Link href={href} className="text-sm text-blue-600 hover:underline">
            {linkLabel || 'View all →'}
          </Link>
        )}
      </div>
      {children}
    </div>
  );
}

function EmptyState({ message }) {
  return <p className="text-muted-foreground text-sm py-6 text-center">{message}</p>;
}

// ─── Dashboard Page ──────────────────────────────────────────────────────────

export default function DashboardPage() {
  const [data, setData]       = useState(null);
  const [loading, setLoading] = useState(true);

  const { user, hasPermission, hasModuleAccess, loading: permLoading } = usePermissions();

  const can = (perm) => {
    if (!user) return false;
    if (user.is_superadmin) return true;
    return hasPermission(perm) || hasModuleAccess(perm.split('.')[0]);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res  = await fetchWithAuth('/api/dashboard');
        const json = await res.json();
        if (json.success) setData(json.data);
      } catch (err) {
        console.error('Dashboard fetch failed:', err);
      } finally {
        setLoading(false);
      }
    };

    if (!permLoading) {
      fetchData();
      const interval = setInterval(fetchData, 60000);
      return () => clearInterval(interval);
    }
  }, [permLoading]);

  if (loading || permLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  const d   = data || {};
  const wd  = d.widgetData || {};

  const sacco  = wd.sacco_overview  || {};
  const loans  = wd.loan_portfolio  || {};
  const savings= wd.savings_summary || {};
  const fin    = wd.financial_summary    || {};
  const admin  = wd.admin_overview  || {};

  const roleLabel = user?.is_superadmin
    ? 'Superadmin'
    : (user?.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : 'User');

  const isAdmin = user?.is_superadmin || user?.role === 'admin';

  return (
    <div className="space-y-6 p-6">

      {/* ── Header ──────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">
            {isAdmin ? 'SACCO Dashboard' : `${roleLabel} Dashboard`}
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            {user?.name || user?.email} · {roleLabel} · Xhaira SACCO
          </p>
        </div>
        <div className="text-xs text-muted-foreground">Auto-refreshes every 60s</div>
      </div>

      {/* ── Members KPI Row (members.view) ──────────────────────────────── */}
      {can('members.view') && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Total Members"
            value={sacco.total_members ?? '—'}
            subtitle="Registered members"
            icon={Users}
            color="blue"
            href="/app/members"
          />
          <StatCard
            title="Active Members"
            value={sacco.active_members ?? '—'}
            subtitle={`${sacco.new_this_month ?? 0} joined this month`}
            icon={UserCheck}
            color="green"
            href="/app/members"
          />
          <StatCard
            title="Member Accounts"
            value={sacco.total_accounts ?? '—'}
            subtitle="Savings, shares & loans"
            icon={CreditCard}
            color="indigo"
            href="/app/account-types"
          />
          {can('finance.view') && (
            <StatCard
              title="Total Savings"
              value={fmt(savings.total_savings)}
              subtitle={`${savings.saving_members ?? 0} saving members`}
              icon={Wallet}
              color="cyan"
              href="/app/transactions"
            />
          )}
        </div>
      )}

      {/* ── Loan + Savings KPI Row (finance.view) ───────────────────────── */}
      {can('finance.view') && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Active Loans"
            value={loans.active_loans ?? '—'}
            subtitle={`${loans.pending_loans ?? 0} pending approval`}
            icon={Banknote}
            color="purple"
            href="/app/loans"
          />
          <StatCard
            title="Total Disbursed"
            value={fmt(loans.total_disbursed)}
            subtitle={`${loans.overdue_loans ?? 0} overdue`}
            icon={TrendingUp}
            color={parseInt(loans.overdue_loans) > 0 ? 'orange' : 'green'}
            href="/app/loans"
          />
          <StatCard
            title="Share Capital"
            value={fmt(savings.total_shares)}
            subtitle="Member shares"
            icon={PieChart}
            color="amber"
            href="/app/account-types"
          />
          <StatCard
            title="Net Position"
            value={fmt(fin.net_position)}
            subtitle={`${fin.total_transactions ?? 0} total transactions`}
            icon={DollarSign}
            color={parseFloat(fin.net_position) >= 0 ? 'green' : 'rose'}
            href="/app/finance"
          />
        </div>
      )}

      {/* ── Loan Portfolio + Recent Transactions ────────────────────────── */}
      {can('finance.view') && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

          {/* Loan Portfolio */}
          <SectionCard title="Loan Portfolio" href="/app/loans" linkLabel="Manage →" icon={Banknote}>
            <div className="space-y-3">
              <div className="flex items-center justify-between py-2 border-b border-border">
                <span className="text-sm text-muted-foreground">Active Loans</span>
                <div className="flex items-center gap-2">
                  <CheckCircle className="w-3.5 h-3.5 text-emerald-500" />
                  <span className="text-sm font-bold text-foreground">{loans.active_loans ?? '—'}</span>
                </div>
              </div>
              <div className="flex items-center justify-between py-2 border-b border-border">
                <span className="text-sm text-muted-foreground">Total Disbursed</span>
                <span className="text-sm font-bold text-blue-600">{fmt(loans.total_disbursed)}</span>
              </div>
              <div className="flex items-center justify-between py-2 border-b border-border">
                <span className="text-sm text-muted-foreground">Pending Approval</span>
                <div className="flex items-center gap-2">
                  <Clock className="w-3.5 h-3.5 text-amber-500" />
                  <span className="text-sm font-bold">{loans.pending_loans ?? 0}</span>
                </div>
              </div>
              <div className="flex items-center justify-between py-2">
                <span className="text-sm text-muted-foreground">Overdue</span>
                <div className="flex items-center gap-2">
                  <AlertTriangle className={`w-3.5 h-3.5 ${parseInt(loans.overdue_loans) > 0 ? 'text-red-500' : 'text-muted-foreground'}`} />
                  <span className={`text-sm font-bold ${parseInt(loans.overdue_loans) > 0 ? 'text-red-600' : 'text-foreground'}`}>
                    {loans.overdue_loans ?? 0}
                  </span>
                </div>
              </div>
            </div>
          </SectionCard>

          {/* Recent Transactions */}
          <SectionCard title="Recent Transactions" href="/app/transactions" icon={Activity}>
            {(wd.recent_transactions || []).length === 0 ? (
              <EmptyState message="No transactions yet" />
            ) : (
              <div className="space-y-2">
                {(wd.recent_transactions || []).map((t) => (
                  <div key={t.id} className="flex items-center justify-between text-sm py-1 border-b border-border/50 last:border-0">
                    <div>
                      <span className="font-medium capitalize">{t.type}</span>
                      {t.description && <span className="text-muted-foreground ml-1 text-xs">— {t.description}</span>}
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`font-bold text-xs ${t.type === 'credit' || t.type === 'deposit' ? 'text-emerald-600' : 'text-red-600'}`}>
                        {fmt(t.amount, t.currency || 'UGX')}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {new Date(t.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </SectionCard>
        </div>
      )}

      {/* ── Financial Summary + Account Balances ────────────────────────── */}
      {can('finance.view') && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

          {/* Monthly Trend */}
          {(wd.monthly_financials || []).length > 0 && (
            <SectionCard title="Monthly Financial Trend" icon={BarChart3}>
              <div className="grid grid-cols-3 gap-2">
                {(wd.monthly_financials || []).slice(0, 6).reverse().map((m, i) => {
                  const income   = parseFloat(m.income   || 0);
                  const expenses = parseFloat(m.expenses || 0);
                  const net      = income - expenses;
                  return (
                    <div key={i} className="text-center p-2.5 rounded-lg bg-muted/50">
                      <div className="text-xs text-muted-foreground mb-1.5">{m.month || m.period}</div>
                      <div className="text-xs text-emerald-600">+{fmt(income)}</div>
                      <div className="text-xs text-red-500">-{fmt(expenses)}</div>
                      <div className={`text-xs font-bold mt-1 ${net >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                        {fmt(net)}
                      </div>
                    </div>
                  );
                })}
              </div>
            </SectionCard>
          )}

          {/* Company Account Balances */}
          {(wd.account_balances || []).length > 0 && (
            <SectionCard title="Company Accounts" href="/app/finance/accounts" linkLabel="Manage →" icon={Wallet}>
              <div className="space-y-3">
                {(wd.account_balances || []).slice(0, 5).map((acct) => (
                  <div key={acct.account_id} className="flex items-center justify-between">
                    <div>
                      <div className="text-sm font-medium">{acct.name}</div>
                      <div className="text-xs text-muted-foreground capitalize">{acct.type}</div>
                    </div>
                    <span className={`text-sm font-bold ${parseFloat(acct.balance) >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                      {fmt(acct.balance)}
                    </span>
                  </div>
                ))}
              </div>
            </SectionCard>
          )}
        </div>
      )}

      {/* ── Admin Overview (users.view + staff.view) ─────────────────────── */}
      {(can('users.view') || can('staff.view')) && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {can('users.view') && (
            <Link href="/app/admin/users">
              <div className="bg-card rounded-xl border p-4 hover:border-blue-300 transition cursor-pointer">
                <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                  <Users className="w-3.5 h-3.5" />System Users
                </div>
                <div className="text-xl font-bold text-foreground">{admin.total_users ?? '—'}</div>
              </div>
            </Link>
          )}
          {can('staff.view') && (
            <Link href="/app/staff">
              <div className="bg-card rounded-xl border p-4 hover:border-blue-300 transition cursor-pointer">
                <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                  <UserCheck className="w-3.5 h-3.5" />Staff Members
                </div>
                <div className="text-xl font-bold text-foreground">{admin.total_staff ?? '—'}</div>
              </div>
            </Link>
          )}
          {can('members.view') && (
            <Link href="/app/members">
              <div className="bg-card rounded-xl border p-4 hover:border-blue-300 transition cursor-pointer">
                <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                  <Users className="w-3.5 h-3.5" />SACCO Members
                </div>
                <div className="text-xl font-bold text-foreground">{admin.total_members ?? sacco.total_members ?? '—'}</div>
              </div>
            </Link>
          )}
          {can('roles.manage') && (
            <Link href="/app/admin/roles">
              <div className="bg-card rounded-xl border p-4 hover:border-blue-300 transition cursor-pointer">
                <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                  <Shield className="w-3.5 h-3.5" />Roles
                </div>
                <div className="text-xl font-bold text-foreground">{admin.total_roles ?? '—'}</div>
              </div>
            </Link>
          )}
        </div>
      )}

      {/* ── Recent Activity ──────────────────────────────────────────────── */}
      {(can('activity_logs.view') || isAdmin) && (wd.recent_activity || []).length > 0 && (
        <SectionCard title="Recent Activity" icon={Activity}>
          <div className="space-y-2">
            {(wd.recent_activity || []).slice(0, 8).map((a, i) => (
              <div key={i} className="flex items-center justify-between text-sm py-1 border-b border-border/50 last:border-0">
                <div>
                  <span className="font-medium capitalize">{a.action}</span>
                  <span className="text-muted-foreground ml-1 text-xs">{a.entity_type}</span>
                </div>
                <span className="text-xs text-muted-foreground">
                  {new Date(a.created_at).toLocaleDateString()}
                </span>
              </div>
            ))}
          </div>
        </SectionCard>
      )}

      {/* ── No-access fallback ───────────────────────────────────────────── */}
      {!can('finance.view') && !can('members.view') && !can('users.view') && (
        <div className="bg-card rounded-xl border border-border p-8 text-center">
          <Shield className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
          <p className="text-foreground font-medium mb-1">Limited Access</p>
          <p className="text-sm text-muted-foreground">
            Your role does not have access to dashboard modules.
            Contact your administrator to request additional permissions.
          </p>
        </div>
      )}
    </div>
  );
}

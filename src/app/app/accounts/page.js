'use client';

import { useEffect, useState } from 'react';
import { CreditCard, TrendingUp, Wallet, PieChart, ArrowRight, Plus } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import Link from 'next/link';

function fmtCurrency(amount, currency = 'UGX') {
  const n = parseFloat(amount || 0);
  if (n >= 1_000_000) return `${currency} ${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `${currency} ${(n / 1_000).toFixed(1)}K`;
  return `${currency} ${Math.round(n).toLocaleString()}`;
}

const TYPE_ICONS = {
  VOL_SAV:   { icon: Wallet,    color: 'text-blue-600',   bg: 'bg-blue-100 dark:bg-blue-900/30' },
  FIXED_SAV: { icon: TrendingUp, color: 'text-emerald-600', bg: 'bg-emerald-100 dark:bg-emerald-900/30' },
  SHARES:    { icon: PieChart,  color: 'text-purple-600', bg: 'bg-purple-100 dark:bg-purple-900/30' },
  LOAN_ACC:  { icon: CreditCard, color: 'text-amber-600',  bg: 'bg-amber-100 dark:bg-amber-900/30' },
  INVEST:    { icon: TrendingUp, color: 'text-indigo-600', bg: 'bg-indigo-100 dark:bg-indigo-900/30' },
  CASH:      { icon: Wallet,    color: 'text-gray-600',   bg: 'bg-gray-100 dark:bg-gray-800' },
};

export default function AccountsPage() {
  const [accountTypes, setAccountTypes] = useState([]);
  const [summary, setSummary]           = useState([]);
  const [loading, setLoading]           = useState(true);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [typesRes, summaryRes] = await Promise.all([
          fetchWithAuth('/api/account-types'),
          fetchWithAuth('/api/members/accounts/summary').catch(() => null),
        ]);
        const typesJson = await typesRes.json();
        if (typesJson.success) setAccountTypes(typesJson.data || []);
        if (summaryRes) {
          const summaryJson = await summaryRes.json().catch(() => ({}));
          if (summaryJson.success) setSummary(summaryJson.data || []);
        }
      } catch (err) {
        console.error('Accounts page fetch failed:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchAll();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 max-w-5xl">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Accounts</h1>
          <p className="text-sm text-muted-foreground mt-1">
            SACCO member accounts — savings, shares, loans, and investments.
          </p>
        </div>
        <Link
          href="/app/account-types"
          className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition"
        >
          <Plus className="w-4 h-4" /> Manage Types
        </Link>
      </div>

      {/* Account Type Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {accountTypes.length === 0 ? (
          <div className="col-span-3 text-center py-12 text-muted-foreground text-sm">
            No account types configured yet.{' '}
            <Link href="/app/account-types" className="text-blue-600 hover:underline">Set up account types →</Link>
          </div>
        ) : (
          accountTypes.map((type) => {
            const cfg = TYPE_ICONS[type.code] || TYPE_ICONS.CASH;
            const Icon = cfg.icon;
            return (
              <div key={type.id} className="bg-card border border-border rounded-xl p-5 hover:border-blue-300 transition">
                <div className="flex items-start justify-between mb-4">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${cfg.bg}`}>
                    <Icon className={`w-5 h-5 ${cfg.color}`} />
                  </div>
                  <span className="text-xs font-mono text-muted-foreground bg-muted px-2 py-0.5 rounded">
                    {type.code}
                  </span>
                </div>
                <h3 className="font-semibold text-foreground">{type.name}</h3>
                {type.description && (
                  <p className="text-xs text-muted-foreground mt-1">{type.description}</p>
                )}
                <div className="mt-3 pt-3 border-t border-border grid grid-cols-2 gap-2 text-xs">
                  {type.minimum_balance != null && (
                    <div>
                      <div className="text-muted-foreground">Min Balance</div>
                      <div className="font-medium">{fmtCurrency(type.minimum_balance)}</div>
                    </div>
                  )}
                  {type.interest_rate != null && (
                    <div>
                      <div className="text-muted-foreground">Interest Rate</div>
                      <div className="font-medium">{parseFloat(type.interest_rate || 0).toFixed(1)}% p.a.</div>
                    </div>
                  )}
                  <div>
                    <div className="text-muted-foreground">Withdrawals</div>
                    <div className={`font-medium ${type.allows_withdrawal ? 'text-emerald-600' : 'text-red-500'}`}>
                      {type.allows_withdrawal ? 'Allowed' : 'Restricted'}
                    </div>
                  </div>
                  <div>
                    <div className="text-muted-foreground">Status</div>
                    <div className={`font-medium capitalize ${type.is_active !== false ? 'text-emerald-600' : 'text-gray-500'}`}>
                      {type.is_active !== false ? 'Active' : 'Inactive'}
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Quick Links */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[
          { label: 'All Members', href: '/app/members', desc: 'View member accounts & balances' },
          { label: 'Transactions', href: '/app/transactions', desc: 'Double-entry ledger history' },
          { label: 'Member Transfers', href: '/app/member-transfers', desc: 'Peer-to-peer transfers' },
        ].map((link) => (
          <Link key={link.href} href={link.href}
            className="bg-card border border-border rounded-xl p-4 flex items-center justify-between hover:border-blue-300 transition group">
            <div>
              <div className="text-sm font-semibold text-foreground">{link.label}</div>
              <div className="text-xs text-muted-foreground mt-0.5">{link.desc}</div>
            </div>
            <ArrowRight className="w-4 h-4 text-muted-foreground group-hover:text-blue-600 transition" />
          </Link>
        ))}
      </div>
    </div>
  );
}

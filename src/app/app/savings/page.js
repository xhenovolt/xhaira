'use client';

/**
 * /app/savings
 * SACCO Savings Management — Deposit, Withdraw, View balances + behaviors
 */

import { useEffect, useState, useCallback } from 'react';
import { fetchWithAuth }     from '@/lib/fetch-client';
import { formatCurrency }    from '@/lib/format-currency';
import { usePermissions }    from '@/components/providers/PermissionProvider';
import Link                  from 'next/link';
import {
  Wallet, ArrowDownLeft, ArrowUpRight, RefreshCw,
  AlertTriangle, CheckCircle, Info, Shield, Lock, Unlock,
  Clock, TrendingUp, Search, ChevronDown,
} from 'lucide-react';

const fmtUGX = n => formatCurrency(Number(n ?? 0), 'UGX');

// ─── Behavior Badge ───────────────────────────────────────────────────────────
function BehaviorBadge({ label, enabled }) {
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
      enabled
        ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
        : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    }`}>
      {enabled ? <Unlock className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
      {label}
    </span>
  );
}

// ─── Transaction Modal ────────────────────────────────────────────────────────
function TransactionModal({ account, action, onClose, onSuccess }) {
  const [amount,      setAmount]      = useState('');
  const [description, setDescription] = useState('');
  const [reference,   setReference]   = useState('');
  const [loading,     setLoading]     = useState(false);
  const [error,       setError]       = useState('');

  async function submit(e) {
    e.preventDefault();
    if (!amount || parseFloat(amount) <= 0) return setError('Enter a valid amount');
    setLoading(true);
    setError('');
    try {
      const res  = await fetchWithAuth('/api/savings', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({
          action,
          member_account_id: account.member_account_id,
          amount:            parseFloat(amount),
          description,
          reference,
        }),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.error);
      onSuccess(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  const isWithdraw = action === 'withdraw';
  const canWithdraw = account.allows_withdrawal !== false;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-card border border-border rounded-xl p-6 w-full max-w-md shadow-2xl">
        <h2 className="text-lg font-bold mb-1 flex items-center gap-2">
          {isWithdraw
            ? <ArrowUpRight className="w-5 h-5 text-rose-500" />
            : <ArrowDownLeft className="w-5 h-5 text-emerald-500" />
          }
          {isWithdraw ? 'Withdraw' : 'Deposit'}
        </h2>
        <p className="text-sm text-muted-foreground mb-4">
          {account.full_name} · {account.account_type_name} · Balance: {fmtUGX(account.balance)}
        </p>

        {isWithdraw && !canWithdraw && (
          <div className="bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800 rounded-lg p-3 mb-4 flex gap-2 text-sm text-red-700 dark:text-red-300">
            <Lock className="w-4 h-4 shrink-0 mt-0.5" />
            Withdrawals are blocked for this account type.
          </div>
        )}

        {isWithdraw && account.requires_maturity && (
          <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 rounded-lg p-3 mb-4 flex gap-2 text-sm text-amber-700 dark:text-amber-300">
            <Clock className="w-4 h-4 shrink-0 mt-0.5" />
            Maturity required: {account.maturity_period_days} days
          </div>
        )}

        {isWithdraw && account.min_balance > 0 && (
          <div className="bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800 rounded-lg p-3 mb-4 flex gap-2 text-sm text-blue-700 dark:text-blue-300">
            <Info className="w-4 h-4 shrink-0 mt-0.5" />
            Min balance: {fmtUGX(account.min_balance)}
          </div>
        )}

        <form onSubmit={submit} className="space-y-3">
          <div>
            <label className="block text-sm font-medium mb-1">Amount (UGX)</label>
            <input
              type="number" min="1" step="1" required
              className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
              value={amount} onChange={e => setAmount(e.target.value)}
              placeholder="0"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Description</label>
            <input
              type="text"
              className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
              value={description} onChange={e => setDescription(e.target.value)}
              placeholder={isWithdraw ? 'Reason for withdrawal' : 'Deposit source'}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Reference (optional)</label>
            <input
              type="text"
              className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
              value={reference} onChange={e => setReference(e.target.value)}
              placeholder="Receipt / cheque number"
            />
          </div>

          {error && (
            <div className="flex items-start gap-2 text-sm text-red-600 bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800 rounded-lg p-3">
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              {error}
            </div>
          )}

          <div className="flex gap-2 pt-1">
            <button type="button" onClick={onClose}
              className="flex-1 border border-border rounded-lg py-2 text-sm font-medium text-foreground hover:bg-muted">
              Cancel
            </button>
            <button type="submit" disabled={loading || (isWithdraw && !canWithdraw)}
              className={`flex-1 rounded-lg py-2 text-sm font-medium text-white disabled:opacity-50 flex items-center justify-center gap-2 ${
                isWithdraw ? 'bg-rose-600 hover:bg-rose-700' : 'bg-emerald-600 hover:bg-emerald-700'
              }`}>
              {loading && <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
              {isWithdraw ? 'Withdraw' : 'Deposit'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function SavingsPage() {
  const { can } = usePermissions();

  const [accounts,  setAccounts]  = useState([]);
  const [loading,   setLoading]   = useState(true);
  const [search,    setSearch]    = useState('');
  const [page,      setPage]      = useState(1);
  const [totalPages,setTotalPages]= useState(1);
  const [modal,     setModal]     = useState(null); // { account, action }
  const [toast,     setToast]     = useState(null);
  const [behaviors, setBehaviors] = useState({});   // { [member_account_id]: behavior }

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const load = useCallback(async (pg = 1) => {
    setLoading(true);
    try {
      const res  = await fetchWithAuth(`/api/savings?page=${pg}&limit=20`);
      const data = await res.json();
      setAccounts(data.data || []);
      setTotalPages(data.pagination?.totalPages ?? 1);
    } catch {
      showToast('Failed to load savings accounts', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(page); }, [load, page]);

  // Lazy-load behavior for visible accounts
  useEffect(() => {
    accounts.forEach(async acc => {
      if (behaviors[acc.member_account_id]) return;
      try {
        const res  = await fetchWithAuth(`/api/savings/accounts/${acc.member_account_id}`);
        const data = await res.json();
        if (data.success) {
          setBehaviors(prev => ({ ...prev, [acc.member_account_id]: data.data }));
        }
      } catch {}
    });
  }, [accounts]);

  function handleSuccess(data) {
    showToast(`${modal.action} successful — new balance: ${fmtUGX(data.balance)}`, 'success');
    setModal(null);
    load(page);
  }

  const filtered = accounts.filter(a =>
    !search ||
    a.full_name?.toLowerCase().includes(search.toLowerCase()) ||
    a.membership_number?.toLowerCase().includes(search.toLowerCase()) ||
    a.account_number?.toLowerCase().includes(search.toLowerCase())
  );

  if (!can('finance.view')) {
    return (
      <div className="p-8 text-center">
        <Shield className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
        <p className="text-muted-foreground">You don&apos;t have access to savings management.</p>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Wallet className="w-6 h-6" /> Savings Accounts
          </h1>
          <p className="text-muted-foreground mt-1">
            Rule-validated deposits and withdrawals. All transactions post to the ledger.
          </p>
        </div>
        <div className="flex gap-2">
          <Link href="/app/settings/account-rules"
            className="text-sm border border-border rounded-lg px-3 py-2 hover:bg-muted flex items-center gap-1.5">
            <Settings className="w-4 h-4" /> Rules
          </Link>
          <button onClick={() => load(page)}
            className="text-sm border border-border rounded-lg px-3 py-2 hover:bg-muted flex items-center gap-1.5">
            <RefreshCw className="w-4 h-4" /> Refresh
          </button>
        </div>
      </div>

      {/* Search */}
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          type="text"
          className="w-full border border-border rounded-lg pl-9 pr-4 py-2 text-sm bg-background text-foreground"
          placeholder="Search by name, membership number, account number…"
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center gap-3 py-12 text-muted-foreground">
          <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin" />
          Loading…
        </div>
      ) : (
        <>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-muted/30 text-xs text-muted-foreground uppercase tracking-wide">
                  <th className="px-4 py-3 text-left">Member</th>
                  <th className="px-4 py-3 text-left">Account Type</th>
                  <th className="px-4 py-3 text-left">Behaviors</th>
                  <th className="px-4 py-3 text-right">Balance</th>
                  {can('finance.manage') && <th className="px-4 py-3 text-right">Actions</th>}
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-12 text-center text-muted-foreground">
                      No savings accounts found.
                    </td>
                  </tr>
                )}
                {filtered.map(acc => {
                  const beh = behaviors[acc.member_account_id];
                  return (
                    <tr key={acc.member_account_id} className="border-t border-border hover:bg-muted/20">
                      <td className="px-4 py-3">
                        <div className="font-medium text-foreground">{acc.full_name}</div>
                        <div className="text-xs text-muted-foreground">{acc.membership_number}</div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="font-medium">{acc.account_type_name}</div>
                        <div className="text-xs text-muted-foreground font-mono">{acc.account_type_code}</div>
                      </td>
                      <td className="px-4 py-3">
                        {beh ? (
                          <div className="flex flex-wrap gap-1">
                            <BehaviorBadge label="Withdraw" enabled={beh.allows_withdrawal} />
                            {beh.interest_rate > 0 && (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
                                <TrendingUp className="w-3 h-3" />{beh.interest_rate}%
                              </span>
                            )}
                            {beh.requires_maturity && (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
                                <Clock className="w-3 h-3" />{beh.maturity_period_days}d
                              </span>
                            )}
                          </div>
                        ) : (
                          <div className="w-24 h-4 bg-muted rounded animate-pulse" />
                        )}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <span className="font-mono font-semibold text-foreground">
                          {fmtUGX(acc.balance)}
                        </span>
                      </td>
                      {can('finance.manage') && (
                        <td className="px-4 py-3">
                          <div className="flex gap-2 justify-end">
                            <button
                              onClick={() => setModal({ account: { ...acc, ...(beh || {}) }, action: 'deposit' })}
                              className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-900/20 dark:hover:bg-emerald-900/40 text-emerald-700 dark:text-emerald-400 text-xs font-medium"
                            >
                              <ArrowDownLeft className="w-3.5 h-3.5" /> Deposit
                            </button>
                            <button
                              onClick={() => setModal({ account: { ...acc, ...(beh || {}) }, action: 'withdraw' })}
                              className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 dark:bg-rose-900/20 dark:hover:bg-rose-900/40 text-rose-700 dark:text-rose-400 text-xs font-medium"
                            >
                              <ArrowUpRight className="w-3.5 h-3.5" /> Withdraw
                            </button>
                          </div>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-2 mt-4">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                className="px-3 py-1.5 text-sm border border-border rounded-lg disabled:opacity-40 hover:bg-muted">
                Prev
              </button>
              <span className="text-sm text-muted-foreground">Page {page} / {totalPages}</span>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                className="px-3 py-1.5 text-sm border border-border rounded-lg disabled:opacity-40 hover:bg-muted">
                Next
              </button>
            </div>
          )}
        </>
      )}

      {/* Transaction Modal */}
      {modal && (
        <TransactionModal
          account={modal.account}
          action={modal.action}
          onClose={() => setModal(null)}
          onSuccess={handleSuccess}
        />
      )}

      {/* Toast */}
      {toast && (
        <div className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium flex items-center gap-2 ${
          toast.type === 'error' ? 'bg-red-600 text-white' : 'bg-emerald-600 text-white'
        }`}>
          {toast.type === 'error' ? <AlertTriangle className="w-4 h-4" /> : <CheckCircle className="w-4 h-4" />}
          {toast.message}
        </div>
      )}
    </div>
  );
}

'use client';

/**
 * /app/shares
 * SACCO Shares Management — equity ownership, purchase history, member totals
 */

import { useEffect, useState, useCallback } from 'react';
import { fetchWithAuth }   from '@/lib/fetch-client';
import { formatCurrency }  from '@/lib/format-currency';
import { usePermissions }  from '@/components/providers/PermissionProvider';
import Link                from 'next/link';
import {
  PieChart, Plus, RefreshCw, AlertTriangle, CheckCircle,
  Shield, Search, TrendingUp, Users, DollarSign,
} from 'lucide-react';

const fmtUGX = n => formatCurrency(Number(n ?? 0), 'UGX');

// ─── Purchase Modal ───────────────────────────────────────────────────────────
function PurchaseModal({ onClose, onSuccess }) {
  const [memberId,       setMemberId]       = useState('');
  const [memberAccId,    setMemberAccId]    = useState('');
  const [units,          setUnits]          = useState('');
  const [valuePerUnit,   setValuePerUnit]   = useState('1000');
  const [notes,          setNotes]          = useState('');
  const [loading,        setLoading]        = useState(false);
  const [error,          setError]          = useState('');
  const [members,        setMembers]        = useState([]);
  const [memberAccounts, setMemberAccounts] = useState([]);

  useEffect(() => {
    fetchWithAuth('/api/members?limit=200')
      .then(r => r.json())
      .then(d => setMembers(d.data || []))
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!memberId) return;
    fetchWithAuth(`/api/members/${memberId}/accounts`)
      .then(r => r.json())
      .then(d => setMemberAccounts(d.data || []))
      .catch(() => {});
  }, [memberId]);

  const totalValue = parseFloat(units || 0) * parseFloat(valuePerUnit || 0);

  async function submit(e) {
    e.preventDefault();
    if (!memberId || !units || !valuePerUnit) return setError('Member, units, and value per unit are required');
    setLoading(true);
    setError('');
    try {
      const res  = await fetchWithAuth('/api/shares', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({
          member_id:        memberId,
          member_account_id: memberAccId || undefined,
          units:             parseFloat(units),
          value_per_unit:    parseFloat(valuePerUnit),
          notes,
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-card border border-border rounded-xl p-6 w-full max-w-md shadow-2xl">
        <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
          <Plus className="w-5 h-5 text-purple-500" /> Record Share Purchase
        </h2>
        <form onSubmit={submit} className="space-y-3">
          <div>
            <label className="block text-sm font-medium mb-1">Member</label>
            <select
              required
              className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
              value={memberId}
              onChange={e => { setMemberId(e.target.value); setMemberAccId(''); }}
            >
              <option value="">Select member…</option>
              {members.map(m => (
                <option key={m.id} value={m.id}>{m.full_name} ({m.membership_number})</option>
              ))}
            </select>
          </div>

          {memberAccounts.length > 0 && (
            <div>
              <label className="block text-sm font-medium mb-1">Debit Account (optional)</label>
              <select
                className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
                value={memberAccId}
                onChange={e => setMemberAccId(e.target.value)}
              >
                <option value="">None — record share only</option>
                {memberAccounts.map(a => (
                  <option key={a.id} value={a.id}>{a.account_type_name} ({a.account_number})</option>
                ))}
              </select>
              <p className="text-xs text-muted-foreground mt-1">
                If selected, share value is debited from this account and credited to Share Capital.
              </p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1">Units</label>
              <input type="number" min="0.0001" step="0.0001" required
                className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
                value={units} onChange={e => setUnits(e.target.value)} placeholder="10" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Value / Unit (UGX)</label>
              <input type="number" min="1" step="1" required
                className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
                value={valuePerUnit} onChange={e => setValuePerUnit(e.target.value)} />
            </div>
          </div>

          {totalValue > 0 && (
            <div className="bg-purple-50 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 rounded-lg px-3 py-2 text-sm text-purple-700 dark:text-purple-300">
              Total value: <strong>{fmtUGX(totalValue)}</strong>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium mb-1">Notes (optional)</label>
            <input type="text"
              className="w-full border border-border rounded-lg px-3 py-2 text-sm bg-background text-foreground"
              value={notes} onChange={e => setNotes(e.target.value)} placeholder="Additional notes" />
          </div>

          {error && (
            <div className="flex items-start gap-2 text-sm text-red-600 bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800 rounded-lg p-3">
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" /> {error}
            </div>
          )}

          <div className="flex gap-2 pt-1">
            <button type="button" onClick={onClose}
              className="flex-1 border border-border rounded-lg py-2 text-sm font-medium hover:bg-muted">
              Cancel
            </button>
            <button type="submit" disabled={loading}
              className="flex-1 bg-purple-600 hover:bg-purple-700 text-white rounded-lg py-2 text-sm font-medium disabled:opacity-50 flex items-center justify-center gap-2">
              {loading && <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
              Record Purchase
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function SharesPage() {
  const { can } = usePermissions();

  const [summary,   setSummary]   = useState([]);
  const [purchases, setPurchases] = useState([]);
  const [loading,   setLoading]   = useState(true);
  const [search,    setSearch]    = useState('');
  const [showModal, setShowModal] = useState(false);
  const [toast,     setToast]     = useState(null);
  const [totals,    setTotals]    = useState({ total_units: 0, total_value: 0, members: 0 });

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res  = await fetchWithAuth('/api/shares?limit=100');
      const data = await res.json();
      setSummary(data.summary   || []);
      setPurchases(data.data    || []);

      const tots = (data.summary || []).reduce(
        (acc, m) => ({
          total_units: acc.total_units + parseFloat(m.total_units  ?? 0),
          total_value: acc.total_value + parseFloat(m.total_value  ?? 0),
          members:     acc.members + 1,
        }),
        { total_units: 0, total_value: 0, members: 0 }
      );
      setTotals(tots);
    } catch {
      showToast('Failed to load shares data', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  function handleSuccess() {
    showToast('Share purchase recorded', 'success');
    setShowModal(false);
    load();
  }

  const filteredSummary = summary.filter(m =>
    !search ||
    m.full_name?.toLowerCase().includes(search.toLowerCase()) ||
    m.membership_number?.toLowerCase().includes(search.toLowerCase())
  );

  if (!can('finance.view')) {
    return (
      <div className="p-8 text-center">
        <Shield className="w-10 h-10 text-muted-foreground mx-auto mb-3" />
        <p className="text-muted-foreground">You don&apos;t have access to shares management.</p>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <PieChart className="w-6 h-6" /> Share Capital
          </h1>
          <p className="text-muted-foreground mt-1">
            Member equity ownership. Shares determine loan eligibility and dividend allocation.
          </p>
        </div>
        <div className="flex gap-2">
          {can('finance.manage') && (
            <button onClick={() => setShowModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg text-sm font-medium hover:bg-purple-700">
              <Plus className="w-4 h-4" /> Record Purchase
            </button>
          )}
          <button onClick={load}
            className="text-sm border border-border rounded-lg px-3 py-2 hover:bg-muted flex items-center gap-1.5">
            <RefreshCw className="w-4 h-4" /> Refresh
          </button>
        </div>
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'Total Members with Shares', value: totals.members,                        icon: Users,       color: 'from-purple-500 to-purple-600' },
          { label: 'Total Share Units',          value: totals.total_units.toLocaleString(),   icon: PieChart,    color: 'from-indigo-500 to-indigo-600' },
          { label: 'Total Share Capital',        value: fmtUGX(totals.total_value),            icon: DollarSign,  color: 'from-blue-500 to-blue-600' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className={`bg-gradient-to-br ${color} rounded-xl p-4 text-white shadow-md`}>
            <Icon className="w-5 h-5 opacity-80 mb-2" />
            <div className="text-2xl font-bold">{loading ? '—' : value}</div>
            <div className="text-sm opacity-90 mt-1">{label}</div>
          </div>
        ))}
      </div>

      {/* Search */}
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input type="text"
          className="w-full border border-border rounded-lg pl-9 pr-4 py-2 text-sm bg-background text-foreground"
          placeholder="Search by name or membership number…"
          value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Member Summary Table */}
      {loading ? (
        <div className="flex items-center gap-3 py-12 text-muted-foreground">
          <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin" />
          Loading…
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-muted/30 text-xs text-muted-foreground uppercase tracking-wide">
                <th className="px-4 py-3 text-left">Member</th>
                <th className="px-4 py-3 text-right">Total Units</th>
                <th className="px-4 py-3 text-right">Total Value (UGX)</th>
                <th className="px-4 py-3 text-right">Purchases</th>
                <th className="px-4 py-3 text-right">Share %</th>
                <th className="px-4 py-3 text-right">Last Purchase</th>
              </tr>
            </thead>
            <tbody>
              {filteredSummary.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-muted-foreground">
                    No share records found.
                  </td>
                </tr>
              )}
              {filteredSummary.map(m => {
                const sharePercent = totals.total_units > 0
                  ? ((parseFloat(m.total_units) / totals.total_units) * 100).toFixed(2)
                  : '0.00';
                return (
                  <tr key={m.member_id} className="border-t border-border hover:bg-muted/20">
                    <td className="px-4 py-3">
                      <div className="font-medium text-foreground">{m.full_name}</div>
                      <div className="text-xs text-muted-foreground">{m.membership_number}</div>
                    </td>
                    <td className="px-4 py-3 text-right font-mono">
                      {parseFloat(m.total_units).toLocaleString()}
                    </td>
                    <td className="px-4 py-3 text-right font-mono font-semibold">
                      {fmtUGX(m.total_value)}
                    </td>
                    <td className="px-4 py-3 text-right text-muted-foreground">
                      {m.purchase_count}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <div className="w-16 bg-muted rounded-full h-1.5">
                          <div className="bg-purple-500 h-1.5 rounded-full" style={{ width: `${Math.min(100, parseFloat(sharePercent))}%` }} />
                        </div>
                        <span className="text-xs text-muted-foreground w-12 text-right">{sharePercent}%</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right text-xs text-muted-foreground">
                      {m.last_purchase_at ? new Date(m.last_purchase_at).toLocaleDateString() : '—'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Purchase Modal */}
      {showModal && (
        <PurchaseModal onClose={() => setShowModal(false)} onSuccess={handleSuccess} />
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

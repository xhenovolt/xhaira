'use client';

import { useEffect, useState } from 'react';
import { Banknote, Plus, Search, Clock, CheckCircle2, XCircle, AlertTriangle } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const STATUS_STYLES = {
  PENDING: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  APPROVED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  DISBURSED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  REJECTED: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  ACTIVE: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  COMPLETED: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
  DEFAULTED: 'bg-red-200 text-red-800 dark:bg-red-900/40 dark:text-red-300',
  WRITTEN_OFF: 'bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-500',
};

const STATUS_ICONS = {
  PENDING: Clock, APPROVED: CheckCircle2, DISBURSED: Banknote, REJECTED: XCircle,
  ACTIVE: Banknote, COMPLETED: CheckCircle2, DEFAULTED: AlertTriangle,
};

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

export default function LoansPage() {
  const [loans, setLoans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [members, setMembers] = useState([]);
  const [products, setProducts] = useState([]);
  const [memberAccounts, setMemberAccounts] = useState([]);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const [form, setForm] = useState({
    member_id: '', product_id: '', member_account_id: '', principal: '',
  });

  const fetchLoans = async () => {
    try {
      const params = new URLSearchParams();
      if (statusFilter) params.set('status', statusFilter);
      const res = await fetchWithAuth(`/api/loans?${params}`);
      const json = await res.json();
      if (json.success) setLoans(json.data || []);
    } catch (err) {
      console.error('Failed to fetch loans:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchLoans(); }, [statusFilter]);

  // Fetch members and products when form opens
  useEffect(() => {
    if (!showForm) return;
    Promise.all([
      fetchWithAuth('/api/members?limit=200').then(r => r.json()),
      fetchWithAuth('/api/sacco-products?type=LOAN&active=true').then(r => r.json()),
    ]).then(([membersJson, productsJson]) => {
      if (membersJson.success) setMembers(membersJson.data || []);
      if (productsJson.success) setProducts(productsJson.data || []);
    });
  }, [showForm]);

  // Fetch member accounts when member selected
  useEffect(() => {
    if (!form.member_id) { setMemberAccounts([]); return; }
    fetchWithAuth(`/api/members/${form.member_id}/accounts`).then(r => r.json()).then(json => {
      if (json.success) setMemberAccounts(json.data || []);
    });
  }, [form.member_id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.member_id || !form.principal) return;
    setSaving(true);
    try {
      const res = await fetchWithAuth('/api/loans', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Loan application submitted');
        setShowForm(false);
        setForm({ member_id: '', product_id: '', member_account_id: '', principal: '' });
        fetchLoans();
      } else {
        toast.error(json.error || 'Failed to create loan');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const handleAction = async (loanId, action) => {
    try {
      const opts = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
      if (action === 'reject') opts.body = JSON.stringify({ reason: 'Rejected by admin' });
      const res = await fetchWithAuth(`/api/loans/${loanId}/${action}`, opts);
      const json = await res.json();
      if (json.success) {
        toast.success(`Loan ${action}d successfully`);
        fetchLoans();
      } else {
        toast.error(json.error || `Failed to ${action} loan`);
      }
    } catch {
      toast.error('Network error');
    }
  };

  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  const pendingCount = loans.filter(l => l.status === 'PENDING').length;
  const activeCount = loans.filter(l => l.status === 'ACTIVE').length;
  const totalDisbursed = loans.filter(l => ['ACTIVE', 'COMPLETED'].includes(l.status)).reduce((s, l) => s + parseFloat(l.principal || 0), 0);
  const totalRepaid = loans.reduce((s, l) => s + parseFloat(l.total_paid || 0), 0);

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Banknote className="w-6 h-6 text-blue-500" /> Loan Management
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Manage loan applications, approvals, disbursements, and repayments</p>
        </div>
        <button onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition">
          <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'New Loan'}
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Pending Approval</div>
          <div className="text-2xl font-bold mt-1 text-amber-600">{pendingCount}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Active Loans</div>
          <div className="text-2xl font-bold mt-1 text-emerald-600">{activeCount}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Disbursed</div>
          <div className="text-2xl font-bold mt-1">{fmtCurrency(totalDisbursed)}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Repaid</div>
          <div className="text-2xl font-bold mt-1 text-blue-600">{fmtCurrency(totalRepaid)}</div>
        </div>
      </div>

      {/* Application Form */}
      {showForm && (
        <form onSubmit={handleSubmit} className="bg-card border border-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-foreground">New Loan Application</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Member *</label>
              <select value={form.member_id} onChange={e => setForm(f => ({ ...f, member_id: e.target.value, member_account_id: '' }))} required className={inputClass}>
                <option value="">Select member...</option>
                {members.filter(m => m.status === 'active').map(m => (
                  <option key={m.id} value={m.id}>{m.full_name} ({m.membership_number})</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Loan Product</label>
              <select value={form.product_id} onChange={e => setForm(f => ({ ...f, product_id: e.target.value }))} className={inputClass}>
                <option value="">Default terms (10% / 12mo)</option>
                {products.map(p => (
                  <option key={p.id} value={p.id}>{p.name} — {p.interest_rate}% / {p.duration}mo</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Disbursement Account</label>
              <select value={form.member_account_id} onChange={e => setForm(f => ({ ...f, member_account_id: e.target.value }))} className={inputClass}>
                <option value="">Select account...</option>
                {memberAccounts.map(a => (
                  <option key={a.member_account_id || a.id} value={a.member_account_id || a.id}>
                    {a.account_type} — {a.account_number} ({fmtCurrency(a.balance, a.currency)})
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Principal Amount (UGX) *</label>
              <input type="number" min="1" step="1" value={form.principal} onChange={e => setForm(f => ({ ...f, principal: e.target.value }))}
                required placeholder="1000000" className={inputClass} />
            </div>
          </div>
          <button type="submit" disabled={saving}
            className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition">
            {saving ? 'Submitting...' : 'Submit Application'}
          </button>
        </form>
      )}

      {/* Status Filter */}
      <div className="flex gap-2">
        {['', 'PENDING', 'APPROVED', 'DISBURSED', 'ACTIVE', 'COMPLETED', 'DEFAULTED', 'REJECTED'].map(s => (
          <button key={s} onClick={() => setStatusFilter(s)}
            className={`px-3 py-1.5 text-xs rounded-lg border transition ${statusFilter === s ? 'bg-blue-600 text-white border-blue-600' : 'border-border hover:bg-muted'}`}>
            {s || 'All'}
          </button>
        ))}
      </div>

      {/* Loans Table */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Loading loans...</div>
      ) : loans.length === 0 ? (
        <div className="bg-card border border-border rounded-xl p-12 text-center">
          <Banknote className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-40" />
          <p className="text-muted-foreground">No loans found</p>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Member</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Product</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Principal</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Total Payable</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Paid</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Status</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loans.map(l => {
                  const Icon = STATUS_ICONS[l.status] || Clock;
                  const progress = parseFloat(l.total_payable) > 0 ? (parseFloat(l.total_paid) / parseFloat(l.total_payable)) * 100 : 0;
                  return (
                    <tr key={l.id} className="border-b border-border last:border-0 hover:bg-muted/20 transition">
                      <td className="px-4 py-3">
                        <Link href={`/app/members/${l.member_id}`} className="font-medium text-foreground hover:text-blue-600">{l.member_name}</Link>
                        <div className="text-xs text-muted-foreground">{l.membership_number}</div>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {l.product_name || 'Default'}<br />
                        {l.interest_rate}% / {l.duration}mo
                      </td>
                      <td className="px-4 py-3 text-right font-medium">{fmtCurrency(l.principal)}</td>
                      <td className="px-4 py-3 text-right">{fmtCurrency(l.total_payable)}</td>
                      <td className="px-4 py-3 text-right">
                        <div>{fmtCurrency(l.total_paid)}</div>
                        {l.status === 'ACTIVE' && (
                          <div className="w-16 h-1 bg-gray-200 rounded-full mt-1 ml-auto">
                            <div className="h-1 bg-emerald-500 rounded-full" style={{ width: `${Math.min(progress, 100)}%` }} />
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${STATUS_STYLES[l.status] || ''}`}>
                          <Icon className="w-3 h-3" /> {l.status}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex gap-1">
                          <Link href={`/app/loans/${l.id}`} className="text-xs px-2 py-1 border border-border rounded hover:bg-muted">View</Link>
                          {l.status === 'PENDING' && (
                            <>
                              <button onClick={() => handleAction(l.id, 'approve')} className="text-xs px-2 py-1 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded hover:bg-emerald-100 dark:bg-emerald-900/20 dark:text-emerald-400 dark:border-emerald-800">Approve</button>
                              <button onClick={() => handleAction(l.id, 'reject')} className="text-xs px-2 py-1 bg-red-50 text-red-600 border border-red-200 rounded hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800">Reject</button>
                            </>
                          )}
                          {l.status === 'APPROVED' && (
                            <button onClick={() => handleAction(l.id, 'disburse')} className="text-xs px-2 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800">Disburse</button>
                          )}
                          {l.status === 'DISBURSED' && (
                            <button onClick={() => handleAction(l.id, 'disburse')} className="text-xs px-2 py-1 bg-purple-50 text-purple-700 border border-purple-200 rounded hover:bg-purple-100 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800">Continue Disburse</button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

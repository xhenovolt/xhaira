'use client';

import { useEffect, useState } from 'react';
import { Plus, Wallet, X } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { formatCurrency } from '@/lib/format-currency';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const TYPE_COLORS = { bank: 'bg-blue-100 text-blue-700', savings: 'bg-emerald-100 text-emerald-700', cash: 'bg-yellow-100 text-yellow-700', mobile_money: 'bg-purple-100 text-purple-700', credit_card: 'bg-pink-100 text-pink-700', investment: 'bg-cyan-100 text-cyan-700', internal: 'bg-orange-100 text-orange-700', salary: 'bg-teal-100 text-teal-700', escrow: 'bg-indigo-100 text-indigo-700', other: 'bg-muted text-foreground' };
const ACCOUNT_TYPES = ['cash','mobile_money','bank','savings','credit_card','investment','internal','salary','escrow','other'];

export default function AccountsPage() {
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', type: 'cash', currency: 'UGX', initial_balance: '', institution: '', account_number: '', description: '' });
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  useEffect(() => { fetchAccounts(); }, []);

  const fetchAccounts = async () => {
    try {
      const res = await fetchWithAuth('/api/accounts');
      const json = await res.json();
      if (json.success) setAccounts(json.data);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const submit = async (e) => {
    e.preventDefault(); setSaving(true);
    try {
      const body = { ...form };
      if (body.initial_balance) body.initial_balance = parseFloat(body.initial_balance);
      else delete body.initial_balance;
      const res = await fetchWithAuth('/api/accounts', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      if ((await res.json()).success) { toast.success('Account created'); setShowForm(false); setForm({ name: '', type: 'cash', currency: 'UGX', initial_balance: '', institution: '', account_number: '', description: '' }); fetchAccounts(); }
    } catch (err) { console.error(err); } finally { setSaving(false); }
  };

  const totalBalance = accounts.reduce((s, a) => s + parseFloat(a.balance || 0), 0);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Accounts</h1>
          <p className="text-sm text-muted-foreground mt-1">{accounts.length} accounts &middot; {formatCurrency(totalBalance)} total balance</p>
        </div>
        <button onClick={() => setShowForm(!showForm)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium">
          {showForm ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />} {showForm ? 'Cancel' : 'New Account'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={submit} className="bg-card rounded-xl border p-5 space-y-4">
          <h2 className="font-semibold">Create Account</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Name *</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground" placeholder="e.g. Business Checking" />
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Type</label>
              <select value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))} className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground">
                {ACCOUNT_TYPES.map(t => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Currency</label>
              <input value={form.currency} onChange={e => setForm(f => ({ ...f, currency: e.target.value }))} className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground" />
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Initial Balance</label>
              <input type="number" step="0.01" value={form.initial_balance} onChange={e => setForm(f => ({ ...f, initial_balance: e.target.value }))} className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground" placeholder="0.00" />
            </div>
          </div>
          <button type="submit" disabled={saving} className="bg-blue-600 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50">{saving ? 'Creating...' : 'Create Account'}</button>
        </form>
      )}

      {loading ? (
        <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div>
      ) : accounts.length === 0 ? (
        <div className="text-center py-16 text-muted-foreground">No accounts yet. Create your first account to start tracking finances.</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {accounts.map(a => (
            <Link key={a.id} href={`/app/finance/accounts`} className="bg-card rounded-xl border p-5 hover:border-blue-300 hover:shadow-sm transition">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Wallet className="w-5 h-5 text-muted-foreground" />
                  <span className="font-medium text-foreground">{a.name}</span>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TYPE_COLORS[a.type] || TYPE_COLORS.other}`}>{a.type}</span>
              </div>
              <div className={`text-2xl font-bold ${parseFloat(a.balance) >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>{formatCurrency(a.balance)}</div>
              <div className="text-xs text-muted-foreground mt-1">{a.currency} &middot; {a.transaction_count || 0} transactions</div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { BookOpen, Plus, Edit2, Save, X, CheckCircle, XCircle } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';

const BOOLEAN_BADGE = (val) => val
  ? <span className="inline-flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400"><CheckCircle className="w-3 h-3" /> Yes</span>
  : <span className="inline-flex items-center gap-1 text-xs text-muted-foreground"><XCircle className="w-3 h-3" /> No</span>;

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

export default function AccountTypesPage() {
  const [types, setTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [editForm, setEditForm] = useState({});
  const [saving, setSaving] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const toast = useToast();

  const [form, setForm] = useState({
    name: '', code: '', description: '',
    allows_withdrawal: true, minimum_balance: '0',
    is_mandatory: false, interest_rate: '0',
  });

  const fetchTypes = async () => {
    try {
      const res = await fetchWithAuth('/api/account-types');
      const json = await res.json();
      if (json.success) setTypes(json.data || []);
    } catch (err) {
      console.error('Failed to fetch account types:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchTypes(); }, []);

  const startEdit = (t) => {
    setEditingId(t.id);
    setEditForm({
      name: t.name,
      description: t.description || '',
      allows_withdrawal: t.allows_withdrawal,
      minimum_balance: String(t.minimum_balance || 0),
      is_mandatory: t.is_mandatory,
      interest_rate: String(t.interest_rate || 0),
    });
  };
  const cancelEdit = () => { setEditingId(null); setEditForm({}); };

  const saveEdit = async (t) => {
    setSaving(true);
    try {
      const res = await fetchWithAuth(`/api/account-types/${t.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...editForm,
          minimum_balance: parseFloat(editForm.minimum_balance) || 0,
          interest_rate: parseFloat(editForm.interest_rate) || 0,
        }),
      });
      const json = await res.json();
      if (json.success) { toast.success('Account type updated'); cancelEdit(); fetchTypes(); }
      else toast.error(json.error || 'Update failed');
    } catch { toast.error('Network error'); }
    finally { setSaving(false); }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!form.name.trim() || !form.code.trim()) return;
    setSaving(true);
    try {
      const res = await fetchWithAuth('/api/account-types', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...form,
          minimum_balance: parseFloat(form.minimum_balance) || 0,
          interest_rate: parseFloat(form.interest_rate) || 0,
        }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Account type created');
        setShowForm(false);
        setForm({ name: '', code: '', description: '', allows_withdrawal: true, minimum_balance: '0', is_mandatory: false, interest_rate: '0' });
        fetchTypes();
      } else toast.error(json.error || 'Failed to create');
    } catch { toast.error('Network error'); }
    finally { setSaving(false); }
  };

  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <BookOpen className="w-6 h-6 text-violet-500" /> Account Types
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Manage member account books — savings, shares, loans, investments</p>
        </div>
        <button onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 px-4 py-2 bg-violet-600 text-white rounded-lg text-sm font-medium hover:bg-violet-700 transition">
          <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'New Type'}
        </button>
      </div>

      {/* Create Form */}
      {showForm && (
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-4">New Account Type</h3>
          <form onSubmit={handleCreate} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Name</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="e.g. Fixed Deposit" className={inputClass} required />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Code</label>
              <input value={form.code} onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))}
                placeholder="e.g. FIXED_SAV" className={inputClass} required />
            </div>
            <div className="sm:col-span-2">
              <label className="text-xs font-medium text-muted-foreground block mb-1">Description</label>
              <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Brief description" className={inputClass} />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Minimum Balance (UGX)</label>
              <input type="number" min="0" value={form.minimum_balance} onChange={e => setForm(f => ({ ...f, minimum_balance: e.target.value }))}
                className={inputClass} />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Interest Rate (%)</label>
              <input type="number" min="0" step="0.01" value={form.interest_rate} onChange={e => setForm(f => ({ ...f, interest_rate: e.target.value }))}
                className={inputClass} />
            </div>
            <div className="flex items-center gap-4">
              <label className="flex items-center gap-2 cursor-pointer text-sm text-foreground">
                <input type="checkbox" checked={form.allows_withdrawal} onChange={e => setForm(f => ({ ...f, allows_withdrawal: e.target.checked }))}
                  className="w-4 h-4 rounded" />
                Allows Withdrawal
              </label>
              <label className="flex items-center gap-2 cursor-pointer text-sm text-foreground">
                <input type="checkbox" checked={form.is_mandatory} onChange={e => setForm(f => ({ ...f, is_mandatory: e.target.checked }))}
                  className="w-4 h-4 rounded" />
                Mandatory
              </label>
            </div>
            <div className="sm:col-span-2 flex justify-end">
              <button type="submit" disabled={saving}
                className="px-4 py-2 bg-violet-600 text-white rounded-lg text-sm font-medium hover:bg-violet-700 disabled:opacity-50">
                {saving ? 'Creating...' : 'Create'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Account Types Table */}
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        {loading ? (
          <div className="text-center py-12 text-muted-foreground text-sm">Loading account types...</div>
        ) : types.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground text-sm">No account types found</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left">
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase">Name / Code</th>
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase">Min Balance</th>
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase">Interest</th>
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase">Withdrawal</th>
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase">Mandatory</th>
                <th className="px-4 py-3 text-xs font-semibold text-muted-foreground uppercase"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {types.map(t => (
                <tr key={t.id}>
                  {editingId === t.id ? (
                    <td colSpan={6} className="px-4 py-4">
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-3">
                        <div>
                          <label className="text-xs text-muted-foreground mb-1 block">Name</label>
                          <input value={editForm.name} onChange={e => setEditForm(f => ({ ...f, name: e.target.value }))} className={inputClass} autoFocus />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground mb-1 block">Description</label>
                          <input value={editForm.description} onChange={e => setEditForm(f => ({ ...f, description: e.target.value }))} className={inputClass} />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground mb-1 block">Min Balance</label>
                          <input type="number" min="0" value={editForm.minimum_balance} onChange={e => setEditForm(f => ({ ...f, minimum_balance: e.target.value }))} className={inputClass} />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground mb-1 block">Interest Rate (%)</label>
                          <input type="number" min="0" step="0.01" value={editForm.interest_rate} onChange={e => setEditForm(f => ({ ...f, interest_rate: e.target.value }))} className={inputClass} />
                        </div>
                        <div className="flex items-center gap-4 pt-5">
                          <label className="flex items-center gap-2 cursor-pointer text-sm text-foreground">
                            <input type="checkbox" checked={editForm.allows_withdrawal} onChange={e => setEditForm(f => ({ ...f, allows_withdrawal: e.target.checked }))} className="w-4 h-4 rounded" />
                            Withdrawal
                          </label>
                          <label className="flex items-center gap-2 cursor-pointer text-sm text-foreground">
                            <input type="checkbox" checked={editForm.is_mandatory} onChange={e => setEditForm(f => ({ ...f, is_mandatory: e.target.checked }))} className="w-4 h-4 rounded" />
                            Mandatory
                          </label>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button onClick={() => saveEdit(t)} disabled={saving}
                          className="flex items-center gap-1 px-3 py-1.5 bg-violet-600 text-white rounded-lg text-xs font-medium hover:bg-violet-700 disabled:opacity-50">
                          <Save className="w-3 h-3" /> {saving ? 'Saving...' : 'Save'}
                        </button>
                        <button onClick={cancelEdit}
                          className="flex items-center gap-1 px-3 py-1.5 border border-border text-foreground rounded-lg text-xs font-medium hover:bg-muted">
                          <X className="w-3 h-3" /> Cancel
                        </button>
                      </div>
                    </td>
                  ) : (
                    <>
                      <td className="px-4 py-3">
                        <div className="font-medium text-foreground">{t.name}</div>
                        <code className="text-xs text-muted-foreground">{t.code}</code>
                        {t.description && <div className="text-xs text-muted-foreground mt-0.5">{t.description}</div>}
                      </td>
                      <td className="px-4 py-3 text-foreground">{fmtCurrency(t.minimum_balance)}</td>
                      <td className="px-4 py-3 text-foreground">{parseFloat(t.interest_rate || 0).toFixed(2)}%</td>
                      <td className="px-4 py-3">{BOOLEAN_BADGE(t.allows_withdrawal)}</td>
                      <td className="px-4 py-3">{BOOLEAN_BADGE(t.is_mandatory)}</td>
                      <td className="px-4 py-3 text-right">
                        <button onClick={() => startEdit(t)}
                          className="flex items-center gap-1 px-2.5 py-1.5 border border-border text-muted-foreground rounded-lg text-xs hover:text-foreground hover:bg-muted transition">
                          <Edit2 className="w-3 h-3" /> Edit
                        </button>
                      </td>
                    </>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

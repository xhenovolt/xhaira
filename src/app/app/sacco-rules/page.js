'use client';

import { useEffect, useState } from 'react';
import { Settings, Edit2, Save, X, Plus, Trash2 } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';

const TYPE_COLORS = {
  LOAN: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  ACCOUNT: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  GUARANTOR: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  TRANSFER: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
};

const RULE_TYPES = ['LOAN', 'ACCOUNT', 'GUARANTOR', 'TRANSFER'];

const RULE_DESCRIPTIONS = {
  min_fixed_savings_for_loan: 'Minimum fixed savings (UGX) required to be eligible for a loan',
  max_loan_multiplier: 'Maximum loan amount as a multiple of fixed savings',
  guarantors_required: 'Number of guarantors required per loan application',
  max_active_loans: 'Maximum number of active loans a member can hold simultaneously',
  min_share_balance: 'Minimum share balance (UGX) required for full membership',
  min_voluntary_savings: 'Minimum voluntary savings balance required (0 = disabled)',
  max_guarantee_percentage: 'Max % of a guarantor\'s total savings they can guarantee',
  min_membership_months: 'Minimum months of membership before qualifying as a guarantor',
  min_transfer_amount: 'Minimum amount (UGX) per member-to-member transfer',
  max_daily_transfers: 'Maximum number of transfers a member can make per day',
};

function formatValue(val) {
  if (val === null || val === undefined) return '—';
  if (typeof val === 'object') return JSON.stringify(val);
  const num = parseFloat(val);
  if (!isNaN(num) && num >= 1000) return num.toLocaleString();
  return String(val);
}

export default function SaccoRulesPage() {
  const [rules, setRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [editValue, setEditValue] = useState('');
  const [editDesc, setEditDesc] = useState('');
  const [saving, setSaving] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [typeFilter, setTypeFilter] = useState('');
  const toast = useToast();

  const [form, setForm] = useState({ rule_type: 'LOAN', rule_key: '', rule_value: '', description: '' });

  const fetchRules = async () => {
    try {
      const res = await fetchWithAuth('/api/sacco-rules');
      const json = await res.json();
      if (json.success) setRules(json.data || []);
    } catch (err) {
      console.error('Failed to fetch rules:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchRules(); }, []);

  const startEdit = (rule) => {
    setEditingId(rule.id);
    const val = rule.rule_value;
    setEditValue(typeof val === 'object' ? JSON.stringify(val) : String(val));
    setEditDesc(rule.description || '');
  };

  const cancelEdit = () => { setEditingId(null); setEditValue(''); setEditDesc(''); };

  const saveEdit = async (rule) => {
    setSaving(true);
    try {
      let parsedValue = editValue;
      try { parsedValue = JSON.parse(editValue); } catch { /* keep as string */ }
      const res = await fetchWithAuth(`/api/sacco-rules/${rule.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ rule_value: parsedValue, description: editDesc }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Rule updated');
        cancelEdit();
        fetchRules();
      } else {
        toast.error(json.error || 'Failed to update rule');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!form.rule_key.trim() || !form.rule_value.trim()) return;
    setSaving(true);
    try {
      let parsedValue = form.rule_value;
      try { parsedValue = JSON.parse(form.rule_value); } catch { /* keep as string */ }
      const res = await fetchWithAuth('/api/sacco-rules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, rule_value: parsedValue }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Rule created');
        setShowForm(false);
        setForm({ rule_type: 'LOAN', rule_key: '', rule_value: '', description: '' });
        fetchRules();
      } else {
        toast.error(json.error || 'Failed to create rule');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const filtered = typeFilter ? rules.filter(r => r.rule_type === typeFilter) : rules;

  const grouped = RULE_TYPES.reduce((acc, type) => {
    acc[type] = filtered.filter(r => r.rule_type === type);
    return acc;
  }, {});

  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Settings className="w-6 h-6 text-emerald-500" /> SACCO Rules
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Configure cooperative policies — loan limits, guarantor requirements, transfer rules</p>
        </div>
        <button onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 transition">
          <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'Add Rule'}
        </button>
      </div>

      {/* Type Filter */}
      <div className="flex gap-2 flex-wrap">
        <button onClick={() => setTypeFilter('')}
          className={`px-3 py-1.5 rounded-full text-xs font-medium transition ${!typeFilter ? 'bg-foreground text-background' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
          All
        </button>
        {RULE_TYPES.map(t => (
          <button key={t} onClick={() => setTypeFilter(t === typeFilter ? '' : t)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition ${typeFilter === t ? 'bg-foreground text-background' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
            {t}
          </button>
        ))}
      </div>

      {/* Create Form */}
      {showForm && (
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-4">New Rule</h3>
          <form onSubmit={handleCreate} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Type</label>
              <select value={form.rule_type} onChange={e => setForm(f => ({ ...f, rule_type: e.target.value }))} className={inputClass}>
                {RULE_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Key</label>
              <input value={form.rule_key} onChange={e => setForm(f => ({ ...f, rule_key: e.target.value }))}
                placeholder="e.g. max_loan_multiplier" className={inputClass} required />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Value</label>
              <input value={form.rule_value} onChange={e => setForm(f => ({ ...f, rule_value: e.target.value }))}
                placeholder="e.g. 3 or true or {}" className={inputClass} required />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Description</label>
              <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Human-readable description" className={inputClass} />
            </div>
            <div className="sm:col-span-2 flex justify-end">
              <button type="submit" disabled={saving}
                className="px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 disabled:opacity-50">
                {saving ? 'Saving...' : 'Create Rule'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Rules by Type */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground text-sm">Loading rules...</div>
      ) : (
        RULE_TYPES.filter(type => !typeFilter || typeFilter === type).map(type => {
          const typeRules = grouped[type];
          if (typeRules.length === 0) return null;
          return (
            <div key={type} className="bg-card border border-border rounded-xl overflow-hidden">
              <div className={`px-4 py-3 flex items-center gap-2 border-b border-border`}>
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${TYPE_COLORS[type]}`}>{type}</span>
                <span className="text-xs text-muted-foreground">{typeRules.length} rule{typeRules.length !== 1 ? 's' : ''}</span>
              </div>
              <div className="divide-y divide-border">
                {typeRules.map(rule => (
                  <div key={rule.id} className="px-4 py-4">
                    {editingId === rule.id ? (
                      <div className="space-y-3">
                        <div className="flex items-center gap-2">
                          <code className="text-sm font-mono font-medium text-foreground">{rule.rule_key}</code>
                        </div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="text-xs text-muted-foreground mb-1 block">Value</label>
                            <input value={editValue} onChange={e => setEditValue(e.target.value)} className={inputClass} autoFocus />
                          </div>
                          <div>
                            <label className="text-xs text-muted-foreground mb-1 block">Description</label>
                            <input value={editDesc} onChange={e => setEditDesc(e.target.value)} className={inputClass} />
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <button onClick={() => saveEdit(rule)} disabled={saving}
                            className="flex items-center gap-1 px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-medium hover:bg-emerald-700 disabled:opacity-50">
                            <Save className="w-3 h-3" /> {saving ? 'Saving...' : 'Save'}
                          </button>
                          <button onClick={cancelEdit}
                            className="flex items-center gap-1 px-3 py-1.5 border border-border text-foreground rounded-lg text-xs font-medium hover:bg-muted">
                            <X className="w-3 h-3" /> Cancel
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-3">
                            <code className="text-sm font-mono font-medium text-foreground">{rule.rule_key}</code>
                            <span className="font-bold text-foreground">{formatValue(rule.rule_value)}</span>
                          </div>
                          <p className="text-xs text-muted-foreground mt-1">
                            {rule.description || RULE_DESCRIPTIONS[rule.rule_key] || ''}
                          </p>
                        </div>
                        <button onClick={() => startEdit(rule)}
                          className="flex items-center gap-1 px-2.5 py-1.5 border border-border text-muted-foreground rounded-lg text-xs hover:text-foreground hover:bg-muted transition shrink-0">
                          <Edit2 className="w-3 h-3" /> Edit
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })
      )}

      {!loading && filtered.length === 0 && (
        <div className="text-center py-12 text-muted-foreground text-sm">No rules found</div>
      )}
    </div>
  );
}

'use client';

/**
 * /app/settings/account-rules
 * SACCO Admin — Account Rule Configuration Panel
 *
 * Allows administrators to:
 * - View all account types and their configured rules
 * - Enable / disable individual rules at runtime
 * - Edit rule values (interest rate, min balance, etc.)
 * - Add new rules to any account type
 */

import { useEffect, useState, useCallback } from 'react';
import { fetchWithAuth }     from '@/lib/fetch-client';
import { formatCurrency }    from '@/lib/format-currency';
import { usePermissions }    from '@/components/providers/PermissionProvider';
import Link                  from 'next/link';
import {
  Settings, ChevronDown, ChevronRight, Plus, Edit2, Trash2,
  ToggleLeft, ToggleRight, RefreshCw, Save, X, AlertTriangle,
  CheckCircle, Info,
} from 'lucide-react';

// ─── Constants ────────────────────────────────────────────────────────────────

const RULE_KEYS = [
  { key: 'min_balance',          label: 'Minimum Balance',    type: 'number',  hint: 'Minimum ledger balance in UGX' },
  { key: 'interest_rate',        label: 'Interest Rate (%)',  type: 'number',  hint: 'Annual rate, e.g. 5 for 5%' },
  { key: 'interest_cycle',       label: 'Interest Cycle',     type: 'select',  options: ['MONTHLY','QUARTERLY','ANNUALLY'], hint: 'How often interest is applied' },
  { key: 'interest_enabled',     label: 'Interest Enabled',   type: 'boolean', hint: 'Toggle interest calculation on/off' },
  { key: 'withdrawal_allowed',   label: 'Withdrawal Allowed', type: 'boolean', hint: 'Allow members to withdraw from this account type' },
  { key: 'requires_maturity',    label: 'Requires Maturity',  type: 'boolean', hint: 'Block withdrawals until maturity period elapses' },
  { key: 'maturity_period_days', label: 'Maturity (days)',    type: 'number',  hint: 'Number of days from open date before withdrawal allowed' },
  { key: 'loan_eligible',        label: 'Loan Eligible',      type: 'boolean', hint: 'Balance counts toward loan eligibility multiplier' },
  { key: 'dividend_eligible',    label: 'Dividend Eligible',  type: 'boolean', hint: 'Account earns dividends' },
];

// ─── Helper: render a rule value for display ─────────────────────────────────
function displayValue(key, value) {
  if (value === null || value === undefined) return '—';
  const def = RULE_KEYS.find(r => r.key === key);
  if (def?.type === 'boolean') return value ? 'Yes' : 'No';
  if (key === 'min_balance')   return formatCurrency(Number(value), 'UGX');
  if (key === 'interest_rate') return `${value}% p.a.`;
  if (key === 'maturity_period_days') return `${value} days`;
  return String(value);
}

// ─── RuleValueInput ───────────────────────────────────────────────────────────
function RuleValueInput({ ruleKey, value, onChange }) {
  const def = RULE_KEYS.find(r => r.key === ruleKey);
  if (!def) return (
    <input
      className="border border-border rounded px-2 py-1 text-sm w-40 bg-background text-foreground"
      value={value ?? ''}
      onChange={e => onChange(e.target.value)}
    />
  );

  if (def.type === 'boolean') return (
    <select
      className="border border-border rounded px-2 py-1 text-sm bg-background text-foreground"
      value={value === true || value === 'true' ? 'true' : 'false'}
      onChange={e => onChange(e.target.value === 'true')}
    >
      <option value="true">Yes</option>
      <option value="false">No</option>
    </select>
  );

  if (def.type === 'select') return (
    <select
      className="border border-border rounded px-2 py-1 text-sm bg-background text-foreground"
      value={value ?? def.options[0]}
      onChange={e => onChange(e.target.value)}
    >
      {def.options.map(o => <option key={o} value={o}>{o}</option>)}
    </select>
  );

  return (
    <input
      type="number"
      className="border border-border rounded px-2 py-1 text-sm w-32 bg-background text-foreground"
      value={value ?? ''}
      min={0}
      step={def.key === 'interest_rate' ? 0.01 : 1}
      onChange={e => onChange(e.target.value)}
    />
  );
}

// ─── Main Page Component ──────────────────────────────────────────────────────
export default function AccountRulesPage() {
  const { can } = usePermissions();

  const [accountTypes, setAccountTypes] = useState([]);
  const [rules,        setRules]        = useState([]);
  const [expanded,     setExpanded]     = useState({});
  const [loading,      setLoading]      = useState(true);
  const [saving,       setSaving]       = useState(null);
  const [toast,        setToast]        = useState(null);

  // Edit state for inline editing
  const [editing, setEditing] = useState(null); // { ruleId, field, value }
  // New rule form per account type
  const [addForm, setAddForm] = useState({}); // { [accountTypeId]: { key, value } }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [typesRes, rulesRes] = await Promise.all([
        fetchWithAuth('/api/account-types'),
        fetchWithAuth('/api/account-type-rules'),
      ]);
      const [typesData, rulesData] = await Promise.all([typesRes.json(), rulesRes.json()]);
      setAccountTypes(typesData.data || []);
      setRules(rulesData.data || []);
    } catch {
      showToast('Failed to load rules', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  // ── Toast ──────────────────────────────────────────────────────────────────
  function showToast(message, type = 'success') {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  }

  // ── Toggle rule enabled/disabled ──────────────────────────────────────────
  async function toggleRule(rule) {
    setSaving(rule.id);
    try {
      const res  = await fetchWithAuth(`/api/account-type-rules/${rule.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_enabled: !rule.is_enabled }),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.error);
      setRules(prev => prev.map(r => r.id === rule.id ? data.data : r));
      showToast(`Rule "${rule.rule_key}" ${data.data.is_enabled ? 'enabled' : 'disabled'}`, 'success');
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setSaving(null);
    }
  }

  // ── Save inline edit ──────────────────────────────────────────────────────
  async function saveEdit() {
    if (!editing) return;
    setSaving(editing.ruleId);
    try {
      const res  = await fetchWithAuth(`/api/account-type-rules/${editing.ruleId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ rule_value: editing.value }),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.error);
      setRules(prev => prev.map(r => r.id === editing.ruleId ? data.data : r));
      setEditing(null);
      showToast('Rule updated', 'success');
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setSaving(null);
    }
  }

  // ── Delete rule ────────────────────────────────────────────────────────────
  async function deleteRule(ruleId, ruleKey) {
    if (!confirm(`Remove rule "${ruleKey}"? This will reset behavior to default.`)) return;
    setSaving(ruleId);
    try {
      const res  = await fetchWithAuth(`/api/account-type-rules/${ruleId}`, { method: 'DELETE' });
      const data = await res.json();
      if (!data.success) throw new Error(data.error);
      setRules(prev => prev.filter(r => r.id !== ruleId));
      showToast(`Rule "${ruleKey}" removed`, 'success');
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setSaving(null);
    }
  }

  // ── Add new rule ───────────────────────────────────────────────────────────
  async function addRule(accountTypeId) {
    const form = addForm[accountTypeId] || {};
    if (!form.key) return showToast('Please select a rule key', 'error');

    const def = RULE_KEYS.find(r => r.key === form.key);
    let parsedValue = form.value;
    if (def?.type === 'number') parsedValue = parseFloat(form.value) || 0;
    if (def?.type === 'boolean') parsedValue = form.value === true || form.value === 'true';

    setSaving(`add-${accountTypeId}`);
    try {
      const res  = await fetchWithAuth('/api/account-type-rules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ account_type_id: accountTypeId, rule_key: form.key, rule_value: parsedValue }),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.error);
      setRules(prev => {
        const exists = prev.find(r => r.id === data.data.id);
        return exists ? prev.map(r => r.id === data.data.id ? data.data : r) : [...prev, data.data];
      });
      setAddForm(prev => ({ ...prev, [accountTypeId]: {} }));
      showToast(`Rule "${form.key}" saved`, 'success');
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setSaving(null);
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────
  if (!can('finance.manage')) {
    return (
      <div className="p-8 text-center text-muted-foreground">
        You do not have permission to manage account rules.
      </div>
    );
  }

  return (
    <div className="p-6 max-w-5xl mx-auto">

      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
            <Link href="/app/settings" className="hover:underline">Settings</Link>
            <span>/</span>
            <span>Account Rules</span>
          </div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Settings className="w-6 h-6" /> Account Rule Engine
          </h1>
          <p className="text-muted-foreground mt-1">
            Configure financial behavior for each account type. Rules override default values at runtime.
          </p>
        </div>
        <button onClick={load} className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
          <RefreshCw className="w-4 h-4" /> Refresh
        </button>
      </div>

      {/* Info Banner */}
      <div className="bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-6 flex gap-3">
        <Info className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
        <div className="text-sm text-blue-800 dark:text-blue-200">
          <strong>Rules are evaluated at runtime.</strong> Changes take effect immediately for the next transaction.
          Disabled rules fall back to the account type&apos;s default settings.
        </div>
      </div>

      {/* Toast */}
      {toast && (
        <div className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium flex items-center gap-2 ${
          toast.type === 'error' ? 'bg-red-600 text-white' : 'bg-emerald-600 text-white'
        }`}>
          {toast.type === 'error' ? <AlertTriangle className="w-4 h-4" /> : <CheckCircle className="w-4 h-4" />}
          {toast.message}
        </div>
      )}

      {loading ? (
        <div className="flex items-center gap-3 text-muted-foreground">
          <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin" />
          Loading rules...
        </div>
      ) : (
        <div className="space-y-4">
          {accountTypes.map(at => {
            const typeRules = rules.filter(r => r.account_type_id === at.id);
            const isOpen    = expanded[at.id];
            const addF      = addForm[at.id] || {};

            return (
              <div key={at.id} className="bg-card border border-border rounded-xl overflow-hidden">

                {/* Account Type Header */}
                <button
                  className="w-full flex items-center justify-between p-4 hover:bg-muted/40 transition-colors"
                  onClick={() => setExpanded(prev => ({ ...prev, [at.id]: !prev[at.id] }))}
                >
                  <div className="flex items-center gap-3">
                    <div className="flex flex-col items-start">
                      <span className="font-semibold text-foreground">{at.name}</span>
                      <span className="text-xs text-muted-foreground font-mono">{at.code}</span>
                    </div>
                    <span className="bg-muted rounded-full px-2 py-0.5 text-xs text-muted-foreground">
                      {typeRules.length} rule{typeRules.length !== 1 ? 's' : ''}
                    </span>
                    {typeRules.some(r => !r.is_enabled) && (
                      <span className="text-xs text-amber-600">
                        {typeRules.filter(r => !r.is_enabled).length} disabled
                      </span>
                    )}
                  </div>
                  {isOpen ? <ChevronDown className="w-4 h-4 text-muted-foreground" /> : <ChevronRight className="w-4 h-4 text-muted-foreground" />}
                </button>

                {isOpen && (
                  <div className="border-t border-border">

                    {/* Rule Rows */}
                    {typeRules.length > 0 ? (
                      <table className="w-full text-sm">
                        <thead>
                          <tr className="bg-muted/30 text-xs text-muted-foreground uppercase tracking-wide">
                            <th className="px-4 py-2 text-left">Rule</th>
                            <th className="px-4 py-2 text-left">Value</th>
                            <th className="px-4 py-2 text-left">Status</th>
                            <th className="px-4 py-2 text-right">Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {typeRules.map(rule => {
                            const isEditing = editing?.ruleId === rule.id;
                            const isSavingThis = saving === rule.id;
                            const ruleDef = RULE_KEYS.find(r => r.key === rule.rule_key);

                            return (
                              <tr key={rule.id} className="border-t border-border hover:bg-muted/20">
                                <td className="px-4 py-3">
                                  <div className="font-medium text-foreground">{ruleDef?.label || rule.rule_key}</div>
                                  {ruleDef?.hint && (
                                    <div className="text-xs text-muted-foreground">{ruleDef.hint}</div>
                                  )}
                                </td>
                                <td className="px-4 py-3">
                                  {isEditing ? (
                                    <RuleValueInput
                                      ruleKey={rule.rule_key}
                                      value={editing.value}
                                      onChange={v => setEditing(prev => ({ ...prev, value: v }))}
                                    />
                                  ) : (
                                    <span className={`font-mono text-sm ${rule.is_enabled ? 'text-foreground' : 'text-muted-foreground line-through'}`}>
                                      {displayValue(rule.rule_key, rule.rule_value)}
                                    </span>
                                  )}
                                </td>
                                <td className="px-4 py-3">
                                  <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${
                                    rule.is_enabled
                                      ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
                                      : 'bg-muted text-muted-foreground'
                                  }`}>
                                    {rule.is_enabled ? 'Active' : 'Disabled'}
                                  </span>
                                </td>
                                <td className="px-4 py-3">
                                  <div className="flex items-center gap-1 justify-end">
                                    {isEditing ? (
                                      <>
                                        <button
                                          onClick={saveEdit}
                                          disabled={isSavingThis}
                                          className="p-1.5 rounded hover:bg-emerald-100 dark:hover:bg-emerald-900/30 text-emerald-600"
                                          title="Save"
                                        >
                                          <Save className="w-4 h-4" />
                                        </button>
                                        <button
                                          onClick={() => setEditing(null)}
                                          className="p-1.5 rounded hover:bg-muted text-muted-foreground"
                                          title="Cancel"
                                        >
                                          <X className="w-4 h-4" />
                                        </button>
                                      </>
                                    ) : (
                                      <>
                                        <button
                                          onClick={() => setEditing({ ruleId: rule.id, value: rule.rule_value })}
                                          className="p-1.5 rounded hover:bg-muted text-muted-foreground"
                                          title="Edit value"
                                        >
                                          <Edit2 className="w-4 h-4" />
                                        </button>
                                        <button
                                          onClick={() => toggleRule(rule)}
                                          disabled={isSavingThis}
                                          className="p-1.5 rounded hover:bg-muted text-muted-foreground"
                                          title={rule.is_enabled ? 'Disable rule' : 'Enable rule'}
                                        >
                                          {rule.is_enabled
                                            ? <ToggleRight className="w-5 h-5 text-emerald-600" />
                                            : <ToggleLeft  className="w-5 h-5 text-muted-foreground" />
                                          }
                                        </button>
                                        <button
                                          onClick={() => deleteRule(rule.id, rule.rule_key)}
                                          disabled={isSavingThis}
                                          className="p-1.5 rounded hover:bg-red-100 dark:hover:bg-red-900/30 text-muted-foreground hover:text-red-600"
                                          title="Remove rule"
                                        >
                                          <Trash2 className="w-4 h-4" />
                                        </button>
                                      </>
                                    )}
                                  </div>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    ) : (
                      <div className="px-4 py-6 text-center text-sm text-muted-foreground">
                        No rules configured — account uses default settings.
                      </div>
                    )}

                    {/* Add New Rule Form */}
                    <div className="p-4 bg-muted/20 border-t border-border">
                      <div className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase mb-3">
                        <Plus className="w-3.5 h-3.5" /> Add Rule
                      </div>
                      <div className="flex items-end gap-2 flex-wrap">
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Rule Key</label>
                          <select
                            className="border border-border rounded px-2 py-1.5 text-sm bg-background text-foreground min-w-[180px]"
                            value={addF.key || ''}
                            onChange={e => setAddForm(p => ({ ...p, [at.id]: { ...p[at.id], key: e.target.value, value: undefined } }))}
                          >
                            <option value="">Select rule…</option>
                            {RULE_KEYS.filter(rk => !typeRules.some(r => r.rule_key === rk.key)).map(rk => (
                              <option key={rk.key} value={rk.key}>{rk.label}</option>
                            ))}
                          </select>
                        </div>
                        {addF.key && (
                          <div>
                            <label className="block text-xs text-muted-foreground mb-1">Value</label>
                            <RuleValueInput
                              ruleKey={addF.key}
                              value={addF.value}
                              onChange={v => setAddForm(p => ({ ...p, [at.id]: { ...p[at.id], value: v } }))}
                            />
                          </div>
                        )}
                        <button
                          onClick={() => addRule(at.id)}
                          disabled={!addF.key || saving === `add-${at.id}`}
                          className="flex items-center gap-1.5 px-3 py-1.5 bg-primary text-primary-foreground rounded text-sm font-medium disabled:opacity-50"
                        >
                          {saving === `add-${at.id}` ? (
                            <div className="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
                          ) : <Plus className="w-3.5 h-3.5" />}
                          Add
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}

          {accountTypes.length === 0 && (
            <div className="text-center py-16 text-muted-foreground">
              No account types found. Create account types first.
            </div>
          )}
        </div>
      )}
    </div>
  );
}

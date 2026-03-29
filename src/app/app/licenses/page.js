'use client';

import { useState, useEffect } from 'react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import { Key, Search, AlertCircle, AlertTriangle, Plus } from 'lucide-react';

const STATUS_CONFIG = {
  active:    { label: 'Active',    color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' },
  expired:   { label: 'Expired',   color: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' },
  suspended: { label: 'Suspended', color: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400' },
  revoked:   { label: 'Revoked',   color: 'bg-red-200 text-red-800' },
};

const TYPE_CONFIG = {
  lifetime: 'Lifetime', annual: 'Annual', monthly: 'Monthly', trial: 'Trial',
};

function HistoricalWarning({ date, onContinue, onCancel, onDisable }) {
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-card rounded-xl border border-amber-400 shadow-xl max-w-md w-full p-6 space-y-4">
        <div className="flex items-center gap-3">
          <AlertTriangle className="w-6 h-6 text-amber-500 shrink-0" />
          <h2 className="font-semibold text-foreground text-lg">Historical Data Entry</h2>
        </div>
        <p className="text-muted-foreground text-sm">
          You are entering a license with an issue date in the past:{' '}
          <strong className="text-foreground">{new Date(date).toLocaleDateString('en-UG', { year: 'numeric', month: 'long', day: 'numeric' })}</strong>.
        </p>
        <p className="text-sm text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 rounded-lg p-3">
          Ensure the date is accurate. Historical records cannot be corrected automatically.
        </p>
        <div className="flex flex-col gap-2">
          <button onClick={onContinue} className="w-full bg-amber-500 text-white py-2 rounded-lg font-medium hover:bg-amber-600 transition">
            Continue — I confirm this is correct
          </button>
          <button onClick={onCancel} className="w-full border border-border py-2 rounded-lg text-sm hover:bg-muted transition">
            Cancel — Let me correct the date
          </button>
          <button onClick={onDisable} className="text-xs text-muted-foreground hover:text-foreground transition text-center">
            Disable warning for this session
          </button>
        </div>
      </div>
    </div>
  );
}

const TODAY = new Date().toISOString().split('T')[0];

const BLANK_FORM = {
  system_id:    '',
  client_name:  '',
  license_type: 'lifetime',
  issued_date:  TODAY,
  start_date:   '',
  end_date:     '',
  status:       'active',
  notes:        '',
};

export default function LicensesPage() {
  const [licenses, setLicenses]         = useState([]);
  const [systems, setSystems]           = useState([]);
  const [loading, setLoading]           = useState(true);
  const [error, setError]               = useState(null);
  const [search, setSearch]             = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  // Issue form
  const [showForm, setShowForm]           = useState(false);
  const [form, setForm]                   = useState(BLANK_FORM);
  const [submitting, setSubmitting]       = useState(false);
  const [formError, setFormError]         = useState(null);

  // Historical warning
  const [showWarning, setShowWarning]     = useState(false);
  const [warningDisabled, setWarningDisabled] = useState(false);
  const [pendingSubmit, setPendingSubmit] = useState(false);
  const toast = useToast();

  const load = () => {
    setLoading(true);
    Promise.all([
      fetchWithAuth('/api/licenses').then(r => r.json()),
      fetchWithAuth('/api/systems').then(r => r.json()),
    ]).then(([ld, sd]) => {
      setLicenses(ld.licenses || ld || []);
      setSystems(sd.systems || sd || []);
      setLoading(false);
    }).catch(e => { setError(e.message); setLoading(false); });
  };

  useEffect(() => { load(); }, []);

  const checkHistorical = (dateStr) => {
    if (!dateStr) return false;
    const d = new Date(dateStr);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return d < today;
  };

  const doSubmit = async () => {
    setSubmitting(true);
    setFormError(null);
    try {
      const payload = {
        ...form,
        is_historical: checkHistorical(form.issued_date),
      };
      const r = await fetchWithAuth('/api/licenses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await r.json();
      if (!r.ok) throw new Error(data.error || 'Failed to create license');
      toast.success('License issued');
      setForm(BLANK_FORM);
      setShowForm(false);
      setPendingSubmit(false);
      load();
    } catch (e) {
      setFormError(e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!warningDisabled && checkHistorical(form.issued_date)) {
      setShowWarning(true);
      return;
    }
    doSubmit();
  };

  const filtered = licenses.filter(l => {
    const matchSearch = !search ||
      l.client_name?.toLowerCase().includes(search.toLowerCase()) ||
      l.system_name?.toLowerCase().includes(search.toLowerCase()) ||
      l.license_type?.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all' || l.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const stats = {
    total:      licenses.length,
    active:     licenses.filter(l => l.status === 'active').length,
    expired:    licenses.filter(l => l.status === 'expired').length,
    historical: licenses.filter(l => l.is_historical).length,
  };

  if (loading) return <div className="p-6 text-muted-foreground">Loading licenses...</div>;
  if (error)   return <div className="p-6 text-destructive">Error: {error}</div>;

  return (
    <div className="p-6 max-w-6xl mx-auto space-y-6">
      {/* Historical Warning Modal */}
      {showWarning && (
        <HistoricalWarning
          date={form.issued_date}
          onContinue={() => { setShowWarning(false); doSubmit(); }}
          onCancel={() => { setShowWarning(false); }}
          onDisable={() => { setShowWarning(false); setWarningDisabled(true); doSubmit(); }}
        />
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
            <Key className="w-5 h-5 text-blue-600 dark:text-blue-400" />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-foreground">License Registry</h1>
            <p className="text-sm text-muted-foreground">All issued software licenses</p>
          </div>
        </div>
        <button
          onClick={() => setShowForm(f => !f)}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition"
        >
          <Plus className="w-4 h-4" />
          Issue License
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {[
          { label: 'Total',      value: stats.total,      color: 'text-foreground' },
          { label: 'Active',     value: stats.active,     color: 'text-emerald-600' },
          { label: 'Expired',    value: stats.expired,    color: 'text-red-600' },
          { label: 'Historical', value: stats.historical, color: 'text-amber-600' },
        ].map(({ label, value, color }) => (
          <div key={label} className="bg-card border border-border rounded-lg p-4 text-center">
            <div className={`text-2xl font-bold ${color}`}>{value}</div>
            <div className="text-xs text-muted-foreground mt-1">{label}</div>
          </div>
        ))}
      </div>

      {/* Issue Form */}
      {showForm && (
        <form onSubmit={handleSubmit} className="bg-card border border-border rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-foreground">Issue New License</h2>
          {formError && (
            <div className="text-sm text-destructive bg-destructive/10 rounded-lg p-3">{formError}</div>
          )}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">System *</label>
              <select
                required
                value={form.system_id}
                onChange={e => setForm(f => ({ ...f, system_id: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background"
              >
                <option value="">— Select system —</option>
                {systems.map(s => (
                  <option key={s.id} value={s.id}>{s.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Client Name *</label>
              <input
                required
                value={form.client_name}
                onChange={e => setForm(f => ({ ...f, client_name: e.target.value }))}
                placeholder="e.g. Acme Corp"
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">License Type</label>
              <select
                value={form.license_type}
                onChange={e => setForm(f => ({ ...f, license_type: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background"
              >
                {Object.entries(TYPE_CONFIG).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">
                Issue Date *
                {checkHistorical(form.issued_date) && (
                  <span className="ml-2 text-amber-600 text-xs font-normal">⚠ Historical</span>
                )}
              </label>
              <input
                required
                type="date"
                value={form.issued_date}
                onChange={e => setForm(f => ({ ...f, issued_date: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Start Date</label>
              <input
                type="date"
                value={form.start_date}
                onChange={e => setForm(f => ({ ...f, start_date: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">End Date</label>
              <input
                type="date"
                value={form.end_date}
                onChange={e => setForm(f => ({ ...f, end_date: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Status</label>
              <select
                value={form.status}
                onChange={e => setForm(f => ({ ...f, status: e.target.value }))}
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background"
              >
                {Object.entries(STATUS_CONFIG).map(([v, c]) => (
                  <option key={v} value={v}>{c.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Notes</label>
              <input
                value={form.notes}
                onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
                placeholder="Optional notes"
                className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            <button
              type="submit"
              disabled={submitting}
              className="px-5 py-2 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition disabled:opacity-50"
            >
              {submitting ? 'Issuing...' : 'Issue License'}
            </button>
            <button
              type="button"
              onClick={() => { setShowForm(false); setFormError(null); setForm(BLANK_FORM); }}
              className="px-4 py-2 border border-border rounded-lg text-sm text-muted-foreground hover:bg-muted transition"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by client, system, type..."
            className="w-full pl-9 pr-4 py-2 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          className="px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background"
        >
          <option value="all">All Statuses</option>
          {Object.entries(STATUS_CONFIG).map(([v, c]) => (
            <option key={v} value={v}>{c.label}</option>
          ))}
        </select>
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <div className="bg-card border border-border rounded-lg p-12 text-center">
          <Key className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-40" />
          <p className="text-muted-foreground">No licenses found.</p>
          <p className="text-xs text-muted-foreground mt-1">Issue a license above or close a deal linked to a system.</p>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-lg overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">Client</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">System</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">Type</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">Issued</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">Status</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">Start</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wide">End</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.map(l => {
                  const sc = STATUS_CONFIG[l.status] || { label: l.status, color: 'bg-muted text-muted-foreground' };
                  const isExpiringSoon = l.end_date && new Date(l.end_date) < new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) && l.status === 'active';
                  return (
                    <tr key={l.id} className="hover:bg-muted/20 transition-colors">
                      <td className="px-4 py-3 font-medium text-foreground">
                        {l.client_name || '—'}
                      </td>
                      <td className="px-4 py-3">
                        {l.system_name ? (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 font-medium">
                            {l.system_name}
                          </span>
                        ) : <span className="text-muted-foreground">—</span>}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {TYPE_CONFIG[l.license_type] || l.license_type || '—'}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {l.issued_date ? (
                          <span className="flex items-center gap-1">
                            {new Date(l.issued_date).toLocaleDateString()}
                            {l.is_historical && (
                              <span className="px-1.5 py-0.5 rounded text-xs bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 font-medium">hist</span>
                            )}
                          </span>
                        ) : '—'}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${sc.color}`}>
                          {sc.label}
                          {isExpiringSoon && <AlertCircle className="w-3 h-3" title="Expiring within 30 days" />}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {l.start_date ? new Date(l.start_date).toLocaleDateString() : '—'}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {l.end_date ? (
                          <span className={isExpiringSoon ? 'text-yellow-600 font-medium' : ''}>
                            {new Date(l.end_date).toLocaleDateString()}
                          </span>
                        ) : '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="px-4 py-2 border-t border-border text-xs text-muted-foreground">
            {filtered.length} license{filtered.length !== 1 ? 's' : ''}
            {statusFilter !== 'all' || search ? ` (filtered from ${licenses.length} total)` : ''}
          </div>
        </div>
      )}
    </div>
  );
}

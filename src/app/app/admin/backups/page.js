'use client';

import { useEffect, useState, useCallback } from 'react';
import { Database, Plus, Trash2, Download, RotateCcw, Clock, HardDrive, Table2, Rows3, CloudUpload, AlertTriangle, CheckCircle2, Loader2, Search, RefreshCw } from 'lucide-react';
import { useToast } from '@/components/ui/Toast';
import { confirmDelete, confirmDangerous } from '@/lib/confirm';

const STATUS_BADGE = {
  completed: 'bg-emerald-100 text-emerald-700',
  uploaded: 'bg-blue-100 text-blue-700',
  in_progress: 'bg-yellow-100 text-yellow-700',
  failed: 'bg-red-100 text-red-700',
  approved: 'bg-emerald-100 text-emerald-700',
  pending: 'bg-yellow-100 text-yellow-700',
  rejected: 'bg-red-100 text-red-700',
};

function formatBytes(bytes) {
  if (!bytes) return '—';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1048576).toFixed(2) + ' MB';
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleString('en-UG', { dateStyle: 'medium', timeStyle: 'short' });
}

export default function AdminBackupsPage() {
  const [backups, setBackups] = useState([]);
  const [restorations, setRestorations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [tab, setTab] = useState('backups');
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ name: '', description: '', backup_type: 'full' });
  const toast = useToast();

  const fetchBackups = useCallback(async () => {
    try {
      const res = await fetch('/api/backups', { credentials: 'include' });
      const data = await res.json();
      if (data.success) setBackups(data.data || []);
    } catch {} finally { setLoading(false); }
  }, []);

  const fetchRestorations = useCallback(async () => {
    try {
      const res = await fetch('/api/backups/restore', { credentials: 'include' });
      const data = await res.json();
      if (data.success) setRestorations(data.data || []);
    } catch {}
  }, []);

  useEffect(() => {
    fetchBackups();
    fetchRestorations();
  }, [fetchBackups, fetchRestorations]);

  const createBackup = async () => {
    setCreating(true);
    try {
      const res = await fetch('/api/backups', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          name: form.name.trim() || undefined,
          description: form.description.trim() || undefined,
          backup_type: form.backup_type,
        }),
      });
      const data = await res.json();
      if (data.success) {
        toast.success(`Backup "${data.data.name}" created — ${data.data.tables} tables, ${data.data.rows?.toLocaleString()} rows`);
        setShowCreate(false);
        setForm({ name: '', description: '', backup_type: 'full' });
        fetchBackups();
      } else {
        toast.error(data.error || 'Failed to create backup');
      }
    } catch {
      toast.error('Backup creation failed');
    } finally {
      setCreating(false);
    }
  };

  const deleteBackup = async (id, name) => {
    if (!await confirmDelete(name)) return;
    try {
      const res = await fetch(`/api/backups?id=${encodeURIComponent(id)}`, { method: 'DELETE', credentials: 'include' });
      const data = await res.json();
      if (data.success) {
        toast.success('Backup deleted');
        fetchBackups();
      } else toast.error(data.error);
    } catch { toast.error('Failed to delete'); }
  };

  const requestRestore = async (backupId, backupName) => {
    if (!await confirmDangerous(`Request restoration of "${backupName}"? This will create a restore request.`, 'Restore Backup')) return;
    try {
      const res = await fetch('/api/backups/restore', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ backup_id: backupId }),
      });
      const data = await res.json();
      if (data.success) {
        toast.success(data.message || 'Restoration requested');
        fetchRestorations();
      } else toast.error(data.error);
    } catch { toast.error('Failed to request restore'); }
  };

  const totalSize = backups.reduce((sum, b) => sum + (parseInt(b.file_size) || 0), 0);
  const uploadedCount = backups.filter(b => b.status === 'uploaded').length;

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Database className="w-6 h-6" style={{ color: 'var(--theme-primary, #3b82f6)' }} />
            System Backups
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            {backups.length} backups · {formatBytes(totalSize)} total · {uploadedCount} cloud-synced
          </p>
        </div>
        <div className="flex gap-2">
          <button onClick={() => { fetchBackups(); fetchRestorations(); }} className="p-2 rounded-lg border border-border hover:bg-muted transition">
            <RefreshCw className="w-4 h-4 text-muted-foreground" />
          </button>
          <button
            onClick={() => setShowCreate(!showCreate)}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium text-white transition"
            style={{ background: 'var(--theme-primary, #3b82f6)' }}
          >
            {showCreate ? 'Cancel' : <><Plus className="w-4 h-4" /> New Backup</>}
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-card rounded-xl border p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1"><Database className="w-3.5 h-3.5" /> Total Backups</div>
          <div className="text-2xl font-bold text-foreground">{backups.length}</div>
        </div>
        <div className="bg-card rounded-xl border p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1"><HardDrive className="w-3.5 h-3.5" /> Total Size</div>
          <div className="text-2xl font-bold text-foreground">{formatBytes(totalSize)}</div>
        </div>
        <div className="bg-card rounded-xl border p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1"><CloudUpload className="w-3.5 h-3.5" /> Cloud Synced</div>
          <div className="text-2xl font-bold text-foreground">{uploadedCount}</div>
        </div>
        <div className="bg-card rounded-xl border p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1"><RotateCcw className="w-3.5 h-3.5" /> Restorations</div>
          <div className="text-2xl font-bold text-foreground">{restorations.length}</div>
        </div>
      </div>

      {/* Create Form */}
      {showCreate && (
        <div className="bg-card rounded-xl border p-5 space-y-4">
          <h2 className="font-semibold text-foreground">Create New Backup</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Name (optional)</label>
              <input
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder={`xhaira_backup_${new Date().toISOString().slice(0, 10)}`}
                className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm"
              />
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Type</label>
              <select
                value={form.backup_type}
                onChange={e => setForm(f => ({ ...f, backup_type: e.target.value }))}
                className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm"
              >
                <option value="full">Full (Schema + Data)</option>
                <option value="data_only">Data Only</option>
                <option value="schema_only">Schema Only</option>
              </select>
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">Description</label>
              <input
                value={form.description}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Pre-migration backup..."
                className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm"
              />
            </div>
          </div>
          <button
            onClick={createBackup}
            disabled={creating}
            className="flex items-center gap-2 px-6 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition"
            style={{ background: 'var(--theme-primary, #3b82f6)' }}
          >
            {creating ? <><Loader2 className="w-4 h-4 animate-spin" /> Creating...</> : <><Database className="w-4 h-4" /> Create Backup</>}
          </button>
          {creating && (
            <p className="text-xs text-muted-foreground">This may take a moment — dumping all tables and optionally uploading to cloud storage...</p>
          )}
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b border-border">
        <button
          onClick={() => setTab('backups')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition ${tab === 'backups' ? 'text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'}`}
          style={tab === 'backups' ? { borderColor: 'var(--theme-primary, #3b82f6)', color: 'var(--theme-primary, #3b82f6)' } : {}}
        >
          <Database className="w-4 h-4 inline mr-1.5" />Backups ({backups.length})
        </button>
        <button
          onClick={() => setTab('restorations')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition ${tab === 'restorations' ? 'text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'}`}
          style={tab === 'restorations' ? { borderColor: 'var(--theme-primary, #3b82f6)', color: 'var(--theme-primary, #3b82f6)' } : {}}
        >
          <RotateCcw className="w-4 h-4 inline mr-1.5" />Restorations ({restorations.length})
        </button>
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2" style={{ borderColor: 'var(--theme-primary, #3b82f6)' }} /></div>
      ) : tab === 'backups' ? (
        backups.length === 0 ? (
          <div className="text-center py-16">
            <Database className="w-12 h-12 mx-auto text-muted-foreground mb-3" />
            <p className="text-muted-foreground">No backups yet. Create your first backup to protect your data.</p>
          </div>
        ) : (
          <div className="bg-card rounded-xl border divide-y divide-border">
            {backups.map(b => (
              <div key={b.id} className="p-4 hover:bg-muted/50 transition">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-foreground truncate">{b.name}</span>
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_BADGE[b.status] || 'bg-muted text-foreground'}`}>
                        {b.status === 'in_progress' ? 'In Progress' : b.status}
                      </span>
                      {b.backup_type && b.backup_type !== 'full' && (
                        <span className="px-2 py-0.5 rounded-full text-xs bg-muted text-muted-foreground">{b.backup_type}</span>
                      )}
                    </div>
                    <div className="flex items-center gap-4 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{formatDate(b.created_at)}</span>
                      {b.table_count && <span className="flex items-center gap-1"><Table2 className="w-3 h-3" />{b.table_count} tables</span>}
                      {b.row_count && <span className="flex items-center gap-1"><Rows3 className="w-3 h-3" />{parseInt(b.row_count).toLocaleString()} rows</span>}
                      <span className="flex items-center gap-1"><HardDrive className="w-3 h-3" />{formatBytes(b.file_size)}</span>
                      {b.file_url && <span className="flex items-center gap-1 text-blue-600"><CloudUpload className="w-3 h-3" />Cloud</span>}
                      {b.created_by_name && <span>by {b.created_by_name}</span>}
                    </div>
                    {b.description && <p className="text-xs text-muted-foreground mt-1">{b.description}</p>}
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    {b.file_url && (
                      <a href={b.file_url} target="_blank" rel="noopener noreferrer" className="p-2 rounded-lg hover:bg-muted transition" title="Download">
                        <Download className="w-4 h-4 text-muted-foreground" />
                      </a>
                    )}
                    <button
                      onClick={() => requestRestore(b.id, b.name)}
                      className="p-2 rounded-lg hover:bg-blue-50 transition"
                      title="Request restoration"
                    >
                      <RotateCcw className="w-4 h-4 text-blue-600" />
                    </button>
                    <button
                      onClick={() => deleteBackup(b.id, b.name)}
                      className="p-2 rounded-lg hover:bg-red-50 transition"
                      title="Delete backup"
                    >
                      <Trash2 className="w-4 h-4 text-red-500" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )
      ) : (
        restorations.length === 0 ? (
          <div className="text-center py-16">
            <RotateCcw className="w-12 h-12 mx-auto text-muted-foreground mb-3" />
            <p className="text-muted-foreground">No restoration requests yet.</p>
          </div>
        ) : (
          <div className="bg-card rounded-xl border divide-y divide-border">
            {restorations.map(r => (
              <div key={r.id} className="p-4 hover:bg-muted/50 transition">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-foreground">{r.backup_name}</span>
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_BADGE[r.status] || 'bg-muted text-foreground'}`}>
                        {r.status}
                      </span>
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Requested {formatDate(r.created_at)} by {r.requested_by_name || 'Unknown'}
                      {r.completed_at && ` · Completed ${formatDate(r.completed_at)}`}
                    </div>
                    {r.notes && <p className="text-xs text-muted-foreground mt-1">{r.notes}</p>}
                  </div>
                  {r.status === 'approved' && (
                    <div className="flex items-center gap-1 text-xs text-emerald-600">
                      <CheckCircle2 className="w-4 h-4" /> Approved
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )
      )}
    </div>
  );
}

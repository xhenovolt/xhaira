'use client';

import { useEffect, useState } from 'react';
import { Save, ArrowLeft } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const CATEGORY_LABELS = {
  general: 'General',
  members: 'Members',
  accounts: 'Accounts',
  loans: 'Loans',
  transfers: 'Transfers',
  ui: 'Interface',
  notifications: 'Notifications',
};

const CATEGORY_ORDER = ['general', 'members', 'accounts', 'loans', 'transfers', 'ui', 'notifications'];

export default function SACCOConfigurationsPage() {
  const toast = useToast();
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState({});
  const [pendingChanges, setPendingChanges] = useState({});

  const fetchConfigs = async () => {
    try {
      const res = await fetchWithAuth('/api/sacco-configurations');
      const json = await res.json();
      if (json.success) setConfigs(json.data || []);
    } catch {
      toast.error('Failed to load configurations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchConfigs(); }, []);

  const getValue = (config) => {
    const key = config.config_key;
    if (key in pendingChanges) return pendingChanges[key];
    if (config.config_type === 'boolean') return config.config_value === true || config.config_value === 'true';
    return config.config_value ?? '';
  };

  const handleToggle = (config) => {
    if (!config.is_editable) return;
    const current = getValue(config);
    setPendingChanges(prev => ({ ...prev, [config.config_key]: !current }));
  };

  const handleTextChange = (config, value) => {
    if (!config.is_editable) return;
    setPendingChanges(prev => ({ ...prev, [config.config_key]: value }));
  };

  const handleSave = async (config) => {
    const key = config.config_key;
    if (!(key in pendingChanges)) return;
    setSaving(prev => ({ ...prev, [key]: true }));
    try {
      const res = await fetchWithAuth('/api/sacco-configurations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config_key: key, config_value: pendingChanges[key] }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Configuration saved');
        setPendingChanges(prev => {
          const next = { ...prev };
          delete next[key];
          return next;
        });
        fetchConfigs();
      } else {
        toast.error(json.error || 'Save failed');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(prev => ({ ...prev, [key]: false }));
    }
  };

  const hasPending = Object.keys(pendingChanges).length > 0;

  const handleSaveAll = async () => {
    const keys = Object.keys(pendingChanges);
    if (!keys.length) return;
    for (const key of keys) {
      const config = configs.find(c => c.config_key === key);
      if (config) await handleSave(config);
    }
  };

  const grouped = configs.reduce((acc, c) => {
    const cat = c.category || 'general';
    if (!acc[cat]) acc[cat] = [];
    acc[cat].push(c);
    return acc;
  }, {});

  if (loading) return (
    <div className="flex justify-center py-20">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
    </div>
  );

  return (
    <div className="p-6 space-y-6 max-w-3xl">
      <div className="flex items-center gap-3">
        <Link href="/app/settings" className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
          <ArrowLeft className="w-4 h-4" /> Settings
        </Link>
      </div>

      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">SACCO Configurations</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Global system toggles and settings for members, accounts, loans, and transfers.
          </p>
        </div>
        {hasPending && (
          <button onClick={handleSaveAll}
            className="flex items-center gap-1.5 px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
            <Save className="w-3.5 h-3.5" /> Save All Changes
          </button>
        )}
      </div>

      {hasPending && (
        <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg text-sm text-amber-700 dark:text-amber-400">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0" />
          {Object.keys(pendingChanges).length} unsaved change{Object.keys(pendingChanges).length !== 1 ? 's' : ''}.
        </div>
      )}

      <div className="space-y-6">
        {CATEGORY_ORDER.map(category => {
          const catConfigs = grouped[category];
          if (!catConfigs?.length) return null;
          return (
            <div key={category} className="bg-card border border-border rounded-xl overflow-hidden">
              <div className="px-5 py-3 bg-muted/30 border-b border-border">
                <h3 className="font-semibold text-sm text-foreground">{CATEGORY_LABELS[category] || category}</h3>
              </div>
              <div className="divide-y divide-border">
                {catConfigs.map(config => {
                  const isPending = config.config_key in pendingChanges;
                  const isSaving = saving[config.config_key];
                  const value = getValue(config);
                  return (
                    <div key={config.config_key} className="flex items-start gap-4 px-5 py-4">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-foreground">{config.label}</span>
                          {!config.is_editable && (
                            <span className="text-xs text-muted-foreground bg-muted px-1.5 py-0.5 rounded">Read-only</span>
                          )}
                          {isPending && (
                            <span className="text-xs text-amber-600 dark:text-amber-400">● Unsaved</span>
                          )}
                        </div>
                        {config.description && (
                          <p className="text-xs text-muted-foreground mt-0.5">{config.description}</p>
                        )}
                        <p className="text-xs text-muted-foreground/60 font-mono mt-0.5">{config.config_key}</p>
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        {config.config_type === 'boolean' ? (
                          <button
                            onClick={() => handleToggle(config)}
                            disabled={!config.is_editable}
                            className={`relative w-10 h-5 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-40 disabled:cursor-not-allowed ${
                              value ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'
                            }`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${
                              value ? 'translate-x-5' : 'translate-x-0'
                            }`} />
                          </button>
                        ) : (
                          <input
                            type={config.config_type === 'number' ? 'number' : 'text'}
                            value={value}
                            onChange={e => handleTextChange(config, config.config_type === 'number' ? parseFloat(e.target.value) : e.target.value)}
                            disabled={!config.is_editable}
                            className="w-32 px-2.5 py-1.5 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
                          />
                        )}
                        {isPending && (
                          <button
                            onClick={() => handleSave(config)}
                            disabled={isSaving}
                            className="px-2.5 py-1 text-xs bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                          >
                            {isSaving ? '...' : 'Save'}
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

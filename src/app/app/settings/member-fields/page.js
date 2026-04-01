'use client';

import { useEffect, useState } from 'react';
import { Save, RotateCcw, ArrowLeft } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const SECTION_LABELS = {
  personal: 'Personal Details',
  identification: 'Identification',
  contact: 'Contact',
  employment: 'Employment',
  kin: 'Next of Kin',
  financial: 'Financial',
  other: 'Other',
};

export default function MemberFieldsPage() {
  const toast = useToast();
  const [fields, setFields] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);

  const fetchFields = async () => {
    try {
      const res = await fetchWithAuth('/api/member-field-configs');
      const json = await res.json();
      if (json.success) setFields(json.data || []);
    } catch {
      toast.error('Failed to load field configs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchFields(); }, []);

  const toggleField = (fieldName, key) => {
    setFields(prev => prev.map(f =>
      f.field_name === fieldName ? { ...f, [key]: !f[key] } : f
    ));
    setDirty(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const updates = fields.map(f => ({
        field_name: f.field_name,
        is_active: f.is_active,
        is_required: f.is_required,
        label: f.label,
      }));
      const res = await fetchWithAuth('/api/member-field-configs', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ updates }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Field configuration saved');
        setDirty(false);
      } else {
        toast.error(json.error || 'Save failed');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    fetchFields();
    setDirty(false);
  };

  // Group fields by section
  const grouped = fields.reduce((acc, f) => {
    const sec = f.section || 'other';
    if (!acc[sec]) acc[sec] = [];
    acc[sec].push(f);
    return acc;
  }, {});

  const sectionOrder = ['personal', 'identification', 'contact', 'employment', 'kin', 'financial', 'other'];

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
          <h1 className="text-2xl font-bold text-foreground">Member Field Configuration</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Control which fields appear on the member registration and profile forms. Required fields must be filled in during registration.
          </p>
        </div>
        <div className="flex gap-2">
          {dirty && (
            <button onClick={handleReset} className="flex items-center gap-1.5 px-3 py-2 text-sm border border-border rounded-lg hover:bg-muted transition">
              <RotateCcw className="w-3.5 h-3.5" /> Reset
            </button>
          )}
          <button onClick={handleSave} disabled={saving || !dirty}
            className="flex items-center gap-1.5 px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition">
            <Save className="w-3.5 h-3.5" /> {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>

      {dirty && (
        <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg text-sm text-amber-700 dark:text-amber-400">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0" />
          You have unsaved changes.
        </div>
      )}

      <div className="space-y-6">
        {sectionOrder.map(section => {
          const sectionFields = grouped[section];
          if (!sectionFields?.length) return null;
          return (
            <div key={section} className="bg-card border border-border rounded-xl overflow-hidden">
              <div className="px-5 py-3 bg-muted/30 border-b border-border">
                <h3 className="font-semibold text-sm text-foreground">{SECTION_LABELS[section] || section}</h3>
              </div>
              <div className="divide-y divide-border">
                {sectionFields.map(field => (
                  <div key={field.field_name} className="flex items-center justify-between px-5 py-3.5">
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium text-foreground">{field.label}</div>
                      <div className="text-xs text-muted-foreground font-mono mt-0.5">{field.field_name}</div>
                    </div>
                    <div className="flex items-center gap-4 ml-4">
                      {/* Active toggle */}
                      <label className="flex items-center gap-2 cursor-pointer">
                        <span className="text-xs text-muted-foreground w-12 text-right">Active</span>
                        <button
                          onClick={() => toggleField(field.field_name, 'is_active')}
                          className={`relative w-9 h-5 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-ring ${
                            field.is_active ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'
                          }`}
                        >
                          <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${
                            field.is_active ? 'translate-x-4' : 'translate-x-0'
                          }`} />
                        </button>
                      </label>
                      {/* Required toggle */}
                      <label className="flex items-center gap-2 cursor-pointer">
                        <span className="text-xs text-muted-foreground w-16 text-right">Required</span>
                        <button
                          onClick={() => {
                            if (!field.is_active) return; // can't require inactive field
                            toggleField(field.field_name, 'is_required');
                          }}
                          disabled={!field.is_active}
                          className={`relative w-9 h-5 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-40 disabled:cursor-not-allowed ${
                            field.is_required && field.is_active ? 'bg-emerald-600' : 'bg-gray-200 dark:bg-gray-700'
                          }`}
                        >
                          <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${
                            field.is_required && field.is_active ? 'translate-x-4' : 'translate-x-0'
                          }`} />
                        </button>
                      </label>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

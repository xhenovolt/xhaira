'use client';

import { useEffect, useState } from 'react';
import { Plus, Users, Search, UserCheck, UserX, Phone, Mail, CreditCard, ChevronDown, ChevronUp, Settings } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const STATUS_STYLES = {
  active: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  inactive: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
  suspended: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  exited: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  blocked: 'bg-red-200 text-red-800 dark:bg-red-900/40 dark:text-red-300',
};

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

const EMPTY_FORM = {
  first_name: '', last_name: '', other_name: '',
  email: '', phone: '', national_id: '', id_type: 'national_id',
  gender: '', date_of_birth: '', address: '',
  occupation: '', employer: '',
  next_of_kin_name: '', next_of_kin_phone: '', next_of_kin_relationship: '',
  notes: '',
};

export default function MembersPage() {
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const toast = useToast();

  const fetchMembers = async () => {
    try {
      const params = new URLSearchParams();
      if (search) params.set('search', search);
      if (statusFilter) params.set('status', statusFilter);
      const res = await fetchWithAuth(`/api/members?${params}`);
      const json = await res.json();
      if (json.success) setMembers(json.data || []);
    } catch (err) {
      console.error('Failed to fetch members:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchMembers(); }, [search, statusFilter]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.first_name.trim() || !form.last_name.trim()) return;
    setSaving(true);
    try {
      const res = await fetchWithAuth('/api/members', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const json = await res.json();
      if (json.success) {
        toast.success(`${json.data.full_name} registered — ${json.data.membership_number}`);
        setShowForm(false);
        setForm(EMPTY_FORM);
        fetchMembers();
      } else {
        toast.error(json.error || 'Failed to register member');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const activeCount = members.filter(m => m.status === 'active').length;
  const totalBalance = members.reduce((sum, m) => sum + parseFloat(m.total_balance || 0), 0);

  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';
  const labelClass = 'block text-xs font-medium text-muted-foreground mb-1';

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Users className="w-6 h-6 text-blue-500" /> SACCO Members
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Manage cooperative membership, accounts, and balances</p>
        </div>
        <div className="flex gap-2">
          <Link href="/app/settings/member-fields"
            className="flex items-center gap-1 px-3 py-2 border border-border text-muted-foreground rounded-lg text-sm hover:text-foreground hover:bg-muted transition">
            <Settings className="w-4 h-4" /> Configure Fields
          </Link>
          <button onClick={() => setShowForm(!showForm)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition">
            <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'New Member'}
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Members</div>
          <div className="text-2xl font-bold text-foreground mt-1">{members.length}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Active</div>
          <div className="text-2xl font-bold text-emerald-600 mt-1">{activeCount}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Balance</div>
          <div className="text-2xl font-bold text-foreground mt-1">{fmtCurrency(totalBalance)}</div>
        </div>
      </div>

      {/* Member Registration Form */}
      {showForm && (
        <div className="bg-card border border-border rounded-xl p-6">
          <h3 className="font-semibold text-foreground mb-5">Register New Member</h3>
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Personal Details */}
            <div>
              <h4 className="text-xs font-semibold text-muted-foreground uppercase mb-3 pb-1 border-b border-border">Personal Details</h4>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className={labelClass}>First Name *</label>
                  <input value={form.first_name} onChange={e => setForm(f => ({ ...f, first_name: e.target.value }))}
                    placeholder="e.g. WEKESA" className={inputClass} required />
                </div>
                <div>
                  <label className={labelClass}>Last Name *</label>
                  <input value={form.last_name} onChange={e => setForm(f => ({ ...f, last_name: e.target.value }))}
                    placeholder="e.g. MUHAMMAD" className={inputClass} required />
                </div>
                <div>
                  <label className={labelClass}>Other / Middle Name</label>
                  <input value={form.other_name} onChange={e => setForm(f => ({ ...f, other_name: e.target.value }))}
                    placeholder="Optional" className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>Gender</label>
                  <select value={form.gender} onChange={e => setForm(f => ({ ...f, gender: e.target.value }))} className={inputClass}>
                    <option value="">— Select —</option>
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                <div>
                  <label className={labelClass}>Date of Birth</label>
                  <input type="date" value={form.date_of_birth} onChange={e => setForm(f => ({ ...f, date_of_birth: e.target.value }))} className={inputClass} />
                </div>
              </div>
            </div>

            {/* Identification */}
            <div>
              <h4 className="text-xs font-semibold text-muted-foreground uppercase mb-3 pb-1 border-b border-border">Identification</h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className={labelClass}>National ID / Passport Number</label>
                  <input value={form.national_id} onChange={e => setForm(f => ({ ...f, national_id: e.target.value }))}
                    placeholder="ID number" className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>ID Type</label>
                  <select value={form.id_type} onChange={e => setForm(f => ({ ...f, id_type: e.target.value }))} className={inputClass}>
                    <option value="national_id">National ID</option>
                    <option value="passport">Passport</option>
                    <option value="driving_licence">Driving Licence</option>
                    <option value="voter_card">Voter Card</option>
                    <option value="work_permit">Work Permit</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Contact */}
            <div>
              <h4 className="text-xs font-semibold text-muted-foreground uppercase mb-3 pb-1 border-b border-border">Contact Information</h4>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className={labelClass}>Phone Number</label>
                  <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                    placeholder="+256 700 000 000" className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>Email Address</label>
                  <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    placeholder="email@example.com" className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>Physical Address</label>
                  <input value={form.address} onChange={e => setForm(f => ({ ...f, address: e.target.value }))}
                    placeholder="e.g. Kampala, Uganda" className={inputClass} />
                </div>
              </div>
            </div>

            {/* Advanced toggle */}
            <button type="button" onClick={() => setShowAdvanced(v => !v)}
              className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition">
              {showAdvanced ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
              {showAdvanced ? 'Hide' : 'Show'} Employment & Next of Kin
            </button>

            {showAdvanced && (
              <div className="space-y-5">
                {/* Employment */}
                <div>
                  <h4 className="text-xs font-semibold text-muted-foreground uppercase mb-3 pb-1 border-b border-border">Employment</h4>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className={labelClass}>Occupation</label>
                      <input value={form.occupation} onChange={e => setForm(f => ({ ...f, occupation: e.target.value }))}
                        placeholder="e.g. Farmer, Teacher" className={inputClass} />
                    </div>
                    <div>
                      <label className={labelClass}>Employer / Business</label>
                      <input value={form.employer} onChange={e => setForm(f => ({ ...f, employer: e.target.value }))}
                        placeholder="Employer name" className={inputClass} />
                    </div>
                  </div>
                </div>
                {/* Next of Kin */}
                <div>
                  <h4 className="text-xs font-semibold text-muted-foreground uppercase mb-3 pb-1 border-b border-border">Next of Kin</h4>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label className={labelClass}>Full Name</label>
                      <input value={form.next_of_kin_name} onChange={e => setForm(f => ({ ...f, next_of_kin_name: e.target.value }))}
                        placeholder="Name" className={inputClass} />
                    </div>
                    <div>
                      <label className={labelClass}>Phone</label>
                      <input value={form.next_of_kin_phone} onChange={e => setForm(f => ({ ...f, next_of_kin_phone: e.target.value }))}
                        placeholder="Phone number" className={inputClass} />
                    </div>
                    <div>
                      <label className={labelClass}>Relationship</label>
                      <input value={form.next_of_kin_relationship} onChange={e => setForm(f => ({ ...f, next_of_kin_relationship: e.target.value }))}
                        placeholder="e.g. Spouse, Parent" className={inputClass} />
                    </div>
                  </div>
                </div>
                <div>
                  <label className={labelClass}>Notes</label>
                  <textarea value={form.notes} onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
                    placeholder="Any additional information..." rows={2} className={inputClass} />
                </div>
              </div>
            )}

            <button type="submit" disabled={saving}
              className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition">
              {saving ? 'Registering...' : 'Register Member'}
            </button>
          </form>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Search by name, email, phone, or membership number..."
            className="w-full pl-9 pr-4 py-2 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
        </div>
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}
          className="px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="suspended">Suspended</option>
          <option value="exited">Exited</option>
          <option value="blocked">Blocked</option>
        </select>
      </div>

      {/* Members Table */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Loading members...</div>
      ) : members.length === 0 ? (
        <div className="bg-card border border-border rounded-xl p-12 text-center">
          <Users className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-40" />
          <p className="text-muted-foreground">No members found</p>
          <p className="text-xs text-muted-foreground mt-1">Register your first SACCO member to get started</p>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Member</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Contact</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Membership #</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Accounts</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Balance</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Status</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Joined</th>
                </tr>
              </thead>
              <tbody>
                {members.map(m => (
                  <tr key={m.id} className="border-b border-border last:border-0 hover:bg-muted/20 transition">
                    <td className="px-4 py-3">
                      <Link href={`/app/members/${m.id}`} className="font-medium text-foreground hover:text-blue-600 transition">
                        {m.full_name}
                      </Link>
                      {m.occupation && <div className="text-xs text-muted-foreground">{m.occupation}</div>}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      <div className="flex flex-col gap-0.5 text-xs">
                        {m.email && <span className="flex items-center gap-1"><Mail className="w-3 h-3" />{m.email}</span>}
                        {m.phone && <span className="flex items-center gap-1"><Phone className="w-3 h-3" />{m.phone}</span>}
                      </div>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{m.membership_number}</td>
                    <td className="px-4 py-3">
                      <span className="flex items-center gap-1 text-xs">
                        <CreditCard className="w-3 h-3 text-muted-foreground" /> {m.account_count || 0}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right font-medium">{fmtCurrency(m.total_balance)}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${STATUS_STYLES[m.status] || ''}`}>
                        {m.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">
                      {m.joined_date ? new Date(m.joined_date).toLocaleDateString() : m.joined_at ? new Date(m.joined_at).toLocaleDateString() : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}


function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

export default function MembersPage() {
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const [form, setForm] = useState({
    full_name: '', email: '', phone: '', national_id: '', gender: '', date_of_birth: '', address: '',
  });

  const fetchMembers = async () => {
    try {
      const params = new URLSearchParams();
      if (search) params.set('search', search);
      if (statusFilter) params.set('status', statusFilter);
      const res = await fetchWithAuth(`/api/members?${params}`);
      const json = await res.json();
      if (json.success) setMembers(json.data || []);
    } catch (err) {
      console.error('Failed to fetch members:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchMembers(); }, [search, statusFilter]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.full_name.trim()) return;
    setSaving(true);
    try {
      const res = await fetchWithAuth('/api/members', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Member registered successfully');
        setShowForm(false);
        setForm({ full_name: '', email: '', phone: '', national_id: '', gender: '', date_of_birth: '', address: '' });
        fetchMembers();
      } else {
        toast.error(json.error || 'Failed to register member');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const activeCount = members.filter(m => m.status === 'active').length;
  const totalBalance = members.reduce((sum, m) => sum + parseFloat(m.total_balance || 0), 0);

  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Users className="w-6 h-6 text-blue-500" /> SACCO Members
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Manage cooperative membership, accounts, and balances</p>
        </div>
        <button onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition">
          <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'New Member'}
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Members</div>
          <div className="text-2xl font-bold mt-1">{members.length}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Active Members</div>
          <div className="text-2xl font-bold mt-1 text-emerald-600">{activeCount}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs font-medium text-muted-foreground uppercase">Total Balances</div>
          <div className="text-2xl font-bold mt-1 text-blue-600">{fmtCurrency(totalBalance)}</div>
        </div>
      </div>

      {/* Registration Form */}
      {showForm && (
        <form onSubmit={handleSubmit} className="bg-card border border-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-foreground">Register New Member</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Full Name *</label>
              <input value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
                required placeholder="John Doe" className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Email</label>
              <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                placeholder="john@example.com" className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Phone</label>
              <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                placeholder="+256 700 000 000" className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">National ID</label>
              <input value={form.national_id} onChange={e => setForm(f => ({ ...f, national_id: e.target.value }))}
                placeholder="CM..." className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Gender</label>
              <select value={form.gender} onChange={e => setForm(f => ({ ...f, gender: e.target.value }))} className={inputClass}>
                <option value="">—</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Date of Birth</label>
              <input type="date" value={form.date_of_birth} onChange={e => setForm(f => ({ ...f, date_of_birth: e.target.value }))} className={inputClass} />
            </div>
            <div className="sm:col-span-2 lg:col-span-3">
              <label className="block text-xs font-medium text-muted-foreground mb-1">Address</label>
              <input value={form.address} onChange={e => setForm(f => ({ ...f, address: e.target.value }))}
                placeholder="Physical address" className={inputClass} />
            </div>
          </div>
          <button type="submit" disabled={saving}
            className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition">
            {saving ? 'Registering...' : 'Register Member'}
          </button>
        </form>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Search by name, email, phone, or membership number..."
            className="w-full pl-9 pr-4 py-2 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
        </div>
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}
          className="px-3 py-2 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring [&>option]:bg-background">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="suspended">Suspended</option>
          <option value="exited">Exited</option>
        </select>
      </div>

      {/* Members Table */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Loading members...</div>
      ) : members.length === 0 ? (
        <div className="bg-card border border-border rounded-xl p-12 text-center">
          <Users className="w-10 h-10 text-muted-foreground mx-auto mb-3 opacity-40" />
          <p className="text-muted-foreground">No members found</p>
          <p className="text-xs text-muted-foreground mt-1">Register your first SACCO member to get started</p>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Member</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Contact</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Membership #</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Accounts</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Balance</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Status</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase">Joined</th>
                </tr>
              </thead>
              <tbody>
                {members.map(m => (
                  <tr key={m.id} className="border-b border-border last:border-0 hover:bg-muted/20 transition">
                    <td className="px-4 py-3">
                      <Link href={`/app/members/${m.id}`} className="font-medium text-foreground hover:text-blue-600 transition">
                        {m.full_name}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      <div className="flex flex-col gap-0.5 text-xs">
                        {m.email && <span className="flex items-center gap-1"><Mail className="w-3 h-3" />{m.email}</span>}
                        {m.phone && <span className="flex items-center gap-1"><Phone className="w-3 h-3" />{m.phone}</span>}
                      </div>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{m.membership_number}</td>
                    <td className="px-4 py-3">
                      <span className="flex items-center gap-1 text-xs">
                        <CreditCard className="w-3 h-3 text-muted-foreground" /> {m.account_count || 0}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right font-medium">{fmtCurrency(m.total_balance)}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${STATUS_STYLES[m.status] || ''}`}>
                        {m.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">
                      {m.joined_at ? new Date(m.joined_at).toLocaleDateString() : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

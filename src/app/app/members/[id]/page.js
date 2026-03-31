'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Users, Mail, Phone, CreditCard, Plus, Edit2, Save, X, IdCard, MapPin, Calendar, ArrowDownRight, ArrowUpRight, History } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const STATUS_STYLES = {
  active: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  inactive: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
  suspended: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  exited: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  frozen: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
  closed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  dormant: 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-500',
};

const ACCOUNT_TYPES = ['savings', 'loan', 'investment', 'shares', 'fixed_deposit'];

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

export default function MemberDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  const toast = useToast();
  const [member, setMember] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editForm, setEditForm] = useState({});
  const [showNewAccount, setShowNewAccount] = useState(false);
  const [newAccount, setNewAccount] = useState({ account_type: 'savings', currency: 'UGX' });
  const [creatingAccount, setCreatingAccount] = useState(false);
  // Transaction state
  const [txModal, setTxModal] = useState(null); // { action: 'deposit'|'withdraw', accountId, accountNumber }
  const [txAmount, setTxAmount] = useState('');
  const [txDescription, setTxDescription] = useState('');
  const [txLoading, setTxLoading] = useState(false);
  const [ledger, setLedger] = useState([]); // ledger entries for selected account
  const [selectedAccount, setSelectedAccount] = useState(null);

  const fetchData = async () => {
    try {
      const [memberRes, accountsRes] = await Promise.all([
        fetchWithAuth(`/api/members/${id}`),
        fetchWithAuth(`/api/members/${id}/accounts`),
      ]);
      const memberJson = await memberRes.json();
      const accountsJson = await accountsRes.json();
      if (memberJson.success) {
        setMember(memberJson.data);
        setEditForm({
          full_name: memberJson.data.full_name || '',
          email: memberJson.data.email || '',
          phone: memberJson.data.phone || '',
          national_id: memberJson.data.national_id || '',
          gender: memberJson.data.gender || '',
          date_of_birth: memberJson.data.date_of_birth?.split('T')[0] || '',
          address: memberJson.data.address || '',
        });
      }
      if (accountsJson.success) setAccounts(accountsJson.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, [id]);

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetchWithAuth(`/api/members/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editForm),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Member updated');
        setEditing(false);
        fetchData();
      } else {
        toast.error(json.error || 'Update failed');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const handleStatusChange = async (newStatus) => {
    try {
      const res = await fetchWithAuth(`/api/members/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success(`Member ${newStatus}`);
        fetchData();
      } else {
        toast.error(json.error || 'Failed to update status');
      }
    } catch {
      toast.error('Network error');
    }
  };

  const handleCreateAccount = async (e) => {
    e.preventDefault();
    setCreatingAccount(true);
    try {
      const res = await fetchWithAuth(`/api/members/${id}/accounts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newAccount),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Account opened');
        setShowNewAccount(false);
        setNewAccount({ account_type: 'savings', currency: 'UGX' });
        fetchData();
      } else {
        toast.error(json.error || 'Failed to open account');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setCreatingAccount(false);
    }
  };

  const handleTransaction = async (e) => {
    e.preventDefault();
    if (!txAmount || parseFloat(txAmount) <= 0 || !txModal) return;
    setTxLoading(true);
    try {
      const res = await fetchWithAuth('/api/transactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: txModal.action,
          member_account_id: txModal.accountId,
          amount: parseFloat(txAmount),
          description: txDescription || `${txModal.action === 'deposit' ? 'Deposit' : 'Withdrawal'} — ${txModal.accountNumber}`,
        }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success(`${txModal.action === 'deposit' ? 'Deposit' : 'Withdrawal'} successful`);
        setTxModal(null);
        setTxAmount('');
        setTxDescription('');
        fetchData();
        if (selectedAccount === txModal.accountId) fetchLedger(txModal.accountId);
      } else {
        toast.error(json.error || 'Transaction failed');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setTxLoading(false);
    }
  };

  const fetchLedger = async (accountId) => {
    setSelectedAccount(accountId);
    try {
      const res = await fetchWithAuth(`/api/members/${id}/accounts/${accountId}/ledger?limit=20`);
      const json = await res.json();
      if (json.success) setLedger(json.data || []);
    } catch {
      setLedger([]);
    }
  };

  if (loading) return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div>;
  if (!member) return <div className="p-6 text-center text-muted-foreground">Member not found</div>;

  const totalBalance = accounts.reduce((s, a) => s + parseFloat(a.balance || 0), 0);
  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  return (
    <div className="p-6 space-y-6 max-w-5xl">
      {/* Back link */}
      <Link href="/app/members" className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="w-4 h-4" /> Back to Members
      </Link>

      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
            <Users className="w-6 h-6 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground">{member.full_name}</h1>
            <p className="text-sm text-muted-foreground font-mono">{member.membership_number}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className={`text-xs font-medium px-2.5 py-1 rounded-full capitalize ${STATUS_STYLES[member.status] || ''}`}>
            {member.status}
          </span>
          {!editing && (
            <button onClick={() => setEditing(true)} className="flex items-center gap-1.5 px-3 py-2 border border-border rounded-lg text-sm hover:bg-muted transition">
              <Edit2 className="w-3.5 h-3.5" /> Edit
            </button>
          )}
        </div>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground mb-1">Accounts</div>
          <div className="text-xl font-bold">{accounts.length}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground mb-1">Total Balance</div>
          <div className="text-xl font-bold text-blue-600">{fmtCurrency(totalBalance)}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground mb-1">Joined</div>
          <div className="text-xl font-bold">{member.joined_at ? new Date(member.joined_at).toLocaleDateString() : '—'}</div>
        </div>
      </div>

      {/* Member info / edit form */}
      <div className="bg-card border border-border rounded-xl p-5 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold text-foreground">Member Information</h3>
          {editing && (
            <div className="flex gap-2">
              <button onClick={() => setEditing(false)} className="flex items-center gap-1 px-3 py-1.5 text-sm border border-border rounded-lg hover:bg-muted">
                <X className="w-3.5 h-3.5" /> Cancel
              </button>
              <button onClick={handleSave} disabled={saving} className="flex items-center gap-1 px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50">
                <Save className="w-3.5 h-3.5" /> {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </div>

        {editing ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Full Name</label>
              <input value={editForm.full_name} onChange={e => setEditForm(f => ({ ...f, full_name: e.target.value }))} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Email</label>
              <input type="email" value={editForm.email} onChange={e => setEditForm(f => ({ ...f, email: e.target.value }))} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Phone</label>
              <input value={editForm.phone} onChange={e => setEditForm(f => ({ ...f, phone: e.target.value }))} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">National ID</label>
              <input value={editForm.national_id} onChange={e => setEditForm(f => ({ ...f, national_id: e.target.value }))} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Gender</label>
              <select value={editForm.gender} onChange={e => setEditForm(f => ({ ...f, gender: e.target.value }))} className={inputClass}>
                <option value="">—</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Date of Birth</label>
              <input type="date" value={editForm.date_of_birth} onChange={e => setEditForm(f => ({ ...f, date_of_birth: e.target.value }))} className={inputClass} />
            </div>
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium text-muted-foreground mb-1">Address</label>
              <input value={editForm.address} onChange={e => setEditForm(f => ({ ...f, address: e.target.value }))} className={inputClass} />
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 text-sm">
            {member.email && <div className="flex items-center gap-2"><Mail className="w-4 h-4 text-muted-foreground" />{member.email}</div>}
            {member.phone && <div className="flex items-center gap-2"><Phone className="w-4 h-4 text-muted-foreground" />{member.phone}</div>}
            {member.national_id && <div className="flex items-center gap-2"><IdCard className="w-4 h-4 text-muted-foreground" />{member.national_id}</div>}
            {member.gender && <div className="flex items-center gap-2"><Users className="w-4 h-4 text-muted-foreground" />Gender: <span className="capitalize">{member.gender}</span></div>}
            {member.date_of_birth && <div className="flex items-center gap-2"><Calendar className="w-4 h-4 text-muted-foreground" />DOB: {new Date(member.date_of_birth).toLocaleDateString()}</div>}
            {member.address && <div className="flex items-center gap-2 md:col-span-2"><MapPin className="w-4 h-4 text-muted-foreground" />{member.address}</div>}
          </div>
        )}

        {/* Status actions */}
        {!editing && member.status !== 'exited' && (
          <div className="flex gap-2 pt-2 border-t border-border">
            {member.status !== 'active' && (
              <button onClick={() => handleStatusChange('active')} className="text-xs px-3 py-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-lg hover:bg-emerald-100 dark:bg-emerald-900/20 dark:border-emerald-800 dark:text-emerald-400">
                Activate
              </button>
            )}
            {member.status !== 'suspended' && (
              <button onClick={() => handleStatusChange('suspended')} className="text-xs px-3 py-1.5 bg-amber-50 text-amber-700 border border-amber-200 rounded-lg hover:bg-amber-100 dark:bg-amber-900/20 dark:border-amber-800 dark:text-amber-400">
                Suspend
              </button>
            )}
            {member.status !== 'inactive' && (
              <button onClick={() => handleStatusChange('inactive')} className="text-xs px-3 py-1.5 bg-gray-50 text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400">
                Deactivate
              </button>
            )}
          </div>
        )}
      </div>

      {/* Accounts section */}
      <div className="bg-card border border-border rounded-xl p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-foreground">Member Accounts ({accounts.length})</h3>
          <button onClick={() => setShowNewAccount(!showNewAccount)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white rounded-lg text-xs font-medium hover:bg-blue-700 transition">
            <Plus className="w-3.5 h-3.5" /> {showNewAccount ? 'Cancel' : 'Open Account'}
          </button>
        </div>

        {/* New account form */}
        {showNewAccount && (
          <form onSubmit={handleCreateAccount} className="flex items-end gap-3 mb-4 p-3 bg-muted/30 rounded-lg border border-border">
            <div className="flex-1">
              <label className="block text-xs font-medium text-muted-foreground mb-1">Account Type</label>
              <select value={newAccount.account_type} onChange={e => setNewAccount(a => ({ ...a, account_type: e.target.value }))} className={inputClass}>
                {ACCOUNT_TYPES.map(t => <option key={t} value={t}>{t.replace('_', ' ')}</option>)}
              </select>
            </div>
            <div className="w-28">
              <label className="block text-xs font-medium text-muted-foreground mb-1">Currency</label>
              <select value={newAccount.currency} onChange={e => setNewAccount(a => ({ ...a, currency: e.target.value }))} className={inputClass}>
                <option value="UGX">UGX</option>
                <option value="USD">USD</option>
                <option value="KES">KES</option>
              </select>
            </div>
            <button type="submit" disabled={creatingAccount}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition whitespace-nowrap">
              {creatingAccount ? 'Opening...' : 'Open'}
            </button>
          </form>
        )}

        {accounts.length === 0 ? (
          <p className="text-sm text-muted-foreground">No accounts yet. Open an account to start transacting.</p>
        ) : (
          <div className="space-y-2">
            {accounts.map(a => (
              <div key={a.member_account_id || a.id} className="border border-border rounded-lg hover:bg-muted/20 transition">
                <div className="flex items-center justify-between p-3">
                  <div className="flex items-center gap-3">
                    <CreditCard className="w-5 h-5 text-muted-foreground" />
                    <div>
                      <div className="text-sm font-medium capitalize">{a.account_type.replace('_', ' ')} Account</div>
                      <div className="text-xs text-muted-foreground font-mono">{a.account_number}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${STATUS_STYLES[a.status] || ''}`}>
                      {a.status}
                    </span>
                    <div className="text-right">
                      <div className="text-sm font-bold">{fmtCurrency(a.balance, a.currency)}</div>
                      <div className="text-xs text-muted-foreground">{a.transaction_count || 0} txns</div>
                    </div>
                    <div className="flex gap-1">
                      <button onClick={() => setTxModal({ action: 'deposit', accountId: a.member_account_id || a.id, accountNumber: a.account_number })}
                        className="p-1.5 rounded-md bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-900/20 dark:text-emerald-400" title="Deposit">
                        <ArrowDownRight className="w-3.5 h-3.5" />
                      </button>
                      <button onClick={() => setTxModal({ action: 'withdraw', accountId: a.member_account_id || a.id, accountNumber: a.account_number })}
                        className="p-1.5 rounded-md bg-red-50 text-red-700 hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400" title="Withdraw">
                        <ArrowUpRight className="w-3.5 h-3.5" />
                      </button>
                      <button onClick={() => fetchLedger(a.member_account_id || a.id)}
                        className="p-1.5 rounded-md bg-blue-50 text-blue-700 hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400" title="View Ledger">
                        <History className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>

                {/* Inline ledger for this account */}
                {selectedAccount === (a.member_account_id || a.id) && (
                  <div className="border-t border-border px-3 py-2 bg-muted/10">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-muted-foreground">Transaction History</span>
                      <button onClick={() => setSelectedAccount(null)} className="text-xs text-muted-foreground hover:text-foreground">&times; Close</button>
                    </div>
                    {ledger.length === 0 ? (
                      <p className="text-xs text-muted-foreground py-2">No transactions yet</p>
                    ) : (
                      <div className="space-y-1 max-h-48 overflow-y-auto">
                        {ledger.map(le => (
                          <div key={le.id} className="flex items-center justify-between text-xs py-1 border-b border-border/50 last:border-0">
                            <div className="flex items-center gap-2">
                              <span className={`w-1.5 h-1.5 rounded-full ${le.entry_type === 'CREDIT' ? 'bg-emerald-500' : 'bg-red-500'}`} />
                              <span className="text-muted-foreground">{le.tx_description || le.description}</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <span className={le.entry_type === 'CREDIT' ? 'text-emerald-600 font-medium' : 'text-red-600 font-medium'}>
                                {le.entry_type === 'CREDIT' ? '+' : '-'}{fmtCurrency(le.amount, a.currency)}
                              </span>
                              <span className="text-muted-foreground/60">{new Date(le.created_at).toLocaleDateString()}</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Deposit/Withdraw Modal */}
      {txModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <form onSubmit={handleTransaction} className="bg-card border border-border rounded-xl p-6 w-full max-w-sm space-y-4 shadow-xl">
            <h3 className="text-lg font-semibold text-foreground capitalize">
              {txModal.action === 'deposit' ? '💰 Deposit' : '💸 Withdraw'}
            </h3>
            <p className="text-xs text-muted-foreground">Account: {txModal.accountNumber}</p>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Amount (UGX)</label>
              <input type="number" min="1" step="1" value={txAmount} onChange={e => setTxAmount(e.target.value)}
                required placeholder="100000" className={inputClass} autoFocus />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">Description (optional)</label>
              <input value={txDescription} onChange={e => setTxDescription(e.target.value)}
                placeholder={txModal.action === 'deposit' ? 'Member deposit' : 'Member withdrawal'} className={inputClass} />
            </div>
            <div className="flex gap-2 pt-2">
              <button type="button" onClick={() => { setTxModal(null); setTxAmount(''); setTxDescription(''); }}
                className="flex-1 px-4 py-2 border border-border rounded-lg text-sm hover:bg-muted">Cancel</button>
              <button type="submit" disabled={txLoading}
                className={`flex-1 px-4 py-2 rounded-lg text-sm text-white font-medium disabled:opacity-50 ${txModal.action === 'deposit' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-red-600 hover:bg-red-700'}`}>
                {txLoading ? 'Processing...' : txModal.action === 'deposit' ? 'Deposit' : 'Withdraw'}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

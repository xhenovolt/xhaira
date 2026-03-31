'use client';

import { useEffect, useState } from 'react';
import { ArrowRightLeft, Plus, Search, RefreshCw } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleString('en-UG', { dateStyle: 'medium', timeStyle: 'short' });
}

export default function MemberTransfersPage() {
  const [transfers, setTransfers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [members, setMembers] = useState([]);
  const [senderAccounts, setSenderAccounts] = useState([]);
  const [receiverAccounts, setReceiverAccounts] = useState([]);
  const [memberSearch, setMemberSearch] = useState('');
  const toast = useToast();

  const [form, setForm] = useState({
    sender_member_id: '',
    sender_account_id: '',
    receiver_member_id: '',
    receiver_account_id: '',
    amount: '',
    description: '',
  });

  const fetchTransfers = async () => {
    setLoading(true);
    try {
      const res = await fetchWithAuth('/api/member-transfers');
      const json = await res.json();
      if (json.success) setTransfers(json.data || []);
    } catch (err) {
      console.error('Failed to fetch transfers:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchMembers = async () => {
    try {
      const res = await fetchWithAuth('/api/members?status=active');
      const json = await res.json();
      if (json.success) setMembers(json.data || []);
    } catch (err) {
      console.error('Failed to fetch members:', err);
    }
  };

  useEffect(() => { fetchTransfers(); }, []);
  useEffect(() => { if (showForm) fetchMembers(); }, [showForm]);

  const fetchMemberAccounts = async (memberId, side) => {
    if (!memberId) {
      if (side === 'sender') setSenderAccounts([]);
      else setReceiverAccounts([]);
      return;
    }
    try {
      const res = await fetchWithAuth(`/api/members/${memberId}/accounts`);
      const json = await res.json();
      const accounts = (json.data || []).filter(a => a.allows_withdrawal !== false);
      if (side === 'sender') setSenderAccounts(accounts);
      else setReceiverAccounts(accounts);
    } catch (err) {
      console.error('Failed to fetch accounts:', err);
    }
  };

  const handleSenderMemberChange = (value) => {
    setForm(f => ({ ...f, sender_member_id: value, sender_account_id: '' }));
    fetchMemberAccounts(value, 'sender');
  };

  const handleReceiverMemberChange = (value) => {
    setForm(f => ({ ...f, receiver_member_id: value, receiver_account_id: '' }));
    fetchMemberAccounts(value, 'receiver');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.sender_account_id || !form.receiver_account_id || !form.amount) return;
    if (form.sender_account_id === form.receiver_account_id) {
      toast.error('Sender and receiver accounts must differ');
      return;
    }
    setSaving(true);
    try {
      const res = await fetchWithAuth('/api/member-transfers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sender_account_id: form.sender_account_id,
          receiver_account_id: form.receiver_account_id,
          amount: parseFloat(form.amount),
          description: form.description || `Transfer from ${form.sender_member_id} to ${form.receiver_member_id}`,
        }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Transfer executed successfully');
        setShowForm(false);
        setForm({ sender_member_id: '', sender_account_id: '', receiver_member_id: '', receiver_account_id: '', amount: '', description: '' });
        setSenderAccounts([]);
        setReceiverAccounts([]);
        fetchTransfers();
      } else {
        toast.error(json.error || 'Transfer failed');
      }
    } catch {
      toast.error('Network error');
    } finally {
      setSaving(false);
    }
  };

  const filteredMembers = memberSearch
    ? members.filter(m => m.full_name?.toLowerCase().includes(memberSearch.toLowerCase()) || m.membership_number?.includes(memberSearch))
    : members;

  const selectClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';
  const inputClass = selectClass;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <ArrowRightLeft className="w-6 h-6 text-cyan-500" /> Member Transfers
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Peer-to-peer fund transfers between member accounts</p>
        </div>
        <div className="flex gap-2">
          <button onClick={fetchTransfers}
            className="flex items-center gap-1 px-3 py-2 border border-border text-muted-foreground rounded-lg text-sm hover:text-foreground hover:bg-muted transition">
            <RefreshCw className="w-4 h-4" />
          </button>
          <button onClick={() => setShowForm(!showForm)}
            className="flex items-center gap-2 px-4 py-2 bg-cyan-600 text-white rounded-lg text-sm font-medium hover:bg-cyan-700 transition">
            <Plus className="w-4 h-4" /> {showForm ? 'Cancel' : 'New Transfer'}
          </button>
        </div>
      </div>

      {/* Transfer Form */}
      {showForm && (
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-4">New Member Transfer</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Member search */}
            <div>
              <label className="text-xs font-medium text-muted-foreground block mb-1">Search Member</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input value={memberSearch} onChange={e => setMemberSearch(e.target.value)}
                  placeholder="Filter members by name or number..." className={`${inputClass} pl-9`} />
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Sender */}
              <div className="space-y-3 p-4 bg-muted/30 rounded-lg">
                <div className="text-xs font-semibold text-muted-foreground uppercase">Sender</div>
                <div>
                  <label className="text-xs font-medium text-muted-foreground block mb-1">Member</label>
                  <select value={form.sender_member_id} onChange={e => handleSenderMemberChange(e.target.value)} className={selectClass} required>
                    <option value="">Select sender...</option>
                    {filteredMembers.filter(m => m.id !== form.receiver_member_id).map(m => (
                      <option key={m.id} value={m.id}>{m.full_name} ({m.membership_number || m.id.slice(0, 8)})</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-muted-foreground block mb-1">Account</label>
                  <select value={form.sender_account_id} onChange={e => setForm(f => ({ ...f, sender_account_id: e.target.value }))} className={selectClass} required disabled={!form.sender_member_id}>
                    <option value="">Select account...</option>
                    {senderAccounts.map(a => (
                      <option key={a.id} value={a.id}>
                        {a.account_type_name || a.account_type} — {a.account_number} (Bal: {fmtCurrency(a.balance, a.currency)})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Receiver */}
              <div className="space-y-3 p-4 bg-muted/30 rounded-lg">
                <div className="text-xs font-semibold text-muted-foreground uppercase">Receiver</div>
                <div>
                  <label className="text-xs font-medium text-muted-foreground block mb-1">Member</label>
                  <select value={form.receiver_member_id} onChange={e => handleReceiverMemberChange(e.target.value)} className={selectClass} required>
                    <option value="">Select receiver...</option>
                    {filteredMembers.filter(m => m.id !== form.sender_member_id).map(m => (
                      <option key={m.id} value={m.id}>{m.full_name} ({m.membership_number || m.id.slice(0, 8)})</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-muted-foreground block mb-1">Account</label>
                  <select value={form.receiver_account_id} onChange={e => setForm(f => ({ ...f, receiver_account_id: e.target.value }))} className={selectClass} required disabled={!form.receiver_member_id}>
                    <option value="">Select account...</option>
                    {receiverAccounts.map(a => (
                      <option key={a.id} value={a.id}>
                        {a.account_type_name || a.account_type} — {a.account_number} (Bal: {fmtCurrency(a.balance, a.currency)})
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-muted-foreground block mb-1">Amount (UGX)</label>
                <input type="number" min="1000" step="1" value={form.amount} onChange={e => setForm(f => ({ ...f, amount: e.target.value }))}
                  placeholder="e.g. 50000" className={inputClass} required />
              </div>
              <div>
                <label className="text-xs font-medium text-muted-foreground block mb-1">Description (optional)</label>
                <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Transfer reason..." className={inputClass} />
              </div>
            </div>

            <div className="flex justify-end">
              <button type="submit" disabled={saving}
                className="px-5 py-2 bg-cyan-600 text-white rounded-lg text-sm font-medium hover:bg-cyan-700 disabled:opacity-50">
                {saving ? 'Processing...' : 'Execute Transfer'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Transfer History */}
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <div className="px-4 py-3 border-b border-border">
          <h2 className="font-semibold text-foreground text-sm">Transfer History</h2>
        </div>
        {loading ? (
          <div className="text-center py-12 text-muted-foreground text-sm">Loading transfers...</div>
        ) : transfers.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground text-sm">No transfers yet</div>
        ) : (
          <div className="divide-y divide-border">
            {transfers.map(t => (
              <div key={t.id} className="px-4 py-4 flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-medium text-foreground text-sm">{t.sender_name}</span>
                    <ArrowRightLeft className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                    <span className="font-medium text-foreground text-sm">{t.receiver_name}</span>
                  </div>
                  <div className="text-xs text-muted-foreground mt-1 flex flex-wrap gap-2">
                    <span>{t.sender_account} → {t.receiver_account}</span>
                    {t.description && <span>· {t.description}</span>}
                  </div>
                  <div className="text-xs text-muted-foreground mt-0.5">{fmtDate(t.created_at)}</div>
                </div>
                <div className="text-right shrink-0">
                  <div className="font-bold text-cyan-600 dark:text-cyan-400 text-sm">
                    {fmtCurrency(t.amount)}
                  </div>
                  {t.reference && <div className="text-xs text-muted-foreground font-mono">{t.reference}</div>}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

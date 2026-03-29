'use client';

import { useEffect, useState } from 'react';
import { use } from 'react';
import { ArrowLeft, RefreshCw, XCircle, Calendar, DollarSign, Building2, CreditCard, Clock } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import Link from 'next/link';

const fmtCurrency = (amount, currency = 'UGX') =>
  `${currency} ${parseFloat(amount || 0).toLocaleString()}`;

const fmtDate = d => d ? new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';
const fmtDateTime = d => d ? new Date(d).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—';

const STATUS_COLORS = {
  active:    'bg-emerald-100 text-emerald-700',
  expired:   'bg-red-100 text-red-600',
  suspended: 'bg-orange-100 text-orange-700',
  cancelled: 'bg-gray-100 text-gray-600',
  trial:     'bg-blue-100 text-blue-700',
};

const EVENT_COLORS = {
  payment:       'bg-emerald-100 text-emerald-700',
  renewal:       'bg-blue-100 text-blue-700',
  upgrade:       'bg-purple-100 text-purple-700',
  downgrade:     'bg-orange-100 text-orange-700',
  refund:        'bg-pink-100 text-pink-700',
  suspension:    'bg-gray-100 text-gray-600',
  reactivation:  'bg-teal-100 text-teal-700',
};

export default function SubscriptionDetailPage({ params }) {
  const { id } = use(params);
  const [sub, setSub]         = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState('');

  const fetchSub = async () => {
    setLoading(true);
    try {
      const res  = await fetchWithAuth(`/api/subscriptions/${id}`);
      const json = await res.json();
      if (json.success) setSub(json.data);
      else setError(json.error || 'Not found');
    } catch { setError('Network error'); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchSub(); }, [id]);

  const handleRenew = async () => {
    if (!confirm('Renew this subscription?')) return;
    try {
      const res  = await fetchWithAuth(`/api/subscriptions/${id}/renew`, { method: 'POST' });
      const json = await res.json();
      if (!json.success) { setError(json.error); return; }
      fetchSub();
    } catch { setError('Renewal failed'); }
  };

  const handleCancel = async () => {
    if (!confirm('Cancel this subscription? This is irreversible.')) return;
    try {
      const res  = await fetchWithAuth(`/api/subscriptions/${id}/cancel`, { method: 'POST' });
      const json = await res.json();
      if (!json.success) { setError(json.error); return; }
      fetchSub();
    } catch { setError('Cancellation failed'); }
  };

  if (loading) {
    return <div className="flex justify-center py-24"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div>;
  }

  if (error || !sub) {
    return (
      <div className="p-6 max-w-3xl mx-auto">
        <Link href="/app/subscriptions" className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground mb-4">
          <ArrowLeft className="w-4 h-4" /> Back to Subscriptions
        </Link>
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl p-6 text-center">{error || 'Subscription not found'}</div>
      </div>
    );
  }

  const today    = new Date();
  const endDate  = new Date(sub.end_date);
  const daysLeft = Math.ceil((endDate - today) / (1000 * 60 * 60 * 24));

  return (
    <div className="p-6 space-y-6 max-w-4xl mx-auto">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link href="/app/subscriptions" className="p-2 rounded-lg hover:bg-muted text-muted-foreground">
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <div>
            <h1 className="text-xl font-bold text-foreground">{sub.client_name}</h1>
            <p className="text-sm text-muted-foreground">{sub.plan_name} · {sub.system}</p>
          </div>
        </div>
        {sub.status !== 'cancelled' && (
          <div className="flex gap-2">
            <button onClick={handleRenew} className="flex items-center gap-2 bg-emerald-600 text-white px-3 py-2 rounded-lg hover:bg-emerald-700 text-sm">
              <RefreshCw className="w-4 h-4" /> Renew
            </button>
            <button onClick={handleCancel} className="flex items-center gap-2 border border-red-300 text-red-600 px-3 py-2 rounded-lg hover:bg-red-50 text-sm">
              <XCircle className="w-4 h-4" /> Cancel
            </button>
          </div>
        )}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-3 rounded-xl flex justify-between">
          {error}
          <button onClick={() => setError('')} className="font-bold ml-4">×</button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Subscription Info */}
        <div className="bg-card border rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-foreground flex items-center gap-2 text-sm uppercase tracking-wide text-muted-foreground">
            <CreditCard className="w-4 h-4" /> Subscription
          </h2>
          <div className="space-y-3">
            <Row label="Status">
              <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${STATUS_COLORS[sub.status] || ''}`}>{sub.status}</span>
            </Row>
            <Row label="Plan">{sub.plan_name}</Row>
            <Row label="System"><span className="capitalize">{sub.system}</span></Row>
            <Row label="Cycle"><span className="capitalize">{sub.cycle_name}</span></Row>
            <Row label="Price">{fmtCurrency(sub.price, sub.currency)} / {sub.cycle_name}</Row>
            <Row label="Auto-renew">{sub.auto_renew ? 'Yes' : 'No'}</Row>
          </div>
        </div>

        {/* Dates */}
        <div className="bg-card border rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-foreground flex items-center gap-2 text-sm uppercase tracking-wide text-muted-foreground">
            <Calendar className="w-4 h-4" /> Dates
          </h2>
          <div className="space-y-3">
            <Row label="Start Date">{fmtDate(sub.start_date)}</Row>
            <Row label="End Date">
              <span className={sub.status === 'active' && daysLeft >= 0 && daysLeft <= 7 ? 'text-red-600 font-semibold' : ''}>
                {fmtDate(sub.end_date)}
              </span>
            </Row>
            {sub.status === 'active' && daysLeft >= 0 && (
              <Row label="Days Left">
                <span className={daysLeft <= 7 ? 'text-red-600 font-semibold' : daysLeft <= 14 ? 'text-amber-600 font-medium' : 'text-emerald-600'}>
                  {daysLeft} days
                </span>
              </Row>
            )}
            <Row label="Created">{fmtDate(sub.created_at)}</Row>
            {sub.cancelled_at && <Row label="Cancelled">{fmtDateTime(sub.cancelled_at)}</Row>}
          </div>
        </div>

        {/* Client */}
        <div className="bg-card border rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-foreground flex items-center gap-2 text-sm uppercase tracking-wide text-muted-foreground">
            <Building2 className="w-4 h-4" /> Client
          </h2>
          <div className="space-y-3">
            <Row label="Company">{sub.client_name}</Row>
            {sub.contact_name && <Row label="Contact">{sub.contact_name}</Row>}
            {sub.client_email && <Row label="Email">{sub.client_email}</Row>}
          </div>
        </div>

        {/* Plan Features */}
        <div className="bg-card border rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-foreground flex items-center gap-2 text-sm uppercase tracking-wide text-muted-foreground">
            <DollarSign className="w-4 h-4" /> Plan Features
          </h2>
          {sub.plan_description && <p className="text-sm text-muted-foreground">{sub.plan_description}</p>}
          {sub.features?.length > 0 ? (
            <ul className="space-y-1">
              {sub.features.map((f, i) => (
                <li key={i} className="text-sm text-foreground flex items-center gap-2 before:content-['✓'] before:text-emerald-500 before:font-bold before:text-xs">{f}</li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground italic">No features listed.</p>
          )}
        </div>
      </div>

      {/* Billing History */}
      <div className="bg-card border rounded-xl overflow-hidden">
        <div className="px-5 py-4 border-b flex items-center gap-2">
          <Clock className="w-4 h-4 text-muted-foreground" />
          <h2 className="font-semibold text-foreground">Billing History</h2>
        </div>
        {!sub.billing_history || sub.billing_history.length === 0 ? (
          <div className="px-5 py-8 text-center text-sm text-muted-foreground">No billing events recorded yet.</div>
        ) : (
          <div className="divide-y">
            {sub.billing_history.map(event => (
              <div key={event.id} className="px-5 py-3 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${EVENT_COLORS[event.event_type] || 'bg-muted text-muted-foreground'}`}>
                    {event.event_type}
                  </span>
                  <div>
                    <p className="text-sm text-foreground">{fmtDate(event.period_start)} → {fmtDate(event.period_end)}</p>
                    {event.notes && <p className="text-xs text-muted-foreground">{event.notes}</p>}
                  </div>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-sm font-medium text-foreground">{fmtCurrency(event.amount, event.currency)}</p>
                  <p className="text-xs text-muted-foreground">{fmtDateTime(event.recorded_at)}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function Row({ label, children }) {
  return (
    <div className="flex items-start justify-between gap-4 text-sm">
      <span className="text-muted-foreground shrink-0">{label}</span>
      <span className="text-foreground text-right">{children}</span>
    </div>
  );
}

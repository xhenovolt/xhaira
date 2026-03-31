'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { ArrowLeft, Banknote, CheckCircle2, Clock, XCircle, AlertTriangle } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import Link from 'next/link';

const STATUS_STYLES = {
  PENDING: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  APPROVED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  DISBURSED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  ACTIVE: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  COMPLETED: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
  REJECTED: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  DEFAULTED: 'bg-red-200 text-red-800 dark:bg-red-900/40 dark:text-red-300',
  PAID: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  PARTIAL: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  OVERDUE: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
};

function fmtCurrency(amount) {
  return `UGX ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

export default function LoanDetailPage() {
  const { id } = useParams();
  const toast = useToast();
  const [loan, setLoan] = useState(null);
  const [loading, setLoading] = useState(true);
  const [repayAmount, setRepayAmount] = useState('');
  const [repaying, setRepaying] = useState(false);
  const [disburseAmount, setDisburseAmount] = useState('');
  const [disbursing, setDisbursing] = useState(false);

  const fetchLoan = async () => {
    try {
      const res = await fetchWithAuth(`/api/loans/${id}`);
      const json = await res.json();
      if (json.success) setLoan(json.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchLoan(); }, [id]);

  const handleAction = async (action, body) => {
    try {
      const opts = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
      if (body) opts.body = JSON.stringify(body);
      else if (action === 'reject') opts.body = JSON.stringify({ reason: 'Rejected by admin' });
      const res = await fetchWithAuth(`/api/loans/${id}/${action}`, opts);
      const json = await res.json();
      if (json.success) {
        toast.success(`Loan ${action}${action.endsWith('e') ? 'd' : 'ed'}`);
        fetchLoan();
      } else {
        toast.error(json.error);
      }
    } catch {
      toast.error('Network error');
    }
  };

  const handleDisburse = async (e) => {
    e.preventDefault();
    setDisbursing(true);
    try {
      const body = disburseAmount ? { amount: parseFloat(disburseAmount) } : {};
      await handleAction('disburse', body);
      setDisburseAmount('');
    } finally {
      setDisbursing(false);
    }
  };

  const handleRepay = async (e) => {
    e.preventDefault();
    if (!repayAmount || parseFloat(repayAmount) <= 0) return;
    setRepaying(true);
    try {
      const res = await fetchWithAuth(`/api/loans/${id}/repay`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: parseFloat(repayAmount) }),
      });
      const json = await res.json();
      if (json.success) {
        toast.success(`Repayment of ${fmtCurrency(repayAmount)} recorded`);
        setRepayAmount('');
        fetchLoan();
      } else {
        toast.error(json.error);
      }
    } catch {
      toast.error('Network error');
    } finally {
      setRepaying(false);
    }
  };

  if (loading) return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div>;
  if (!loan) return <div className="p-6 text-center text-muted-foreground">Loan not found</div>;

  const remaining = parseFloat(loan.total_payable) - parseFloat(loan.total_paid);
  const progress = parseFloat(loan.total_payable) > 0 ? (parseFloat(loan.total_paid) / parseFloat(loan.total_payable)) * 100 : 0;
  const approvedAmt = parseFloat(loan.approved_amount || loan.principal);
  const disbursedAmt = parseFloat(loan.disbursed_amount || 0);
  const disbursementRemaining = approvedAmt - disbursedAmt;
  const inputClass = 'w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring';

  return (
    <div className="p-6 space-y-6 max-w-5xl">
      <Link href="/app/loans" className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="w-4 h-4" /> Back to Loans
      </Link>

      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
            <Banknote className="w-6 h-6 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground">
              Loan — <Link href={`/app/members/${loan.member_id}`} className="hover:text-blue-600">{loan.member_name}</Link>
            </h1>
            <p className="text-sm text-muted-foreground">{loan.product_name || 'Default Terms'} &middot; {loan.interest_rate}% &middot; {loan.duration} months</p>
          </div>
        </div>
        <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_STYLES[loan.status] || ''}`}>{loan.status}</span>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Requested</div>
          <div className="text-xl font-bold mt-1">{fmtCurrency(loan.principal)}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Approved</div>
          <div className="text-xl font-bold mt-1">{loan.approved_amount ? fmtCurrency(loan.approved_amount) : '—'}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Disbursed</div>
          <div className="text-xl font-bold mt-1 text-blue-600">{fmtCurrency(disbursedAmt)}</div>
          {disbursementRemaining > 0.01 && ['APPROVED', 'DISBURSED'].includes(loan.status) && (
            <div className="text-xs text-muted-foreground mt-0.5">{fmtCurrency(disbursementRemaining)} remaining</div>
          )}
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Total Payable</div>
          <div className="text-xl font-bold mt-1">{fmtCurrency(loan.total_payable)}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Total Paid</div>
          <div className="text-xl font-bold mt-1 text-emerald-600">{fmtCurrency(loan.total_paid)}</div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="text-xs text-muted-foreground">Remaining</div>
          <div className="text-xl font-bold mt-1 text-red-600">{fmtCurrency(remaining)}</div>
        </div>
      </div>

      {/* Progress bar */}
      {loan.status === 'ACTIVE' && (
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="flex justify-between text-xs text-muted-foreground mb-2">
            <span>Repayment Progress</span>
            <span>{progress.toFixed(1)}%</span>
          </div>
          <div className="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-full">
            <div className="h-2 bg-emerald-500 rounded-full transition-all" style={{ width: `${Math.min(progress, 100)}%` }} />
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex flex-wrap gap-2">
        {loan.status === 'PENDING' && (
          <>
            <button onClick={() => handleAction('approve')} className="px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700">Approve (Full)</button>
            <button onClick={() => handleAction('reject')} className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700">Reject</button>
          </>
        )}
        {['APPROVED', 'DISBURSED'].includes(loan.status) && disbursementRemaining > 0.01 && (
          <form onSubmit={handleDisburse} className="flex gap-2 items-center">
            <input type="number" min="1" max={disbursementRemaining} step="1" value={disburseAmount}
              onChange={e => setDisburseAmount(e.target.value)} placeholder={`Amount (max ${Math.round(disbursementRemaining).toLocaleString()})`}
              className={`w-56 ${inputClass}`} />
            <button type="submit" disabled={disbursing}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 whitespace-nowrap">
              {disbursing ? 'Disbursing...' : disburseAmount ? 'Partial Disburse' : 'Disburse All'}
            </button>
          </form>
        )}
      </div>

      {/* Guarantors */}
      {loan.guarantors && loan.guarantors.length > 0 && (
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-3">Guarantors ({loan.guarantors.length})</h3>
          <div className="space-y-2">
            {loan.guarantors.map(g => (
              <div key={g.id} className="flex items-center justify-between bg-muted/20 rounded-lg px-4 py-2">
                <div>
                  <span className="font-medium text-foreground">{g.full_name}</span>
                  <span className="text-xs text-muted-foreground ml-2">#{g.membership_number}</span>
                </div>
                <div className="text-right">
                  <span className="font-medium">{fmtCurrency(g.guaranteed_amount)}</span>
                  <span className={`ml-2 text-xs px-2 py-0.5 rounded-full ${STATUS_STYLES[g.status] || 'bg-gray-100 text-gray-600'}`}>{g.status}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Repayment form */}
      {loan.status === 'ACTIVE' && (
        <form onSubmit={handleRepay} className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-3">Record Repayment</h3>
          <div className="flex gap-3">
            <input type="number" min="1" max={remaining} step="1" value={repayAmount} onChange={e => setRepayAmount(e.target.value)}
              required placeholder="Amount to repay" className={`flex-1 ${inputClass}`} />
            <button type="submit" disabled={repaying}
              className="px-5 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 disabled:opacity-50 whitespace-nowrap">
              {repaying ? 'Processing...' : 'Record Repayment'}
            </button>
          </div>
        </form>
      )}

      {/* Repayment Schedule */}
      {loan.schedule && loan.schedule.length > 0 && (
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="font-semibold text-foreground mb-3">Repayment Schedule ({loan.schedule.length} installments)</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left px-3 py-2 text-xs font-medium text-muted-foreground">#</th>
                  <th className="text-left px-3 py-2 text-xs font-medium text-muted-foreground">Due Date</th>
                  <th className="text-right px-3 py-2 text-xs font-medium text-muted-foreground">Principal</th>
                  <th className="text-right px-3 py-2 text-xs font-medium text-muted-foreground">Interest</th>
                  <th className="text-right px-3 py-2 text-xs font-medium text-muted-foreground">Total</th>
                  <th className="text-right px-3 py-2 text-xs font-medium text-muted-foreground">Paid</th>
                  <th className="text-left px-3 py-2 text-xs font-medium text-muted-foreground">Status</th>
                </tr>
              </thead>
              <tbody>
                {loan.schedule.map(s => (
                  <tr key={s.id} className="border-b border-border/50 last:border-0 hover:bg-muted/20">
                    <td className="px-3 py-2 text-muted-foreground">{s.installment_number}</td>
                    <td className="px-3 py-2">{new Date(s.due_date).toLocaleDateString()}</td>
                    <td className="px-3 py-2 text-right">{fmtCurrency(s.principal_amount)}</td>
                    <td className="px-3 py-2 text-right text-muted-foreground">{fmtCurrency(s.interest_amount)}</td>
                    <td className="px-3 py-2 text-right font-medium">{fmtCurrency(s.total_amount)}</td>
                    <td className="px-3 py-2 text-right">{fmtCurrency(s.paid_amount)}</td>
                    <td className="px-3 py-2">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${STATUS_STYLES[s.status] || ''}`}>{s.status}</span>
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

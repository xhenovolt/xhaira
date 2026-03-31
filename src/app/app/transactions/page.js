'use client';

import { useEffect, useState } from 'react';
import { Receipt, Search, ChevronLeft, ChevronRight, ExternalLink, RefreshCw } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import Link from 'next/link';

const TYPE_COLORS = {
  deposit: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  withdrawal: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  transfer: 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-400',
  loan_disbursement: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  loan_repayment: 'bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400',
  fee: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  interest: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  adjustment: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
  initial_balance: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',
};

const TX_TYPES = ['deposit', 'withdrawal', 'transfer', 'loan_disbursement', 'loan_repayment', 'fee', 'interest', 'adjustment', 'initial_balance'];

function fmtCurrency(amount, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(amount || 0)).toLocaleString()}`;
}

function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleString('en-UG', { dateStyle: 'medium', timeStyle: 'short' });
}

function TxTypeBadge({ type }) {
  const cls = TYPE_COLORS[type] || TYPE_COLORS.adjustment;
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${cls}`}>
      {(type || 'unknown').replace(/_/g, ' ')}
    </span>
  );
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total: 0, pages: 1 });
  const [expandedId, setExpandedId] = useState(null);

  const fetchTransactions = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: '50' });
      if (typeFilter) params.set('type', typeFilter);
      if (search) params.set('search', search);
      const res = await fetchWithAuth(`/api/transactions?${params}`);
      const json = await res.json();
      if (json.success) {
        setTransactions(json.data || []);
        setPagination(json.pagination || { total: 0, pages: 1 });
      }
    } catch (err) {
      console.error('Failed to fetch transactions:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchTransactions(); }, [page, typeFilter]);

  const handleSearch = (e) => {
    e.preventDefault();
    setPage(1);
    fetchTransactions();
  };

  const totalPages = pagination.totalPages || pagination.pages || 1;

  return (
    <div className="p-6 max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <Receipt className="w-6 h-6 text-emerald-500" /> Ledger Transactions
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Double-entry accounting journal — {pagination.total?.toLocaleString() || 0} transactions total
          </p>
        </div>
        <button onClick={fetchTransactions}
          className="flex items-center gap-1 px-3 py-2 border border-border text-muted-foreground rounded-lg text-sm hover:text-foreground hover:bg-muted transition">
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <form onSubmit={handleSearch} className="relative flex-1 min-w-48 max-w-80">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Search description or reference..."
            className="w-full pl-9 pr-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
        </form>
        <div className="flex gap-2 flex-wrap">
          <button onClick={() => { setTypeFilter(''); setPage(1); }}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition ${!typeFilter ? 'bg-foreground text-background' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
            All
          </button>
          {TX_TYPES.map(t => (
            <button key={t} onClick={() => { setTypeFilter(t === typeFilter ? '' : t); setPage(1); }}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition capitalize ${typeFilter === t ? 'bg-foreground text-background' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
              {t.replace(/_/g, ' ')}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        {loading ? (
          <div className="text-center py-12 text-muted-foreground text-sm">Loading transactions...</div>
        ) : transactions.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground text-sm">No transactions found</div>
        ) : (
          <div className="divide-y divide-border">
            {transactions.map(tx => {
              const entries = Array.isArray(tx.entries) ? tx.entries : [];
              const debits = entries.filter(e => e.entry_type === 'DEBIT');
              const credits = entries.filter(e => e.entry_type === 'CREDIT');
              const totalAmount = debits.reduce((sum, e) => sum + parseFloat(e.amount || 0), 0);
              const isExpanded = expandedId === tx.id;

              return (
                <div key={tx.id}>
                  <button
                    onClick={() => setExpandedId(isExpanded ? null : tx.id)}
                    className="w-full px-4 py-3 text-left hover:bg-muted/30 transition"
                  >
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <TxTypeBadge type={tx.transaction_type} />
                          <span className="font-medium text-foreground text-sm truncate">{tx.description}</span>
                        </div>
                        <div className="flex items-center gap-3 mt-1 flex-wrap">
                          <span className="text-xs text-muted-foreground">{fmtDate(tx.created_at)}</span>
                          {tx.reference && (
                            <span className="text-xs font-mono text-muted-foreground">Ref: {tx.reference}</span>
                          )}
                          <span className="text-xs text-muted-foreground">
                            {entries.length} entr{entries.length === 1 ? 'y' : 'ies'}
                          </span>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="font-bold text-foreground text-sm">{fmtCurrency(totalAmount)}</div>
                      </div>
                    </div>
                  </button>

                  {/* Expanded entries */}
                  {isExpanded && entries.length > 0 && (
                    <div className="px-4 pb-4 bg-muted/20">
                      <table className="w-full text-xs mt-2">
                        <thead>
                          <tr className="text-left border-b border-border">
                            <th className="pb-1.5 font-semibold text-muted-foreground uppercase">Type</th>
                            <th className="pb-1.5 font-semibold text-muted-foreground uppercase">Account</th>
                            <th className="pb-1.5 font-semibold text-muted-foreground uppercase">Member</th>
                            <th className="pb-1.5 font-semibold text-muted-foreground uppercase text-right">Amount</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/50">
                          {entries.map((e, i) => (
                            <tr key={i}>
                              <td className="py-1.5">
                                <span className={`font-semibold ${e.entry_type === 'DEBIT' ? 'text-red-500 dark:text-red-400' : 'text-emerald-600 dark:text-emerald-400'}`}>
                                  {e.entry_type}
                                </span>
                              </td>
                              <td className="py-1.5 text-muted-foreground font-mono">
                                {e.account_number || e.system_account || e.account_id?.slice(0, 8)}
                              </td>
                              <td className="py-1.5 text-muted-foreground">
                                {e.member_name || (e.system_account ? `(${e.system_account})` : '—')}
                              </td>
                              <td className="py-1.5 text-right font-medium text-foreground">
                                {fmtCurrency(e.amount, e.currency)}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">
            Page {page} of {totalPages} ({pagination.total?.toLocaleString()} total)
          </span>
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
              className="flex items-center gap-1 px-3 py-1.5 border border-border rounded-lg text-sm text-muted-foreground hover:text-foreground hover:bg-muted disabled:opacity-50">
              <ChevronLeft className="w-4 h-4" /> Prev
            </button>
            <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages}
              className="flex items-center gap-1 px-3 py-1.5 border border-border rounded-lg text-sm text-muted-foreground hover:text-foreground hover:bg-muted disabled:opacity-50">
              Next <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

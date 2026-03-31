'use client';

import { useEffect, useState, useMemo } from 'react';
import { Plus, Package, Banknote, PiggyBank, CreditCard, Layers, TrendingUp, Search } from 'lucide-react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import { PRODUCT_TYPES, PRODUCT_TYPE_KEYS, getFieldsForType, STATUS_STYLES } from '@/lib/product-types';
import Link from 'next/link';

const TYPE_ICONS = { LOAN: Banknote, SAVINGS: PiggyBank, INSTALLMENT: CreditCard, SERVICE: Layers, INVESTMENT: TrendingUp };

function formatAmount(n, currency = 'UGX') {
  return `${currency} ${Math.round(parseFloat(n || 0)).toLocaleString()}`;
}

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [filterType, setFilterType] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [form, setForm] = useState({
    name: '', description: '', version: '', status: 'active', product_type: 'SERVICE',
    interest_rate: '', duration_months: '', min_amount: '', max_amount: '',
    requires_approval: false, upfront_amount: '', return_rate: '',
    billing_frequency: '', currency: 'UGX', price: '',
  });
  const toast = useToast();

  useEffect(() => { fetchProducts(); }, []);

  const fetchProducts = async () => {
    try {
      const res = await fetchWithAuth('/api/products');
      const json = await res.json();
      if (json.success) setProducts(json.data);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const filteredProducts = useMemo(() => {
    let result = products;
    if (filterType) result = result.filter(p => p.product_type === filterType);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(p => p.name.toLowerCase().includes(q) || (p.description || '').toLowerCase().includes(q));
    }
    return result;
  }, [products, filterType, searchQuery]);

  const submit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const body = { ...form };
      ['interest_rate', 'duration_months', 'min_amount', 'max_amount', 'upfront_amount', 'return_rate', 'price'].forEach(f => {
        body[f] = body[f] !== '' && body[f] !== null ? parseFloat(body[f]) : null;
      });
      const res = await fetchWithAuth('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const json = await res.json();
      if (json.success) {
        toast.success('Product created');
        setProducts(prev => [json.data, ...prev]);
        resetForm();
        setShowForm(false);
      } else {
        toast.error(json.error || 'Failed to create product');
      }
    } catch (err) { console.error(err); } finally { setSaving(false); }
  };

  const resetForm = () => setForm({
    name: '', description: '', version: '', status: 'active', product_type: 'SERVICE',
    interest_rate: '', duration_months: '', min_amount: '', max_amount: '',
    requires_approval: false, upfront_amount: '', return_rate: '',
    billing_frequency: '', currency: 'UGX', price: '',
  });

  const typeConfig = PRODUCT_TYPES[form.product_type] || {};
  const dynamicFields = getFieldsForType(form.product_type);

  const totalRevenue = products.reduce((s, p) => s + parseFloat(p.total_revenue || 0), 0);
  const activeProducts = products.filter(p => p.status === 'active').length;
  const typeCounts = PRODUCT_TYPE_KEYS.reduce((acc, t) => { acc[t] = products.filter(p => p.product_type === t).length; return acc; }, {});

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Products</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {activeProducts} active · {products.length} total · {formatAmount(totalRevenue)} revenue
          </p>
        </div>
        <button onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium transition">
          <Plus className="w-4 h-4" /> New Product
        </button>
      </div>

      {/* Type Filter Chips */}
      <div className="flex flex-wrap gap-2">
        <button onClick={() => setFilterType('')}
          className={`px-3 py-1.5 text-xs rounded-full font-medium transition ${!filterType ? 'bg-blue-600 text-white' : 'bg-muted text-muted-foreground hover:bg-blue-50 hover:text-blue-600'}`}>
          All ({products.length})
        </button>
        {PRODUCT_TYPE_KEYS.map(t => {
          const Icon = TYPE_ICONS[t];
          const config = PRODUCT_TYPES[t];
          return (
            <button key={t} onClick={() => setFilterType(filterType === t ? '' : t)}
              className={`px-3 py-1.5 text-xs rounded-full font-medium transition flex items-center gap-1.5 ${filterType === t ? config.color : 'bg-muted text-muted-foreground hover:bg-blue-50'}`}>
              <Icon className="w-3 h-3" /> {config.label} ({typeCounts[t] || 0})
            </button>
          );
        })}
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
          placeholder="Search products..." className="w-full pl-9 pr-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm" />
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {PRODUCT_TYPE_KEYS.map(t => {
          const Icon = TYPE_ICONS[t];
          const config = PRODUCT_TYPES[t];
          return (
            <div key={t} className="bg-card rounded-xl border border-border p-3">
              <div className="flex items-center gap-2 mb-1">
                <div className={`w-6 h-6 rounded-md flex items-center justify-center ${config.color}`}>
                  <Icon className="w-3.5 h-3.5" />
                </div>
                <p className="text-xs text-muted-foreground">{config.label}s</p>
              </div>
              <p className="text-lg font-bold text-foreground">{typeCounts[t] || 0}</p>
            </div>
          );
        })}
      </div>

      {/* Create Product Form */}
      {showForm && (
        <form onSubmit={submit} className="bg-card rounded-xl border border-border p-5 space-y-4">
          <h2 className="font-semibold text-foreground">Create New Product</h2>

          {/* Product Type Selection */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">Product Type</label>
            <div className="flex flex-wrap gap-2">
              {PRODUCT_TYPE_KEYS.map(t => {
                const Icon = TYPE_ICONS[t];
                const config = PRODUCT_TYPES[t];
                return (
                  <button key={t} type="button" onClick={() => setForm(f => ({ ...f, product_type: t }))}
                    className={`px-3 py-2 rounded-lg text-sm font-medium transition flex items-center gap-2 border ${
                      form.product_type === t ? 'border-blue-500 bg-blue-50 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400' : 'border-border hover:border-blue-300'
                    }`}>
                    <Icon className="w-4 h-4" /> {config.label}
                  </button>
                );
              })}
            </div>
            <p className="text-xs text-muted-foreground mt-1">{typeConfig.description}</p>
          </div>

          {/* Basic Fields */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <input required value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="Product name *" className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm" />
            <input value={form.version} onChange={e => setForm(f => ({ ...f, version: e.target.value }))}
              placeholder="Version (optional)" className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm" />
          </div>
          <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
            placeholder="Product description" rows={2}
            className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm" />

          {/* Dynamic Fields Based on Product Type */}
          {Object.keys(dynamicFields).length > 0 && (
            <div className="border-t border-border pt-4">
              <h3 className="text-sm font-medium text-foreground mb-3">{typeConfig.label} Configuration</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {Object.entries(dynamicFields).map(([key, config]) => {
                  if (config.type === 'boolean') {
                    return (
                      <label key={key} className="flex items-center gap-2 cursor-pointer">
                        <input type="checkbox" checked={!!form[key]}
                          onChange={e => setForm(f => ({ ...f, [key]: e.target.checked }))}
                          className="w-4 h-4 rounded border-border" />
                        <span className="text-sm text-foreground">{config.label}</span>
                      </label>
                    );
                  }
                  if (config.type === 'select') {
                    return (
                      <div key={key}>
                        <label className="block text-xs text-muted-foreground mb-1">{config.label}{config.required ? ' *' : ''}</label>
                        <select value={form[key] || ''} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                          required={config.required}
                          className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm [&>option]:bg-background">
                          <option value="">Select...</option>
                          {config.options.map(o => <option key={o} value={o}>{o}</option>)}
                        </select>
                      </div>
                    );
                  }
                  return (
                    <div key={key}>
                      <label className="block text-xs text-muted-foreground mb-1">{config.label}{config.required ? ' *' : ''}</label>
                      <input type={config.type || 'text'} step={config.step || 'any'}
                        value={form[key] || ''} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                        required={config.required}
                        className="w-full px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm" />
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Status + Submit */}
          <div className="flex items-center gap-3">
            <select value={form.status} onChange={e => setForm(f => ({ ...f, status: e.target.value }))}
              className="px-3 py-2 border border-border rounded-lg bg-background text-foreground text-sm [&>option]:bg-background">
              <option value="active">Active</option>
              <option value="development">In Development</option>
              <option value="deprecated">Deprecated</option>
              <option value="archived">Archived</option>
            </select>
            <button type="submit" disabled={saving}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium disabled:opacity-50 transition">
              {saving ? 'Saving…' : 'Create Product'}
            </button>
            <button type="button" onClick={() => { setShowForm(false); resetForm(); }}
              className="px-4 py-2 rounded-lg border border-border text-sm hover:bg-muted transition">Cancel</button>
          </div>
        </form>
      )}

      {/* Products Grid */}
      {loading ? (
        <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div>
      ) : filteredProducts.length === 0 ? (
        <div className="text-center py-16 text-muted-foreground">
          <Package className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p className="font-medium">{filterType ? `No ${PRODUCT_TYPES[filterType]?.label} products` : 'No products yet'}</p>
          <p className="text-sm mt-1">Create your first product to get started</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredProducts.map(product => {
            const config = PRODUCT_TYPES[product.product_type] || PRODUCT_TYPES.SERVICE;
            const Icon = TYPE_ICONS[product.product_type] || Package;
            return (
              <Link key={product.id} href={`/app/products/${product.id}`}
                className="bg-card rounded-xl border border-border p-5 hover:border-blue-400 hover:shadow-sm transition group">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${config.color}`}>
                      <Icon className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-foreground group-hover:text-blue-600 transition">{product.name}</h3>
                      {product.version && <p className="text-xs text-muted-foreground">v{product.version}</p>}
                    </div>
                  </div>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${STATUS_STYLES[product.status] || 'bg-muted text-muted-foreground'}`}>
                    {product.status}
                  </span>
                </div>
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${config.color}`}>{config.label}</span>
                {product.description && <p className="text-sm text-muted-foreground mt-2 line-clamp-2">{product.description}</p>}

                {/* Type-specific info */}
                <div className="mt-3 pt-3 border-t border-border space-y-1 text-xs">
                  {product.interest_rate && (
                    <div className="flex justify-between"><span className="text-muted-foreground">Interest Rate</span><span className="font-medium text-foreground">{product.interest_rate}%</span></div>
                  )}
                  {product.price && (
                    <div className="flex justify-between"><span className="text-muted-foreground">Price</span><span className="font-medium text-foreground">{formatAmount(product.price, product.currency)}</span></div>
                  )}
                  {product.duration_months && (
                    <div className="flex justify-between"><span className="text-muted-foreground">Duration</span><span className="font-medium text-foreground">{product.duration_months} months</span></div>
                  )}
                  {(product.min_amount || product.max_amount) && (
                    <div className="flex justify-between"><span className="text-muted-foreground">Range</span>
                      <span className="font-medium text-foreground">{product.min_amount ? formatAmount(product.min_amount, product.currency) : '—'} – {product.max_amount ? formatAmount(product.max_amount, product.currency) : '—'}</span>
                    </div>
                  )}
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-2 text-center text-xs mt-3 pt-3 border-t border-border">
                  <div><p className="font-semibold text-foreground">{product.deal_count || 0}</p><p className="text-muted-foreground">Deals</p></div>
                  <div><p className="font-semibold text-foreground">{product.active_licenses || 0}</p><p className="text-muted-foreground">Licenses</p></div>
                  <div><p className="font-semibold text-foreground">{product.open_issues || 0}</p><p className={`${parseInt(product.open_issues) > 0 ? 'text-orange-600' : 'text-muted-foreground'}`}>Issues</p></div>
                </div>
                {parseFloat(product.total_revenue) > 0 && (
                  <div className="mt-2 pt-2 border-t border-border">
                    <p className="text-xs text-muted-foreground">Revenue</p>
                    <p className="text-sm font-semibold text-emerald-600">{formatAmount(product.total_revenue, product.currency)}</p>
                  </div>
                )}
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}

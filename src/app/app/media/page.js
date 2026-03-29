'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { fetchWithAuth } from '@/lib/fetch-client';
import { useToast } from '@/components/ui/Toast';
import { confirmDelete } from '@/lib/confirm';

const ENTITY_TYPES = [
  { value: '', label: 'All' },
  { value: 'system', label: 'System' },
  { value: 'deal', label: 'Deal' },
  { value: 'client', label: 'Client' },
  { value: 'staff', label: 'Staff' },
  { value: 'resource', label: 'Resource' },
  { value: 'general', label: 'General' },
];

function formatSize(bytes) {
  if (!bytes) return '—';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function FileIcon({ mime }) {
  if (!mime) return <div className="w-10 h-10 rounded-lg bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-xs font-bold">?</div>;
  if (mime.startsWith('image/')) return <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center text-purple-600 text-xs font-bold">IMG</div>;
  if (mime.startsWith('video/')) return <div className="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-red-600 text-xs font-bold">VID</div>;
  if (mime.includes('pdf')) return <div className="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center text-orange-600 text-xs font-bold">PDF</div>;
  return <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 text-xs font-bold">FILE</div>;
}

export default function MediaPage() {
  const [media, setMedia] = useState([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [filterType, setFilterType] = useState('');
  const [filterTag, setFilterTag] = useState('');
  const [showUpload, setShowUpload] = useState(false);
  const [uploadForm, setUploadForm] = useState({ entity_type: 'general', entity_id: '', tags: '', quality: 'original' });
  const [dragActive, setDragActive] = useState(false);
  const [preview, setPreview] = useState(null);
  const fileRef = useRef(null);
  const toast = useToast();

  const fetchMedia = useCallback(async () => {
    try {
      let url = '/api/media?';
      if (filterType) url += `entity_type=${filterType}&`;
      if (filterTag) url += `tag=${filterTag}&`;
      const res = await fetchWithAuth(url);
      if (res.success) setMedia(res.data || []);
    } catch (e) { console.error('Failed to fetch media:', e); }
    setLoading(false);
  }, [filterType, filterTag]);

  useEffect(() => { fetchMedia(); }, [fetchMedia]);

  const handleUpload = async (file) => {
    if (!file) return;
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('entity_type', uploadForm.entity_type);
      if (uploadForm.entity_id) formData.append('entity_id', uploadForm.entity_id);
      if (uploadForm.tags) formData.append('tags', uploadForm.tags);
      formData.append('quality', uploadForm.quality);

      const res = await fetch('/api/media/upload', {
        method: 'POST',
        credentials: 'include',
        body: formData,
      });
      const data = await res.json();
      if (data.success) {
        toast.success('File uploaded');
        setShowUpload(false);
        setUploadForm({ entity_type: 'general', entity_id: '', tags: '', quality: 'original' });
        fetchMedia();
      } else {
        toast.error(data.error || 'Upload failed');
      }
    } catch (e) { console.error('Upload error:', e); toast.error('Upload failed'); }
    setUploading(false);
  };

  const handleDelete = async (id) => {
    if (!await confirmDelete('media file')) return;
    try {
      await fetchWithAuth(`/api/media?id=${id}`, { method: 'DELETE' });
      toast.success('File deleted');
      fetchMedia();
    } catch (e) { console.error('Delete error:', e); toast.error('Failed to delete'); }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragActive(false);
    const file = e.dataTransfer?.files?.[0];
    if (file) handleUpload(file);
  };

  if (loading) return <div className="p-8 text-center opacity-60">Loading…</div>;

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Media Library</h1>
          <p className="text-sm opacity-60 mt-1">
            Upload and manage files, images, and documents with Cloudinary
          </p>
        </div>
        <button onClick={() => setShowUpload(!showUpload)}
          className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 text-sm font-medium">
          {showUpload ? 'Cancel' : '+ Upload'}
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="rounded-xl border p-4" style={{ background: 'var(--card-bg, #fff)' }}>
          <div className="text-xs font-medium opacity-60 uppercase">Total Files</div>
          <div className="text-2xl font-bold mt-1">{media.length}</div>
        </div>
        <div className="rounded-xl border p-4" style={{ background: 'var(--card-bg, #fff)' }}>
          <div className="text-xs font-medium opacity-60 uppercase">Images</div>
          <div className="text-2xl font-bold mt-1">{media.filter(m => m.mime_type?.startsWith('image/')).length}</div>
        </div>
        <div className="rounded-xl border p-4" style={{ background: 'var(--card-bg, #fff)' }}>
          <div className="text-xs font-medium opacity-60 uppercase">Videos</div>
          <div className="text-2xl font-bold mt-1">{media.filter(m => m.mime_type?.startsWith('video/')).length}</div>
        </div>
        <div className="rounded-xl border p-4" style={{ background: 'var(--card-bg, #fff)' }}>
          <div className="text-xs font-medium opacity-60 uppercase">Total Size</div>
          <div className="text-2xl font-bold mt-1">{formatSize(media.reduce((a, m) => a + (m.file_size || 0), 0))}</div>
        </div>
      </div>

      {/* Upload Zone */}
      {showUpload && (
        <div className="rounded-xl border p-5 space-y-4" style={{ background: 'var(--card-bg, #fff)' }}>
          <h3 className="font-semibold">Upload File</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Entity Type</label>
              <select value={uploadForm.entity_type} onChange={e => setUploadForm({...uploadForm, entity_type: e.target.value})}
                className="w-full rounded-lg border px-3 py-2 text-sm" style={{ background: 'var(--input-bg, #fff)' }}>
                {ENTITY_TYPES.filter(t => t.value).map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Tags (comma-separated)</label>
              <input type="text" value={uploadForm.tags} onChange={e => setUploadForm({...uploadForm, tags: e.target.value})}
                placeholder="logo, branding" className="w-full rounded-lg border px-3 py-2 text-sm" style={{ background: 'var(--input-bg, #fff)' }} />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Quality</label>
              <select value={uploadForm.quality} onChange={e => setUploadForm({...uploadForm, quality: e.target.value})}
                className="w-full rounded-lg border px-3 py-2 text-sm" style={{ background: 'var(--input-bg, #fff)' }}>
                <option value="original">Original</option>
                <option value="optimized">Optimized (auto compress)</option>
              </select>
            </div>
          </div>

          {/* Drop zone */}
          <div
            onDragOver={e => { e.preventDefault(); setDragActive(true); }}
            onDragLeave={() => setDragActive(false)}
            onDrop={handleDrop}
            onClick={() => fileRef.current?.click()}
            className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors
              ${dragActive ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/10' : 'border-gray-300 hover:border-gray-400'}`}>
            <input ref={fileRef} type="file" className="hidden" onChange={e => handleUpload(e.target.files?.[0])} />
            {uploading ? (
              <div className="text-blue-600 font-medium">Uploading…</div>
            ) : (
              <>
                <div className="text-lg font-medium">Drop file here or click to browse</div>
                <div className="text-xs opacity-50 mt-2">Images up to 10MB, Videos up to 100MB</div>
              </>
            )}
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <label className="text-sm font-medium">Filter:</label>
        <select value={filterType} onChange={e => setFilterType(e.target.value)}
          className="rounded-lg border px-3 py-1.5 text-sm" style={{ background: 'var(--input-bg, #fff)' }}>
          {ENTITY_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
        <input type="text" value={filterTag} onChange={e => setFilterTag(e.target.value)}
          placeholder="Filter by tag…" className="rounded-lg border px-3 py-1.5 text-sm" style={{ background: 'var(--input-bg, #fff)' }} />
      </div>

      {/* Media Grid */}
      {media.length === 0 ? (
        <div className="text-center py-12 opacity-50">
          <p className="text-lg font-medium">No media files yet</p>
          <p className="text-sm mt-1">Upload your first file to get started</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {media.map(m => (
            <div key={m.id} className="rounded-xl border overflow-hidden group" style={{ background: 'var(--card-bg, #fff)' }}>
              {/* Preview area */}
              {m.mime_type?.startsWith('image/') && m.secure_url ? (
                <div className="h-40 bg-gray-100 dark:bg-gray-800 overflow-hidden cursor-pointer"
                  onClick={() => setPreview(m)}>
                  <img src={m.thumbnail_url || m.secure_url} alt={m.original_filename}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                </div>
              ) : (
                <div className="h-40 bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
                  <FileIcon mime={m.mime_type} />
                </div>
              )}
              {/* Info */}
              <div className="p-3">
                <div className="font-medium text-sm truncate">{m.original_filename || m.filename}</div>
                <div className="flex items-center gap-2 mt-1 text-xs opacity-50">
                  <span>{formatSize(m.file_size)}</span>
                  {m.width && m.height && <span>{m.width}×{m.height}</span>}
                  {m.format && <span className="uppercase">{m.format}</span>}
                </div>
                {m.entity_type && (
                  <div className="mt-1">
                    <span className="px-2 py-0.5 rounded-full text-xs bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                      {m.entity_type}
                    </span>
                  </div>
                )}
                {m.tags && m.tags.length > 0 && m.tags[0] !== '' && (
                  <div className="flex flex-wrap gap-1 mt-1">
                    {(Array.isArray(m.tags) ? m.tags : []).map((t, i) => (
                      <span key={i} className="px-1.5 py-0.5 rounded text-xs bg-gray-100 dark:bg-gray-700">{t}</span>
                    ))}
                  </div>
                )}
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs opacity-40">{m.created_at?.split('T')[0]}</span>
                  <div className="flex gap-2">
                    {m.secure_url && (
                      <a href={m.secure_url} target="_blank" rel="noopener noreferrer"
                        className="text-blue-500 hover:text-blue-700 text-xs">Open</a>
                    )}
                    <button onClick={() => handleDelete(m.id)}
                      className="text-red-500 hover:text-red-700 text-xs">Delete</button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Image Preview Modal */}
      {preview && (
        <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4"
          onClick={() => setPreview(null)}>
          <div className="max-w-4xl max-h-[90vh] relative" onClick={e => e.stopPropagation()}>
            <button onClick={() => setPreview(null)}
              className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-white dark:bg-gray-800 shadow flex items-center justify-center text-sm font-bold">
              ×
            </button>
            <img src={preview.secure_url || preview.url} alt={preview.original_filename}
              className="max-w-full max-h-[85vh] rounded-lg shadow-2xl" />
            <div className="text-white text-center mt-2 text-sm">{preview.original_filename} — {formatSize(preview.file_size)}</div>
          </div>
        </div>
      )}
    </div>
  );
}

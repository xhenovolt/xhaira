'use client';

import { useState, useEffect } from 'react';
import { Plus, Trash2, Edit2, Grid3X3, AlertCircle, Eye } from 'lucide-react';
import Link from 'next/link';

export default function TechIntelligencePage() {
  const [stacks, setStacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newStack, setNewStack] = useState({ name: '', description: '' });

  useEffect(() => {
    loadStacks();
  }, []);

  const loadStacks = async () => {
    try {
      const res = await fetch('/api/tech-stacks');
      const data = await res.json();
      setStacks(data.stacks || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const createStack = async (e) => {
    e.preventDefault();
    if (!newStack.name.trim()) return;

    try {
      const res = await fetch('/api/tech-stacks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newStack),
      });

      if (res.ok) {
        setNewStack({ name: '', description: '' });
        setShowCreateForm(false);
        loadStacks();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const deleteStack = async (id) => {
    if (!confirm('Delete this tech stack? This cannot be undone.')) return;

    try {
      const res = await fetch(`/api/tech-stacks/${id}`, { method: 'DELETE' });
      if (res.ok) {
        loadStacks();
      }
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) return <div className="p-6">Loading tech stacks...</div>;

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <Grid3X3 className="w-8 h-8" />
            Tech Intelligence
          </h1>
          <p className="text-gray-600 mt-1">Centralized technical knowledge base - reusable tech stacks</p>
        </div>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700"
        >
          <Plus className="w-4 h-4" />
          New Stack
        </button>
      </div>

      {showCreateForm && (
        <form onSubmit={createStack} className="bg-white border rounded-lg p-6 mb-6">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2">Stack Name</label>
              <input
                type="text"
                value={newStack.name}
                onChange={(e) => setNewStack({ ...newStack, name: e.target.value })}
                placeholder="e.g., Next.js SaaS Stack"
                className="w-full border rounded px-3 py-2"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Description</label>
              <textarea
                value={newStack.description}
                onChange={(e) => setNewStack({ ...newStack, description: e.target.value })}
                placeholder="Describe this tech stack..."
                className="w-full border rounded px-3 py-2 h-20"
              />
            </div>
            <div className="flex gap-2">
              <button
                type="submit"
                className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
              >
                Create Stack
              </button>
              <button
                type="button"
                onClick={() => setShowCreateForm(false)}
                className="bg-gray-300 text-gray-900 px-4 py-2 rounded hover:bg-gray-400"
              >
                Cancel
              </button>
            </div>
          </div>
        </form>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {stacks.map((stack) => (
          <div key={stack.id} className="bg-white border rounded-lg p-6 hover:shadow-lg transition">
            <div className="flex items-start justify-between mb-4">
              <div className="flex-1">
                <h3 className="text-lg font-bold">{stack.name}</h3>
                <p className="text-sm text-gray-600 line-clamp-2">{stack.description}</p>
              </div>
              <button
                onClick={() => deleteStack(stack.id)}
                className="text-red-600 hover:bg-red-50 p-2 rounded ml-2"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
            <div className="flex gap-4 text-sm text-gray-600 border-t pt-4 mb-4">
              <div>
                <span className="font-medium">{stack.item_count}</span> components
              </div>
              <div>
                <span className="font-medium">{stack.system_count}</span> systems using
              </div>
            </div>
            <Link
              href={`/app/tech-intelligence/${stack.id}`}
              className="w-full bg-blue-50 text-blue-600 hover:bg-blue-100 px-4 py-2 rounded text-sm font-medium flex items-center justify-center gap-2"
            >
              <Eye className="w-4 h-4" />
              View Details
            </Link>
          </div>
        ))}
      </div>

      {stacks.length === 0 && (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <AlertCircle className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-600">No tech stacks yet. Create one to get started.</p>
        </div>
      )}
    </div>
  );
}

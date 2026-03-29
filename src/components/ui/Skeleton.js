'use client';

/**
 * Skeleton loading components for Xhaira.
 * Replace traditional loaders with content-shaped placeholders
 * for perceived speed and visual stability.
 */

function Bone({ className = '' }) {
  return (
    <div className={`animate-pulse rounded-lg bg-muted ${className}`} />
  );
}

export function SkeletonTable({ rows = 5, cols = 4 }) {
  return (
    <div className="border border-border rounded-xl overflow-hidden">
      {/* Header */}
      <div className="flex gap-4 px-4 py-3 bg-muted/50 border-b border-border">
        {Array.from({ length: cols }).map((_, i) => (
          <Bone key={i} className="h-4 flex-1" />
        ))}
      </div>
      {/* Rows */}
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="flex gap-4 px-4 py-3 border-b border-border last:border-0">
          {Array.from({ length: cols }).map((_, c) => (
            <Bone key={c} className={`h-4 flex-1 ${c === 0 ? 'max-w-[200px]' : ''}`} />
          ))}
        </div>
      ))}
    </div>
  );
}

export function SkeletonCards({ count = 6 }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="border border-border rounded-xl p-5 space-y-3">
          <Bone className="h-5 w-3/4" />
          <Bone className="h-4 w-1/2" />
          <div className="flex gap-2 pt-2">
            <Bone className="h-6 w-16 rounded-full" />
            <Bone className="h-6 w-20 rounded-full" />
          </div>
          <Bone className="h-4 w-full" />
          <Bone className="h-4 w-2/3" />
        </div>
      ))}
    </div>
  );
}

export function SkeletonDashboard() {
  return (
    <div className="space-y-6">
      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="border border-border rounded-xl p-4 space-y-2">
            <Bone className="h-4 w-20" />
            <Bone className="h-8 w-24" />
            <Bone className="h-3 w-16" />
          </div>
        ))}
      </div>
      {/* Chart placeholder */}
      <div className="border border-border rounded-xl p-6">
        <Bone className="h-5 w-40 mb-4" />
        <Bone className="h-48 w-full" />
      </div>
      {/* List */}
      <SkeletonTable rows={4} cols={5} />
    </div>
  );
}

export function SkeletonForm({ fields = 6 }) {
  return (
    <div className="space-y-4 p-6 border border-border rounded-xl">
      <Bone className="h-6 w-48 mb-2" />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {Array.from({ length: fields }).map((_, i) => (
          <div key={i} className="space-y-2">
            <Bone className="h-4 w-24" />
            <Bone className="h-10 w-full" />
          </div>
        ))}
      </div>
      <Bone className="h-10 w-32 mt-4" />
    </div>
  );
}

export function SkeletonLine({ className = '' }) {
  return <Bone className={`h-4 ${className}`} />;
}

export function TableSkeleton({ rows = 5, cols = 3 }: { rows?: number; cols?: number }) {
  return (
    <div className="animate-pulse">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="flex gap-2 py-2">
          {Array.from({ length: cols }).map((__, c) => (
            <div key={c} className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4" />
          ))}
        </div>
      ))}
    </div>
  )
}

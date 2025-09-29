export function EmptyState({ title, description }: { title: string; description?: string }) {
  return (
    <div className="text-center text-sm text-muted py-8">
      <div className="font-medium text-fg mb-1">{title}</div>
      {description && <div>{description}</div>}
    </div>
  )
}

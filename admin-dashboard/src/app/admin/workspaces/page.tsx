"use client"
import { useInfiniteQuery } from '@tanstack/react-query'
import { useRouter } from 'next/navigation'
import { call, isFirebaseConfigured } from '@/lib/firebase'
import { FunctionNames, type ListWorkspacesInput, type ListWorkspacesOutput } from '@c3/contracts'
import { Button } from '@/components/ui/Button'

export default function WorkspacesPage() {
  const configured = isFirebaseConfigured()
  const q = useInfiniteQuery({
    queryKey: ['workspaces'],
    queryFn: async ({ pageParam }) => {
      const input: ListWorkspacesInput = { limit: 20, cursor: pageParam as string | undefined }
      return call<ListWorkspacesInput, ListWorkspacesOutput>(FunctionNames.listWorkspaces)(input)
    },
    getNextPageParam: (last) => last.nextCursor,
    initialPageParam: undefined as unknown as string | undefined,
    enabled: configured,
  })
  const router = useRouter()
  const items = q.data ? q.data.pages.flatMap(p => p.items) : []
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Workspaces</h1>
      {!configured && (
        <div className="text-sm text-red-600">Firebase environment variables are not configured. Fill in .env.local to load workspaces.</div>
      )}
      {q.isError && (
        <div className="text-sm text-red-600">Failed to load workspaces. {(q.error as any)?.message ?? ''}</div>
      )}
      <div className="card">
        <table className="w-full text-sm table-zebra table-head">
          <thead>
            <tr>
              <th className="text-left px-3 py-2">Name</th>
              <th className="text-left px-3 py-2">Location</th>
              <th className="text-left px-3 py-2">Created</th>
            </tr>
          </thead>
          <tbody>
            {q.isLoading && (
              <tr><td colSpan={3} className="px-3 py-4 text-sm text-gray-500">Loading…</td></tr>
            )}
            {items.map(ws => (
              <tr
                key={ws.id}
                onClick={() => router.push(`/admin/workspaces/${ws.id}`)}
                className="border-t border-border hover:bg-[color:var(--surface-hover)] cursor-pointer transition"
              >
                <td className="px-3 py-2">{ws.name}</td>
                <td className="px-3 py-2">{ws.location ?? '—'}</td>
                <td className="px-3 py-2">{ws.createdAt ? new Date(ws.createdAt).toLocaleString() : '—'}</td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr><td className="px-3 py-6 text-center text-gray-500" colSpan={3}>No workspaces</td></tr>
            )}
          </tbody>
        </table>
      </div>
      <div className="flex justify-center">
        <Button onClick={() => q.fetchNextPage()} disabled={q.isFetchingNextPage || !q.hasNextPage}>
          {q.isFetchingNextPage ? 'Loading…' : q.hasNextPage ? 'Load more' : 'No more'}
        </Button>
      </div>
    </div>
  )
}

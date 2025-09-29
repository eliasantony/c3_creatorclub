"use client"
import { useInfiniteQuery } from '@tanstack/react-query'
import { call, isFirebaseConfigured } from '@/lib/firebase'
import { FunctionNames, type ListBookingsInput, type ListBookingsOutput } from '@c3/contracts'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'

export default function BookingsPage() {
  const configured = isFirebaseConfigured()
  const [filters, setFilters] = useState<{ userId?: string; roomId?: string; from?: string; to?: string }>({})
  const q = useInfiniteQuery({
    queryKey: ['bookings', filters.userId ?? '', filters.roomId ?? '', filters.from ?? '', filters.to ?? ''],
    queryFn: async ({ pageParam }) => {
      const fromIso = filters.from ? new Date(filters.from).toISOString() : undefined
      const toIso = filters.to ? new Date(new Date(filters.to).setHours(23, 59, 59, 999)).toISOString() : undefined
      const input: ListBookingsInput = { userId: filters.userId, roomId: filters.roomId, from: fromIso, to: toIso, limit: 20, cursor: pageParam as string | undefined }
      return call<ListBookingsInput, ListBookingsOutput>(FunctionNames.listBookings)(input)
    },
    getNextPageParam: (last) => last.nextCursor,
    initialPageParam: undefined as unknown as string | undefined,
  })
  const router = useRouter()
  const items = q.data ? q.data.pages.flatMap(p => p.items) : []
  if (!configured) {
    return <div className="text-sm text-red-600">Firebase environment variables are not configured. Fill in .env.local to load bookings.</div>
  }
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Bookings</h1>
      {q.isError && (
        <div className="text-sm text-red-600">Failed to load bookings. {(q.error as any)?.message ?? ''}</div>
      )}
      <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); q.refetch() }}>
        <Input placeholder="User ID" value={filters.userId ?? ''} onChange={(e) => setFilters(f => ({ ...f, userId: e.target.value || undefined }))} />
        <Input placeholder="Workspace ID" value={filters.roomId ?? ''} onChange={(e) => setFilters(f => ({ ...f, roomId: e.target.value || undefined }))} />
        <Input type="date" value={filters.from ?? ''} onChange={(e) => setFilters(f => ({ ...f, from: e.target.value || undefined }))} />
        <Input type="date" value={filters.to ?? ''} onChange={(e) => setFilters(f => ({ ...f, to: e.target.value || undefined }))} />
        <Button type="submit">Apply</Button>
      </form>
      <div className="card overflow-x-auto">
        <table className="w-full text-sm table-zebra table-head">
          <thead>
            <tr>
              <th className="text-left px-3 py-2">ID</th>
              <th className="text-left px-3 py-2">User</th>
              <th className="text-left px-3 py-2">Workspace</th>
              <th className="text-left px-3 py-2">Start</th>
              <th className="text-left px-3 py-2">End</th>
              <th className="text-left px-3 py-2">Status</th>
            </tr>
          </thead>
          <tbody>
            {q.isLoading && (
              <tr><td colSpan={6} className="px-3 py-4 text-sm text-gray-500">Loading…</td></tr>
            )}
            {items.map(b => (
              <tr
                key={b.id}
                onClick={() => router.push(`/admin/bookings/${b.id}`)}
                className="border-t border-border hover:bg-[color:var(--surface-hover)] cursor-pointer transition"
              >
                <td className="px-3 py-2">{b.id}</td>
                <td className="px-3 py-2">{b.userId}</td>
                <td className="px-3 py-2">{b.workspaceId}</td>
                <td className="px-3 py-2">{b.start ? new Date(b.start).toLocaleString() : '—'}</td>
                <td className="px-3 py-2">{b.end ? new Date(b.end).toLocaleString() : '—'}</td>
                <td className="px-3 py-2">{b.status ?? '—'}</td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr><td className="px-3 py-6 text-center text-gray-500" colSpan={6}>No bookings</td></tr>
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

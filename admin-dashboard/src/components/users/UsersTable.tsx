"use client"
import { useMemo, useState } from 'react'
import { ColumnDef, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'
import { isFirebaseConfigured, call } from '@/lib/firebase'
import { useRouter } from 'next/navigation'
import { normalizeUser } from './utils'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { useInfiniteQuery } from '@tanstack/react-query'
import { FunctionNames, type ListUsersInput, type ListUsersOutput } from '@c3/contracts'
import { TableSkeleton } from '@/components/ui/LoadingState'

export type UserRow = {
  id: string
  name: string
  email: string
  tier?: string
}

type PageResult = { rows: UserRow[]; lastCursor: string | undefined }

async function fetchPage(pageSize: number, cursor: string | undefined, filters: { name?: string; email?: string; tier?: string }): Promise<PageResult> {
  const input: ListUsersInput = {
    q: filters.name || filters.email || undefined, // simple combined q for now
    tier: filters.tier as any,
    limit: pageSize,
    cursor,
  }
  const res = await call<ListUsersInput, ListUsersOutput>(FunctionNames.listUsers)(input)
  const rows: UserRow[] = res.items.map(u => ({ id: u.id, name: u.name, email: u.email, tier: u.tier }))
  return { rows, lastCursor: res.nextCursor }
}

export function UsersTable() {
  const [filters, setFilters] = useState<{ name?: string; email?: string; tier?: string }>({})
  const router = useRouter()
  const configured = isFirebaseConfigured()

  const columns = useMemo<ColumnDef<UserRow>[]>(
    () => [
      { header: 'Name', accessorKey: 'name' },
      { header: 'Email', accessorKey: 'email' },
      { header: 'Tier', accessorKey: 'tier' },
    ],
    []
  )

  const queryKey = useMemo(() => ['users', filters.name ?? '', filters.email ?? '', filters.tier ?? ''], [filters])
  const q = useInfiniteQuery({
    queryKey,
    queryFn: ({ pageParam }) => fetchPage(20, (pageParam as string | undefined) ?? undefined, filters),
    initialPageParam: undefined as unknown as string | undefined,
    getNextPageParam: (last) => last.lastCursor ?? undefined,
  })

  const data = useMemo(() => (q.data ? q.data.pages.flatMap((p) => p.rows) : []), [q.data])
  const table = useReactTable({ data, columns, getCoreRowModel: getCoreRowModel() })

  const onApplyFilters = (e: React.FormEvent) => {
    e.preventDefault()
    // Changing the queryKey via filters triggers cache separation; just refetch.
    q.refetch({ throwOnError: false })
  }

  if (!configured) {
    return <div className="text-sm text-red-600">Firebase environment variables are not configured. Fill in .env.local to load users.</div>
  }

  return (
    <div className="space-y-4">
      {q.isError && (
        <div className="text-sm text-red-600">Failed to load users. Please ensure Firebase env is set and Functions are available. {(q.error as any)?.message ?? ''}</div>
      )}
      <form className="flex gap-2" onSubmit={onApplyFilters}>
        <Input placeholder="Name" value={filters.name ?? ''} onChange={(e) => setFilters((f) => ({ ...f, name: e.target.value || undefined }))} />
        <Input placeholder="Email" value={filters.email ?? ''} onChange={(e) => setFilters((f) => ({ ...f, email: e.target.value || undefined }))} />
        <select className="border rounded px-2 py-1" value={filters.tier ?? ''} onChange={(e) => setFilters((f) => ({ ...f, tier: e.target.value || undefined }))}>
          <option value="">All tiers</option>
          <option value="free">Free</option>
          <option value="premium">Premium</option>
        </select>
        <Button type="submit" variant="primary">Apply</Button>
      </form>
      <div className="card overflow-x-auto">
        <table className="w-full text-sm table-zebra table-head">
          <thead className="text-left">
            {table.getHeaderGroups().map((hg) => (
              <tr key={hg.id}>
                {hg.headers.map((h) => (
                  <th key={h.id} className="px-3 py-2">
                    {h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {q.isLoading && (
              <tr>
                <td colSpan={columns.length} className="px-3 py-4">
                  <TableSkeleton rows={6} cols={3} />
                </td>
              </tr>
            )}
            {table.getRowModel().rows.map((row) => (
              <tr key={row.id} className="cursor-pointer transition hover:bg-[color:var(--surface-hover)]" onClick={() => router.push(`/admin/users/${row.original.id}`)}>
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-3 py-2 border-t border-border">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
            {!q.isLoading && table.getRowModel().rows.length === 0 && (
              <tr>
                <td className="px-3 py-8 text-center text-[color:var(--fg-muted)]" colSpan={columns.length}>No users found</td>
              </tr>
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

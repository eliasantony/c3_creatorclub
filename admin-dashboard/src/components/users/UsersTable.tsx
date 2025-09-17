"use client"
import { useMemo, useState } from 'react'
import { ColumnDef, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'
import { collection, getDocs, limit, orderBy, query, startAfter, where } from 'firebase/firestore'
import { getDb, isFirebaseConfigured } from '@/lib/firebase'
import { useRouter } from 'next/navigation'
import { normalizeUser } from './utils'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { useInfiniteQuery } from '@tanstack/react-query'

export type UserRow = {
  id: string
  name: string
  email: string
  tier?: string
}

type PageResult = { rows: UserRow[]; lastCursor: unknown | null }

async function fetchPage(pageSize: number, cursor: unknown | null, filters: { name?: string; email?: string; tier?: string }): Promise<PageResult> {
  const db = getDb()
  let q: any = query(collection(db, 'users'), orderBy('createdAt', 'desc'), limit(pageSize))

  const clauses: any[] = []
  if (filters.name) clauses.push(where('name', '>=', filters.name), where('name', '<=', filters.name + '\uf8ff'))
  if (filters.email) clauses.push(where('email', '>=', filters.email), where('email', '<=', filters.email + '\uf8ff'))
  if (filters.tier) clauses.push(where('tier', '==', filters.tier))
  if (clauses.length) {
    // Note: Firestore requires appropriate composite indexes for combined queries.
    q = query(collection(db, 'users'), ...clauses, orderBy('createdAt', 'desc'), limit(pageSize))
  }
  if (cursor) q = query(q, startAfter(cursor))

  const snap = await getDocs(q)
  const rows: UserRow[] = snap.docs.map((d) => normalizeUser(d.data(), d.id))
  const last = snap.docs[snap.docs.length - 1]
  return { rows, lastCursor: last ?? null }
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
    queryFn: ({ pageParam }) => fetchPage(20, (pageParam as unknown) ?? null, filters),
    initialPageParam: null as unknown,
    getNextPageParam: (last) => last.lastCursor,
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
      <form className="flex gap-2" onSubmit={onApplyFilters}>
        <Input placeholder="Name" value={filters.name ?? ''} onChange={(e) => setFilters((f) => ({ ...f, name: e.target.value || undefined }))} />
        <Input placeholder="Email" value={filters.email ?? ''} onChange={(e) => setFilters((f) => ({ ...f, email: e.target.value || undefined }))} />
        <select className="border rounded px-2 py-1" value={filters.tier ?? ''} onChange={(e) => setFilters((f) => ({ ...f, tier: e.target.value || undefined }))}>
          <option value="">All tiers</option>
          <option value="free">Free</option>
          <option value="pro">Pro</option>
          <option value="enterprise">Enterprise</option>
        </select>
        <Button type="submit" variant="primary">Apply</Button>
      </form>
      <div className="border rounded overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left">
            {table.getHeaderGroups().map((hg) => (
              <tr key={hg.id}>
                {hg.headers.map((h) => (
                  <th key={h.id} className="px-3 py-2 font-medium">
                    {h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {table.getRowModel().rows.map((row) => (
              <tr key={row.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => router.push(`/admin/users/${row.original.id}`)}>
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-3 py-2 border-t">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
            {!q.isLoading && table.getRowModel().rows.length === 0 && (
              <tr>
                <td className="px-3 py-8 text-center text-gray-500" colSpan={columns.length}>No users found</td>
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

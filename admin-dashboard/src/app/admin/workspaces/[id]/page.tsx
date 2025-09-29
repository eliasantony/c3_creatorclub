"use client"
import { useEffect, useState } from 'react'
import { doc, getDoc } from 'firebase/firestore'
import { getDb } from '@/lib/firebase'
import { Button } from '@/components/ui/Button'
import { call } from '@/lib/firebase'
import { FunctionNames, type ListBookingsInput, type ListBookingsOutput } from '@c3/contracts'
import { useRouter } from 'next/navigation'

type Props = { params: Promise<{ id: string }> }

interface WorkspaceData {
  name?: string
  location?: string
  description?: string
  createdAt?: { seconds: number; nanoseconds: number }
}

export default function WorkspaceDetailsPage({ params }: Props) {
  const [id, setId] = useState('')
  const [ws, setWs] = useState<WorkspaceData | null>(null)
  const [bookings, setBookings] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()

  useEffect(() => { params.then(({ id }) => setId(id)) }, [params])

  useEffect(() => {
    if (!id) return
    const run = async () => {
      setLoading(true)
      setError(null)
      try {
        const db = getDb()
  const snap = await getDoc(doc(db, 'rooms', id))
        setWs((snap.data() as any) ?? null)
        const input: ListBookingsInput = { roomId: id, limit: 10 }
        const res = await call<ListBookingsInput, ListBookingsOutput>(FunctionNames.listBookings)(input)
        setBookings(res.items)
      } catch (e: any) {
        setError(e?.message || 'Failed to load workspace')
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [id])

  const createdAt = ws?.createdAt ? new Date(ws.createdAt.seconds * 1000) : undefined

  if (loading) {
    return <div className="p-6 text-sm text-gray-500">Loading workspace…</div>
  }
  if (error) {
    return <div className="p-6 space-y-4">
      <div className="text-sm text-red-600">{error}</div>
      <Button onClick={() => router.refresh()}>Retry</Button>
    </div>
  }
  if (!ws) {
    return <div className="p-6 text-sm text-gray-500">Workspace not found</div>
  }

  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{ws.name || 'Workspace'}</h1>
          <p className="text-xs text-gray-500 break-all">ID: {id}</p>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="space-y-4 md:col-span-1 text-sm card">
          <Field label="Location" value={ws.location} />
          <Field label="Created" value={createdAt?.toLocaleString()} />
          <Field label="Description" value={ws.description} />
        </div>
        <div className="md:col-span-2 space-y-4">
          <h2 className="font-semibold">Recent bookings</h2>
          <div className="card">
            <table className="w-full text-sm table-head table-zebra">
              <thead>
                <tr>
                  <th className="text-left px-3 py-2">Booking</th>
                  <th className="text-left px-3 py-2">User</th>
                  <th className="text-left px-3 py-2">Start</th>
                  <th className="text-left px-3 py-2">End</th>
                  <th className="text-left px-3 py-2">Status</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map(b => (
                  <tr key={b.id} className="border-t">
                    <td className="px-3 py-2 break-all">{b.id}</td>
                    <td className="px-3 py-2">{b.userId}</td>
                    <td className="px-3 py-2">{b.start ? new Date(b.start).toLocaleString() : '—'}</td>
                    <td className="px-3 py-2">{b.end ? new Date(b.end).toLocaleString() : '—'}</td>
                    <td className="px-3 py-2">{b.status ?? '—'}</td>
                  </tr>
                ))}
                {bookings.length === 0 && (
                  <tr><td colSpan={5} className="px-3 py-6 text-center text-gray-500">No bookings</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

function Field({ label, value }: { label: string; value?: string | null }) {
  return (
    <div className="flex items-start justify-between gap-2">
      <span className="text-gray-500 field-label">{label}</span>
  <span className="max-w-[60%] break-all text-gray-900 dark:text-gray-100">{value ?? '—'}</span>
    </div>
  )
}

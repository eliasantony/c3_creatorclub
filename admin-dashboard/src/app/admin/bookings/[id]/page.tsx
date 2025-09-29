"use client"
import { useEffect, useState } from 'react'
import { doc, getDoc } from 'firebase/firestore'
import { getDb } from '@/lib/firebase'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/Button'

type Props = { params: Promise<{ id: string }> }

interface BookingDoc {
  userId?: string
  workspaceId?: string
  start?: { seconds: number; nanoseconds: number }
  end?: { seconds: number; nanoseconds: number }
  status?: string
  priceCents?: number
  createdAt?: { seconds: number; nanoseconds: number }
}

export default function BookingDetailsPage({ params }: Props) {
  const [id, setId] = useState('')
  const [booking, setBooking] = useState<BookingDoc | null>(null)
  const [userName, setUserName] = useState<string>('')
  const [workspaceName, setWorkspaceName] = useState<string>('')
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
        const snap = await getDoc(doc(db, 'bookings', id))
        if (!snap.exists()) {
          setBooking(null)
          return
        }
        const data = snap.data() as any
        setBooking(data)
        if (data.userId) {
          const us = await getDoc(doc(db, 'users', data.userId))
            .then(d => d.exists() ? (d.data() as any).name || d.id : d.id)
          setUserName(us)
        }
        if (data.workspaceId) {
          const ws = await getDoc(doc(db, 'rooms', data.workspaceId))
            .then(d => d.exists() ? (d.data() as any).name || d.id : d.id)
          setWorkspaceName(ws)
        }
      } catch (e: any) {
        setError(e?.message || 'Failed to load booking')
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [id])

  const toDate = (ts?: { seconds: number; nanoseconds: number }) => ts ? new Date(ts.seconds * 1000) : undefined
  const start = toDate(booking?.start)
  const end = toDate(booking?.end)
  const created = toDate(booking?.createdAt)

  if (loading) return <div className="p-6 text-sm text-gray-500">Loading booking…</div>
  if (error) return <div className="p-6 space-y-4"><div className="text-sm text-red-600">{error}</div><Button onClick={() => router.refresh()}>Retry</Button></div>
  if (!booking) return <div className="p-6 text-sm text-gray-500">Booking not found</div>

  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Booking</h1>
          <p className="text-xs text-gray-500 break-all">ID: {id}</p>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-sm">
        <div className="space-y-3 card">
          <Field label="User" value={userName || booking.userId} />
          <Field label="Workspace" value={workspaceName || booking.workspaceId} />
          <Field label="Status" value={booking.status} />
          <Field label="Start" value={start?.toLocaleString()} />
          <Field label="End" value={end?.toLocaleString()} />
          <Field label="Price" value={booking.priceCents != null ? `€${(booking.priceCents/100).toFixed(2)}` : undefined} />
          <Field label="Created" value={created?.toLocaleString()} />
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

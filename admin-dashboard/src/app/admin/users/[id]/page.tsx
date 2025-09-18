"use client"
import { useEffect, useState } from 'react'
import { doc, getDoc, collection, getDocs, limit, orderBy, query, where } from 'firebase/firestore'
import { getDb } from '@/lib/firebase'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { RbacGate } from '@/components/security/RbacGate'
import { call } from '@/lib/firebase'
import { sendPasswordResetEmail } from 'firebase/auth'
import { getAuthInstance } from '@/lib/firebase'

type Props = { params: Promise<{ id: string }> }

type UserData = {
  name?: string
  email?: string
  tier?: string
  profession?: string
  createdAt?: { seconds: number, nanoseconds: number }
}

type Booking = { id: string; userId: string; roomId: string; startsAt?: any; status?: string }

export default function UserDetailsPage({ params }: Props) {
  const [id, setId] = useState<string>('')
  const [user, setUser] = useState<UserData | null>(null)
  const [bookings, setBookings] = useState<Booking[]>([])

  useEffect(() => {
    params.then(({ id }) => setId(id))
  }, [params])

  useEffect(() => {
    if (!id) return
    const db = getDb()
    getDoc(doc(db, 'users', id)).then((snap) => setUser((snap.data() as any) ?? null))
    const q = query(collection(db, 'bookings'), where('userId', '==', id), orderBy('startsAt', 'desc'), limit(10))
    getDocs(q).then((snap) => setBookings(snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }))))
  }, [id])

  const ban = call<{ userId: string }, { ok: boolean }>('banUser')
  const mute = call<{ userId: string; hours: number }, { ok: boolean }>('muteUser')

  const createdAt = user?.createdAt ? new Date(user.createdAt.seconds * 1000) : undefined

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">User Details</h1>
        <p className="text-sm text-gray-500">ID: {id}</p>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <div><span className="font-medium">Name:</span> {user?.name ?? '—'}</div>
          <div><span className="font-medium">Email:</span> {user?.email ?? '—'}</div>
          <div><span className="font-medium">Tier:</span> {user?.tier ?? '—'}</div>
          <div><span className="font-medium">Profession:</span> {user?.profession ?? '—'}</div>
          <div><span className="font-medium">Created:</span> {createdAt?.toLocaleString() ?? '—'}</div>
          <div className="flex gap-2 mt-2">
            <RbacGate action="ban">
              {(allowed) => (
                <ConfirmDialog title="Ban user" description="This will ban the user." onConfirm={async () => { await ban({ userId: id }) }}>
                  {(open) => <Button onClick={open} variant="danger" disabled={!allowed}>Ban</Button>}
                </ConfirmDialog>
              )}
            </RbacGate>
            <RbacGate action="ban">
              {(allowed) => (
                <ConfirmDialog title="Mute user for 24h" description="User will be muted for 24 hours." onConfirm={async () => { await mute({ userId: id, hours: 24 }) }}>
                  {(open) => <Button onClick={open} disabled={!allowed}>Mute 24h</Button>}
                </ConfirmDialog>
              )}
            </RbacGate>
            <Button onClick={() => user?.email && sendPasswordResetEmail(getAuthInstance(), user.email)}>
              Reset password
            </Button>
          </div>
        </div>
        <div>
          <h2 className="font-semibold mb-2">Last 10 bookings</h2>
          <div className="border rounded">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="text-left px-3 py-2">Booking</th>
                  <th className="text-left px-3 py-2">Room</th>
                  <th className="text-left px-3 py-2">Starts</th>
                  <th className="text-left px-3 py-2">Status</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map((b) => (
                  <tr key={b.id} className="border-t">
                    <td className="px-3 py-2">{b.id}</td>
                    <td className="px-3 py-2">{b.roomId}</td>
                    <td className="px-3 py-2">{b.startsAt ? new Date(b.startsAt.seconds * 1000).toLocaleString() : '—'}</td>
                    <td className="px-3 py-2">{b.status ?? '—'}</td>
                  </tr>
                ))}
                {bookings.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-3 py-6 text-center text-gray-500">No bookings found</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

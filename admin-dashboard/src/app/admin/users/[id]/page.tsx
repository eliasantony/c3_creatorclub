"use client"
import { useEffect, useState } from 'react'
import { doc, getDoc } from 'firebase/firestore'
import { getDb } from '@/lib/firebase'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { RbacGate } from '@/components/security/RbacGate'
import { call } from '@/lib/firebase'
import { sendPasswordResetEmail } from 'firebase/auth'
import { getAuthInstance } from '@/lib/firebase'
import { FunctionNames, type ListBookingsInput, type ListBookingsOutput } from '@c3/contracts'

type Props = { params: Promise<{ id: string }> }

type UserData = {
  name?: string
  email?: string
  membershipTier?: string
  profession?: string
  niche?: string
  phone?: string
  photoUrl?: string | null
  stripeCustomerId?: string
  chatTosAccepted?: boolean
  createdAt?: { seconds: number; nanoseconds: number }
}

type Booking = { id: string; userId: string; workspaceId?: string; start?: string; status?: string }

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
    // Fetch last 10 bookings via callable for consistent RBAC and schema
    const fetch = async () => {
      const input: ListBookingsInput = { userId: id, limit: 10 }
      const res = await call<ListBookingsInput, ListBookingsOutput>(FunctionNames.listBookings)(input)
      setBookings(res.items)
    }
    fetch()
  }, [id])

  const ban = call<{ userId: string }, { ok: boolean }>('banUser')
  const mute = call<{ userId: string; hours: number }, { ok: boolean }>('muteUser')

  const createdAt = user?.createdAt ? new Date(user.createdAt.seconds * 1000) : undefined

  const copy = (text?: string) => text && navigator.clipboard.writeText(text).catch(() => {})
  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div className="space-y-1">
          <h1 className="text-2xl font-semibold">User Details</h1>
          <p className="text-xs text-gray-500 break-all">UID: <button onClick={() => copy(id)} className="underline decoration-dotted">{id}</button></p>
        </div>
        <div className="flex gap-2 flex-wrap">
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
          <Button onClick={() => user?.email && sendPasswordResetEmail(getAuthInstance(), user.email)}>Reset password</Button>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="space-y-6 md:col-span-1">
          <div className="flex items-center gap-4">
            <div className="h-20 w-20 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden border">
              {user?.photoUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={user.photoUrl} alt={user.name || 'avatar'} className="h-full w-full object-cover" />
              ) : (
                <span className="text-xl font-semibold text-gray-500">{(user?.name || '?').slice(0,1).toUpperCase()}</span>
              )}
            </div>
            <div>
              <div className="text-lg font-medium">{user?.name ?? '—'}</div>
              <div className="text-sm text-gray-500 break-all">
                {user?.email ? <button onClick={() => copy(user.email)} className="underline decoration-dotted">{user.email}</button> : '—'}
              </div>
              <div className="mt-1 inline-flex items-center rounded-full bg-indigo-50 text-indigo-700 text-xs px-2 py-0.5">
                {user?.membershipTier ?? 'unknown'}
              </div>
            </div>
          </div>
          <div className="grid grid-cols-1 gap-3 text-sm">
            <Field label="Profession" value={user?.profession} />
            <Field label="Niche" value={user?.niche} />
            <Field label="Phone" value={user?.phone} />
            <Field label="Stripe Customer" value={user?.stripeCustomerId} copy onCopy={() => copy(user?.stripeCustomerId)} />
            <Field label="Chat TOS" value={user?.chatTosAccepted ? 'Accepted' : '—'} />
            <Field label="Created" value={createdAt?.toLocaleString()} />
          </div>
        </div>
        <div className="md:col-span-2 space-y-4">
          <h2 className="font-semibold">Last 10 bookings</h2>
          <div className="card">
            <table className="w-full text-sm table-head table-zebra">
              <thead>
                <tr>
                  <th className="text-left px-3 py-2">Booking</th>
                  <th className="text-left px-3 py-2">Workspace</th>
                  <th className="text-left px-3 py-2">Start</th>
                  <th className="text-left px-3 py-2">Status</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map((b) => (
                  <tr key={b.id} className="border-t">
                    <td className="px-3 py-2 break-all">{b.id}</td>
                    <td className="px-3 py-2">{b.workspaceId ?? '—'}</td>
                    <td className="px-3 py-2">{b.start ? new Date(b.start).toLocaleString() : '—'}</td>
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

function Field({ label, value, copy, onCopy }: { label: string; value?: string | null; copy?: boolean; onCopy?: () => void }) {
  return (
    <div className="flex items-start justify-between gap-2">
        <span className="text-gray-500 field-label">{label}</span>
          <div className="flex items-center gap-2 max-w-[60%] break-all text-gray-900 dark:text-gray-100">
        <span>{value ?? '—'}</span>
        {copy && value && (
          <button onClick={onCopy} className="text-xs px-1 py-0.5 border rounded hover:bg-gray-50">Copy</button>
        )}
      </div>
    </div>
  )
}

import * as functions from 'firebase-functions'
import * as admin from 'firebase-admin'
import { ListBookingsInput, ListBookingsOutput } from '@c3/contracts'
import { db, requireRole, writeAuditLog, encodeCursor, decodeCursor } from './utils'

export const listBookings = functions.https.onCall(async (data, context) => {
  try {
    requireRole(context, ['superadmin', 'moderator'])
    const safeData = data && typeof data === 'object' ? { ...data } : {}
    for (const k of ['cursor','roomId','userId','from','to','limit']) {
      if ((safeData as any)[k] === null) delete (safeData as any)[k]
    }
    const input = ListBookingsInput.parse(safeData || {})
    const limit = input.limit ?? 20
    let q: FirebaseFirestore.Query = db.collection('bookings')
    if (input.userId) q = q.where('userId', '==', input.userId)
    if (input.roomId) q = q.where('workspaceId', '==', input.roomId)
    if (input.from) q = q.where('startAt', '>=', admin.firestore.Timestamp.fromMillis(Date.parse(input.from)))
    if (input.to) q = q.where('startAt', '<=', admin.firestore.Timestamp.fromMillis(Date.parse(input.to)))
    q = q.orderBy('startAt', 'desc').limit(limit)
    const cursor = decodeCursor<[FirebaseFirestore.Timestamp, string]>(input.cursor)
    if (cursor) {
      const [startAt, id] = cursor
      q = q.startAfter(startAt, id)
    }
    const snap = await q.get()
    const items = snap.docs.map((d) => {
      const v = d.data() as any
      return {
        id: d.id,
        userId: v.userId,
        workspaceId: v.workspaceId || v.roomId,
        start: v.startAt?.toDate ? v.startAt.toDate().toISOString() : undefined,
        end: v.endAt?.toDate ? v.endAt.toDate().toISOString() : undefined,
        status: v.status,
      }
    })
    const last = snap.docs[snap.size - 1]
    const nextCursor = last ? encodeCursor([last.get('startAt') || admin.firestore.Timestamp.fromMillis(0), last.id]) : undefined
    await writeAuditLog({ action: 'listBookings', adminUid: context.auth?.uid, params: { userId: input.userId, roomId: input.roomId, limit } })
    return ListBookingsOutput.parse({ items, nextCursor })
  } catch (e: any) {
    if (e instanceof functions.https.HttpsError) throw e
    if (e?.name === 'ZodError') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid input: ' + e.message)
    }
    console.error('listBookings failed', e)
    throw new functions.https.HttpsError('internal', e?.message || 'Internal error')
  }
})

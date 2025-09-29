import * as functions from 'firebase-functions'
import * as admin from 'firebase-admin'
import { ListWorkspacesInput, ListWorkspacesOutput } from '@c3/contracts'
import { db, requireRole, writeAuditLog, encodeCursor, decodeCursor } from './utils'

export const listWorkspaces = functions.https.onCall(async (data, context) => {
  try {
    requireRole(context, ['superadmin', 'moderator'])
    // Treat explicit null cursor as undefined to avoid Zod invalid_type
    const safeData = data && typeof data === 'object' ? { ...data } : {}
    if (safeData && (safeData as any).cursor === null) delete (safeData as any).cursor
    const input = ListWorkspacesInput.parse(safeData || {})
    const limit = input.limit ?? 20
    let q: FirebaseFirestore.Query = db.collection('rooms').orderBy('createdAt', 'desc').limit(limit)
    const cursor = decodeCursor<[FirebaseFirestore.Timestamp, string]>(input.cursor)
    if (cursor) {
      const [createdAt, id] = cursor
      q = q.startAfter(createdAt, id)
    }
    const snap = await q.get()
    const items = snap.docs.map((d) => {
      const v = d.data() as any
      return {
        id: d.id,
        name: v.name || '',
        location: v.neighborhood || v.location || undefined,
        createdAt: v.createdAt?.toDate ? v.createdAt.toDate().toISOString() : undefined,
      }
    })
    const last = snap.docs[snap.size - 1]
    const nextCursor = last ? encodeCursor([last.get('createdAt') || admin.firestore.Timestamp.fromMillis(0), last.id]) : undefined
    await writeAuditLog({ action: 'listWorkspaces', adminUid: context.auth?.uid, params: { limit } })
    return ListWorkspacesOutput.parse({ items, nextCursor })
  } catch (e: any) {
    if (e instanceof functions.https.HttpsError) throw e
    if (e?.name === 'ZodError') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid input: ' + e.message)
    }
    console.error('listWorkspaces failed', e)
    throw new functions.https.HttpsError('internal', e?.message || 'Internal error')
  }
})

import * as functions from 'firebase-functions'
import * as admin from 'firebase-admin'
import { ListUsersInput, ListUsersOutput } from '@c3/contracts'
import { db, requireRole, writeAuditLog, decodeCursor, encodeCursor } from './utils'

export const listUsers = functions.https.onCall(async (data, context) => {
  try {
    requireRole(context, ['superadmin', 'moderator'])
    const safeData = data && typeof data === 'object' ? { ...data } : {}
    // Remove explicit nulls for optional fields to avoid Zod invalid_type
    for (const k of ['cursor','q','tier','limit']) {
      if ((safeData as any)[k] === null) delete (safeData as any)[k]
    }
    const input = ListUsersInput.parse(safeData || {})
    const limit = input.limit ?? 20
    let q: FirebaseFirestore.Query = db.collection('users')
    if (input.tier) q = q.where('membershipTier', '==', input.tier)
    const hasPrefix = Boolean(input.q && input.q.trim())
    if (hasPrefix) {
      q = q
        .where('email', '>=', input.q!)
        .where('email', '<=', input.q! + '\uf8ff')
        .orderBy('email')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(limit)
      const cursor = decodeCursor<[string, string]>(input.cursor || undefined)
      if (cursor) {
        const [email, id] = cursor
        q = q.startAfter(email, id)
      }
    } else {
      q = q.orderBy('createdAt', 'desc').orderBy(admin.firestore.FieldPath.documentId()).limit(limit)
      const cursor = decodeCursor<[FirebaseFirestore.Timestamp, string]>(input.cursor || undefined)
      if (cursor) {
        const [createdAt, id] = cursor
        q = q.startAfter(createdAt, id)
      }
    }
    let snap = await q.get()
    // If default branch (no prefix) and some docs are missing createdAt, fallback to email ordering for broader coverage
    if (!hasPrefix && snap.empty === false) {
      const missingCreated = snap.docs.some(d => !d.get('createdAt'))
      if (missingCreated) {
        let fq: FirebaseFirestore.Query = db.collection('users').orderBy('email').orderBy(admin.firestore.FieldPath.documentId()).limit(limit)
        const altCursor = decodeCursor<[string, string]>(input.cursor || undefined)
        if (altCursor) {
          const [email, id] = altCursor
          fq = fq.startAfter(email, id)
        }
        snap = await fq.get()
      }
    }
    const items = snap.docs.map((d) => {
      const v = d.data() as any
      return {
        id: d.id,
        name: v.name || '',
        email: v.email || '',
        tier: v.membershipTier || v.tier || 'free',
        createdAt: v.createdAt?.toDate ? v.createdAt.toDate().toISOString() : undefined,
      }
    })
    const last = snap.docs[snap.size - 1]
    let nextCursor: string | undefined
    if (last) {
      if (hasPrefix) {
        const email = (last.get('email') as string) || ''
        nextCursor = encodeCursor([email, last.id])
      } else {
        // If createdAt exists use createdAt cursor else fallback to email cursor encoding
        const created = last.get('createdAt') as admin.firestore.Timestamp | undefined
        if (created) {
          nextCursor = encodeCursor([created, last.id])
        } else {
          const email = (last.get('email') as string) || ''
            nextCursor = encodeCursor([email, last.id])
        }
      }
    }
    await writeAuditLog({ action: 'listUsers', adminUid: context.auth?.uid, params: { q: input.q, tier: input.tier, limit } })
    return ListUsersOutput.parse({ items, nextCursor })
  } catch (e: any) {
    if (e instanceof functions.https.HttpsError) throw e
    if (e?.name === 'ZodError') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid input: ' + e.message)
    }
    console.error('listUsers failed', e)
    throw new functions.https.HttpsError('internal', e?.message || 'Internal error')
  }
})

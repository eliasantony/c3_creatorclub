import * as functions from 'firebase-functions'
import * as admin from 'firebase-admin'
import { GetKpisInput, GetKpisOutput } from '@c3/contracts'
import { db, requireRole, writeAuditLog } from './utils'

function rangeToStart(range: '7d'|'30d'|'90d') {
  const now = Date.now()
  const days = range === '7d' ? 7 : range === '30d' ? 30 : 90
  return admin.firestore.Timestamp.fromMillis(now - days * 24 * 60 * 60 * 1000)
}

export const getKpis = functions.https.onCall(async (data, context) => {
  requireRole(context, ['superadmin', 'finance'])
  const input = GetKpisInput.parse(data || {})
  const startTs = rangeToStart(input.range)

  // total users
  const totalUsersSnap = await db.collection('users').count().get()
  const totalUsers = totalUsersSnap.data().count

  // premium users
  const premiumSnap = await db.collection('users').where('tier', '==', 'premium').count().get()
  const premiumUsers = premiumSnap.data().count

  // bookings in range
  const bookingsSnap = await db.collection('bookings').where('startAt', '>=', startTs).count().get()
  const totalBookings = bookingsSnap.data().count

  // occupancyPct placeholder
  const occupancyPct: number | null = null // TODO: compute once open hours modeled

  const result = { totalUsers, premiumUsers, totalBookings, occupancyPct }
  await writeAuditLog({ action: 'getKpis', adminUid: context.auth?.uid, params: { range: input.range } })
  return GetKpisOutput.parse(result)
})

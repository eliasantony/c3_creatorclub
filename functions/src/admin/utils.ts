import * as admin from 'firebase-admin'
import * as functions from 'firebase-functions'

const app = admin.apps.length ? admin.app() : admin.initializeApp()
export const db = app.firestore()

type Role = 'superadmin' | 'moderator' | 'finance'

export function requireRole(context: functions.https.CallableContext, allowed: Role[]) {
  const auth = context.auth
  if (!auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required')
  const role = (auth.token as any)?.role as Role | undefined
  if (!role) throw new functions.https.HttpsError('permission-denied', 'Missing admin role')
  if (role === 'superadmin') return
  if (!allowed.includes(role)) throw new functions.https.HttpsError('permission-denied', 'Insufficient role')
}

export async function writeAuditLog(entry: { action: string; adminUid?: string; params?: any }) {
  try {
    await db.collection('admin_audit_logs').add({
      action: entry.action,
      adminUid: entry.adminUid ?? null,
      params: entry.params ? sanitizeParams(entry.params) : null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    })
  } catch (e) {
    console.error('audit log write failed', e)
  }
}

function sanitizeParams(params: any) {
  try {
    return JSON.parse(JSON.stringify(params))
  } catch {
    return null
  }
}

export function encodeCursor(value: any): string {
  const json = JSON.stringify(normalizeCursor(value))
  return Buffer.from(json).toString('base64url')
}

export function decodeCursor<T = any>(encoded?: string): T | undefined {
  if (!encoded) return undefined
  try {
    const json = Buffer.from(encoded, 'base64url').toString('utf8')
    const raw = JSON.parse(json)
    return denormalizeCursor(raw) as T
  } catch {
    return undefined
  }
}

function normalizeCursor(value: any): any {
  if (Array.isArray(value)) return value.map(normalizeCursor)
  if (value && typeof value === 'object' && 'toMillis' in value) {
    // Firestore Timestamp
    return { __ts: true, ms: (value as any).toMillis() }
  }
  return value
}

function denormalizeCursor(value: any): any {
  if (Array.isArray(value)) return value.map(denormalizeCursor)
  if (value && value.__ts && typeof value.ms === 'number') {
    return admin.firestore.Timestamp.fromMillis(value.ms)
  }
  return value
}

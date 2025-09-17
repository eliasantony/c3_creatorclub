import { auth } from './firebase'

export type Role = 'superadmin' | 'moderator' | 'finance' | 'viewer'

export async function getCurrentRole(): Promise<Role> {
  const user = auth.currentUser
  if (!user) return 'viewer'
  const token = await user.getIdTokenResult(true)
  const claims = token.claims as Record<string, unknown>
  if (claims['superadmin']) return 'superadmin'
  if (claims['moderator']) return 'moderator'
  if (claims['finance']) return 'finance'
  return 'viewer'
}

export function canPerform(action: 'refund' | 'ban' | 'delete' | 'announce' | 'workspace:modify', role: Role) {
  const matrix: Record<Role, Set<string>> = {
    superadmin: new Set(['refund', 'ban', 'delete', 'announce', 'workspace:modify']),
    moderator: new Set(['ban', 'delete', 'announce']),
    finance: new Set(['refund']),
    viewer: new Set([]),
  }
  return matrix[role].has(action)
}

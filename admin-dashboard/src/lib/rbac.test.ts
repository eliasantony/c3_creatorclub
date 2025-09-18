import { describe, it, expect } from 'vitest'
import { canPerform, type Role } from './rbac'

describe('RBAC matrix', () => {
  const actions: Array<Parameters<typeof canPerform>[0]> = ['refund', 'ban', 'delete', 'announce', 'workspace:modify']
  const expectations: Record<Role, Record<string, boolean>> = {
    superadmin: { refund: true, ban: true, delete: true, announce: true, 'workspace:modify': true },
    moderator: { refund: false, ban: true, delete: true, announce: true, 'workspace:modify': false },
    finance: { refund: true, ban: false, delete: false, announce: false, 'workspace:modify': false },
    viewer: { refund: false, ban: false, delete: false, announce: false, 'workspace:modify': false },
  }
  for (const role of Object.keys(expectations) as Role[]) {
    it(`${role} permissions`, () => {
      for (const action of actions) {
        expect(canPerform(action, role)).toBe(expectations[role][action])
      }
    })
  }
})

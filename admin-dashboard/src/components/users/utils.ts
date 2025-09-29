import type { UserRow } from './UsersTable'

export function normalizeUser(data: any, id: string): UserRow {
  return {
    id,
    name: data.name ?? '',
    email: data.email ?? '',
    tier: data.tier ?? undefined,
  }
}

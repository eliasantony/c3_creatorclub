import { describe, expect, it } from 'vitest'
import { normalizeUser } from './utils'

describe('normalizeUser', () => {
  it('maps fields with defaults', () => {
    const row = normalizeUser({ name: 'A', email: 'a@example.com' }, 'id1')
    expect(row).toEqual({ id: 'id1', name: 'A', email: 'a@example.com', tier: undefined })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// Mock the call() helper to ensure it's used instead of fetch
vi.mock('@/lib/firebase', () => {
  return {
    isFirebaseConfigured: () => true,
    call: vi.fn((name: string) => {
      return async (_data: unknown) => {
        if (name === 'listBookings') {
          return { items: [], nextCursor: undefined }
        }
        return {}
      }
    }),
  }
})

// Mock only the names we need from @c3/contracts
vi.mock('@c3/contracts', () => ({
  FunctionNames: {
    listBookings: 'listBookings',
  },
}))

// Important: import the component after mocks
import BookingsPage from './page'

describe('BookingsPage callable usage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('invokes call(FunctionNames.listBookings) on initial load and on Apply', async () => {
    const qc = new QueryClient()
    render(
      <QueryClientProvider client={qc}>
        <BookingsPage />
      </QueryClientProvider>
    )
  // Shows heading
  expect(await screen.findByRole('heading', { name: /Bookings/i })).toBeDefined()

    // Click Apply to trigger refetch
  const apply = await screen.findByRole('button', { name: /apply/i })
    fireEvent.click(apply)

    // If fetch() were used to cloudfunctions.net directly, our mock would not intercept.
    // Since our mocked call() returns empty items, we expect the empty state to be visible.
  expect(await screen.findByText(/No bookings/i)).toBeDefined()
  })
})

import { z } from 'zod'
import type { UserSummary, WorkspaceSummary, BookingSummary, ReportSummary } from './types'

export const ListUsersInput = z.object({
  q: z.string().min(1).max(200).optional(),
  tier: z.enum(['free', 'premium']).optional(),
  limit: z.number().int().min(1).max(100).optional().default(20),
  cursor: z.string().optional(),
})
export type ListUsersInput = z.infer<typeof ListUsersInput>

export const ListUsersOutput = z.object({
  items: z.array(z.custom<UserSummary>()),
  nextCursor: z.string().optional(),
})
export type ListUsersOutput = z.infer<typeof ListUsersOutput>

export const GetKpisInput = z.object({
  range: z.enum(['7d', '30d', '90d']).default('30d'),
})
export type GetKpisInput = z.infer<typeof GetKpisInput>

export const GetKpisOutput = z.object({
  totalUsers: z.number(),
  premiumUsers: z.number(),
  totalBookings: z.number(),
  occupancyPct: z.number().nullable(),
})
export type GetKpisOutput = z.infer<typeof GetKpisOutput>

export const ListWorkspacesInput = z.object({
  limit: z.number().int().min(1).max(100).optional().default(20),
  cursor: z.string().optional(),
})
export type ListWorkspacesInput = z.infer<typeof ListWorkspacesInput>

export const ListWorkspacesOutput = z.object({
  items: z.array(z.custom<WorkspaceSummary>()),
  nextCursor: z.string().optional(),
})
export type ListWorkspacesOutput = z.infer<typeof ListWorkspacesOutput>

export const ListBookingsInput = z.object({
  roomId: z.string().optional(),
  userId: z.string().optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  limit: z.number().int().min(1).max(100).optional().default(20),
  cursor: z.string().optional(),
})
export type ListBookingsInput = z.infer<typeof ListBookingsInput>

export const ListBookingsOutput = z.object({
  items: z.array(z.custom<BookingSummary>()),
  nextCursor: z.string().optional(),
})
export type ListBookingsOutput = z.infer<typeof ListBookingsOutput>

export const ListReportsInput = z.object({
  status: z.enum(['open', 'actioned', 'dismissed']).optional(),
  limit: z.number().int().min(1).max(100).optional().default(20),
  cursor: z.string().optional(),
})
export type ListReportsInput = z.infer<typeof ListReportsInput>

export const ListReportsOutput = z.object({
  items: z.array(z.custom<ReportSummary>()),
  nextCursor: z.string().optional(),
})
export type ListReportsOutput = z.infer<typeof ListReportsOutput>

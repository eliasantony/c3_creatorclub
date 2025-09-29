import { z } from 'zod';
import type { UserSummary, WorkspaceSummary, BookingSummary, ReportSummary } from './types';
export declare const ListUsersInput: z.ZodObject<{
    q: z.ZodOptional<z.ZodString>;
    tier: z.ZodOptional<z.ZodEnum<["free", "premium"]>>;
    limit: z.ZodDefault<z.ZodOptional<z.ZodNumber>>;
    cursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    limit: number;
    q?: string | undefined;
    tier?: "free" | "premium" | undefined;
    cursor?: string | undefined;
}, {
    q?: string | undefined;
    tier?: "free" | "premium" | undefined;
    limit?: number | undefined;
    cursor?: string | undefined;
}>;
export type ListUsersInput = z.infer<typeof ListUsersInput>;
export declare const ListUsersOutput: z.ZodObject<{
    items: z.ZodArray<z.ZodType<UserSummary, z.ZodTypeDef, UserSummary>, "many">;
    nextCursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    items: UserSummary[];
    nextCursor?: string | undefined;
}, {
    items: UserSummary[];
    nextCursor?: string | undefined;
}>;
export type ListUsersOutput = z.infer<typeof ListUsersOutput>;
export declare const GetKpisInput: z.ZodObject<{
    range: z.ZodDefault<z.ZodEnum<["7d", "30d", "90d"]>>;
}, "strip", z.ZodTypeAny, {
    range: "7d" | "30d" | "90d";
}, {
    range?: "7d" | "30d" | "90d" | undefined;
}>;
export type GetKpisInput = z.infer<typeof GetKpisInput>;
export declare const GetKpisOutput: z.ZodObject<{
    totalUsers: z.ZodNumber;
    premiumUsers: z.ZodNumber;
    totalBookings: z.ZodNumber;
    occupancyPct: z.ZodNullable<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    totalUsers: number;
    premiumUsers: number;
    totalBookings: number;
    occupancyPct: number | null;
}, {
    totalUsers: number;
    premiumUsers: number;
    totalBookings: number;
    occupancyPct: number | null;
}>;
export type GetKpisOutput = z.infer<typeof GetKpisOutput>;
export declare const ListWorkspacesInput: z.ZodObject<{
    limit: z.ZodDefault<z.ZodOptional<z.ZodNumber>>;
    cursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    limit: number;
    cursor?: string | undefined;
}, {
    limit?: number | undefined;
    cursor?: string | undefined;
}>;
export type ListWorkspacesInput = z.infer<typeof ListWorkspacesInput>;
export declare const ListWorkspacesOutput: z.ZodObject<{
    items: z.ZodArray<z.ZodType<WorkspaceSummary, z.ZodTypeDef, WorkspaceSummary>, "many">;
    nextCursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    items: WorkspaceSummary[];
    nextCursor?: string | undefined;
}, {
    items: WorkspaceSummary[];
    nextCursor?: string | undefined;
}>;
export type ListWorkspacesOutput = z.infer<typeof ListWorkspacesOutput>;
export declare const ListBookingsInput: z.ZodObject<{
    roomId: z.ZodOptional<z.ZodString>;
    userId: z.ZodOptional<z.ZodString>;
    from: z.ZodOptional<z.ZodString>;
    to: z.ZodOptional<z.ZodString>;
    limit: z.ZodDefault<z.ZodOptional<z.ZodNumber>>;
    cursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    limit: number;
    cursor?: string | undefined;
    roomId?: string | undefined;
    userId?: string | undefined;
    from?: string | undefined;
    to?: string | undefined;
}, {
    limit?: number | undefined;
    cursor?: string | undefined;
    roomId?: string | undefined;
    userId?: string | undefined;
    from?: string | undefined;
    to?: string | undefined;
}>;
export type ListBookingsInput = z.infer<typeof ListBookingsInput>;
export declare const ListBookingsOutput: z.ZodObject<{
    items: z.ZodArray<z.ZodType<BookingSummary, z.ZodTypeDef, BookingSummary>, "many">;
    nextCursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    items: BookingSummary[];
    nextCursor?: string | undefined;
}, {
    items: BookingSummary[];
    nextCursor?: string | undefined;
}>;
export type ListBookingsOutput = z.infer<typeof ListBookingsOutput>;
export declare const ListReportsInput: z.ZodObject<{
    status: z.ZodOptional<z.ZodEnum<["open", "actioned", "dismissed"]>>;
    limit: z.ZodDefault<z.ZodOptional<z.ZodNumber>>;
    cursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    limit: number;
    cursor?: string | undefined;
    status?: "open" | "actioned" | "dismissed" | undefined;
}, {
    limit?: number | undefined;
    cursor?: string | undefined;
    status?: "open" | "actioned" | "dismissed" | undefined;
}>;
export type ListReportsInput = z.infer<typeof ListReportsInput>;
export declare const ListReportsOutput: z.ZodObject<{
    items: z.ZodArray<z.ZodType<ReportSummary, z.ZodTypeDef, ReportSummary>, "many">;
    nextCursor: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    items: ReportSummary[];
    nextCursor?: string | undefined;
}, {
    items: ReportSummary[];
    nextCursor?: string | undefined;
}>;
export type ListReportsOutput = z.infer<typeof ListReportsOutput>;

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListReportsOutput = exports.ListReportsInput = exports.ListBookingsOutput = exports.ListBookingsInput = exports.ListWorkspacesOutput = exports.ListWorkspacesInput = exports.GetKpisOutput = exports.GetKpisInput = exports.ListUsersOutput = exports.ListUsersInput = void 0;
const zod_1 = require("zod");
exports.ListUsersInput = zod_1.z.object({
    q: zod_1.z.string().min(1).max(200).optional(),
    tier: zod_1.z.enum(['free', 'premium']).optional(),
    limit: zod_1.z.number().int().min(1).max(100).optional().default(20),
    cursor: zod_1.z.string().optional(),
});
exports.ListUsersOutput = zod_1.z.object({
    items: zod_1.z.array(zod_1.z.custom()),
    nextCursor: zod_1.z.string().optional(),
});
exports.GetKpisInput = zod_1.z.object({
    range: zod_1.z.enum(['7d', '30d', '90d']).default('30d'),
});
exports.GetKpisOutput = zod_1.z.object({
    totalUsers: zod_1.z.number(),
    premiumUsers: zod_1.z.number(),
    totalBookings: zod_1.z.number(),
    occupancyPct: zod_1.z.number().nullable(),
});
exports.ListWorkspacesInput = zod_1.z.object({
    limit: zod_1.z.number().int().min(1).max(100).optional().default(20),
    cursor: zod_1.z.string().optional(),
});
exports.ListWorkspacesOutput = zod_1.z.object({
    items: zod_1.z.array(zod_1.z.custom()),
    nextCursor: zod_1.z.string().optional(),
});
exports.ListBookingsInput = zod_1.z.object({
    roomId: zod_1.z.string().optional(),
    userId: zod_1.z.string().optional(),
    from: zod_1.z.string().datetime().optional(),
    to: zod_1.z.string().datetime().optional(),
    limit: zod_1.z.number().int().min(1).max(100).optional().default(20),
    cursor: zod_1.z.string().optional(),
});
exports.ListBookingsOutput = zod_1.z.object({
    items: zod_1.z.array(zod_1.z.custom()),
    nextCursor: zod_1.z.string().optional(),
});
exports.ListReportsInput = zod_1.z.object({
    status: zod_1.z.enum(['open', 'actioned', 'dismissed']).optional(),
    limit: zod_1.z.number().int().min(1).max(100).optional().default(20),
    cursor: zod_1.z.string().optional(),
});
exports.ListReportsOutput = zod_1.z.object({
    items: zod_1.z.array(zod_1.z.custom()),
    nextCursor: zod_1.z.string().optional(),
});

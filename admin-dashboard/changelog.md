## 2025-09-18 — Hydration + favicon + App Check option

- Fix: Suppressed hydration warning on <html> to avoid dark-mode class mismatch between SSR and client (`src/app/layout.tsx`).
- UX: Added `public/favicon.svg` and stub `favicon.ico` to eliminate 404 noise in dev.
- Infra: Optional Firebase App Check initialization gated by env vars to satisfy callable checks when enforcement is enabled (`src/lib/firebase.ts`). Set `NEXT_PUBLIC_ENABLE_APPCHECK=true` and provide `NEXT_PUBLIC_RECAPTCHA_V3_SITE_KEY` (optionally `NEXT_PUBLIC_APPCHECK_DEBUG_TOKEN`) to enable.

## 2025-09-18 — Enforce callable-only Cloud Functions

- Policy: Replace any direct fetch/axios calls to Cloud Functions with Firebase `httpsCallable` via our `call<I,O>()` helper. This avoids CORS and ensures auth/App Check are attached.
- Infra: Ensure Functions region is `us-central1` by default with `NEXT_PUBLIC_FIREBASE_FUNCTIONS_REGION` override.
- QA: Added unit test for Bookings page to assert callable usage; configured Vitest jsdom env and path alias.
- Docs: Updated README with a dedicated "Callable-only policy (avoid CORS)" section.

## 2025-09-18 — Fix listUsers query + indexes

- Fixed `functions/src/admin/listUsers.ts` to correctly handle email-prefix searches with proper orderBy/email + docId cursor and tier filter using `membershipTier`.
- Added composite indexes for `users` combining `membershipTier` with `email` and with `createdAt` in `firestore.indexes.json`.
- Rationale: Firestore disallowed query/order combination was causing INTERNAL errors, which surfaced in the browser as CORS-like failures on preflight.

## 2025-09-18 — Data functions integration (partial)

- Created `packages/c3-contracts` with Zod schemas and shared types; added `FunctionNames` constants.
- Implemented callable functions `listUsers` and `getKpis` with RBAC (custom claims) and audit logs.
- Added `firestore.indexes.json` with composite indexes for users/bookings/reports.
- Overview now fetches real KPIs via `getKpis(range='30d')`.
- Users list now uses `listUsers` callable with infinite pagination.
- Bookings page now wired to `listBookings` with simple filters (userId, workspaceId, date range) and cursor pagination.

## 2025-09-18 — UI polish: breadcrumbs, overview, dark theme tokens

- Added Breadcrumbs component and wired into Topbar.
- Implemented Overview page with KPI cards and a mocked Recharts line chart.
- Introduced Card UI primitive and a TableSkeleton loader.
- Aligned root layout with theme CSS variables (bg/fg) for dark mode support.
- Minor style refinements for dark mode readiness.

## 2025-09-17

## 2025-09-18

- Added AuthProvider and /login page (email/password), redirects to `/admin/overview` on success; sign-out in Topbar
- Implemented client-side route guard for `/admin/*` (redirects to /login when unauthenticated)
- Built User Detail page: profile fields, last 10 bookings, actions (Ban, Mute 24h, Reset password) with ConfirmDialog + RBAC gate and callable stubs
- Added tests: RBAC matrix unit test; Playwright login smoke (skips if creds missing)
- Updated README with login and E2E env guidance
- Bootstrapped Next.js (TS, App Router) in `/admin-dashboard` with Tailwind
- Added core libs: Firebase init (`src/lib/firebase.ts`) with `call<I,O>()`, RBAC helpers (`src/lib/rbac.ts`)
- Implemented base layout with sidebar/topbar and routes: `/admin`, `/admin/users`, `/admin/workspaces`, `/admin/bookings`, `/admin/moderation`, `/admin/overview`
- Implemented MVP Users table with Firestore pagination and filters; row click to details placeholder
- Added ConfirmDialog component and basic RBAC gating helpers
- Added unit test setup (Vitest) and a users util test + Playwright smoke test
- Added scripts to `package.json` and README with setup steps

## 2025-09-29 — Login page restyle + App Check hardening

- UX: Restyled `/login` with brand gradient backdrop, elevated card, improved labels & focus rings consistent with design tokens (#3533CD, #363433, white). Improves contrast vs prior white-on-white layout.
- DX: Added warning when `NEXT_PUBLIC_ENABLE_APPCHECK` is true but `NEXT_PUBLIC_RECAPTCHA_V3_SITE_KEY` missing (`src/lib/firebase.ts`). Prevents silent 403 App Check token fetch failures.
- Docs: Note appended for future troubleshooting (403 AppCheck fetch-status-error typically indicates missing site key, unverified domain, or enforcement before token issuance).

## 2025-09-29 — Admin data UX & createdAt backfill

- Users: Added adaptive fallback ordering in `listUsers` callable (email ordering when `createdAt` missing) to surface legacy user docs; added full detail page fields (phone, niche, stripeCustomerId, chatTosAccepted, avatar, membershipTier badge, copy buttons).
- Workspaces: Added detail route `/admin/workspaces/[id]` with recent bookings list, loading & retry states; rows now clickable.
- Bookings: Added detail route `/admin/bookings/[id]` showing related user/workspace names, times, price, status; rows now clickable.
- Loading UX: Added inline loading rows for Workspaces & Bookings initial fetch and detail page skeleton-like placeholders.
- Data Integrity: Flutter user creation now sets `createdAt` (server timestamp). Added backfill script `functions/src/scripts/backfillCreatedAt.ts` for existing users.
- Safety: Cursor generation now tolerates missing `createdAt` by switching to email-based pagination.

## 2025-09-29 — Design system overhaul (dark mode + typography)

- Palette: Introduced refined light/dark tokens (background/surface/surface-alt/surface-hover, softer borders) for improved contrast (#121212 / #18181B dark surfaces, light #F8F9FB base).
- Typography: Switched primary UI font to Inter (weights 400–700) improving legibility; preserved `--font-garet` variable for backward compatibility.
- Components: Refactored `Input` and `Button` primitives (rounded-md, consistent padding, focus ring in accent, ghost & outline variants).
- Tables: Added zebra striping, hover states, card container (`.card` class) and consistent muted header styling across Users, Workspaces, Bookings.
- Detail Pages: Benefit from new surface tokens; improved hierarchy with subtle shadow and 12px rounding.
- Accessibility: Improved contrast for muted text vs backgrounds and visible focus outlines using accent ring.

## 2025-09-29 — Dark mode detail contrast pass

- Added `card` surface wrappers to user, workspace, and booking detail panes to prevent large undifferentiated dark regions.
- Applied `table-head` + `table-zebra` + `card` classes to detail tables (user bookings, workspace bookings) for unified styling.
- Standardized label styling with `field-label` class across user/workspace/booking Field components (muted color token for readability).
- Result: Eliminates prior white-on-white header issue and black-on-black label areas; establishes consistent layered surface hierarchy.

## 2025-09-29 — Table styling + permissions tweak

- Unified Workspaces & Bookings list row styling with Users table (surface-hover token, border-border, transition hover).
- Increased detail page text contrast (value spans now include dark:text-gray-100) for Users, Workspaces, Bookings.
- Added Firestore security rules for `workspaces` collection (admin read/write) and clarified bookings admin read path.
- Minor consistency update to bookings/workspaces table headers already using `table-head` and zebra patterns.

## 2025-09-29 — Rooms collection fix

- Corrected admin dashboard detail pages to read from `rooms` (actual collection) instead of non-existent `workspaces`.
- Updated booking detail page to resolve room name via `rooms/{id}`.
- Removed temporary `/workspaces` rules block from `firestore.rules` to avoid confusion.

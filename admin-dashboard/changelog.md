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


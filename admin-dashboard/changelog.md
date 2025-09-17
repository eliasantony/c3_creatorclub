## 2025-09-17

- Bootstrapped Next.js (TS, App Router) in `/admin-dashboard` with Tailwind
- Added core libs: Firebase init (`src/lib/firebase.ts`) with `call<I,O>()`, RBAC helpers (`src/lib/rbac.ts`)
- Implemented base layout with sidebar/topbar and routes: `/admin`, `/admin/users`, `/admin/workspaces`, `/admin/bookings`, `/admin/moderation`, `/admin/overview`
- Implemented MVP Users table with Firestore pagination and filters; row click to details placeholder
- Added ConfirmDialog component and basic RBAC gating helpers
- Added unit test setup (Vitest) and a users util test + Playwright smoke test
- Added scripts to `package.json` and README with setup steps


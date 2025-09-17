# Creator Club Admin Dashboard

Next.js 15 + TypeScript admin app.

## Prereqs
- Node 18+
- Firebase project

## Setup
1. Copy env file:
   - `cp .env.local.example .env.local` and fill Firebase web config.
2. Install deps:
   - `npm install`
3. Run dev server:
   - `npm run dev`

## Tests
- Unit: `npm run test`
- E2E: `npm run test:e2e`

## Notes
- Destructive actions must use callable Cloud Functions via `call<I,O>(name)` from `src/lib/firebase.ts` (no direct writes to sensitive collections).
- RBAC via Firebase custom claims; see `src/lib/rbac.ts`.
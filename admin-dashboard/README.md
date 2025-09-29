# Creator Club Admin Dashboard

Next.js 15 + TypeScript admin app.

## Prereqs

- Node 18+
- Firebase project

## Setup

1. Copy env file:
   - `cp .env.local.example .env.local` and fill Firebase web config.
   - To avoid CORS-like errors on callable functions when App Check enforcement is enabled, enable App Check and set `NEXT_PUBLIC_ENABLE_APPCHECK=true` with your `NEXT_PUBLIC_RECAPTCHA_V3_SITE_KEY`. For local dev, you can set `NEXT_PUBLIC_APPCHECK_DEBUG_TOKEN=auto`.
2. Install deps:
   - `npm install`
3. Run dev server:
   - `npm run dev`

## Tests

- Unit: `npm run test`
- E2E: `npm run test:e2e`
  - Optional envs to enable login flow: `PW_ADMIN_EMAIL`, `PW_ADMIN_PASSWORD`, `PW_TEST_USER_ID`

## Notes

- Destructive actions must use callable Cloud Functions via `call<I,O>(name)` from `src/lib/firebase.ts` (no direct writes to sensitive collections).
- RBAC via Firebase custom claims; see `src/lib/rbac.ts`.
- Auth: Email/password login at `/login`. Unauthenticated users are redirected from `/admin/*` to `/login`.

## Callable-only policy (avoid CORS)

- Never call Cloud Functions via fetch/axios to their HTTPS URLs.
- Always use the `call<I, O>(FunctionNames.x)` helper from `src/lib/firebase.ts`. It attaches Firebase Auth and App Check (when enabled) and targets the configured region via `NEXT_PUBLIC_FIREBASE_FUNCTIONS_REGION` (default `us-central1`).
- This avoids CORS errors and ensures RBAC and audit logging are enforced consistently.

Example:

```ts
import { call } from "@/lib/firebase";
import { FunctionNames } from "@c3/contracts";

const list = await call<{ limit: number }, { items: unknown[] }>(
  FunctionNames.listUsers
)({ limit: 20 });
```

## Theming & Dark Mode

- Dark mode is powered by `next-themes`. Use the theme toggle in the top bar to switch between light/dark.
- Brand tokens are defined as CSS variables in `src/app/globals.css` and mapped in `tailwind.config.ts`:
  - `--brand-primary` `#3533CD` (Deep Indigo)
  - `--neutral-900` `#363433` (Dark Gray)
  - `--neutral-0` `#FFFFFF` (White)
- Use Tailwind colors `bg-bg`, `text-fg`, `text-muted`, and `border-border` for surfaces and typography that adapt to dark mode.

## Emulators & Callables

Run with emulators:

```
firebase emulators:start
cd admin-dashboard
npm run dev
To connect the dashboard to local emulators, set `NEXT_PUBLIC_USE_FIREBASE_EMULATORS=1`.
```

Callable functions used by the dashboard (via `call<I,O>()`):

- `getKpis({ range: '7d'|'30d'|'90d' })` → Overview KPIs
- `listUsers({ q?, tier?, limit?, cursor? })` → Users list with infinite pagination
- More to come: `listWorkspaces`, `listBookings`, `listReports`, and action functions (banUser, muteUser, deleteMessage, create/update/deleteWorkspace)

Deploy indexes and functions:

```
firebase deploy --only firestore:indexes
cd functions && npm run deploy
```

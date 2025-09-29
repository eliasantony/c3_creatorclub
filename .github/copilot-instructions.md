# Copilot Instructions for c3_creatorclub

Purpose: Enable AI coding agents to be productive immediately in this repository, which contains both a Flutter mobile app and a Next.js admin dashboard. Keep changes small, append-only changelogs, and follow the relevant PRDs/design guidelines.

---

## Project Structure

- `/lib` → Flutter app code
- `/functions` → Firebase Cloud Functions (TypeScript). Shared backend for both Flutter app and admin dashboard. **All sensitive operations must go through these functions, never direct writes.**
- `/admin-dashboard` → Next.js (TypeScript) admin dashboard
- `/docs` → design guidelines, PRDs, shared docs

---

## Flutter App (mobile)

## Big picture

- App type: Flutter mobile app (iOS/Android), Material 3, Riverpod 2.x, GoRouter.
- Backend: Firebase (Auth, Firestore, Storage; Functions/Webhooks later). Stripe planned.
- Structure: feature-first with core/data/features:
  - `lib/core/` → theme (`core/theme/app_theme.dart`), router (`core/router/app_router.dart`), utils.
  - `lib/data/` → models (Freezed), repositories (Firebase + Stripe later).
  - `lib/features/` → UI flows (auth/, rooms/, bookings/, membership/, chat/, notifications/).
  - Entrypoint: `lib/app.dart` (MaterialApp.router) and `lib/main.dart` (Firebase init + ProviderScope).

## Conventions

- Design system: use Deep Indigo #3533CD, Dark Gray #363433, White #FFFFFF; font family `Garet` (assets/fonts). Use `AppTheme.light()/dark()`.
- Riverpod: prefer providers in repositories and features; expose streams for Firebase. Keep controller logic in providers, not widgets.
- Routing: use GoRouter with a single router provider (`routerProvider`) that redirects based on auth state.
- Models: use `freezed_annotation 3.1.0` + `json_serializable`; run build_runner as needed. Files include parts `*.freezed.dart`/`*.g.dart`.
  - Migration notes for current Freezed:
    - Classes using factory constructors must be declared with the `sealed` or `abstract` keyword (e.g., `sealed class` for unions, or `abstract class` for simple data classes).
    - Freezed no longer generates `.map`/`.when` and related extensions for pattern matching. Use Dart's built-in pattern matching instead (switch expressions and destructuring patterns).
- Changelog: always append the changes made to `changelog.md` (never overwrite). Keep increments small.

## Auth & profile (current)

- Providers: see `data/repositories/auth_repository.dart` for `authStateChangesProvider`, `userProfileProvider`.
- Registration creates `users/{uid}` with `UserProfile` then redirects to `/profile`.
- Avatar uploads via `StorageRepository` to `avatars/{uid}.jpg`; photoUrl saved in Firestore.
- Screens:
  - `/signin` → `features/auth/sign_in_screen.dart` (email/password + anonymous fallback)
  - `/register` → `features/auth/register_screen.dart` (name, email, password, phone, profession, niche, avatar)
  - `/profile` → `features/auth/profile_screen.dart`
  - `/profile/edit` → `features/auth/profile_edit_screen.dart`

## Developer workflow

- Analyze: run `flutter analyze` (keep 0 issues before committing).
- Tests: run `flutter test` (widget test exists; add more per feature). Use `--concurrency=1` if reporter stalls.
- Codegen: if adding/altering Freezed/JSON models: `dart run build_runner build --delete-conflicting-outputs`.
- Run app: `flutter run -d ios` or `-d macos`/`-d android` after `flutterfire configure` has generated `lib/firebase_options.dart`.

## Patterns & examples

- Theming: import `core/theme/app_theme.dart` and use `AppTheme.light()/dark()` in MaterialApp.
- Router guard: see `core/router/app_router.dart` redirect logic; send unauthenticated to `/signin`, and signed-in users away from `/`/auth routes to `/profile`.
- Firestore mapping: `userProfileProvider` maps document to model and injects `uid` into JSON before `fromJson`.
- Storage: `StorageRepository.uploadUserAvatar` returns a download URL; write to Firestore under the user.

## External integration (planned per PRD)

- Stripe payments (flutter_stripe) with Cloud Functions for webhooks and memberships.
- Chat via Firestore subcollections and a chat UI package.

---

## Admin Dashboard (`/admin-dashboard`)

- **App type:** Next.js 15 + TypeScript, data-intensive web app for admins only.
- **Structure:** feature-first under `/src` (`components/`, `features/`, `routes/`).
- **UI libraries:** shadcn/ui for components, TanStack Table/Query for tables & data fetching, React Hook Form + Zod for forms, Recharts for analytics.
- **Auth:** Firebase Auth with email/password login. Use Firebase Custom Claims for RBAC (`superadmin`, `moderator`, `finance`).
- **Data access:** Use Firestore SDK for reads. Use **Cloud Functions in `/functions`** for all destructive actions (refunds, bans, deletes, announcements). Do not put secrets in client.
- **Stripe:** Interact only via Cloud Functions (never from client).
- **Analytics:** Aggregated by Functions, dashboard only renders.
- **Tests:** Use Vitest for unit tests and Playwright for basic E2E smoke tests.
- **Design system:** Use the same color palette and typography as the Flutter app (Deep Indigo `#3533CD`, Dark Gray `#363433`, White `#FFFFFF`, font `Garet` where possible).

---

## Changelogs

- **Flutter app:** append-only to root `changelog.md`.
- **Admin dashboard:** maintain a separate `admin-dashboard/changelog.md`.
- Each commit must update the relevant changelog file, never overwrite.

---

## Guardrails (global)

- Always respect the appropriate PRD:  
  - `c3 - PRD.md` for the Flutter app  
  - `admin-dashboard/docs/PRD.md` for the admin dashboard
- Keep edits minimal and consistent with the feature-first layout of each project.
- Never break the build; always run tests/lints before committing.
- Always add confirmation dialogs for destructive actions in the dashboard.
- Paginate Firestore queries with `limit` + `startAfter`.
- All admin actions should log to `admin_audit_logs`.

---

## References

- Mobile PRD: `c3 - PRD.md`
- Admin PRD: `admin-dashboard/docs/PRD.md`
- Design Guidelines: `c3 - DesignGuidelines.md`

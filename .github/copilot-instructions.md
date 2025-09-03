# Copilot Instructions for c3_creatorclub

Purpose: Enable AI coding agents to be productive immediately in this Flutter + Firebase app. Keep changes small, append-only changelog, and follow the PRD/design system.

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

## Guardrails for agents

- Respect PRD in `c3 - PRD.md` and design tokens in `c3 - DesignGuidelines.md`.
- Keep edits minimal and consistent with feature-first layout.
- Never break the build; run analyze/tests after changes.
- Always append a new section to `changelog.md` describing the change.

## Known gotchas

- Version alignment: Firebase packages aligned around `firebase_core ^3.15.2` currently. Update carefully.
- DropdownButtonFormField: prefer `initialValue` over `value` (deprecation).
- Router output sometimes hides in tests; use `flutter test -r compact --concurrency=1`.

## References

- Product Requirements: `c3 - PRD.md`
- Design Guidelines: `c3 - DesignGuidelines.md`

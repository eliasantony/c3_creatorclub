## 2025-09-16 Android Stripe init resilience & Activity base class

- Android: Set manifest package to `com.c3.creatorclub` and added `android:name="com.c3.creatorclub.MainActivity"` so the correct Activity is used.
- Android: Added `android/app/src/main/kotlin/com/c3/creatorclub/MainActivity.kt` extending `FlutterFragmentActivity` (required by `flutter_stripe`).
- Cleanup: Neutralized stray legacy Activity file under `com/example/c3_creatorclub` to avoid duplicate class confusion.
- Startup: Wrapped Stripe init in try/catch so a platform init failure no longer blocks app from leaving splash screen.
- Logging: Added explicit debug logs for successful and skipped Stripe init.

## 2025-09-16 Membership deep link success routing fix

- Startup: Switched root widget from `C3App` to `C3Root` so the custom scheme deep link handler actually runs.
- Fixes `GoException: no routes for location c3creatorclub://membership/success` after returning from Stripe Checkout.
- Deep link handler now properly maps `c3creatorclub://membership/success` -> `/membership/success` and `.../cancel` -> `/membership`.

## 2025-09-16 Root path redirect fix

- Router: Added explicit `GoRoute` for `'/'` that redirects to `/rooms` to eliminate `GoException: no routes for location /` seen when the framework or external intents produced a bare root path.

## 2025-09-16 Android MaterialComponents theme for Stripe PaymentSheet

- Android: Updated `LaunchTheme` and `NormalTheme` to inherit from `Theme.MaterialComponents.DayNight.NoActionBar` (was legacy `@android:style/Theme.Light.NoTitleBar`).
- Gradle: Added `com.google.android.material:material:1.12.0` dependency.
- Fixes `PlatformException(... Your theme isn't set to use Theme.AppCompat or Theme.MaterialComponents ...)` when initializing Stripe PaymentSheet.
- No visual regression expected; splash drawable preserved via `android:windowBackground`.

## 2025-09-16 Android AppTheme & AppCompat addition

- Manifest: Set `android:theme="@style/AppTheme"` on `<application>` to ensure a MaterialComponents base after launch.
- Styles: Added `AppTheme` with brand colors (primary #3533CD, secondary #363433) inheriting `Theme.MaterialComponents.DayNight.NoActionBar`.
- Gradle: Added explicit `androidx.appcompat:appcompat:1.7.0` to guarantee AppCompat classes present for Stripe internals.

## 2025-09-16 Stripe theme detection tweak

- Android: Switched `LaunchTheme` & `NormalTheme` parents to `Theme.AppCompat.DayNight.NoActionBar` while keeping `AppTheme` on MaterialComponents to satisfy Stripe's initialization theme check.
- Styles: Added `StripePaymentSheet` overlay (MaterialComponents BottomSheet variant) for future explicit theming if needed.

## 2025-09-16 Stripe theme verification diagnostics

- Android: Updated `LaunchTheme` & `NormalTheme` to inherit directly from `AppTheme` (MaterialComponents) so the splash/normal windows expose the same Material attribute set as the application, reducing risk of mismatched theme during early PaymentSheet attachment.
- Diagnostics: Added lightweight logging in `MainActivity` (`ThemeCheck` tag) dumping activity theme reference + a subset of styled attributes to confirm Material/AppCompat ancestry at runtime.
- Purpose: Assist in resolving persistent `PlatformException` complaining about missing AppCompat/MaterialComponents theme despite dependencies & base theme being present.

## 2025-09-16 Membership deep link normalization

- Router: Added early redirect normalization for custom scheme URLs `c3creatorclub://membership/success` and `.../cancel` directly inside `routerProvider` redirect to prevent `GoException: no routes for location c3creatorclub://...`.
- Rationale: Some returns from external browser (Stripe Checkout) yield the full scheme URI before `_DeepLinkHandler` can translate; normalizing inside redirect guarantees safe navigation path.
- Fallback: Unknown membership path segments default to `/membership`.

## 2025-09-13 Booking success navigation

## 2025-09-13 Booking success calendar

## 2025-09-13 Booking detail view & tile

## 2025-09-13 Booking success shortcut

## 2025-09-13 Onboarding avatar optional

## 2025-09-13 Stripe booking payment scaffolding

## 2025-09-14 Stripe webhook skeleton

## 2025-09-14 Booking processing screen refactor

- Booking: Introduced `BookingProcessingScreen` (`/booking/processing`) to handle post-PaymentSheet polling instead of inline loop in `BookingDetailScreen`.
- BookingDetail: Removed inline Firestore polling; now navigates to processing route and waits for returned `bookingId` before pushing success screen.
- Router: Existing `booking_processing` route now actively used by flow.
- UX: Added retry + informative pending state; prevents user from landing on success before server-authoritative booking creation (webhook) completes.
- Chore: Minor import cleanup after refactor (removed unused Firestore import in detail screen).

## 2025-09-14 Booking processing query fix

- Fixed permission-denied error on processing screen by adding `userId` equality filter to booking polling query (Firestorm rule requires user ownership check when reading bookings). Added fallback to auth state's current user ID before polling.

## 2025-09-14 Membership subscription scaffold

## 2025-09-14 Membership dynamic pricing & trial removal

- Firestore rules: opened `config/*` for public read, admin write.
- Added `config_repository.dart` with `pricingConfigProvider` (doc: `config/membership_pricing`) supplying `priceId`, `priceCents`, `currency`.
- Membership UI: Removed 30‑day free trial messaging; button now reads "Subscribe now" and reflects dynamic price from config; fallback messaging when pricing missing.
- Upgrade flow: replaced hardcoded price ID with fetched config value; errors surfaced if missing.

## 2025-09-14 Subscription metadata enhancement

- Added `subscription_data.metadata` (userId, purpose) to Stripe Checkout session so downstream `customer.subscription.*` webhook events carry user association reliably.

## 2025-09-15 Hosting membership result pages

- Added static hosting pages `web/membership-success/` and `web/membership-cancel/` for Stripe Checkout `success_url` / `cancel_url` landing with simple guidance and optional custom-scheme redirect comments.

- Functions: Added `createMembershipCheckoutSession`, `createBillingPortalSession`, and extended `stripeWebhook` to handle subscription lifecycle events (create/update/delete) updating `users/{uid}.membershipTier` and `memberships/{uid}` metadata.
- Repo: Extended `PaymentRepository` with methods for checkout and billing portal sessions.
- UI: Revamped `MembershipScreen` with feature list card, upgrade CTA (Stripe Checkout), manage subscription (Billing Portal) for active members.
- Placeholder: Uses hardcoded `price_premium_monthly_eur` (to externalize later). Web deep link origin used for success/cancel/return URLs (mobile custom scheme future work).

## 2025-09-15 Membership origin fallback fix

- Membership: Fixed Stripe Checkout error "Origin is only applicable schemes http and https" when running under `file://` (debug/mobile). Added origin resolver using `config/membership_pricing.checkoutBaseUrl` when current scheme isn't http(s); applied to both upgrade (Checkout) and manage (Billing Portal) flows.

## 2025-09-15 Membership webhook & sync enhancements

- Functions: Added richer logging, broadened premium gating to include `incomplete` status, immediate handling in `checkout.session.completed`, and a `syncMembershipForUser` callable for recovery.
- Client: Added `syncMembershipForUser()` in `PaymentRepository` and automatic/manual sync attempts from `MembershipProcessingScreen` on timeout (with Force Sync button).

## 2025-09-15 Membership customer persistence & portal fix

- Functions: Persist `stripeCustomerId` onto user document during `checkout.session.completed` and subscription lifecycle events. Billing portal callable now first reads stored `stripeCustomerId`, then falls back to subscription scan and stores it for future calls.
- Client: Processing screen uses GoRouter for success navigation avoiding missing Navigator routes. Portal errors should drop once customer id is stored.

## 2025-09-15 Membership cancellation callable

- Functions: Added `cancelMembership` callable supporting immediate or period-end cancellation, updating membership doc and user tier.
- Client: Added `cancelMembership()` method in `PaymentRepository` (UI hook pending).

## 2025-09-15 Membership success navigation & periodEnd guard

- UI: `MembershipSuccessScreen` now uses `context.go('/rooms')` for the Continue button to avoid no-op when stack came from external browser return (previous Navigator.popUntil could fail if stack root differed).
- Functions: Guard writes of `currentPeriodEnd` to omit invalid Unix epoch (1970) when Stripe returns 0/undefined (common during early `incomplete` state). Extracted repeated logic to build membership update objects; prevented storing meaningless placeholder timestamps.
- Functions: Added precedence guard to skip overwriting an already active/trialing membership with a later `incomplete` event (possible event ordering edge case) to keep user premium access stable.

## 2025-09-15 Membership management UI & deep links

- Infra: Replaced deprecated `uni_links` (caused Android namespace build failure) with `app_links` for deep link handling; updated `app.dart` accordingly.
- Android: Upgraded module JVM target to 17 and added Kotlin toolchain (jvmToolchain(17)) to resolve 'Inconsistent JVM-target compatibility (17 vs 21)' build failure.
- Android: Enabled Gradle Java toolchain auto-detect/download and root toolchain languageVersion=17 to resolve missing local JDK 17 error.
  \n## 2025-09-15 Android build fix (remove invalid root java extension)

- Removed erroneous root-level Java toolchain configuration in `android/build.gradle.kts` that attempted to access a non-existent `java` extension (root project doesn't apply Java plugin). This caused build failure: `Extension with name 'java' does not exist`. JVM targeting now relies solely on module (`android/app/build.gradle.kts`) `compileOptions` + `kotlin { jvmToolchain(17) }`.

  \n+## 2025-09-13 Booking list screen\n+\n+- Booking: Implemented `MyBookingsScreen` with upcoming and past sections using new `userSplitBookingsProvider` (streams & splits user bookings). Added `BookingData` lightweight model and repository stream helpers. Added `/bookings` route (`my_bookings`) and AppBar action on `RoomsListScreen` (event_note icon) to access bookings. Empty state encourages exploring rooms.\n\*\*\* End Patch

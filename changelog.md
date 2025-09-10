## 2025-09-10

- Rooms: Added full-screen swipeable image gallery (`ImageGalleryScreen`) and wired it from `RoomDetailScreen` header images (tap to open). Minimal, no routing change; uses `MaterialPageRoute` from detail screen.

## [Unreleased] - Add Chat ToS gating for premium users

- Added `chatTosAccepted` to `UserProfile` (default false) to persist one-time agreement.
- Implemented a first-run Terms dialog in `ChatListScreen` for premium members; blocks until accepted; persisted to Firestore via `AuthRepository.setChatTosAccepted`.
- Session guard avoids duplicate dialogs during rebuilds.
- Improved dialog UX: bullet-point highlights and a primary FilledButton for agreement.

## 2025-09-09 Chat polish

- Keep message time inside bubble; enforce min width and left-align text; timestamp anchored bottom-right.
- Tighten spacing for grouped messages (smaller vertical gaps when group continues).
- Fix PDF in-app preview by switching to PdfViewPinch with proper controller; add loader and error.
- Stabilize message ordering and eliminate brief duplicate-send flicker by writing client `createdAt` and server `serverAt`; prefer `serverAt` for display.

## 2025-09-04 Chat improvements

- Chat UI now shows user avatars (circles) and names via resolveUser.
- Consecutive messages are visually grouped by hiding intermediate timestamps (handled in repository).
- Moved attach action into the composer next to send and added an attachment preview overlay above the input field.
- Implemented reliable image (ImagePicker) and PDF (file_selector) picking and sending through StorageRepository.
- Fixed attachment sending flow and added progress state in preview.

## 2025-09-04

- Added router guard to redirect signed-in users with incomplete profiles to `/onboarding` until phone, profession, niche, and avatar are set.
- Added Storage rules (`storage.rules`) to permit users to write their avatar at `avatars/{uid}.jpg` (public read), and keep other paths denied.
- Added combined `AuthScreen` with gradient background, glowing SVG logo, and signup-first UX with login toggle.
- Implemented `OnboardingFlow` (two intro pages + details form for phone, niche, profession, avatar upload) and route `/onboarding`.
- Updated router to use `/auth` as entry and skip onboarding for existing users (redirects signed-in users to `/rooms`). Legacy `/signin` and `/register` now point to combined auth.
- Styled old `SignInScreen` to match branding; kept for back-compat.
- Added `flutter_svg` and registered `assets/logo.svg` in `pubspec.yaml`.

## 2025-09-04 (2)

- Chat: Group consecutive messages by same author; only last in run shows time (others have createdAt suppressed).
- Chat: Fixed attachment picker crash (MissingPluginException from FileType.custom). Uses image/pdf choices and platform-supported pickers.
- Chat: Attachment action remains in AppBar due to current flutter_chat_ui API; can move beside send after upgrading to a version exposing input builders.

# Changelog

- Bootstrapped a new Flutter app inside the existing `c3_creatorclub` repository; configured iOS/Android bundle IDs; integrated Firebase via FlutterFire; generated `lib/firebase_options.dart`; installed `firebase_core`; implemented init screen showing project/app IDs; added `.gitignore` and pushed to GitHub. (Notes: CI draft not included; iOS CocoaPods installed and bundle ID set; Android `applicationId` updated.)
- Implemented design system theming with `AppTheme` using brand colors (Primary #3533CD, Dark Gray #363433, White #FFFFFF); wired into `MaterialApp`; styled AppBar, Buttons, Inputs, Dividers, Cards, Chips. Replaced seed theme with explicit `AppTheme.light()`/`dark()`.
- Added Garet fonts to `assets/fonts/` and registered in `pubspec.yaml`; typography across light/dark uses `Garet`.
- Added `flutter_riverpod` and `go_router`; created `lib/app.dart` (`C3App`) with `MaterialApp.router`; added `core/router/app_router.dart` and basic route to Firebase check; updated `main.dart` to use `ProviderScope`; fixed widget test after `MyApp` removal.
- Added codegen stack (macros): pinned `freezed_annotation 3.1.0`, `freezed`, `json_annotation`, `json_serializable`, `build_runner`; added `UserProfile` model (`lib/data/models/user_profile.dart`) with PRD fields and `fromJson`. (Notes: Using Dart macros; no generated files committed.)
- Added `firebase_auth` and `cloud_firestore` (aligned with `firebase_core` 3.15.2); built `auth_repository.dart` with auth state provider, user profile stream, and sign-in/out helpers; added `SignInScreen` and `ProfileScreen`; router guards redirect unauthenticated to `/signin` and authenticated to `/profile`; `app.dart` now reads router from `routerProvider`; updated tests to expect Sign In when unauthenticated.
- Extended registration: profession selector; avatar upload to Firebase Storage with photoUrl persisted; `UserProfile` includes `profession`; profile shows avatar and profession; refined register form integrated with repository; analyzer/tests green.
- Added Profile Edit screen (`/profile/edit`) to edit name, phone, profession, niche, and avatar; route and AppBar action wired; flows refined to match PRD.
- Added `firebase_storage`, `image_picker`, `cached_network_image`; created `storage_repository.dart`; implemented email/password register + sign-in with Firestore profile creation; added `/register` route; kept analyzer/tests green. (Notes: earlier macro alignment impacted profession; later restored.)
- Added MVP shell with bottom NavigationBar (`HomeShell`) and routes `/rooms`, `/chat`, `/profile`; placeholder screens for Rooms, Chat, My Bookings, Membership; simple `isPremiumProvider` for premium checks; router migrated to `ShellRoute` and redirects signed-in users to `/rooms`.
- UI widgets: `MembershipBadge`, `UserAvatar`, `SectionHeader`, `RoomCard`, `SlotGrid`; Rooms list shows sample RoomCards and navigates to `RoomDetailScreen` preview. (Notes: Chat premium gating stubbed for now.)
- Added Room domain model (`Room` via Freezed/JSON) and `RoomsRepository` with `roomsProvider` stream; enhanced `RoomCard` (photos, location, capacity, facilities, price, rating); `RoomDetailScreen` initially showed hours, facilities, description, and SlotGrid; `RoomsListScreen` consumes provider with sample fallback when Firestore is empty. (Notes: codegen via macros may output 0 files but analyzer compiles.)
- Infra: added `firestore.rules` allowing public read of `/rooms/*` and self read/write for `/users/{uid}`; updated README with rules deployment and manual seeding instructions for `rooms`.
- Added `.github/copilot-instructions.md` with project conventions, Freezed migration notes, and references to PRD and Design Guidelines.
- Redesigned `RoomDetailScreen` with a modern layout: photo carousel with rounded corners, info chips (location, capacity, hours), amenities grid with icons, TableCalendar date selector, SlotGrid bound to the room’s open hours, and a footer with price and “Book Now” CTA; converted screen to `StatefulWidget`, cleaned duplicate imports, and kept analyzer green. Also added the `table_calendar` dependency.

- Added chat feature scaffolding per PRD using flutter_chat_ui 2.9.0.
- Added dependencies: flutter_chat_ui, flutter_chat_core, flutter_chat_types.
- Implemented `Group` model (Freezed) and `ChatRepository` for Firestore groups/messages.
- Added `ChatListScreen` (lists groups) and `ChatScreen` (message UI) with GoRouter route `/chat/:id`.
- Extended `StorageRepository` with `uploadChatImage` for future image messages.
- Note: Run codegen for Freezed and pub get; Firestore rules and moderation to follow.

### Firestore rules and Cloud Functions scaffold

- Updated `firestore.rules` to cover users, memberships, bookings, groups/members/messages, reports, announcements with Premium write gate for chat messages and self-delete.
- Created `functions/` TypeScript workspace with basic functions (`ping`, `onReportCreated`, `stripeWebhook`) and a `seed` script to create initial community groups.

## 2025-09-04

- Chat: Messages now load immediately when opening a group (bind controller with fireImmediately).
- Chat: Live updates from other users appear instantly via Firestore snapshot -> controller sync.
- Chat: Replaced floating attachment button with AppBar action to avoid overlapping the send button; uses File Picker for images/PDFs.

## 2025-09-08 Chat refinements

- Fixed iOS PDF picker (added UTI `com.adobe.pdf` to `XTypeGroup`).
- Reworked `ChatScreen` with custom builders: consistent avatar slot width, sender name on first message of group, date headers (Today / Yesterday / dd.MM.yyyy).
- Added media (image/file) timestamp overlay and unified rounded radius (16).
- Solid composer background; attach icon now flush right next to send; inline attachment preview moved into composer (removed overlay Stack).
- Added `_MediaBubble` and `_DateHeader` helper widgets; improved spacing for grouped messages.
- Cleaned up legacy timestamp suppression logic in repository (UI handles grouping now).

## 2025-09-08 Chat media & composer fixes

- Fixed corrupted chat builders and stabilized custom composer rendering at the bottom (removed extra Stack wrapper misuse).
- Added fullscreen image viewer with pinch-zoom (InteractiveViewer + Hero) and external open action.
- Added file (PDF) tap handling to open externally via url_launcher (dependency added).
- Began groundwork for embedding sender metadata hints for avatar/name fallback (userHints map) pending repository metadata support.
- Added `url_launcher` dependency to `pubspec.yaml` for external URL opening.

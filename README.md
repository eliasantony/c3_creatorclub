# c³ – Creator Club (c3_app)

Minimal, modern, clean Flutter + Firebase starter with Riverpod, GoRouter, Material 3, strict lints, and CI.

## Stack

- Flutter 3.35.x (Dart 3.9), Material 3 theming
- Riverpod 2.x, GoRouter 16.x
- Firebase: Core, Auth, Firestore, Storage, Functions, Analytics, Crashlytics, (FCM stub)
- Freezed + JsonSerializable models
- Tests: unit, widget, golden (golden_toolkit)

## Setup

1. **Install Flutter** (stable 3.35.x).
2. **Install Firebase tooling**
   ```bash
   npm i -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```

## Firestore rules

See `firestore.rules` for current access:

- Public read for `/rooms/*` (browsing without auth)
- Users can read/write their own `/users/{uid}`
- Other collections are locked by default

Deploy with the Firebase CLI (optional):

```bash
firebase deploy --only firestore:rules
```

## Seeding rooms (local)

Until admin tooling exists, create a couple of sample docs in Firestore:

- Collection: `rooms`
- Doc fields (example):
  - name: "Podcast Studio – Neubau"
  - neighborhood: "Neubau"
  - capacity: 3
  - facilities: ["podcast","acoustic","mic x3","wifi"]
  - photos: ["https://…"]
  - openHourStart: 6
  - openHourEnd: 23
  - priceCents: 6900
  - rating: 4.8

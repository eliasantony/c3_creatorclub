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
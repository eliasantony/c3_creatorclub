# Firebase Functions for c3_creatorclub

This folder contains Cloud Functions (TypeScript) and scripts.

Setup:

- npm install
- For local development: use Firebase Emulators or service account.

Scripts:

- `npm run seed` seeds initial community groups into Firestore.

Functions:

- `ping`: HTTP health check.

Run seed against production

- Download a service account JSON with Firestore access.
- Set env var GOOGLE_APPLICATION_CREDENTIALS or SERVICE_ACCOUNT_PATH to its file path.
- Ensure GCLOUD_PROJECT is set if not embedded in the service account file.
- Then run:
  - npm run seed

Run seed against emulator

- export FIRESTORE_EMULATOR_HOST=localhost:8080
- export GCLOUD_PROJECT=c3club-app
- npm run seed
- `onReportCreated`: scaffold for moderation flow.
- `stripeWebhook`: placeholder to be implemented.

Deploy:

- `npm run build && npm run deploy`

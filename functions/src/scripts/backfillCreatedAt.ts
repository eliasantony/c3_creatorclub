/**
 * Backfill script: sets createdAt (Firestore Timestamp) on user docs missing it.
 * Usage (from functions directory): npx ts-node src/scripts/backfillCreatedAt.ts
 */
import * as admin from 'firebase-admin'
import { readFileSync } from "fs";

// Load service account key
const serviceAccount = JSON.parse(
  readFileSync("serviceAccount.json", "utf8")
);

if (admin.apps.length === 0) {
  admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
});
}

async function run() {
  const db = admin.firestore()
  const usersRef = db.collection('users')
  const batchSize = 300
  let processed = 0
  let updated = 0

  const snap = await usersRef.get()
  const docs = snap.docs
  for (let i = 0; i < docs.length; i += batchSize) {
    const slice = docs.slice(i, i + batchSize)
    const batch = db.batch()
    slice.forEach(d => {
      const data = d.data() as any
      if (!data.createdAt) {
        batch.update(d.ref, { createdAt: admin.firestore.FieldValue.serverTimestamp() })
        updated++
      }
      processed++
    })
    if (slice.length > 0) {
      await batch.commit()
      // eslint-disable-next-line no-console
      console.info(`[backfillCreatedAt] Batch committed: processed=${processed} updated=${updated}`)
    }
  }
  // eslint-disable-next-line no-console
  console.info(`[backfillCreatedAt] Complete. Total processed=${processed} newly set=${updated}`)
}

run().catch(e => {
  // eslint-disable-next-line no-console
  console.error('[backfillCreatedAt] Failed', e)
  process.exit(1)
})

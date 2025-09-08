import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Hello World health check
export const ping = functions.https.onRequest((_req, res) => {
  res.status(200).send({ ok: true, ts: Date.now() });
});

// Chat moderation: hide message after N reports (basic scaffold)
export const onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap) => {
    const report = snap.data();
    const targetRef: string | undefined = report?.targetRef;
    if (!targetRef) return;
    // TODO: increment a counter on target; if above threshold, mark hidden
    // await db.doc(targetRef).update({ hidden: true });
  });

// Stripe webhooks placeholder (to be implemented)
export const stripeWebhook = functions.https.onRequest(async (_req, res) => {
  // TODO: verify signature, handle events
  res.status(200).send('ok');
});

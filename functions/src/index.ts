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

// Slot Locking (simplified): lock a slot for N minutes to avoid race conditions
// Path: roomSlots/{roomId}/{yyyymmdd}/{slotId}
// Request body: { roomId, yyyymmdd, slotId, holdMinutes }
export const lockSlot = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  const { roomId, yyyymmdd, slotId, holdMinutes = 10 } = data || {};
  if (!roomId || !yyyymmdd || !slotId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing params');
  }
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + holdMinutes * 60 * 1000
  );
  const ref = db
    .collection('roomSlots')
    .doc(roomId)
    .collection(yyyymmdd)
    .doc(slotId);

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) {
        const s = snap.data() as any;
        // if existing lock not expired, reject
        if (s.status === 'locked' && s.expiresAt && s.expiresAt.toMillis() > now.toMillis()) {
          throw new functions.https.HttpsError('already-exists', 'Slot already locked');
        }
        if (s.status === 'booked') {
          throw new functions.https.HttpsError('failed-precondition', 'Slot already booked');
        }
      }
      tx.set(ref, {
        status: 'locked',
        lockedBy: context.auth?.uid,
        lockedAt: now,
        expiresAt,
      }, { merge: true });
    });
    return { ok: true, expiresAt: expiresAt.toMillis() };
  } catch (e: any) {
    if (e instanceof functions.https.HttpsError) throw e;
    throw new functions.https.HttpsError('internal', e?.message ?? 'lock failed');
  }
});

// Mark a slot as booked (called after payment or premium confirm)
export const markSlotBooked = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  const { roomId, yyyymmdd, slotId } = data || {};
  if (!roomId || !yyyymmdd || !slotId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing params');
  }
  const ref = db
    .collection('roomSlots')
    .doc(roomId)
    .collection(yyyymmdd)
    .doc(slotId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new functions.https.HttpsError('failed-precondition', 'Slot not locked');
    }
    const s = snap.data() as any;
    if (s.status === 'booked') {
      return; // idempotent
    }
    tx.set(ref, { status: 'booked', bookedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  });
  return { ok: true };
});

// Atomically lock a range (array) of slots to reduce latency vs multiple calls.
// data: { roomId, yyyymmdd, slots: number[], holdMinutes }
// Behavior: if any slot booked OR locked (not expired) by another user -> abort.
// If locked by same user OR expired -> overwrite/refresh.
export const lockSlotRange = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  const { roomId, yyyymmdd, slots, holdMinutes = 10 } = data || {};
  if (!roomId || !yyyymmdd || !Array.isArray(slots) || slots.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing params');
  }
  const uid = context.auth.uid;
  const uniqueSlots = Array.from(new Set(slots.map((s: any) => parseInt(String(s), 10)))).filter((n) => !isNaN(n));
  uniqueSlots.sort((a, b) => a - b);
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + holdMinutes * 60 * 1000
  );
  const col = db.collection('roomSlots').doc(roomId).collection(yyyymmdd);
  try {
    await db.runTransaction(async (tx) => {
      const snaps = await Promise.all(uniqueSlots.map((i) => tx.get(col.doc(String(i)))));
      // Validate
      for (let idx = 0; idx < snaps.length; idx++) {
        const snap = snaps[idx];
        if (!snap.exists) continue;
        const data = snap.data() as any;
        if (data.status === 'booked') {
          throw new functions.https.HttpsError('failed-precondition', `Slot ${uniqueSlots[idx]} already booked`);
        }
        if (data.status === 'locked' && data.expiresAt && data.expiresAt.toMillis() > now.toMillis() && data.lockedBy !== uid) {
          throw new functions.https.HttpsError('already-exists', `Slot ${uniqueSlots[idx]} locked`);
        }
      }
      // Write / refresh
      for (const s of uniqueSlots) {
        tx.set(col.doc(String(s)), {
          status: 'locked',
          lockedBy: uid,
          lockedAt: now,
          expiresAt,
        }, { merge: true });
      }
    });
    return { ok: true, slots: uniqueSlots, expiresAt: expiresAt.toMillis() };
  } catch (e: any) {
    if (e instanceof functions.https.HttpsError) throw e;
    throw new functions.https.HttpsError('internal', e?.message ?? 'lock range failed');
  }
});

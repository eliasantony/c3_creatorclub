import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
export { listUsers } from './admin/listUsers'
export { getKpis } from './admin/getKpis'
export { listWorkspaces } from './admin/listWorkspaces'
export { listBookings } from './admin/listBookings'
export { listReports } from './admin/listReports'

const app = admin.apps.length ? admin.app() : admin.initializeApp();
const db = app.firestore();
// Secure Stripe secret via Firebase Functions secrets. Set with:
//   firebase functions:secrets:set STRIPE_SECRET_KEY
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
let stripeInstance: Stripe | null = null;
function getStripe(): Stripe {
  if (!stripeInstance) {
    stripeInstance = new Stripe(stripeSecret.value(), { apiVersion: '2024-06-20' });
  }
  return stripeInstance;
}

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
export const stripeWebhook = functions
  .runWith({ secrets: [stripeSecret, stripeWebhookSecret] })
  .https.onRequest(async (req, res) => {
    const sig = req.headers['stripe-signature'] as string | undefined;
    if (!sig) {
      res.status(400).send('Missing signature');
      return;
    }
    let event: Stripe.Event;
    try {
      const stripe = getStripe();
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        stripeWebhookSecret.value(),
      );
    } catch (e: any) {
      console.error('Webhook signature verification failed', e);
      res.status(400).send(`Webhook Error: ${e.message}`);
      return;
    }

    try {
      switch (event.type) {
        case 'payment_intent.succeeded': {
          const pi = event.data.object as Stripe.PaymentIntent;
          const md = (pi.metadata || {}) as any;
          const roomId = md.roomId;
          const userId = md.userId;
          const startAtMs = parseInt(md.startAt || '0', 10);
          const endAtMs = parseInt(md.endAt || '0', 10);
          const slotIndicesStr = md.slotIndices as string | undefined;
          const yyyymmdd = md.yyyymmdd as string | undefined;
          if (roomId && userId && startAtMs > 0 && endAtMs > 0) {
            const existing = await db
              .collection('bookings')
              .where('paymentIntentId', '==', pi.id)
              .limit(1)
              .get();
            if (existing.empty) {
              await db.collection('bookings').add({
                roomId,
                userId,
                startAt: admin.firestore.Timestamp.fromMillis(startAtMs),
                endAt: admin.firestore.Timestamp.fromMillis(endAtMs),
                priceCents: pi.amount_received ?? pi.amount ?? 0,
                paymentIntentId: pi.id,
                status: 'confirmed',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
            if (slotIndicesStr && yyyymmdd) {
              const parts = slotIndicesStr.split('-').map(p => parseInt(p, 10)).filter(n => !isNaN(n));
              if (parts.length) {
                const col = db.collection('roomSlots').doc(roomId).collection(yyyymmdd);
                const batch = db.batch();
                for (const idx of parts) {
                  batch.set(col.doc(String(idx)), { status: 'booked', bookedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
                }
                await batch.commit();
              }
            }
          }
          break;
        }
        case 'checkout.session.completed': {
          const session = event.data.object as Stripe.Checkout.Session;
            try {
              if (session.mode === 'subscription') {
                const subId = session.subscription as string | undefined;
                let userId = (session.metadata as any)?.userId;
                const stripe = getStripe();
        const customerId = session.customer as string | undefined;
                if (subId) {
                  const sub = await stripe.subscriptions.retrieve(subId);
                  const status = sub.status;
                  if (!userId) userId = (sub.metadata as any)?.userId;
                  console.log('[WEBHOOK] checkout.session.completed subId=%s status=%s userId=%s', subId, status, userId);
                  if (userId && (status === 'active' || status === 'trialing' || status === 'incomplete')) {
                    // Avoid downgrading an already active/trialing membership back to incomplete (possible event reordering)
                    if (status === 'incomplete') {
                      const existing = await db.collection('memberships').doc(userId).get();
                      const prev = existing.exists ? (existing.data() as any)?.status : undefined;
                      if (prev === 'active' || prev === 'trialing') {
                        console.log('[WEBHOOK] skipping incomplete overwrite after active/trialing for user %s', userId);
                        break;
                      }
                    }
                    const userUpdate: any = { membershipTier: 'premium' };
                    if (customerId) userUpdate.stripeCustomerId = customerId;
                    await db.collection('users').doc(userId).set(userUpdate, { merge: true });
                    const periodEndSeconds = sub.current_period_end || 0;
                    const membershipUpdate: any = {
                      status,
                      subscriptionId: sub.id,
                      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    };
                    if (periodEndSeconds > 0) {
                      membershipUpdate.currentPeriodEnd = admin.firestore.Timestamp.fromMillis(periodEndSeconds * 1000);
                    }
                    await db.collection('memberships').doc(userId).set(membershipUpdate, { merge: true });
                  } else {
                    console.log('[WEBHOOK] checkout.session.completed subscription status not premium-applicable yet');
                  }
                } else {
                  console.log('[WEBHOOK] checkout.session.completed without subscription id');
                }
              }
            } catch (e) {
              console.error('Error handling checkout.session.completed', e);
            }
            break;
        }
        case 'customer.subscription.created':
        case 'customer.subscription.updated': {
          const sub = event.data.object as Stripe.Subscription;
          const md: any = sub.metadata || {};
          const userId = md.userId;
          const status = sub.status; // trialing, active, past_due, canceled, etc.
          console.log('[WEBHOOK] %s subId=%s status=%s userId=%s', event.type, sub.id, status, userId);
          if (userId && (status === 'active' || status === 'trialing' || status === 'incomplete')) {
            if (status === 'incomplete') {
              const existing = await db.collection('memberships').doc(userId).get();
              const prev = existing.exists ? (existing.data() as any)?.status : undefined;
              if (prev === 'active' || prev === 'trialing') {
                console.log('[WEBHOOK] skipping incomplete overwrite after active/trialing for user %s', userId);
                break;
              }
            }
            const update: any = { membershipTier: 'premium' };
            if (sub.customer) update.stripeCustomerId = sub.customer;
            await db.collection('users').doc(userId).set(update, { merge: true });
            const periodEndSeconds = sub.current_period_end || 0;
            const membershipUpdate: any = {
              status,
              subscriptionId: sub.id,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            if (periodEndSeconds > 0) {
              membershipUpdate.currentPeriodEnd = admin.firestore.Timestamp.fromMillis(periodEndSeconds * 1000);
            }
            await db.collection('memberships').doc(userId).set(membershipUpdate, { merge: true });
          } else if (userId && (status === 'canceled' || status === 'incomplete_expired' || status === 'unpaid')) {
            await db.collection('users').doc(userId).set({ membershipTier: 'basic' }, { merge: true });
            const periodEndSeconds = sub.current_period_end || 0;
            const membershipUpdate: any = {
              status,
              subscriptionId: sub.id,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            if (periodEndSeconds > 0) {
              membershipUpdate.currentPeriodEnd = admin.firestore.Timestamp.fromMillis(periodEndSeconds * 1000);
            }
            await db.collection('memberships').doc(userId).set(membershipUpdate, { merge: true });
          }
          break;
        }
        case 'customer.subscription.deleted': {
          const sub = event.data.object as Stripe.Subscription;
          const md: any = sub.metadata || {};
          const userId = md.userId;
          if (userId) {
            await db.collection('users').doc(userId).set({ membershipTier: 'basic' }, { merge: true });
            await db.collection('memberships').doc(userId).set({
              status: 'canceled',
              subscriptionId: sub.id,
              currentPeriodEnd: admin.firestore.Timestamp.fromMillis((sub.current_period_end || 0) * 1000),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
          }
          break;
        }
        case 'payment_intent.payment_failed': {
          // Could release locks early if desired; need metadata to identify slots.
          break;
        }
        default:
          // Ignore other events for now
          break;
      }
      res.json({ received: true });
    } catch (e: any) {
      console.error('Webhook handler error', e);
      res.status(500).send('Internal webhook error');
    }
  });

// Create Stripe Checkout Session for recurring membership subscription.
// Expects { priceId, successUrl, cancelUrl }
// Returns { url }
export const createMembershipCheckoutSession = functions
  .runWith({ secrets: [stripeSecret] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }
    const { priceId, successUrl, cancelUrl } = data || {};
    if (!priceId || !successUrl || !cancelUrl) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing params');
    }
    const stripe = getStripe();
    try {
      // Try to find existing customer id from user doc metadata (optional improvement later)
      const uid = context.auth.uid;
      const session = await stripe.checkout.sessions.create({
        mode: 'subscription',
        line_items: [
          {
            price: priceId,
            quantity: 1,
          },
        ],
        success_url: successUrl + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: cancelUrl,
        metadata: { userId: uid, purpose: 'membership_subscription' },
        subscription_data: {
          metadata: { userId: uid, purpose: 'membership_subscription' },
        },
      });
      return { url: session.url };
    } catch (e: any) {
      functions.logger.error('Checkout session create failed', e);
      throw new functions.https.HttpsError('internal', e?.message || 'Failed to create session');
    }
  });

// Create a billing portal session so user can manage subscription.
// Expects { returnUrl }
// Returns { url }
export const createBillingPortalSession = functions
  .runWith({ secrets: [stripeSecret] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    const { returnUrl, customerId } = data || {};
    if (!returnUrl) throw new functions.https.HttpsError('invalid-argument', 'Missing returnUrl');
    if (typeof returnUrl !== 'string' || !/^https?:\/\//i.test(returnUrl)) {
      throw new functions.https.HttpsError('invalid-argument', 'returnUrl must start with http or https');
    }
    const stripe = getStripe();
    try {
      // In a production system you'd persist the Stripe customer ID on the user profile after first subscription.
      // For MVP we look up the active subscription by metadata userId.
      let custId = customerId as string | undefined;
      const uid = context.auth.uid;
      if (!custId) {
        // Check stored user doc
        const userSnap = await db.collection('users').doc(uid).get();
        const stored = userSnap.exists ? (userSnap.data() as any)?.stripeCustomerId : undefined;
        if (stored) custId = stored;
      }
      if (!custId) {
        // Fallback: search subscription list by metadata (inefficient)
        const subs = await stripe.subscriptions.list({ limit: 50 });
        const match = subs.data.find(s => (s.metadata as any)?.userId === uid);
        custId = match?.customer as string | undefined;
        if (custId) {
          await db.collection('users').doc(uid).set({ stripeCustomerId: custId }, { merge: true });
        }
      }
      if (!custId) throw new functions.https.HttpsError('failed-precondition', 'No customer found for user');

      // Verify customer exists (helps differentiate missing vs generic INTERNAL)
      try {
        await stripe.customers.retrieve(custId);
      } catch (verifyErr: any) {
        if (verifyErr?.statusCode === 404) {
          throw new functions.https.HttpsError('failed-precondition', 'Stripe customer not found (maybe subscription not fully created yet)');
        }
        throw verifyErr;
      }
      const portal = await stripe.billingPortal.sessions.create({
        customer: custId,
        return_url: returnUrl,
      });
      return { url: portal.url };
    } catch (e: any) {
      functions.logger.error('Billing portal session failed', e);
      if (e instanceof functions.https.HttpsError) throw e;
      const msg: string = e?.message || 'Failed to create billing portal session';
      if (e?.statusCode === 404) {
        throw new functions.https.HttpsError('failed-precondition', 'Stripe resource missing while creating portal session');
      }
      if (e?.statusCode === 400 && typeof e?.message === 'string' && e.message.includes('No configuration provided')) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Stripe Billing Portal not configured in this (test) mode. Visit https://dashboard.stripe.com/test/settings/billing/portal, adjust settings if needed, and click Save to create the default configuration.'
        );
      }
      throw new functions.https.HttpsError('internal', msg);
    }
  });

// Create a one-time PaymentIntent for a booking. Expects { roomId, startAt, endAt, amountCents, currency }
// Returns { paymentIntentId, clientSecret }.
// NOTE: Booking document is NOT created here; it's created after confirmation (webhook) to avoid unpaid bookings.
export const createBookingPaymentIntent = functions.runWith({ secrets: [stripeSecret] }).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  const { roomId, startAt, endAt, amountCents, currency = 'eur', slotIndices, yyyymmdd, openHourStart } = data || {};
  if (!roomId || !startAt || !endAt || !amountCents || !Array.isArray(slotIndices) || slotIndices.length === 0 || !yyyymmdd) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing params');
  }
  // Optionally: validate that requested timeframe is still locked by this user.
  const userId = context.auth.uid;
  try {
  const stripe = getStripe();
  const intent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency,
      metadata: {
        roomId,
        startAt: String(startAt),
        endAt: String(endAt),
        userId,
        purpose: 'room_booking',
        slotIndices: slotIndices.join('-'),
        yyyymmdd: String(yyyymmdd),
        openHourStart: String(openHourStart ?? ''),
      },
      automatic_payment_methods: { enabled: true },
    });
    return { paymentIntentId: intent.id, clientSecret: intent.client_secret };
  } catch (e: any) {
    throw new functions.https.HttpsError('internal', e?.message || 'Failed to create payment intent');
  }
});

// Manual recovery/sync: find most recent subscription by metadata userId and sync Firestore.
export const syncMembershipForUser = functions
  .runWith({ secrets: [stripeSecret] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    const uid = context.auth.uid;
    try {
      const stripe = getStripe();
      const subs = await stripe.subscriptions.list({ limit: 100 });
      const match = subs.data.find(s => (s.metadata as any)?.userId === uid);
      if (!match) {
        return { found: false };
      }
      const status = match.status;
      const tier = (status === 'active' || status === 'trialing' || status === 'incomplete') ? 'premium' : 'basic';
      await db.collection('users').doc(uid).set({ membershipTier: tier }, { merge: true });
      await db.collection('memberships').doc(uid).set({
        status,
        subscriptionId: match.id,
        currentPeriodEnd: admin.firestore.Timestamp.fromMillis((match.current_period_end || 0) * 1000),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return { found: true, status };
    } catch (e: any) {
      console.error('syncMembershipForUser failed', e);
      throw new functions.https.HttpsError('internal', e?.message || 'sync failed');
    }
  });

// Allow user to cancel their subscription (default: cancel at period end)
export const cancelMembership = functions
  .runWith({ secrets: [stripeSecret] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    const immediate: boolean = !!data?.immediate;
    const uid = context.auth.uid;
    try {
      const stripe = getStripe();
      // Attempt to locate subscription by metadata userId first
      const subs = await stripe.subscriptions.list({ limit: 100 });
      const match = subs.data.find(s => (s.metadata as any)?.userId === uid && (s.status === 'active' || s.status === 'trialing' || s.status === 'incomplete'));
      if (!match) {
        throw new functions.https.HttpsError('failed-precondition', 'No active subscription for user');
      }
      let updated: Stripe.Subscription;
      if (immediate) {
        updated = await stripe.subscriptions.cancel(match.id);
      } else {
        updated = await stripe.subscriptions.update(match.id, { cancel_at_period_end: true });
      }
      await db.collection('memberships').doc(uid).set({
        status: updated.status,
        subscriptionId: updated.id,
        cancelAtPeriodEnd: updated.cancel_at_period_end || false,
        currentPeriodEnd: admin.firestore.Timestamp.fromMillis((updated.current_period_end || 0) * 1000),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      if (immediate) {
        await db.collection('users').doc(uid).set({ membershipTier: 'basic' }, { merge: true });
      }
      return { status: updated.status, immediate };
    } catch (e: any) {
      console.error('cancelMembership failed', e);
      if (e instanceof functions.https.HttpsError) throw e;
      throw new functions.https.HttpsError('internal', e?.message || 'Cancel failed');
    }
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

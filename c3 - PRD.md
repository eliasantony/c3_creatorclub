# c3 \- Product Requirements Document (DRAFT)

# **1\. Project Overview**

**Working Title:** c3 \- Creator Club

**Date:** August 2025

**Summary:**

c3 \- Creator Club is a **subscription-based mobile app** that allows freelancers, creators, and small teams to book **exclusive workspaces** (offices, studios, creator spaces) in **flexible 3-hour slots**. The app operates with **two membership tiers** (Basic & Premium), integrates **Stripe for payments**, and provides **premium community features** like in-app chat for paid members.

---

## **2\. Problem Statement**

- **Co-working memberships** are often too rigid (fixed desks, monthly only).
- **Ad-hoc rentals** (AirBnB, event spaces) are too expensive and not designed for creative work.
- **Creators need specialized facilities** (e.g. podcast booths, studio lighting) that are rarely available flexibly.

---

## **3\. Objectives**

1. Enable **flexible 3-hour workspace bookings** through a seamless app.
2. Monetize via **Premium memberships** and **paid bookings**.
3. Provide **chat & community features** to connect creators.
4. Build a **trusted creative network** around Vienna as pilot market.
5. Achieve **MVP traction with 50 paying members** and high monthly usage.

---

##

## **4\. Target Audience**

1. **Freelance Creators** (photographers, designers, videographers)
   - Need affordable but premium studio/workspace access.
   - Want short, flexible bookings.
2. **Small Teams/Startups** (2–4 people)
   - Need temporary meeting spaces.
   - Value professional locations without long-term contracts.
3. **Content Creators/Influencers**
   - Need creative backdrops & podcast/video corners.
   - Share experiences online → indirect marketing channel.

---

## **5\. Functional Requirements (MVP)**

### **User-Facing**

- **Registration & Login**
  - Email \+ password (optional SSO later).
  - User data collected: name, email, phone, profession/niche, profile picture.
- **Memberships**
  - **Basic (Free):** Can browse & book rooms (paid), no chat.
  - **Premium (Paid, \~75–100€):** Unlimited booking access (or discounted), full chat/community access.
- **Booking**
  - Time slots: **30 min increments, max 3h per booking**.
  - Booking hours: **6:00–23:00**.
  - Cancellation: possible **until 24h before slot**, refund/credit applied.
  - Confirmation via email \+ push notification.
- **Payments**
  - **Stripe Checkout** for memberships & bookings.
  - Apple Pay / Google Pay supported through Stripe.
  - No App Store billing.
- **Profile**
  - Membership status, booking history, personal data.
- **Notifications**
  - Reminders 1h before booking.
  - Updates for cancellations/changes.
  - Admin-triggered newsletters or announcements.

###

### **Chat & Community (Premium Feature)**

- **Community Rooms:**
  - Predefined groups by topic (e.g. _Photographers_, _Videographers_, _Web Developers_).
  - Open for all Premium members.
- **Private Groups:**
  - Premium users can create private groups (e.g. project teams, max. \~5–10 members).
  - Group owner can invite/remove members.
- **Moderation & Safety (Store Compliance):**
  - Users can **report messages** (required by App Store/Play Store).
  - Admins can **delete reported content**.
  - Users can **delete their own messages**.
  - Community guidelines will be displayed in onboarding & profile.
  - Push notifications for new messages.
- **Admin Moderation:**
  - Admins have tools in the console to:
    - Review reported content.
    - Remove inappropriate groups.
    - Block or warn users if necessary.

---

### **Admin-Facing (Web Console)**

- Manage rooms: name, description, availability, capacity.
- Manage bookings: view, edit, cancel.
- Manage users: view profiles, subscriptions, booking history.
- Notifications: send announcements to all or segmented users.

---

## **6\. Non-Functional Requirements**

- **Platform:** Flutter native apps (iOS & Android).
- **Backend:** Firebase (Auth, Firestore, Functions).
- **Payments:** Stripe integration (memberships, one-time bookings).
- **Calendar Integration:** Optional Google Calendar sync (future).
- **Notifications:** FCM (push), email via Firebase Extensions.
- **Scalability:** MVP goal 1000+ members, 100 bookings/day.
- **Language:** Start with **English**, prepare multi-language structure (German next).
- **Design:** Based on client CI (see provided branding). Tabs: Home, Chat, Profile.

---

## **7\. Open Questions**

1. **Memberships & Bookings**
   - Premium: unlimited booking or discounted per booking?
   - Basic: fixed booking price per slot?
   - Do Premium members still pay per booking, or is it included?
2. **Admin & Roles**
   - Will location partners (e.g. space owners) get their own admin access?
   - Centralized vs decentralized management?
3. **Future Features**
   - Group bookings on weekends?
   - QR/NFC check-in to avoid no-shows?
   - Multi-language rollout?

## **8\. Prototype-Preview**

[Place Media App Prototyp](https://www.figma.com/design/FwtSpVM1n18WhBPkmVklJJ/Place-Media-App-Prototyp?node-id=0-1&t=Fi7ZyOzOJNdJL6CQ-1)

![][image1]

##

## Tech Stack & Architecture (Finalized)

### App (Flutter)

- **State & DI:** `flutter_riverpod` (v2, with `riverpod_generator` for codegen)
- **Routing:** `go_router` (v16+, typed routes with `go_router_builder`)
- **Codegen:** `freezed` (v3+), `json_serializable`, `build_runner`
- **Dates & formatting:** `intl`
- **Local env:** `flutter_dotenv`
- **UI extras:** `cached_network_image`, `image_picker`, `url_launcher`
- **Localization:** Built-in `flutter_localizations` \+ gen-l10n

### Firebase (Core)

- **Auth:** `firebase_auth`
- **Database:** `cloud_firestore`
- **Storage:** `firebase_storage` (avatars, room photos)
- **Functions:** `cloud_functions` (TypeScript, 2nd gen)
- **Push:** `firebase_messaging` \+ `flutter_local_notifications`
- **Analytics/Crash:** `firebase_analytics`, `firebase_crashlytics`
- **Security:** Firestore Rules \+ App Check enforced

### Bookings

- **Calendar view:** `table_calendar` (lightweight, month/agenda view)
- **Slot selection:** custom 30-minute grid (max 3h, respect opening hours)
- **Reminders:** `flutter_local_notifications` for T-60 min reminders  
  (server-side fallback via Cloud Scheduler → Pub/Sub → FCM)

### Payments (Stripe)

- **Client:** `flutter_stripe` (PaymentSheet, Apple Pay / Google Pay support)
- **Server:** Cloud Functions (TypeScript)
  - Create Checkout Sessions / PaymentIntents
  - Handle Stripe webhooks for booking confirmation \+ memberships
- **Invoices:** Users can download official Stripe invoices (useful for Austrian tax declarations)
- **Compliance:** Premium \= **physical access** (unlimited/discounted bookings).  
  → Stripe only, no Apple IAP required.

### Chat (Premium)

- **Backend:** Firestore subcollections (`groups/{id}/messages/{messageId}`)
- **UI:** `flutter_chat_ui` (Flyer Chat)
- **Features:** text \+ image uploads, pagination, mentions
- **Moderation:** Cloud Functions handle reports, auto-hide on thresholds
- **Unread tracking:** `members/{uid}` subcollection with `lastReadAt`

### Deep Links & Invites

- **Preferred:** Universal Links (iOS) & App Links (Android)
- **Fallback:** `firebase_dynamic_links` (maintenance mode, OK for MVP)

---

## Firestore Data Model

- **users/{uid}** → profile info, membershipTier, stripeCustomerId
- **rooms/{roomId}** → description, capacity, facilities, photos, openHours
- **bookings/{bookingId}** → roomId, userId, startAt, endAt, priceCents, paymentIntentId
- **roomSlots/{roomId}/{YYYYMMDD}/{slotId}** → one doc per slot (prevents hotspots), locked via Functions
- **memberships/{uid}** → tier, status, currentPeriodEnd, source (stripe), planId
- **groups/{groupId}** → type, name, ownerId, createdAt
- **groups/{groupId}/members/{uid}** → role, lastReadAt, muted
- **groups/{groupId}/messages/{messageId}** → senderId, text, imageUrl, createdAt
- **reports/{reportId}** → targetType, targetRef, reporterId, reason, status
- **announcements/{id}** (optional admin broadcasts)

---

## Cloud Functions (TypeScript, v2)

1. **Create booking session**: validate slot → Stripe Checkout → return client secret/URL
2. **Stripe webhooks**: handle `checkout.session.completed`, `invoice.paid`, `subscription.updated`
3. **Slot locking & validation**: transactional hold \+ TTL auto-release
4. **Cancellation policy**: enforce 24h cutoff, handle refunds/credits
5. **Moderation**: process reports, auto-hide after N flags
6. **Push notifications**: booking reminders (via Scheduler \+ FCM), chat mentions

---

##

## Project Structure (feature-first)

lib/  
 core/ // config, router, theme, utils, shared widgets  
 data/ // models, repositories, services  
 features/  
 auth/ // SignIn, Profile  
 rooms/ // RoomList, SlotPicker  
 bookings/ // MyBookings, BookingDetail  
 membership/ // Upgrade, Manage  
 chat/ // GroupList, ChatScreen  
 notifications/ // handlers, permissions  
 app.dart  
 main.dart

- **Riverpod pattern:** Repository (Firestore/Stripe) → Provider
- Controllers/Notifiers per feature domain → StateNotifierProvider/AsyncNotifier
- Route guards: `requiresAuth`, `requiresPremium`

---

## Security & Compliance

- **Firestore Rules**:
  - Users can only modify own bookings
  - Slot docs: write only via Functions
  - Group messages: members only; self-delete allowed
  - Reports: open to authenticated users
- **Stripe**:
  - Only webhooks confirm bookings/memberships
  - Use idempotency keys for payment calls
- **App Store**:
  - Premium \= physical studio access → Stripe-only
  - Keep Stripe invoices downloadable for tax compliance

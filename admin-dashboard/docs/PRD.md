# Creator Club Admin Dashboard – Product Requirements Document

**Version:** 1.0
**Date:** September 2025
**Status:** Final

## 1. Purpose & Overview

This document outlines the product and technical requirements for the **Creator Club Admin Dashboard**. The primary purpose of this web-based application is to provide internal administrators with a comprehensive set of tools to efficiently manage all aspects of the Creator Club mobile app ecosystem. This includes user management, workspace and booking administration, payment and subscription oversight, and community moderation.

The dashboard is a critical operational tool that directly supports the business objectives of achieving high member satisfaction, ensuring platform safety, and enabling scalable growth.

---

## 2. Target Audience & Roles

The dashboard will be used by internal c3 staff. The following roles are anticipated:

- **Super Admin:** Full access to all features, including system settings and financial data. Can manage other admin accounts.
- **Community Moderator:** Limited access, focused primarily on the chat moderation queue and user management actions (muting, banning).
- **Finance Manager (Future):** Access to payment logs, subscription data, and refund processing tools.

---

## 3. Core Features (MVP)

The Minimum Viable Product (MVP) focuses on the essential day-to-day operational needs.

### 3.1. User Management

- **User Dashboard:** A central, searchable, and filterable table of all users.
  - **Search/Filter:** By name, email, and membership tier (Basic/Premium).
- **Detailed User Profile View:** A dedicated page for each user displaying:
  - Core profile information (name, email, phone, profession).
  - Current membership status and tier.
  - A complete history of their bookings (past and upcoming).
  - A direct link to their customer profile in the Stripe Dashboard.

### 3.2. Workspace (Room) Management

- **CRUD Interface:** Full Create, Read, Update, and Delete functionality for all workspaces.
- **Manageable Fields:**
  - Name & Description
  - Capacity & Photos
  - Available facilities (e.g., "Podcast Booth," "Green Screen")
  - Booking hours (e.g., 6:00–23:00)

### 3.3. Booking Management

- **Master Calendar:** A global calendar providing a visual overview of all bookings across all rooms.
  - Filterable by room and date.
- **Admin Booking Actions:**
  - Manually cancel any existing booking on behalf of a user.
  - Manually create a new booking for a specific user in an available slot.

### 3.4. Basic Community Moderation

- **Moderation Queue:** A real-time feed of user-reported chat messages, showing the message content and sender.
- **Moderation Actions:**
  - **Delete Message:** Permanently remove the reported message from the chat.
  - **Dismiss Report:** Mark the report as resolved with no action taken.

---

## 4. Post-MVP & Growth Features

These features will be prioritized after the successful launch of the MVP.

### 4.1. Financial & Payment Tools

- **Transaction Log:** A searchable log of all Stripe transactions (memberships and bookings).
- **Refund Processing:** A secure interface to issue full or partial refunds via a dedicated Stripe Cloud Function.

### 4.2. Advanced Moderation & Community

- **Advanced User Actions:**
  - **Mute User:** Temporarily prevent a user from sending messages for a defined period.
  - **Ban User:** Permanently suspend a user's account.
- **Chat Room Management:** Ability for admins to create, rename, or delete the predefined community chat rooms.

### 4.3. Analytics & Reporting

- **KPI Dashboard:** A visual dashboard tracking key metrics:
  - New user sign-ups over time.
  - Total number of active Premium members.
  - Daily, weekly, and monthly booking volume.
- **Booking Trends:** Reports to identify the most popular rooms and peak booking times.

### 4.4. System Tools

- **Announcements:** A simple form to compose and send push notifications to all users or segment by membership tier.

---

## 5. Technical Stack & Architecture

- **Frontend:** **Next.js 15+** with **TypeScript**.
- **UI / State Management:**
  - **UI Kit:** **shadcn/ui** for its accessible and composable components.
  - **Data Tables:** **TanStack Table** for powerful, headless table logic.
  - **Data Fetching:** **TanStack Query** for server-state management.
  - **Charts:** **Recharts** for data visualization.
- **Backend:** The existing **Firebase** project will be leveraged.
  - **Authentication:** Firebase Auth with email/password and custom claims for RBAC.
  - **Database:** Direct, secure interaction with **Cloud Firestore**.
  - **File Management:** **Firebase Storage** for room photos.
  - **Serverless Logic:** **Cloud Functions (TypeScript)** to handle all sensitive actions.
- **Payments:** Integration with **Stripe** via server-side Cloud Functions.

---

## 6. Security & Guardrails (Non-Negotiable)

- **Role-Based Access Control (RBAC):** All admin access is gated by Firebase Authentication. An admin's role (`super_admin`, `moderator`) will be stored in their Firebase custom claims. The frontend UI and backend Functions must validate these roles before permitting any action.
- **Cloud Functions for Mutations:** All sensitive, state-changing actions (e.g., issuing refunds, banning users, deleting content) **must** be executed through a dedicated Cloud Function. Direct client-side writes for these operations are strictly forbidden.
- **Audit Logging:** Every destructive or significant admin action (e.g., booking cancellation, user ban, message deletion, refund issued) **must** write a record to a dedicated `admin_audit_logs` collection in Firestore. Each log should contain the timestamp, the admin's UID, the action performed, and the target document ID.

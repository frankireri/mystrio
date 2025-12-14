# Mystrio Admin Dashboard - Feature Roadmap

This document outlines the current and planned features for the Mystrio Admin Dashboard.

---

## Tier 1: Core Management (Implemented)

These features provide the essential tools for managing the application and its users.

### 1. Secure Admin Login
- **Status:** Implemented
- **Description:** A dedicated login page that authenticates users and verifies their `is_admin` status before granting access.

### 2. User Management Table
- **Status:** Implemented
- **Description:** A searchable and sortable table listing all registered users.
- **Columns:** User ID, Username, Email, Premium Subscription Expiry (`premium_until`), and Admin status.

### 3. Full User CRUD (Create, Read, Update, Delete)
- **Status:** Implemented
- **Description:**
    - **Read:** The user table provides the read functionality.
    - **Update:** An "Edit" button for each user that opens a dialog to modify their username, email, and `premium_until` date. This allows for manual granting/revoking of premium access.
    - **Delete:** A "Delete" button for each user (with a confirmation dialog) to permanently remove them from the database.

### 4. Dashboard Stats Overview
- **Status:** Backend Implemented, Frontend Pending
- **Description:** The dashboard will show key metrics at a glance.
    - Total number of users.
    - Total number of active premium subscribers.
    - A list of the most recent signups.

---

## Tier 2: Content & Activity Monitoring (Planned)

These features provide insight into application usage and are crucial for community safety.

### 1. Content Moderation
- **Status:** Planned
- **Description:** A new section to view, search, and delete user-generated content to handle spam or inappropriate posts.
    - **Question & Answer Feed:** A live feed of all questions and answers being submitted.
    - **Quiz Moderation:** A view to inspect the content of user-created quizzes.

### 2. User Activity Insights
- **Status:** Planned
- **Description:** When viewing a user's details, expand the view to include a summary of their activity, such as:
    - Date of last login.
    - Total questions asked.
    - Total answers given.
    - Number of quizzes created.

---

## Tier 3: Advanced & Proactive Features (Planned)

These features are for growth, advanced support, and security.

### 1. Subscription & Payment Management
- **Status:** Planned
- **Description:** A dedicated page to view a log of all successful and failed payments received from Kopo Kopo.
    - Searchable by user email, phone number, or transaction ID.
    - Ability to manually mark a transaction for review or refund.

### 2. In-App Announcement System
- **Status:** Planned
- **Description:** A form where an admin can compose a message and send it as a push notification or in-app alert to all users, or a targeted subset (e.g., only premium users).

### 3. Impersonation Mode ("Log in as User")
- **Status:** Planned
- **Description:** A secure feature allowing an admin to temporarily log in as a specific user to debug issues from their perspective. All impersonation actions would be strictly logged for security auditing.

### 4. Application Health Dashboard
- **Status:** Planned
- **Description:** A panel showing real-time health metrics of the application.
    - Live CPU and Memory usage of the API process from `pm2`.
    - Status of the database connection.
    - A log of the most recent API errors (5xx status codes).

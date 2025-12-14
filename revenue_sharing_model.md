# Mystrio Creator Program - Revenue Sharing Model

This document outlines a proposed revenue-sharing model to incentivize user engagement and content creation by allowing users to earn a percentage of the application's ad revenue.

---

## 1. Core Concept

The fundamental idea is to reward users whose content (profiles, quizzes) generates traffic and, therefore, ad impressions. This transforms users into active partners in the app's growth. We will use a "Creator Points" system as an abstraction layer between user actions and monetary value.

---

## 2. The "Creator Points" System

Instead of calculating micro-payments in real-time, users will earn "Creator Points" for valuable actions. These points are accumulated over a monthly cycle.

### How Points are Earned
The primary method for earning points is by driving external traffic to the app.

- **Quiz/Profile Page Views (Primary):** A user earns **1 point** every time their unique quiz link or profile link is visited by another person, resulting in a page view with an ad impression.
- **Content Creation (Secondary):** A user earns a small, one-time bonus of **10 points** for creating and publishing a new quiz.
- **Engagement (Secondary):** A user earns **2 points** each time another user successfully completes their quiz.

*Note: These values can be tuned to balance incentives.*

---

## 3. How Points are Converted to Money

At the end of each calendar month, a calculation is performed to determine the monetary value of each point.

1.  **Determine Total Ad Revenue:** Get the total ad revenue from AdSense for the month (e.g., `$1,000`).
2.  **Determine Creator Payout Pool:** A fixed percentage of the total revenue is allocated to the creator pool. (e.g., **40%** -> `$400`).
3.  **Calculate Total Points:** The system queries the database for the total number of points earned by *all* users during that month (e.g., `1,000,000` points).
4.  **Calculate Value Per Point:** The value of a single point is calculated. (e.g., `$400 / 1,000,000 points = $0.0004` per point).
5.  **Distribute Earnings:** Each user's monthly point total is multiplied by the value per point to determine their earnings for that month.

---

## 4. Payout System

1.  **M-Pesa B2C Integration:** To send payments to users in Kenya, the backend will integrate with Safaricom's M-Pesa B2C (Business-to-Customer) API. This is a separate integration from the one used for receiving subscription payments.
2.  **Minimum Payout Threshold:** Users must accumulate a minimum balance (e.g., **100 KES**) before they can request a payout. This minimizes transaction fees and administrative overhead.
3.  **Admin-Approved Payouts:**
    - Users request a payout from their "Earnings" dashboard in the app.
    - The request appears in the Admin Dashboard for manual review and approval.
    - An admin clicks "Approve" to trigger the M-Pesa B2C API call, sending the funds to the user. This is a critical anti-fraud measure.

---

## 5. Strategic Considerations & Improvements

### Transparency & User Experience
- **Creator Hub:** A dedicated "Earnings" page in the app is essential. It must clearly show:
    - Current points balance.
    - Estimated earnings for the current month.
    - The value-per-point from the previous month.
    - A detailed history of points earned and payouts received.
- **Clear Communication:** The rules for earning points must be simple and clearly explained to all users.

### Gamification
- **Leaderboards:** Public weekly/monthly leaderboards showing top point earners.
- **Badges & Milestones:** Digital badges for achievements like "First Payout," "10,000 Views Club," or "Top Creator of the Week."
- **Challenges:** Limited-time events like "Double Points Weekend" to drive spikes in engagement.

### Anti-Fraud & Abuse Prevention
- **Bot Detection:** The API must implement IP address rate-limiting, user-agent analysis, and other techniques to identify and discard fraudulent, non-human traffic.
- **Manual Review:** The top 5-10% of earners each month must be manually reviewed for suspicious activity before payouts are approved.
- **Clear Terms of Service:** The ToS must explicitly forbid paying for traffic, using bots, or any other means of artificially inflating view counts. Violations should result in a permanent ban and forfeiture of earnings.

### Tiered System
- **Reward Power Users:** Consider implementing a tiered system where the revenue share percentage increases for top creators.
    - **Standard Creator:** 40% revenue share.
    - **Power Creator (Top 10%):** 50% revenue share.
This provides a strong incentive for users to remain engaged and invested in the platform's success.

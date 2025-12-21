# Remaining App Development Tasks

This document tracks the completion of the remaining features and backend integrations.

---

### Phase 1: Complete Anonymous Question Flow (Frontend)

- [x] **Distinguish Sent vs. Received Questions:** Modify `InboxPage` to differentiate between questions sent *to* the user and questions sent *from* the user.

---

### Phase 2: Core Backend Integration (Questions & Quizzes)

- [x] **Backend for User-Created Questions:** Integrate `QuestionProvider` with the backend for creating and answering styled questions.
- [x] **Backend for User-Created Quizzes:** Integrate `QuizProvider` with the backend for full quiz lifecycle management.
- [x] **Backend for Quiz Leaderboards:** Integrate `QuizProvider` with the backend for saving and fetching leaderboard scores.

---

### Phase 3: Refine UI/UX & Remaining Features

- [x] **Dynamic Share Links:** Replace the hardcoded `mystrio.app` base URL with a configurable one.
- [x] **User Activity Insights:** Verify and complete the admin dashboard's user activity display.
- [x] **Profile Image Upload:** Implement backend API and frontend logic for user profile image uploads.
- [x] **Quiz Creation UI/UX:** Add UI for quiz titles, descriptions, and question deletion in `CreateQuizPage`.

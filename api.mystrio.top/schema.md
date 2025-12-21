# Database Schema for Mystrio API

This document outlines the structure of the MySQL/MariaDB database used by the Mystrio backend API.

---

## Table: `users`

Stores user authentication and profile information.

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL, -- Hashed password using bcrypt
  chosen_question_text TEXT, -- User's chosen default question text
  chosen_question_style_id VARCHAR(255), -- ID for the chosen question card style
  profile_image_path VARCHAR(255), -- Path to the user's profile image
  premium_until TIMESTAMP NULL DEFAULT NULL, -- Timestamp when premium access expires
  is_admin BOOLEAN NOT NULL DEFAULT FALSE, -- New: Flag to identify admin users
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## Table: `questions`

Stores questions asked by users and their corresponding answers.

```sql
CREATE TABLE questions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  recipient_user_id INT NOT NULL,
  question_text TEXT NOT NULL,
  answer_text TEXT,
  is_from_ai BOOLEAN DEFAULT FALSE,
  hints TEXT,
  sender_ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## Table: `quizzes`

Stores user-created quizzes.

```sql
CREATE TABLE quizzes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  selectedThemeName VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## Table: `quiz_questions`

Stores the individual questions for a specific quiz.

```sql
CREATE TABLE quiz_questions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  quiz_id INT NOT NULL,
  question_text TEXT NOT NULL,
  correct_option_index INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);
```

---

## Table: `quiz_options`

Stores the answer options for a specific quiz question.

```sql
CREATE TABLE quiz_options (
  id INT AUTO_INCREMENT PRIMARY KEY,
  question_id INT NOT NULL,
  option_text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
);
```

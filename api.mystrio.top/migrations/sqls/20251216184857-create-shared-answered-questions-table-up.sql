CREATE TABLE shared_answered_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    short_code VARCHAR(10) NOT NULL UNIQUE,
    answered_question_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (answered_question_id) REFERENCES answered_questions(id) ON DELETE CASCADE
);
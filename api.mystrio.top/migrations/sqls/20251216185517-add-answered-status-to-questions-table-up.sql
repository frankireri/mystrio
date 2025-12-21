ALTER TABLE questions
ADD COLUMN is_answered BOOLEAN DEFAULT FALSE,
ADD COLUMN answered_question_id INT DEFAULT NULL,
ADD CONSTRAINT fk_answered_question
FOREIGN KEY (answered_question_id) REFERENCES answered_questions(id) ON DELETE SET NULL;

-- Migrate existing answers from 'questions' to 'answered_questions' and update 'questions' table
INSERT INTO answered_questions (user_id, original_question_id, question_text, answer_text, answered_at)
SELECT
    q.user_id,
    q.id,
    q.question_text,
    q.answer_text,
    q.updated_at
FROM questions q
WHERE q.answer_text IS NOT NULL;

-- Update original questions with the new answered_question_id
UPDATE questions q
JOIN answered_questions aq ON q.id = aq.original_question_id
SET
    q.answered_question_id = aq.id,
    q.is_answered = TRUE;

-- Remove answer_text from questions table
ALTER TABLE questions
DROP COLUMN answer_text;
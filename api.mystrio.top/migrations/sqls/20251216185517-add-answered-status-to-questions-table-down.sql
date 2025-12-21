ALTER TABLE questions
DROP FOREIGN KEY fk_answered_question;

ALTER TABLE questions
DROP COLUMN is_answered,
DROP COLUMN answered_question_id;

-- Re-add answer_text column (if needed, this depends on whether old data should be restored)
-- For now, we will just re-add the column. Restoring data would be complex.
ALTER TABLE questions
ADD COLUMN answer_text TEXT;
const express = require('express');
const router = express.Router();
const db = require('../database');
const authenticateToken = require('../middleware/authenticateToken');

// GET all quizzes for the logged-in user (and public/dummy quizzes)
router.get('/', authenticateToken, async (req, res) => {
    try {
        const [quizzes] = await db.query(
            `SELECT 
                q.id, 
                q.user_id, 
                q.title, 
                q.description, 
                q.selectedThemeName, 
                u.username as author 
             FROM quizzes q
             JOIN users u ON q.user_id = u.id
             WHERE q.user_id = ? OR q.user_id = 1`,
            [req.user.userId]
        );

        for (const quiz of quizzes) {
            const [questions] = await db.query(
                `SELECT id, question_text, correct_option_index 
                 FROM quiz_questions 
                 WHERE quiz_id = ?`,
                [quiz.id]
            );

            for (const question of questions) {
                const [options] = await db.query(
                    `SELECT option_text 
                     FROM quiz_options 
                     WHERE question_id = ?`,
                    [question.id]
                );
                question.options = options.map(opt => opt.option_text);
            }
            quiz.questions = questions;
        }

        res.json({ success: true, data: quizzes });
    } catch (error) {
        console.error('Failed to fetch quizzes:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch quizzes.' });
    }
});

// Create a new quiz
router.post('/', authenticateToken, async (req, res) => {
    const { title, description, selectedThemeName, questions } = req.body;
    const userId = req.user.userId;

    if (!title || !questions || !Array.isArray(questions)) {
        return res.status(400).json({ success: false, message: 'Quiz title and questions are required.' });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const [quizResult] = await connection.query(
            'INSERT INTO quizzes (user_id, title, description, selectedThemeName) VALUES (?, ?, ?, ?)',
            [userId, title, description || '', selectedThemeName || 'Friendship']
        );
        const quizId = quizResult.insertId;

        if (questions.length > 0) {
            for (const q of questions) {
                const [questionResult] = await connection.query(
                    'INSERT INTO quiz_questions (quiz_id, question_text, correct_option_index) VALUES (?, ?, ?)',
                    [quizId, q.question_text, q.correct_option_index]
                );
                const questionId = questionResult.insertId;

                if (q.options && q.options.length > 0) {
                    const optionsData = q.options.map(optionText => [questionId, optionText]);
                    await connection.query(
                        'INSERT INTO quiz_options (question_id, option_text) VALUES ?',
                        [optionsData]
                    );
                }
            }
        }

        await connection.commit();
        res.status(201).json({ success: true, message: 'Quiz created successfully!', data: { quizId } });
    } catch (error) {
        await connection.rollback();
        console.error('CRITICAL ERROR creating quiz:', error);
        res.status(500).json({ success: false, message: 'Failed to create quiz.', error: error.message });
    } finally {
        connection.release();
    }
});

// UPDATE a quiz
router.put('/:quizId', authenticateToken, async (req, res) => {
    const { quizId } = req.params;
    const { title, description, questions } = req.body;
    const userId = req.user.userId;

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // Verify user owns the quiz
        const [quizzes] = await connection.query('SELECT user_id FROM quizzes WHERE id = ?', [quizId]);
        if (quizzes.length === 0) {
            throw new Error('Quiz not found.');
        }
        if (quizzes[0].user_id !== userId) {
            throw new Error('User not authorized to update this quiz.');
        }

        // Update quiz title and description
        await connection.query('UPDATE quizzes SET title = ?, description = ? WHERE id = ?', [title, description, quizId]);

        // Delete old questions and options
        const [existingQuestions] = await connection.query('SELECT id FROM quiz_questions WHERE quiz_id = ?', [quizId]);
        if (existingQuestions.length > 0) {
            const questionIds = existingQuestions.map(q => q.id);
            await connection.query('DELETE FROM quiz_options WHERE question_id IN (?)', [questionIds]);
            await connection.query('DELETE FROM quiz_questions WHERE quiz_id = ?', [quizId]);
        }

        // Insert new questions and options
        if (questions && questions.length > 0) {
            for (const q of questions) {
                const [questionResult] = await connection.query(
                    'INSERT INTO quiz_questions (quiz_id, question_text, correct_option_index) VALUES (?, ?, ?)',
                    [quizId, q.question_text, q.correct_option_index]
                );
                const questionId = questionResult.insertId;

                if (q.options && q.options.length > 0) {
                    const optionsData = q.options.map(optionText => [questionId, optionText]);
                    await connection.query(
                        'INSERT INTO quiz_options (question_id, option_text) VALUES ?',
                        [optionsData]
                    );
                }
            }
        }

        await connection.commit();
        res.json({ success: true, message: 'Quiz updated successfully.' });
    } catch (error) {
        await connection.rollback();
        console.error('Failed to update quiz:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        connection.release();
    }
});


// DELETE a quiz
router.delete('/:quizId', authenticateToken, async (req, res) => {
    const { quizId } = req.params;
    const userId = req.user.userId;

    try {
        const [quizzes] = await db.query('SELECT user_id FROM quizzes WHERE id = ?', [quizId]);

        if (quizzes.length === 0) {
            return res.status(404).json({ success: false, message: 'Quiz not found.' });
        }

        if (quizzes[0].user_id !== userId && userId !== 1) { // Allow admin (user 1) to delete
            return res.status(403).json({ success: false, message: 'You are not authorized to delete this quiz.' });
        }

        // ON DELETE CASCADE will handle associated questions and options
        await db.query('DELETE FROM quizzes WHERE id = ?', [quizId]);

        res.json({ success: true, message: 'Quiz deleted successfully.' });
    } catch (error) {
        console.error('Failed to delete quiz:', error);
        res.status(500).json({ success: false, message: 'Failed to delete quiz.' });
    }
});

module.exports = router;

const mysql = require('mysql2/promise');
const { toCamelCase } = require('../utils/helpers');

const dbConfig = require('../config/db');

const getQuestionsByUserId = async (userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            `SELECT
                q.id,
                q.question_text,
                q.is_from_ai,
                q.hints,
                q.created_at,
                q.updated_at,
                q.is_answered,
                aq.answer_text,
                aq.answered_at
            FROM questions q
            LEFT JOIN answered_questions aq ON q.answered_question_id = aq.id
            WHERE q.user_id = ? ORDER BY q.created_at DESC`,
            [userId]
        );
        const questions = rows.map(row => ({
            ...toCamelCase(row),
            hints: row.hints ? JSON.parse(row.hints) : {},
        }));
        return questions;
    } catch (error) {
        throw new Error('Failed to retrieve questions.');
    } finally {
        if (connection) await connection.end();
    }
};

const createQuestion = async (userId, questionText, isFromAI, hints) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const sql = 'INSERT INTO questions (user_id, question_text, is_from_ai, hints) VALUES (?, ?, ?, ?)';
        const [result] = await connection.execute(sql, [userId, questionText, isFromAI, JSON.stringify(hints)]);

        return toCamelCase({ // Convert response to camelCase
            id: result.insertId,
            user_id: userId,
            question_text: questionText,
            is_from_ai: isFromAI,
            hints: hints,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (error) {
        throw new Error('Failed to create question.');
    } finally {
        if (connection) await connection.end();
    }
};

const updateQuestion = async (questionId, userId, questionData) => {
    const { answerText } = questionData; // Only answerText is relevant for this update
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // Get original question details
        const [originalQuestionRows] = await connection.execute('SELECT user_id, question_text FROM questions WHERE id = ?', [questionId]);
        if (originalQuestionRows.length === 0) {
            throw new Error('Original question not found.');
        }
        if (originalQuestionRows[0].user_id !== userId) {
            throw new Error('You can only answer questions sent to you.');
        }

        const originalQuestion = originalQuestionRows[0];

        // Insert into answered_questions table
        const [answeredResult] = await connection.execute(
            'INSERT INTO answered_questions (user_id, original_question_id, question_text, answer_text) VALUES (?, ?, ?, ?)',
            [userId, questionId, originalQuestion.question_text, answerText]
        );

        const newAnsweredQuestionId = answeredResult.insertId;

        // Update original question to mark as answered and link to answered_questions table
        const [updateQuestionResult] = await connection.execute(
            'UPDATE questions SET answered_question_id = ?, is_answered = TRUE WHERE id = ?',
            [newAnsweredQuestionId, questionId]
        );

        if (updateQuestionResult.affectedRows === 0) {
            throw new Error('Failed to link original question to answered question.');
        }

        // Fetch the newly answered question to return
        const [returnedAnsweredQuestionRows] = await connection.execute(
            'SELECT id, user_id, original_question_id, question_text, answer_text, answered_at FROM answered_questions WHERE id = ?',
            [newAnsweredQuestionId]
        );
        return toCamelCase(returnedAnsweredQuestionRows[0]);

    } catch (error) {
        throw error;
    } finally {
        if (connection) await connection.end();
    }
};

const deleteQuestion = async (questionId, userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const [questionRows] = await connection.execute('SELECT user_id FROM questions WHERE id = ?', [questionId]);
        if (questionRows.length === 0) {
            throw new Error('Question not found.');
        }
        if (questionRows[0].user_id !== userId) {
            throw new Error('You can only delete your own questions.');
        }

        const [result] = await connection.execute('DELETE FROM questions WHERE id = ?', [questionId]);
        if (result.affectedRows === 0) {
            throw new Error('Question not found.');
        }
        return { message: 'Question deleted successfully.' };
    } catch (error) {
        throw error;
    } finally {
        if (connection) await connection.end();
    }
};

const submitAnonymousQuestion = async (recipientUserId, questionText, senderIpAddress) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const [userRows] = await connection.execute('SELECT id FROM users WHERE id = ?', [recipientUserId]);
        if (userRows.length === 0) {
            throw new Error('Recipient user not found.');
        }

        // Generate a simple hint based on the IP address (e.g., first two octets)
        const senderHint = senderIpAddress ? `From IP: ${senderIpAddress.split('.').slice(0, 2).join('.')}.XXX.XXX` : 'No IP hint available';

        const sql = `INSERT INTO questions (user_id, recipient_user_id, question_text, sender_ip_address, sender_hint) VALUES (?, ?, ?, ?, ?)`;
        const [result] = await connection.execute(sql, [null, recipientUserId, questionText, senderIpAddress, senderHint]);

        return { success: true, message: 'Anonymous question submitted.', questionId: result.insertId };
    } catch (error) {
        throw new Error('Failed to submit anonymous question.');
    } finally {
        if (connection) await connection.end();
    }
};

const getQuestionSenderHint = async (questionId, userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT sender_hint, recipient_user_id FROM questions WHERE id = ?', [questionId]);

        if (rows.length === 0) {
            throw new Error('Question not found.');
        }

        if (rows[0].recipient_user_id !== userId) {
             throw new Error('You can only retrieve hints for questions sent to you.');
        }

        return rows[0].sender_hint;
    } catch (error) {
        throw error;
    } finally {
        if (connection) await connection.end();
    }
};

const getAnonymousQuestions = async (userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [received] = await connection.execute(
            'SELECT id, question_text, created_at FROM questions WHERE recipient_user_id = ? AND user_id IS NULL ORDER BY created_at DESC',
            [userId]
        );
        const [sent] = await connection.execute(
            'SELECT q.id, q.question_text, q.created_at, u.username as recipient_username FROM questions q JOIN users u ON q.recipient_user_id = u.id WHERE q.user_id = ? AND q.recipient_user_id IS NOT NULL ORDER BY q.created_at DESC',
            [userId]
        );
        return { received: received.map(toCamelCase), sent: sent.map(toCamelCase) };
    } catch (error) {
        throw new Error('Failed to retrieve anonymous questions.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    getQuestionsByUserId,
    createQuestion,
    updateQuestion,
    deleteQuestion,
    submitAnonymousQuestion,
    getQuestionSenderHint,
    getAnonymousQuestions
};

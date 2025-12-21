const mysql = require('mysql2/promise');
const { toCamelCase, formatUserForResponse } = require('../utils/helpers');

const dbConfig = require('../config/db');

const getAdminStats = async () => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [totalUsers] = await connection.execute('SELECT COUNT(*) as count FROM users');
        const [premiumUsers] = await connection.execute('SELECT COUNT(*) as count FROM users WHERE premium_until > NOW()');
        const [recentSignups] = await connection.execute('SELECT id, username, email, created_at FROM users ORDER BY created_at DESC LIMIT 5');

        return {
            totalUsers: totalUsers[0].count,
            premiumUsers: premiumUsers[0].count,
            recentSignups: toCamelCase(recentSignups),
        };
    } catch (error) {
        throw new Error('Failed to retrieve admin stats.');
    } finally {
        if (connection) await connection.end();
    }
};

const getAllUsersAdmin = async () => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT id, username, email, created_at, premium_until, is_admin FROM users ORDER BY id');
        return rows.map(formatUserForResponse);
    } catch (error) {
        throw new Error('Failed to retrieve users.');
    } finally {
        if (connection) await connection.end();
    }
};

const getUserActivity = async (userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const [questionsReceivedResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM questions WHERE recipient_user_id = ?',
            [userId]
        );
        const totalQuestionsReceived = questionsReceivedResult[0].count;

        const [answersGivenResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM questions WHERE user_id = ? AND answer_text IS NOT NULL',
            [userId]
        );
        const totalAnswersGiven = answersGivenResult[0].count;

        const [quizzesCreatedResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM quizzes WHERE user_id = ?',
            [userId]
        );
        const totalQuizzesCreated = quizzesCreatedResult[0].count;

        return authService.toCamelCase({
            totalQuestionsAsked: totalQuestionsReceived,
            totalAnswersGiven,
            totalQuizzesCreated,
        });
    } catch (error) {
        if (error.code === 'ER_NO_SUCH_TABLE') {
            throw new Error("Database table 'quizzes' not found. Please create it.");
        }
        throw new Error('Failed to retrieve user activity.');
    } finally {
        if (connection) await connection.end();
    }
};

const updateUserAdmin = async (userId, userData) => {
    const { username, email, premiumUntil, isAdmin } = userData;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const fields = [];
        const values = [];

        if (username !== undefined) { fields.push('username = ?'); values.push(username); }
        if (email !== undefined) { fields.push('email = ?'); values.push(email); }
        if (premiumUntil !== undefined) { fields.push('premium_until = ?'); values.push(premiumUntil); }
        if (isAdmin !== undefined) { fields.push('is_admin = ?'); values.push(isAdmin); }

        if (fields.length === 0) {
            throw new Error('No fields provided for update.');
        }

        const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
        values.push(userId);

        const [result] = await connection.execute(sql, values);

        if (result.affectedRows === 0) {
            throw new Error('User not found.');
        }

        return { success: true, message: 'User updated successfully.' };
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            throw new Error('This email address is already in use.');
        }
        throw new Error('Failed to update user.');
    } finally {
        if (connection) await connection.end();
    }
};

const deleteUserAdmin = async (userId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM users WHERE id = ?', [userId]);
        if (result.affectedRows === 0) {
            throw new Error('User not found.');
        }
        return { message: 'User deleted successfully.' };
    } catch (error) {
        throw new Error('Failed to delete user.');
    } finally {
        if (connection) await connection.end();
    }
};

const getAllQuestionsAdmin = async () => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(`
            SELECT
              q.id,
              q.question_text,
              q.answer_text,
              q.is_from_ai,
              q.hints,
              q.created_at,
              u.username,
              u.email,
              ru.username AS recipientUsername,
              ru.email AS recipientEmail
            FROM questions q
            LEFT JOIN users u ON q.user_id = u.id
            JOIN users ru ON q.recipient_user_id = ru.id
            ORDER BY q.created_at DESC
        `);

        const questions = rows.map(row => ({
            ...toCamelCase(row),
            ownerUsername: row.username,
            ownerEmail: row.email,
            recipientUsername: row.recipientUsername,
            recipientEmail: row.recipientEmail,
        }));
        return questions;
    } catch (error) {
        throw new Error('Failed to retrieve questions for moderation.');
    } finally {
        if (connection) await connection.end();
    }
};

const deleteQuestionAdmin = async (questionId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM questions WHERE id = ?', [questionId]);
        if (result.affectedRows === 0) {
            throw new Error('Question not found.');
        }
        return { message: 'Question deleted successfully.' };
    } catch (error) {
        throw new Error('Failed to delete question.');
    } finally {
        if (connection) await connection.end();
    }
};

const getAllQuizzesAdmin = async () => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(`
            SELECT
              qz.id,
              qz.title,
              qz.description,
              qz.created_at,
              u.username,
              u.email
            FROM quizzes qz
            LEFT JOIN users u ON qz.user_id = u.id
            ORDER BY qz.created_at DESC
        `);

        const quizzes = rows.map(row => ({
            ...toCamelCase(row),
            ownerUsername: row.username,
            ownerEmail: row.email,
        }));
        return quizzes;
    } catch (error) {
        if (error.code === 'ER_NO_SUCH_TABLE') {
            throw new Error("Database table 'quizzes' not found. Please create it.");
        }
        throw new Error('Failed to retrieve quizzes for moderation.');
    } finally {
        if (connection) await connection.end();
    }
};

const deleteQuizAdmin = async (quizId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM quizzes WHERE id = ?', [quizId]);
        if (result.affectedRows === 0) {
            throw new Error('Quiz not found.');
        }
        return { message: 'Quiz deleted successfully.' };
    } catch (error) {
        if (error.code === 'ER_NO_SUCH_TABLE') {
            throw new Error("Database table 'quizzes' not found. Please create it.");
        }
        throw new Error('Failed to delete quiz.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    getAdminStats,
    getAllUsersAdmin,
    getUserActivity,
    updateUserAdmin,
    deleteUserAdmin,
    getAllQuestionsAdmin,
    deleteQuestionAdmin,
    getAllQuizzesAdmin,
    deleteQuizAdmin
};

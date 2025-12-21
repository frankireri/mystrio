const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');
const dbConfig = require('../config/db');

// Function to generate a short, unique alphanumeric code
const generateShortCode = () => {
    return uuidv4().substring(0, 8); // 8 character code
};

const createShareLink = async (answeredQuestionId) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        let shortCode;
        let isUnique = false;

        // Ensure the generated short code is unique
        while (!isUnique) {
            shortCode = generateShortCode();
            const [rows] = await connection.execute('SELECT id FROM shared_answered_questions WHERE short_code = ?', [shortCode]);
            if (rows.length === 0) {
                isUnique = true;
            }
        }

        const [result] = await connection.execute(
            'INSERT INTO shared_answered_questions (short_code, answered_question_id) VALUES (?, ?)',
            [shortCode, answeredQuestionId]
        );

        if (result.affectedRows === 0) {
            throw new Error('Failed to create share link.');
        }

        return shortCode;

    } catch (error) {
        throw new Error('Failed to create share link.');
    } finally {
        if (connection) await connection.end();
    }
};

const getAnsweredQuestionIdByShortCode = async (shortCode) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT answered_question_id FROM shared_answered_questions WHERE short_code = ?',
            [shortCode]
        );

        if (rows.length === 0) {
            throw new Error('Share link not found.');
        }

        return rows[0].answered_question_id;

    } catch (error) {
        throw new Error('Failed to retrieve answered question ID.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    createShareLink,
    getAnsweredQuestionIdByShortCode
};

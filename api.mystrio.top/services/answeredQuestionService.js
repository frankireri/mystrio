const mysql = require('mysql2/promise');
const { toCamelCase } = require('../utils/helpers');
const dbConfig = require('../config/db');

const getAnsweredQuestionById = async (id) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT id, user_id, original_question_id, question_text, answer_text, answered_at FROM answered_questions WHERE id = ?',
            [id]
        );

        if (rows.length === 0) {
            throw new Error('Answered question not found.');
        }

        return toCamelCase(rows[0]);

    } catch (error) {
        throw new Error('Failed to retrieve answered question.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    getAnsweredQuestionById
};

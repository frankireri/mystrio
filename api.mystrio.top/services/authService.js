const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const dbConfig = require('../config/db');
const { JWT_SECRET, saltRounds } = require('../config/constants');
const { toCamelCase, formatUserForResponse } = require('../utils/helpers');

const signup = async (username, email, password, chosenQuestionText, chosenQuestionStyleId, profileImagePath) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        const sql = `INSERT INTO users (username, email, password, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin) VALUES (?, ?, ?, ?, ?, ?, NULL, FALSE)`;
        const [result] = await connection.execute(sql, [username, email, hashedPassword, chosenQuestionText, chosenQuestionStyleId, profileImagePath]);

        const newUser = {
            id: result.insertId,
            username,
            email,
            chosen_question_text: chosenQuestionText,
            chosen_question_style_id: chosenQuestionStyleId,
            profile_image_path: profileImagePath,
            premium_until: null,
            is_admin: false,
        };

        const tokenPayload = { id: newUser.id, username: newUser.username };
        const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1d' });

        return { token, user: formatUserForResponse(newUser) };
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            throw new Error('This email address is already in use.');
        }
        throw new Error('Failed to create user.');
    } finally {
        if (connection) await connection.end();
    }
};

const login = async (email, password) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const sql = 'SELECT id, username, email, password, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users WHERE email = ?';
        const [rows] = await connection.execute(sql, [email]);

        if (rows.length === 0) {
            throw new Error('Invalid credentials.');
        }

        const user = rows[0];
        const match = await bcrypt.compare(password, user.password);

        if (match) {
            const tokenPayload = { id: user.id, username: user.username };
            const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1d' });
            return { token, user: formatUserForResponse(user) };
        } else {
            throw new Error('Invalid credentials.');
        }
    } catch (error) {
        throw new Error('Login failed.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    signup,
    login,
    toCamelCase,
    formatUserForResponse // Exporting for other services if needed
};

const mysql = require('mysql2/promise');
const { toCamelCase, formatUserForResponse } = require('../utils/helpers');

const dbConfig = require('../config/db');

const getAllUsers = async (page = 1, limit = 10) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const offset = (page - 1) * limit;

        const [totalUsersResult] = await connection.execute('SELECT COUNT(*) as count FROM users');
        const totalUsers = totalUsersResult[0].count;

        const [rows] = await connection.execute(
            'SELECT id, username, email, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users ORDER BY id LIMIT ? OFFSET ?',
            [limit, offset]
        );
        
        return {
            data: rows.map(formatUserForResponse),
            metadata: {
                total: totalUsers,
                page: page,
                limit: limit,
                totalPages: Math.ceil(totalUsers / limit)
            }
        };
    } catch (error) {
        throw new Error('Failed to retrieve users.');
    } finally {
        if (connection) await connection.end();
    }
};

const deleteUser = async (id) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM users WHERE id = ?', [id]);
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

const updateUser = async (id, userData) => {
    const { username, email, chosenQuestionText, chosenQuestionStyleId, profileImagePath, premiumUntil } = userData;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const fields = [];
        const values = [];

        if (username !== undefined) { fields.push('username = ?'); values.push(username); }
        if (email !== undefined) { fields.push('email = ?'); values.push(email); }
        if (chosenQuestionText !== undefined) { fields.push('chosen_question_text = ?'); values.push(chosenQuestionText); }
        if (chosenQuestionStyleId !== undefined) { fields.push('chosen_question_style_id = ?'); values.push(chosenQuestionStyleId); }
        if (profileImagePath !== undefined) { fields.push('profile_image_path = ?'); values.push(profileImagePath); }
        if (premiumUntil !== undefined) { fields.push('premium_until = ?'); values.push(premiumUntil); }

        if (fields.length === 0) {
            throw new Error('No fields provided for update.');
        }

        const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
        values.push(id);

        const [result] = await connection.execute(sql, values);

        if (result.affectedRows === 0) {
            throw new Error('User not found.');
        }

        const [updatedUserRows] = await connection.execute(
            'SELECT id, username, email, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users WHERE id = ?',
            [id]
        );
        return formatUserForResponse(updatedUserRows[0]);

    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            throw new Error('This email address is already in use.');
        }
        throw new Error('Failed to update user.');
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
    getAllUsers,
    deleteUser,
    updateUser,
    getUsernameById: async (id) => {
        let connection;
        try {
            connection = await mysql.createConnection(dbConfig);
            const [rows] = await connection.execute('SELECT username FROM users WHERE id = ?', [id]);
            if (rows.length === 0) {
                throw new Error('User not found.');
            }
            return rows[0].username;
        } catch (error) {
            throw new Error('Failed to retrieve username.');
        } finally {
            if (connection) await connection.end();
        }
    }
};

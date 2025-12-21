require('dotenv').config(); // Load environment variables from .env file

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const axios = require('axios'); // For making HTTP requests to Kopo Kopo
const crypto = require('crypto'); // For generating random codes

const app = express();
const port = process.env.PORT || 3000;
const saltRounds = 10; // For bcrypt password hashing

// --- Configuration ---
const dbConfig = {
    host: 'localhost',
    user: 'mystrio',
    password: '@Franko09', // IMPORTANT: Replace with your actual password
    database: 'mystrio'
};

// IMPORTANT: Replace with a long, random, secret string
const JWT_SECRET = '0517AAF488012BB6C836C845D5E035CDC6EEF5B92E7A8C67589928BE985C8D01';

// Kopo Kopo M-Pesa Configuration (use environment variables for production!)
const KOPOKOPO_CLIENT_ID = process.env.KOPOKOPO_CLIENT_ID || 'QAKpUkYMaI7u1XzQ0Si3ahAQpUgkBH9NvK1eSo5XdII';
const KOPOKOPO_CLIENT_SECRET = process.env.KOPOKOPO_CLIENT_SECRET || 'SFeifjjDrxz1HsN8qHfkBzflrCbZ6On1ynJquZQO1t0';
const KOPOKOPO_API_KEY = process.env.KOPOKOPO_API_KEY || 'f306e47c883c259e718896768525070720cb98db';
const KOPOKOPO_TILL_NUMBER = process.env.KOPOKOPO_TILL_NUMBER || '525881';
const KOPOKOPO_BASE_URL = 'https://sandbox.kopokopo.com/api/v1'; // Use sandbox for testing, then production URL

// --- Middleware ---
app.use(cors()); // Allow all origins
app.use(express.json());

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (token == null) return res.sendStatus(401); // if there isn't any token

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403); // if the token is invalid
        req.user = user; // Attach user payload to request
        next();
    });
};

// NEW: Middleware to verify if the user is an admin
const authenticateAdmin = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token == null) return res.sendStatus(401);

    jwt.verify(token, JWT_SECRET, async (err, user) => {
        if (err) return res.sendStatus(403);

        let connection;
        try {
            connection = await mysql.createConnection(dbConfig);
            const [rows] = await connection.execute('SELECT is_admin FROM users WHERE id = ?', [user.id]);

            if (rows.length === 0 || !rows[0].is_admin) {
                return res.status(403).json({ error: 'Forbidden: Requires admin privileges.' });
            }

            req.user = user; // Attach user payload to request
            next();
        } catch (error) {
            console.error('Admin authentication error:', error);
            res.status(500).json({ error: 'Failed to verify admin status.' });
        } finally {
            if (connection) await connection.end();
        }
    });
};


// Helper to convert snake_case to camelCase for API responses
const toCamelCase = (obj) => {
    if (Array.isArray(obj)) {
        return obj.map(v => toCamelCase(v));
    } else if (obj !== null && typeof obj === 'object') {
        return Object.keys(obj).reduce((acc, key) => {
            const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
            acc[camelKey] = obj[key];
            return acc;
        }, {});
    }
    return obj;
};

// Helper to format user data for response, including premium_until and is_admin
const formatUserForResponse = (user) => {
    const formattedUser = toCamelCase({
        id: user.id,
        username: user.username,
        display_name: user.display_name || user.username, // Fallback to username if display_name is null
        email: user.email,
        chosen_question_text: user.chosen_question_text,
        chosen_question_style_id: user.chosen_question_style_id,
        profile_image_path: user.profile_image_path,
        premium_until: user.premium_until ? new Date(user.premium_until).toISOString() : null, // Format as ISO string
        is_admin: user.is_admin, // NEW: Include admin status
    });
    return formattedUser;
};

// --- Kopo Kopo Helpers ---
let kopoKopoAccessToken = null;
let kopoKopoTokenExpiry = 0;

const getKopoKopoAccessToken = async () => {
    if (kopoKopoAccessToken && Date.now() < kopoKopoTokenExpiry) {
        return kopoKopoAccessToken;
    }

    try {
        const response = await axios.post(`${KOPOKOPO_BASE_URL}/oauth/token`, {
            client_id: KOPOKOPO_CLIENT_ID,
            client_secret: KOPOKOPO_CLIENT_SECRET,
            grant_type: 'client_credentials',
        }, {
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
        });

        kopoKopoAccessToken = response.data.access_token;
        kopoKopoTokenExpiry = Date.now() + (response.data.expires_in * 1000) - 60000; // Refresh 1 minute before expiry
        console.log('Kopo Kopo Access Token obtained.');
        return kopoKopoAccessToken;
    } catch (error) {
        console.error('Error getting Kopo Kopo Access Token:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get Kopo Kopo Access Token');
    }
};

const initiateKopoKopoSTKPush = async (phoneNumber, amount, callbackUrl, clientReference) => {
    try {
        const accessToken = await getKopoKopoAccessToken();
        const response = await axios.post(`${KOPOKOPO_BASE_URL}/till_numbers/${KOPOKOPO_TILL_NUMBER}/stk_push`, {
            amount: amount,
            currency: 'KES',
            metadata: {
                client_reference: clientReference, // Use this to link payment to user/transaction
                payment_type: 'premium_subscription',
            },
            callback_url: callbackUrl,
            customer_phone_number: phoneNumber,
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Api-Key': KOPOKOPO_API_KEY,
            },
        });
        console.log('Kopo Kopo STK Push initiated:', response.data);
        return response.data;
    } catch (error) {
        console.error('Error initiating Kopo Kopo STK Push:', error.response ? error.response.data : error.message);
        throw new Error('Failed to initiate STK Push');
    }
};

// --- Database Schema Updates ---
const ensureDisplayNameColumn = async () => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [columns] = await connection.execute("SHOW COLUMNS FROM users LIKE 'display_name'");
        if (columns.length === 0) {
            console.log("Adding display_name column to users table...");
            await connection.execute("ALTER TABLE users ADD COLUMN display_name VARCHAR(255)");
            // Backfill display_name with username for existing users
            await connection.execute("UPDATE users SET display_name = username");
        }
    } catch (error) {
        console.error("Error ensuring display_name column:", error);
    } finally {
        if (connection) await connection.end();
    }
};


// --- Auth Routes ---

// POST /api/signup - Register a new user
app.post('/api/signup', async (req, res) => {
    const { username, email, password, chosenQuestionText, chosenQuestionStyleId, profileImagePath } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ error: 'Username, email, and password are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // Logic to find unique username (handle)
        let uniqueUsername = username;
        let isUnique = false;
        let attempts = 0;

        while (!isUnique && attempts < 10) {
            const [rows] = await connection.execute('SELECT id FROM users WHERE username = ?', [uniqueUsername]);
            if (rows.length === 0) {
                isUnique = true;
            } else {
                // Append a random 4-digit number
                const randomNum = Math.floor(1000 + Math.random() * 9000);
                uniqueUsername = `${username}${randomNum}`;
                attempts++;
            }
        }

        if (!isUnique) {
            return res.status(409).json({ error: 'Could not generate a unique username. Please try a different one.' });
        }

        const hashedPassword = await bcrypt.hash(password, saltRounds);
        // Insert with uniqueUsername as 'username' and original username as 'display_name'
        const sql = `INSERT INTO users (username, display_name, email, password, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin) VALUES (?, ?, ?, ?, ?, ?, ?, NULL, FALSE)`;
        const [result] = await connection.execute(sql, [uniqueUsername, username, email, hashedPassword, chosenQuestionText, chosenQuestionStyleId, profileImagePath]);

        const newUser = {
            id: result.insertId,
            username: uniqueUsername,
            display_name: username,
            email,
            chosen_question_text: chosenQuestionText,
            chosen_question_style_id: chosenQuestionStyleId,
            profile_image_path: profileImagePath,
            premium_until: null,
            is_admin: false,
        };

        // Generate JWT token for the newly registered user
        const tokenPayload = { id: newUser.id, username: newUser.username };
        const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1d' }); // Token expires in 1 day

        res.status(201).json({
            token,
            user: formatUserForResponse(newUser)
        });
    } catch (error) {
        console.error('POST /api/signup - Error:', error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'This email address is already in use.' });
        }
        res.status(500).json({ error: 'Failed to create user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/login - Authenticate a user and return a JWT
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;
    console.log('Login attempt for email:', email);
    console.log('Password received:', password); // WARNING: Do not log passwords in production!

    if (!email || !password) {
        console.log('Login failed: Email or password missing.');
        return res.status(400).json({ error: 'Email and password are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const sql = 'SELECT id, username, display_name, email, password, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users WHERE email = ?';
        const [rows] = await connection.execute(sql, [email]);

        if (rows.length === 0) {
            console.log('Login failed: User not found for email:', email);
            return res.status(401).json({ error: 'Invalid credentials.' });
        }

        const user = rows[0];
        console.log('User found in DB (excluding password hash):', { id: user.id, username: user.username, email: user.email });
        const match = await bcrypt.compare(password, user.password);
        console.log('Bcrypt password comparison result:', match);

        if (match) {
            // Passwords match, create JWT
            const tokenPayload = { id: user.id, username: user.username };
            const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1d' }); // Token expires in 1 day

            // Return user data in camelCase
            res.json({
                token,
                user: formatUserForResponse(user)
            });
        } else {
            // Passwords don't match
            console.log('Login failed: Password mismatch for email:', email);
            res.status(401).json({ error: 'Invalid credentials.' });
        }
    } catch (error) {
        console.error('POST /api/login - Error:', error);
        res.status(500).json({ error: 'Login failed.' });
    } finally {
        if (connection) await connection.end();
    }
});


// --- User Data Routes ---

// GET all users (publicly accessible, but without password)
app.get('/api/users', async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        // Explicitly select columns to avoid sending the password hash
        const [rows] = await connection.execute('SELECT id, username, display_name, email, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users ORDER BY id');
        res.json(rows.map(formatUserForResponse)); // Convert to camelCase and format premium_until
    } catch (error) {
        console.error('GET /api/users - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve users.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE a user by ID (Protected)
app.delete('/api/users/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    // Optional: Check if the logged-in user is the one they are trying to delete (or an admin)
    if (req.user.id !== parseInt(id)) {
        return res.status(403).json({ error: "You can only delete your own account." });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM users WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ error: 'User not found.' });
        res.status(204).send(); // 204 No Content is standard for a successful delete
    } catch (error) {
        console.error(`DELETE /api/users/${id} - Error:`, error);
        res.status(500).json({ error: 'Failed to delete user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// PUT (update) a user by ID (Protected)
app.put('/api/users/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { username, displayName, email, chosenQuestionText, chosenQuestionStyleId, profileImagePath, premiumUntil } = req.body;

    // Optional: Check if the logged-in user is the one they are trying to update
    if (req.user.id !== parseInt(id)) {
        return res.status(403).json({ error: "You can only update your own account." });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const fields = [];
        const values = [];

        if (username !== undefined) { fields.push('username = ?'); values.push(username); }
        if (displayName !== undefined) { fields.push('display_name = ?'); values.push(displayName); }
        if (email !== undefined) { fields.push('email = ?'); values.push(email); }
        if (chosenQuestionText !== undefined) { fields.push('chosen_question_text = ?'); values.push(chosenQuestionText); }
        if (chosenQuestionStyleId !== undefined) { fields.push('chosen_question_style_id = ?'); values.push(chosenQuestionStyleId); }
        if (profileImagePath !== undefined) { fields.push('profile_image_path = ?'); values.push(profileImagePath); }
        if (premiumUntil !== undefined) { fields.push('premium_until = ?'); values.push(premiumUntil); } // Allow updating premium_until

        if (fields.length === 0) {
            return res.status(400).json({ error: 'No fields provided for update.' });
        }

        const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
        values.push(id);

        const [result] = await connection.execute(sql, values);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'User not found.' });
        }

        // Fetch the updated user to return
        const [updatedUserRows] = await connection.execute(
            'SELECT id, username, display_name, email, chosen_question_text, chosen_question_style_id, profile_image_path, premium_until, is_admin FROM users WHERE id = ?',
            [id]
        );
        res.json(formatUserForResponse(updatedUserRows[0])); // Convert to camelCase and format premium_until

    } catch (error) {
        console.error(`PUT /api/users/${id} - Error:`, error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'This email address or username is already in use.' });
        }
        res.status(500).json({ error: 'Failed to update user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// --- Question Routes (Protected) ---

// GET /api/questions - Get all questions for the logged-in user
app.get('/api/questions', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT id, question_text, answer_text, is_from_ai, hints, created_at, updated_at FROM questions WHERE user_id = ? ORDER BY created_at DESC',
            [req.user.id]
        );
        // Parse hints from JSON string back to object and convert to camelCase
        const questions = rows.map(row => ({
            ...toCamelCase(row),
            hints: row.hints ? JSON.parse(row.hints) : {},
        }));
        res.json(questions);
    } catch (error) {
        console.error('GET /api/questions - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve questions.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/questions - Create a new question for the logged-in user
app.post('/api/questions', authenticateToken, async (req, res) => {
    const { questionText, isFromAI = false, hints = {} } = req.body; // Expect camelCase from client
    if (!questionText) {
        return res.status(400).json({ error: 'Question text is required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const sql = 'INSERT INTO questions (user_id, question_text, is_from_ai, hints) VALUES (?, ?, ?, ?)';
        const [result] = await connection.execute(sql, [req.user.id, questionText, isFromAI, JSON.stringify(hints)]);

        res.status(201).json(toCamelCase({ // Convert response to camelCase
            id: result.insertId,
            user_id: req.user.id,
            question_text: questionText,
            is_from_ai: isFromAI,
            hints: hints,
            created_at: new Date(),
            updated_at: new Date()
        }));
    } catch (error) {
        console.error('POST /api/questions - Error:', error);
        res.status(500).json({ error: 'Failed to create question.' });
    } finally {
        if (connection) await connection.end();
    }
});

// PUT /api/questions/:id - Update a question (e.g., add an answer)
app.put('/api/questions/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { questionText, answerText, isFromAI, hints } = req.body; // Expect camelCase from client

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // First, verify the question belongs to the authenticated user
        const [questionRows] = await connection.execute('SELECT user_id FROM questions WHERE id = ?', [id]);
        if (questionRows.length === 0) {
            return res.status(404).json({ error: 'Question not found.' });
        }
        if (questionRows[0].user_id !== req.user.id) {
            return res.status(403).json({ error: 'You can only update your own questions.' });
        }

        // Build update query dynamically
        const fields = [];
        const values = [];
        if (questionText !== undefined) { fields.push('question_text = ?'); values.push(questionText); }
        if (answerText !== undefined) { fields.push('answer_text = ?'); values.push(answerText); }
        if (isFromAI !== undefined) { fields.push('is_from_ai = ?'); values.push(isFromAI); }
        if (hints !== undefined) { fields.push('hints = ?'); values.push(hints ? JSON.stringify(hints) : null); }

        if (fields.length === 0) {
            return res.status(400).json({ error: 'No fields provided for update.' });
        }

        const sql = `UPDATE questions SET ${fields.join(', ')} WHERE id = ?`;
        values.push(id);

        const [result] = await connection.execute(sql, values);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Question not found or no changes made.' });
        }

        // Fetch the updated question to return
        const [updatedQuestionRows] = await connection.execute(
            'SELECT id, question_text, answer_text, is_from_ai, hints, created_at, updated_at FROM questions WHERE id = ?',
            [id]
        );
        const updatedQuestion = {
            ...toCamelCase(updatedQuestionRows[0]),
            hints: updatedQuestionRows[0].hints ? JSON.parse(updatedQuestionRows[0].hints) : {},
        };
        res.json(updatedQuestion);

    } catch (error) {
        console.error(`PUT /api/questions/${id} - Error:`, error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'This email address is already in use.' });
        }
        res.status(500).json({ error: 'Failed to update user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE /api/questions/:id - Delete a question
app.delete('/api/questions/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // First, verify the question belongs to the authenticated user
        const [questionRows] = await connection.execute('SELECT user_id FROM questions WHERE id = ?', [id]);
        if (questionRows.length === 0) {
            return res.status(404).json({ error: 'Question not found.' });
        }
        if (questionRows[0].user_id !== req.user.id) {
            return res.status(403).json({ error: 'You can only delete your own questions.' });
        }

        const [result] = await connection.execute('DELETE FROM questions WHERE id = ?', [id]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Question not found.' });
        }
        res.status(204).send(); // 204 No Content for successful deletion
    } catch (error) {
        console.error(`DELETE /api/questions/${id} - Error:`, error);
        res.status(500).json({ error: 'Failed to delete question.' });
    } finally {
        if (connection) await connection.end();
    }
});

// --- Kopo Kopo Payment Routes ---

// POST /api/payment/initiate-stk - Initiate an STK Push
app.post('/api/payment/initiate-stk', authenticateToken, async (req, res) => {
    const { phoneNumber, amount, userId } = req.body; // userId is from Flutter app, not JWT

    if (!phoneNumber || !amount || !userId) {
        return res.status(400).json({ error: 'Phone number, amount, and userId are required.' });
    }

    // Ensure the user initiating the payment is the logged-in user
    if (req.user.id !== parseInt(userId)) {
        return res.status(403).json({ error: "You can only update your own account." });
    }

    try {
        // Kopo Kopo requires phone number in E.164 format (e.g., +2547XXXXXXXX)
        const formattedPhoneNumber = phoneNumber.startsWith('+') ? phoneNumber : `+254${phoneNumber.substring(phoneNumber.length - 9)}`;

        // The callback URL Kopo Kopo will hit after payment
        const callbackUrl = `https://api.mystrio.top/api/payment/webhook`; // IMPORTANT: Use your actual domain

        const kopoKopoResponse = await initiateKopoKopoSTKPush(
            formattedPhoneNumber,
            amount,
            callbackUrl,
            userId.toString() // Use userId as clientReference to link payment to user
        );

        res.json({ success: true, message: 'STK Push initiated successfully.', kopoKopoResponse });
    } catch (error) {
        console.error('Error in /api/payment/initiate-stk:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// POST /api/payment/webhook - Kopo Kopo callback for payment status
app.post('/api/payment/webhook', async (req, res) => {
    console.log('Kopo Kopo Webhook received:', JSON.stringify(req.body, null, 2));

    const { status, metadata, till_number, amount, currency, mpesa_receipt_number, customer_phone_number } = req.body;
    const userId = metadata ? metadata.client_reference : null;
    const paymentType = metadata ? metadata.payment_type : null;

    if (!userId || paymentType !== 'premium_subscription') {
        console.error('Webhook: Missing userId or invalid paymentType in metadata.');
        return res.status(400).json({ error: 'Invalid webhook data.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        if (status === 'success') {
            // Determine subscription duration (e.g., 1 month for a fixed amount)
            const subscriptionMonths = 1; // Example: 1 month subscription
            const expiryDate = new Date();
            expiryDate.setMonth(expiryDate.getMonth() + subscriptionMonths);

            const sql = 'UPDATE users SET premium_until = ? WHERE id = ?';
            await connection.execute(sql, [expiryDate, userId]);
            console.log(`Webhook: User ${userId} premium_until updated to ${expiryDate}`);
        } else {
            console.log(`Webhook: Payment for user ${userId} failed or was cancelled. Status: ${status}`);
        }

        res.status(200).send('Webhook received successfully.');
    } catch (error) {
        console.error('Webhook: Error processing payment:', error);
        res.status(500).json({ error: 'Internal server error during webhook processing.' });
    } finally {
        if (connection) await connection.end();
    }
});

// NEW: --- Admin Routes ---

// GET /api/admin/stats - Get dashboard statistics
app.get('/api/admin/stats', authenticateAdmin, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [totalUsers] = await connection.execute('SELECT COUNT(*) as count FROM users');
        const [premiumUsers] = await connection.execute('SELECT COUNT(*) as count FROM users WHERE premium_until > NOW()');
        const [recentSignups] = await connection.execute('SELECT id, username, email, created_at FROM users ORDER BY created_at DESC LIMIT 5');

        res.json({
            totalUsers: totalUsers[0].count,
            premiumUsers: premiumUsers[0].count,
            recentSignups: toCamelCase(recentSignups),
        });
    } catch (error) {
        console.error('GET /api/admin/stats - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve admin stats.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/admin/users - Get all users for admin management
app.get('/api/admin/users', authenticateAdmin, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT id, username, email, created_at, premium_until, is_admin FROM users ORDER BY id');
        res.json(rows.map(formatUserForResponse));
    } catch (error) {
        console.error('GET /api/admin/users - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve users.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/admin/users/:id/activity - Get activity for a specific user
app.get('/api/admin/users/:id/activity', authenticateAdmin, async (req, res) => {
    const { id } = req.params;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // FIX: Count questions where recipient_user_id is this user
        const [questionsReceivedResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM questions WHERE recipient_user_id = ?',
            [id]
        );
        const totalQuestionsReceived = questionsReceivedResult[0].count;

        // FIX: Count answers given by this user (where user_id is the sender and answer_text is not NULL)
        const [answersGivenResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM questions WHERE user_id = ? AND answer_text IS NOT NULL',
            [id]
        );
        const totalAnswersGiven = answersGivenResult[0].count;

        // Count quizzes created by this user
        const [quizzesCreatedResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM quizzes WHERE user_id = ?',
            [id]
        );
        const totalQuizzesCreated = quizzesCreatedResult[0].count;


        res.json(toCamelCase({
            totalQuestionsAsked: totalQuestionsReceived, // FIX: Renamed to reflect questions received
            totalAnswersGiven,
            totalQuizzesCreated,
        }));
    } catch (error) {
        console.error(`GET /api/admin/users/${id}/activity - Error:`, error);
        // NEW: Check for ER_NO_SUCH_TABLE specifically for quizzes
        if (error.code === 'ER_NO_SUCH_TABLE') {
            return res.status(500).json({ error: "Database table 'quizzes' not found. Please create it." });
        }
        res.status(500).json({ error: 'Failed to retrieve user activity.' });
    } finally {
        if (connection) await connection.end();
    }
});


// PUT /api/admin/users/:id - Update a user's details (admin)
app.put('/api/admin/users/:id', authenticateAdmin, async (req, res) => {
    const { id } = req.params;
    const { username, email, premiumUntil, isAdmin } = req.body;

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
            return res.status(400).json({ error: 'No fields provided for update.' });
        }

        const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
        values.push(id);

        const [result] = await connection.execute(sql, values);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'User not found.' });
        }

        res.json({ success: true, message: 'User updated successfully.' });
    } catch (error) {
        console.error(`PUT /api/admin/users/${id} - Error:`, error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'This email address is already in use.' });
        }
        res.status(500).json({ error: 'Failed to update user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE /api/admin/users/:id - Delete a user (admin)
app.delete('/api/admin/users/:id', authenticateAdmin, async (req, res) => {
    const { id } = req.params;

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM questions WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ error: 'Question not found.' });
        res.status(204).send();
    } catch (error) {
        console.error(`DELETE /api/admin/users/${id} - Error:`, error);
        res.status(500).json({ error: 'Failed to delete user.' });
    } finally {
        if (connection) await connection.end();
    }
});

// NEW: --- Admin Question Moderation Routes ---

// GET /api/admin/questions - Get all questions for moderation
app.get('/api/admin/questions', authenticateAdmin, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        // Join with users table to get username and email of the question owner
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
                ru.username AS recipientUsername, -- NEW: Recipient's username
                ru.email AS recipientEmail       -- NEW: Recipient's email
            FROM questions q
                     LEFT JOIN users u ON q.user_id = u.id -- FIX: Use LEFT JOIN for sender
                     JOIN users ru ON q.recipient_user_id = ru.id -- NEW: Join for recipient user
            ORDER BY q.created_at DESC
        `);

        // Format hints and convert to camelCase
        const questions = rows.map(row => ({
            ...toCamelCase(row),
            ownerUsername: row.username, // Add owner's username (sender)
            ownerEmail: row.email,       // Add owner's email (sender)
            recipientUsername: row.recipientUsername, // NEW: Recipient's username
            recipientEmail: row.recipientEmail,       // NEW: Recipient's email
        }));
        res.json(questions);
    } catch (error) {
        console.error('GET /api/admin/questions - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve questions for moderation.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE /api/admin/questions/:id - Delete a question (admin)
app.delete('/api/admin/questions/:id', authenticateAdmin, async (req, res) => {
    const { id } = req.params;

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM questions WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ error: 'Question not found.' });
        res.status(204).send(); // 204 No Content for successful deletion
    } catch (error) {
        console.error(`DELETE /api/admin/questions/${id} - Error:`, error);
        res.status(500).json({ error: 'Failed to delete question.' });
    } finally {
        if (connection) await connection.end();
    }
});

// NEW: --- Admin Quiz Moderation Routes ---
// NOTE: These routes assume you have a 'quizzes' table in your database.
// If not, you'll need to create it first.

// GET /api/admin/quizzes - Get all quizzes for moderation
app.get('/api/admin/quizzes', authenticateAdmin, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        // Assuming a 'quizzes' table exists with at least id, title, user_id, created_at
        // Join with users table to get username and email of the quiz owner
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

        // Format and convert to camelCase
        const quizzes = rows.map(row => ({
            ...toCamelCase(row),
            ownerUsername: row.username, // Add owner's username
            ownerEmail: row.email,       // Add owner's email
        }));
        res.json(quizzes);
    } catch (error) {
        console.error('GET /api/admin/quizzes - Error:', error);
        // NEW: Check for ER_NO_SUCH_TABLE specifically
        if (error.code === 'ER_NO_SUCH_TABLE') {
            return res.status(500).json({ error: "Database table 'quizzes' not found. Please create it." });
        }
        res.status(500).json({ error: 'Failed to retrieve quizzes for moderation.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE /api/admin/quizzes/:id - Delete a quiz (admin)
app.delete('/api/admin/quizzes/:id', authenticateAdmin, async (req, res) => {
    const { id } = req.params;

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('DELETE FROM quizzes WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ error: 'Quiz not found.' });
        res.status(204).send(); // 204 No Content for successful deletion
    } catch (error) {
        console.error(`DELETE /api/admin/quizzes/${id} - Error:`, error);
        // NEW: Check for ER_NO_SUCH_TABLE specifically
        if (error.code === 'ER_NO_SUCH_TABLE') {
            return res.status(500).json({ error: "Database table 'quizzes' not found. Please create it." });
        }
        res.status(500).json({ error: 'Failed to delete quiz.' });
    } finally {
        if (connection) await connection.end();
    }
});

// NEW: --- Anonymous Question Submission ---
app.post('/api/questions/anonymous', async (req, res) => {
    const { recipientUserId, questionText } = req.body;
    const senderIpAddress = req.ip; // Express's req.ip gets the client IP

    if (!recipientUserId || !questionText) {
        return res.status(400).json({ error: 'Recipient User ID and question text are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // Verify recipient user exists
        const [userRows] = await connection.execute('SELECT id FROM users WHERE id = ?', [recipientUserId]);
        if (userRows.length === 0) {
            return res.status(404).json({ error: 'Recipient user not found.' });
        }

        const sql = `INSERT INTO questions (user_id, recipient_user_id, question_text, sender_ip_address) VALUES (?, ?, ?, ?)`;
        const [result] = await connection.execute(sql, [null, recipientUserId, questionText, senderIpAddress]);

        res.status(201).json({ success: true, message: 'Anonymous question submitted.', questionId: result.insertId });
    } catch (error) {
        console.error('POST /api/questions/anonymous - Error:', error);
        res.status(500).json({ error: 'Failed to submit anonymous question.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/questions/anonymous/all - Get all anonymous questions for the logged-in user
app.get('/api/questions/anonymous/all', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [received] = await connection.execute(
            'SELECT id, question_text, created_at FROM questions WHERE recipient_user_id = ? AND user_id IS NULL ORDER BY created_at DESC',
            [req.user.id]
        );
        const [sent] = await connection.execute(
            'SELECT q.id, q.question_text, q.created_at, u.username as recipient_username FROM questions q JOIN users u ON q.recipient_user_id = u.id WHERE q.user_id = ? AND q.recipient_user_id IS NOT NULL ORDER BY q.created_at DESC',
            [req.user.id]
        );
        res.status(200).json({ success: true, data: { received: received.map(toCamelCase), sent: sent.map(toCamelCase) } });
    } catch (error) {
        console.error('GET /api/questions/anonymous/all - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve anonymous questions.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/quizzes - Get all quizzes for the logged-in user
app.get('/api/quizzes', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [quizzes] = await connection.execute(
            'SELECT id, title, created_at FROM quizzes WHERE user_id = ? ORDER BY created_at DESC',
            [userId]
        );
        res.status(200).json({ success: true, data: quizzes.map(toCamelCase) });
    } catch (error) {
        console.error('GET /api/quizzes - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve quizzes.' });
    } finally {
        if (connection) await connection.end();
    }
});

// Create a new quiz
app.post('/api/quizzes', authenticateToken, async (req, res) => {
    const { title, questions } = req.body;
    const userId = req.user.id;

    if (!title || !questions || !Array.isArray(questions) || questions.length === 0) {
        return res.status(400).json({ success: false, message: 'Quiz title and at least one question are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        // Start a transaction
        await connection.beginTransaction();

        // Insert the quiz
        const [quizResult] = await connection.query(
            'INSERT INTO quizzes (user_id, title) VALUES (?, ?)',
            [userId, title]
        );
        const quizId = quizResult.insertId;

        // Insert the questions
        for (const q of questions) {
            if (!q.question_text || !q.options || !Array.isArray(q.options) || q.options.length < 2 || q.correct_option_index === undefined) {
                throw new Error('Each question must have text, at least two options, and a correct answer index.');
            }
            const [questionResult] = await connection.query(
                'INSERT INTO quiz_questions (quiz_id, question_text, correct_option_index) VALUES (?, ?, ?)',
                [quizId, q.question_text, q.correct_option_index]
            );
            const questionId = questionResult.insertId;

            // Insert the options
            for (const optionText of q.options) {
                await connection.query(
                    'INSERT INTO quiz_options (question_id, option_text) VALUES (?, ?)',
                    [questionId, optionText]
                );
            }
        }

        // Commit the transaction
        await connection.commit();

        res.status(201).json({ success: true, message: 'Quiz created successfully!', data: { quizId } });
    } catch (error) {
        // Rollback the transaction in case of an error
        if (connection) await connection.rollback();
        console.error('POST /api/quizzes - Error:', error);
        res.status(500).json({ error: 'Failed to create quiz.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/questions/card - Save or update a question card
app.post('/api/questions/card', authenticateToken, async (req, res) => {
    const { questionText, styleId, existingCode } = req.body;
    const userId = req.user.id;

    if (!questionText || !styleId) {
        return res.status(400).json({ success: false, message: 'Question text and style ID are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        let finalCode = existingCode;

        if (existingCode) {
            const [updateResult] = await connection.execute(
                'UPDATE question_cards SET question_text = ?, style_id = ? WHERE code = ? AND user_id = ?',
                [questionText, styleId, existingCode, userId]
            );

            if (updateResult.affectedRows === 0) {
                const [existingCard] = await connection.execute('SELECT id FROM question_cards WHERE code = ?', [existingCode]);
                if (existingCard.length > 0) {
                    finalCode = crypto.randomBytes(3).toString('hex');
                    await connection.execute(
                        'INSERT INTO question_cards (user_id, code, question_text, style_id) VALUES (?, ?, ?, ?)',
                        [userId, finalCode, questionText, styleId]
                    );
                } else {
                    await connection.execute(
                        'INSERT INTO question_cards (user_id, code, question_text, style_id) VALUES (?, ?, ?, ?)',
                        [userId, existingCode, questionText, styleId]
                    );
                }
            }
        } else {
            finalCode = crypto.randomBytes(3).toString('hex');
            await connection.execute(
                'INSERT INTO question_cards (user_id, code, question_text, style_id) VALUES (?, ?, ?, ?)',
                [userId, finalCode, questionText, styleId]
            );
        }

        res.status(201).json({ success: true, data: { code: finalCode } });

    } catch (error) {
        console.error('POST /api/questions/card - Error:', error);
        res.status(500).json({ error: 'Failed to save question card.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/questions/card/:code - Get a question card by its code
app.get('/api/questions/card/:code', async (req, res) => {
    const { code } = req.params;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            `SELECT qc.question_text, qc.style_id, qc.code, u.username
             FROM question_cards qc
                      JOIN users u ON qc.user_id = u.id
             WHERE qc.code = ?`,
            [code]
        );

        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Question card not found.' });
        }

        res.json({ success: true, data: toCamelCase(rows[0]) });
    } catch (error) {
        console.error(`GET /api/questions/card/${code} - Error:`, error);
        res.status(500).json({ error: 'Failed to retrieve question card.' });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/questions/cards/all - Get all question cards for the logged-in user
app.get('/api/questions/cards/all', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT code, question_text, style_id FROM question_cards WHERE user_id = ? ORDER BY created_at DESC',
            [userId]
        );
        res.json({ success: true, data: rows.map(toCamelCase) });
    } catch (error) {
        console.error('GET /api/questions/cards/all - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve question cards.' });
    } finally {
        if (connection) await connection.end();
    }
});

// DELETE /api/questions/card/:code - Delete a question card
app.delete('/api/questions/card/:code', authenticateToken, async (req, res) => {
    const { code } = req.params;
    const userId = req.user.id;

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute(
            'DELETE FROM question_cards WHERE code = ? AND user_id = ?',
            [code, userId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: 'Card not found or you do not have permission to delete it.' });
        }

        res.status(200).json({ success: true, message: 'Card deleted successfully.' });
    } catch (error) {
        console.error(`DELETE /api/questions/card/${code} - Error:`, error);
        res.status(500).json({ error: 'Failed to delete question card.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/questions/card/reply - Reply to a question card
app.post('/api/questions/card/reply', async (req, res) => {
    const { questionCode, replyText } = req.body;

    if (!questionCode || !replyText) {
        return res.status(400).json({ success: false, message: 'Question code and reply text are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const [cardRows] = await connection.execute('SELECT id, user_id, question_text FROM question_cards WHERE code = ?', [questionCode]);
        if (cardRows.length === 0) {
            return res.status(404).json({ success: false, message: 'Question card not found.' });
        }
        const card = cardRows[0];

        const [replyResult] = await connection.execute(
            'INSERT INTO question_replies (question_card_id, reply_text) VALUES (?, ?)',
            [card.id, replyText]
        );

        await connection.execute(
            'INSERT INTO notifications (user_id, type, title, content, related_code) VALUES (?, ?, ?, ?, ?)',
            [card.user_id, 'question_reply', card.question_text, replyText, questionCode]
        );

        res.status(201).json({ success: true, message: 'Reply submitted successfully.' });
    } catch (error) {
        console.error('POST /api/questions/card/reply - Error:', error);
        res.status(500).json({ error: 'Failed to submit reply.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/quizzes/:quizId/leaderboard - Add a score to a quiz's leaderboard
app.post('/api/quizzes/:quizId/leaderboard', authenticateToken, async (req, res) => {
    const { quizId } = req.params;
    const { username, score } = req.body;

    if (!username || score === undefined) {
        return res.status(400).json({ success: false, message: 'Username and score are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // Ensure table exists
        await connection.execute(`
            CREATE TABLE IF NOT EXISTS quiz_leaderboard (
                id INT AUTO_INCREMENT PRIMARY KEY,
                quiz_id INT NOT NULL,
                username VARCHAR(255) NOT NULL,
                score INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
            )
        `);

        // Verify quiz exists AND get owner ID and title
        const [quizRows] = await connection.execute('SELECT id, user_id, title FROM quizzes WHERE id = ?', [quizId]);
        if (quizRows.length === 0) {
            return res.status(404).json({ success: false, message: 'Quiz not found.' });
        }
        const quiz = quizRows[0];

        // Insert the new leaderboard entry
        await connection.execute(
            'INSERT INTO quiz_leaderboard (quiz_id, username, score) VALUES (?, ?, ?)',
            [quizId, username, score]
        );

        // NEW: Create notification for the quiz owner
        // Don't notify if the owner took their own quiz
        if (req.user.id !== quiz.user_id) {
             const notificationTitle = `New Score on "${quiz.title}"`;
             const notificationContent = `${username} scored ${score} points!`;
             
             await connection.execute(
                'INSERT INTO notifications (user_id, type, title, content, related_code) VALUES (?, ?, ?, ?, ?)',
                [quiz.user_id, 'quiz_answer', notificationTitle, notificationContent, quizId]
            );
        }

        res.status(201).json({ success: true, message: 'Score added to leaderboard.' });
    } catch (error) {
        console.error(`POST /api/quizzes/${quizId}/leaderboard - Error:`, error);
        // Return the actual error message for debugging purposes (in dev)
        res.status(500).json({ error: 'Failed to add score to leaderboard.', details: error.message });
    } finally {
        if (connection) await connection.end();
    }
});

// GET /api/notifications - Get all notifications for the logged-in user
app.get('/api/notifications', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT id, type, title, content, related_code, is_seen, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
            [userId]
        );
        res.json({ success: true, data: rows.map(toCamelCase) });
    } catch (error) {
        console.error('GET /api/notifications - Error:', error);
        res.status(500).json({ error: 'Failed to retrieve notifications.' });
    } finally {
        if (connection) await connection.end();
    }
});

// POST /api/notifications/mark-seen - Mark notifications as seen
app.post('/api/notifications/mark-seen', authenticateToken, async (req, res) => {
    const { notificationIds } = req.body;
    const userId = req.user.id;

    if (!notificationIds || !Array.isArray(notificationIds) || notificationIds.length === 0) {
        return res.status(400).json({ success: false, message: 'Notification IDs are required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.query(
            'UPDATE notifications SET is_seen = TRUE WHERE id IN (?) AND user_id = ?',
            [notificationIds, userId]
        );
        res.status(200).json({ success: true, message: 'Notifications marked as seen.' });
    } catch (error) {
        console.error('POST /api/notifications/mark-seen - Error:', error);
        res.status(500).json({ error: 'Failed to mark notifications as seen.' });
    } finally {
        if (connection) await connection.end();
    }
});


// Start the server
app.listen(port, () => {
    console.log(`Mystrio API server running on port ${port}`);
    ensureDisplayNameColumn(); // Ensure the column exists on startup
});

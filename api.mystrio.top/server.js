const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

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

// --- Middleware ---
app.use(cors());
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
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const sql = `INSERT INTO users (username, email, password, chosen_question_text, chosen_question_style_id, profile_image_path) VALUES (?, ?, ?, ?, ?, ?)`;
    const [result] = await connection.execute(sql, [username, email, hashedPassword, chosenQuestionText, chosenQuestionStyleId, profileImagePath]);
    
    const newUser = {
      id: result.insertId, 
      username, 
      email, 
      chosen_question_text: chosenQuestionText, 
      chosen_question_style_id: chosenQuestionStyleId, 
      profile_image_path: profileImagePath 
    };

    // Generate JWT token for the newly registered user
    const tokenPayload = { id: newUser.id, username: newUser.username };
    const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1d' }); // Token expires in 1 day

    res.status(201).json({ 
      token,
      user: toCamelCase(newUser) // Nest newUser under 'user' key
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
    const sql = 'SELECT id, username, email, password, chosen_question_text, chosen_question_style_id, profile_image_path FROM users WHERE email = ?';
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
        user: toCamelCase({
          id: user.id, 
          username: user.username, 
          email: user.email,
          chosen_question_text: user.chosen_question_text,
          chosen_question_style_id: user.chosen_question_style_id,
          profile_image_path: user.profile_image_path,
        })
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
    const [rows] = await connection.execute('SELECT id, username, email, chosen_question_text, chosen_question_style_id, profile_image_path FROM users ORDER BY id');
    res.json(toCamelCase(rows)); // Convert to camelCase
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
  const { username, email, chosenQuestionText, chosenQuestionStyleId, profileImagePath } = req.body;
  
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
    if (email !== undefined) { fields.push('email = ?'); values.push(email); }
    if (chosenQuestionText !== undefined) { fields.push('chosen_question_text = ?'); values.push(chosenQuestionText); }
    if (chosenQuestionStyleId !== undefined) { fields.push('chosen_question_style_id = ?'); values.push(chosenQuestionStyleId); }
    if (profileImagePath !== undefined) { fields.push('profile_image_path = ?'); values.push(profileImagePath); }

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
      'SELECT id, username, email, chosen_question_text, chosen_question_style_id, profile_image_path FROM users WHERE id = ?',
      [id]
    );
    res.json(toCamelCase(updatedUserRows[0])); // Convert to camelCase

  } catch (error) {
    console.error(`PUT /api/users/${id} - Error:`, error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'This email address is already in use.' });
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
    res.status(500).json({ error: 'Failed to update question.' });
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


// Start the server
app.listen(port, () => {
  console.log(`Mystrio API server running on port ${port}`);
});

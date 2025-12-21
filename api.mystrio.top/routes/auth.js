const express = require('express');
const router = express.Router();
const authService = require('../services/authService'); // Import the auth service

// POST /signup - Register a new user
router.post('/signup', async (req, res) => {
  const { username, email, password, chosenQuestionText, chosenQuestionStyleId, profileImagePath } = req.body;
  if (!username || !email || !password) {
    return res.status(400).json({ error: 'Username, email, and password are required.' });
  }

  try {
    const { token, user } = await authService.signup(username, email, password, chosenQuestionText, chosenQuestionStyleId, profileImagePath);
    res.status(201).json({ token, user });
  } catch (error) {
    if (error.message === 'This email address is already in use.') {
      return res.status(409).json({ error: error.message });
    }
    next(error);
  }
});

// POST /login - Authenticate a user and return a JWT
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  try {
    const { token, user } = await authService.login(email, password);
    res.json({ token, user });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
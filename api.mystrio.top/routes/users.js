const express = require('express');
const router = express.Router();
const userService = require('../services/userService'); // Import the user service
const { authenticateToken } = require('../middleware/authMiddleware');

// GET all users (publicly accessible, but without password)
router.get('/', async (req, res, next) => {
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;

  try {
    const users = await userService.getAllUsers(page, limit);
    res.json(users);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', authenticateToken, async (req, res, next) => {
  const { id } = req.params;
  if (req.user.id !== parseInt(id)) {
      return res.status(403).json({ error: "You can only delete your own account." });
  }

  try {
    await userService.deleteUser(id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// PUT (update) a user by ID (Protected)
router.put('/:id', authenticateToken, async (req, res, next) => {
  const { id } = req.params;
  const { username, email, chosenQuestionText, chosenQuestionStyleId, profileImagePath, premiumUntil } = req.body;

  if (req.user.id !== parseInt(id)) {
      return res.status(403).json({ error: "You can only update your own account." });
  }

  try {
    const updatedUser = await userService.updateUser(id, { username, email, chosenQuestionText, chosenQuestionStyleId, profileImagePath, premiumUntil });
    res.json(updatedUser);
  } catch (error) {
    next(error);
  }
});

// GET a username by ID
router.get('/:id/username', async (req, res, next) => {
    const { id } = req.params;
    try {
        const username = await userService.getUsernameById(parseInt(id, 10));
        res.status(200).json({ success: true, username });
    } catch (error) {
        next(error);
    }
});

module.exports = router;
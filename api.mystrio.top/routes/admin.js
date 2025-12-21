const express = require('express');
const router = express.Router();
const adminService = require('../services/adminService'); // Import the admin service
const { authenticateAdmin } = require('../middleware/authMiddleware');

// GET /api/admin/stats - Get dashboard statistics
router.get('/stats', authenticateAdmin, async (req, res, next) => {
  try {
    const stats = await adminService.getAdminStats();
    res.json(stats);
  } catch (error) {
    next(error);
  }
});

// GET /api/admin/users - Get all users for admin management
router.get('/users', authenticateAdmin, async (req, res, next) => {
  try {
    const users = await adminService.getAllUsersAdmin();
    res.json(users);
  } catch (error) {
    next(error);
  }
});

// GET /api/admin/users/:id/activity - Get activity for a specific user
router.get('/users/:id/activity', authenticateAdmin, async (req, res, next) => {
  const { id } = req.params;
  try {
    const activity = await adminService.getUserActivity(id);
    res.json(activity);
  } catch (error) {
    next(error);
  }
});


// PUT /api/admin/users/:id - Update a user's details (admin)
router.put('/users/:id', authenticateAdmin, async (req, res, next) => {
  const { id } = req.params;
  const { username, email, premiumUntil, isAdmin } = req.body;

  try {
    const result = await adminService.updateUserAdmin(id, { username, email, premiumUntil, isAdmin });
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/admin/users/:id - Delete a user (admin)
router.delete('/users/:id', authenticateAdmin, async (req, res, next) => {
  const { id } = req.params;
  try {
    const result = await adminService.deleteUserAdmin(id);
    res.status(204).send(result.message);
  } catch (error) {
    next(error);
  }
});

// GET /api/admin/questions - Get all questions for moderation
router.get('/questions', authenticateAdmin, async (req, res, next) => {
  try {
    const questions = await adminService.getAllQuestionsAdmin();
    res.json(questions);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/admin/questions/:id - Delete a question (admin)
router.delete('/questions/:id', authenticateAdmin, async (req, res, next) => {
  const { id } = req.params;
  try {
    const result = await adminService.deleteQuestionAdmin(id);
    res.status(204).send(result.message);
  } catch (error) {
    next(error);
  }
});

// GET /api/admin/quizzes - Get all quizzes for moderation
router.get('/quizzes', authenticateAdmin, async (req, res, next) => {
  try {
    const quizzes = await adminService.getAllQuizzesAdmin();
    res.json(quizzes);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/admin/quizzes/:id - Delete a quiz (admin)
router.delete('/quizzes/:id', authenticateAdmin, async (req, res, next) => {
  const { id } = req.params;
  try {
    const result = await adminService.deleteQuizAdmin(id);
    res.status(204).send(result.message);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
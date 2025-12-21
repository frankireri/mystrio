const express = require('express');
const router = express.Router();
const questionService = require('../services/questionService'); // Import the question service
const { authenticateToken, isPremium } = require('../middleware/authMiddleware');

// GET /api/questions - Get all questions for the logged-in user
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const questions = await questionService.getQuestionsByUserId(req.user.id);
    res.json(questions);
  } catch (error) {
    next(error);
  }
});

// POST /api/questions - Create a new question for the logged-in user
router.post('/', authenticateToken, async (req, res, next) => {
  const { questionText, isFromAI = false, hints = {} } = req.body;
  if (!questionText) {
    return res.status(400).json({ error: 'Question text is required.' });
  }

  try {
    const newQuestion = await questionService.createQuestion(req.user.id, questionText, isFromAI, hints);
    res.status(201).json(newQuestion);
  } catch (error) {
    next(error);
  }
});

// PUT /api/questions/:id - Update a question (e.g., add an answer)
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { questionText, answerText, isFromAI, hints } = req.body;

  try {
    const updatedQuestion = await questionService.updateQuestion(id, req.user.id, { questionText, answerText, isFromAI, hints });
    res.json(updatedQuestion);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/questions/:id - Delete a question
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    await questionService.deleteQuestion(id, req.user.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// POST /api/questions/anonymous - Submit an anonymous question
router.post('/anonymous', async (req, res, next) => {
  const { recipientUserId, questionText } = req.body;
  const senderIpAddress = req.ip;

  if (!recipientUserId || !questionText) {
    return res.status(400).json({ error: 'Recipient User ID and question text are required.' });
  }

  try {
    const result = await questionService.submitAnonymousQuestion(recipientUserId, questionText, senderIpAddress);
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

// GET /api/questions/anonymous/all - Get all anonymous questions for the logged-in user
router.get('/anonymous/all', authenticateToken, async (req, res, next) => {
    try {
        const questions = await questionService.getAnonymousQuestions(req.user.id);
        res.status(200).json({ success: true, data: questions });
    } catch (error) {
        next(error);
    }
});

// GET /api/questions/:id/sender-hint - Get sender hint for a question (Premium feature)
router.get('/:id/sender-hint', authenticateToken, isPremium, async (req, res, next) => {
    const { id } = req.params;
    try {
        const senderHint = await questionService.getQuestionSenderHint(id, req.user.id);
        res.status(200).json({ success: true, hint: senderHint });
    } catch (error) {
        next(error);
    }
});

module.exports = router;

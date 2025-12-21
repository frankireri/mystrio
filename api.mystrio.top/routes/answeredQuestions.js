const express = require('express');
const router = express.Router();
const answeredQuestionService = require('../services/answeredQuestionService');
const { authenticateToken } = require('../middleware/authMiddleware');

// GET /api/answered-questions/:id - Retrieve a single answered question by ID
router.get('/:id', authenticateToken, async (req, res, next) => {
    const { id } = req.params;

    try {
        const answeredQuestion = await answeredQuestionService.getAnsweredQuestionById(id);
        res.status(200).json({ success: true, data: answeredQuestion });
    } catch (error) {
        next(error);
    }
});

module.exports = router;

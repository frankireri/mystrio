const express = require('express');
const router = express.Router();
const shareService = require('../services/shareService');
const { authenticateToken } = require('../middleware/authMiddleware');

// POST /api/share/answered-question/:answeredQuestionId - Generate a share link for an answered question
router.post('/answered-question/:answeredQuestionId', authenticateToken, async (req, res, next) => {
    const { answeredQuestionId } = req.params;

    // Optional: Verify that the authenticated user owns this answered question
    // This would require a function in a service to check ownership

    try {
        const shortCode = await shareService.createShareLink(answeredQuestionId);
        res.status(201).json({ success: true, shortCode });
    } catch (error) {
        next(error);
    }
});

// GET /api/share/answered-question/:shortCode - Retrieve answered_question_id by short code
router.get('/answered-question/:shortCode', async (req, res, next) => {
    const { shortCode } = req.params;

    try {
        const answeredQuestionId = await shareService.getAnsweredQuestionIdByShortCode(shortCode);
        res.status(200).json({ success: true, answeredQuestionId });
    } catch (error) {
        next(error);
    }
});

module.exports = router;

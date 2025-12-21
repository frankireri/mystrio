const express = require('express');
const router = express.Router();
const paymentService = require('../services/paymentService'); // Import the payment service
const { authenticateToken } = require('../middleware/authMiddleware');

// POST /api/payment/initiate-stk - Initiate an STK Push
router.post('/initiate-stk', authenticateToken, async (req, res) => {
  const { phoneNumber, amount, userId } = req.body;

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

    const kopoKopoResponse = await paymentService.initiateKopoKopoSTKPush(
      formattedPhoneNumber,
      amount,
      callbackUrl,
      userId.toString()
    );

    res.json({ success: true, message: 'STK Push initiated successfully.', kopoKopoResponse });
  } catch (error) {
    next(error);
  }
});

// POST /api/payment/webhook - Kopo Kopo callback for payment status
router.post('/webhook', async (req, res) => {
  try {
    const result = await paymentService.processKopoKopoWebhook(req.body);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
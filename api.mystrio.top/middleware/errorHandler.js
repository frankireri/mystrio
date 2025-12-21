const errorHandler = (err, req, res, next) => {
    console.error(err); // Log the error for debugging purposes

    if (err.message === 'This email address is already in use.') {
        return res.status(409).json({ error: err.message });
    }
    if (err.message === 'Invalid credentials.') {
        return res.status(401).json({ error: err.message });
    }
    if (err.message === 'User not found.') {
        return res.status(404).json({ error: err.message });
    }
    if (err.message === 'Question not found.') {
        return res.status(404).json({ error: err.message });
    }
    if (err.message === 'You can only update your own account.') {
        return res.status(403).json({ error: err.message });
    }
    if (err.message === 'You can only delete your own account.') {
        return res.status(403).json({ error: err.message });
    }
    if (err.message === 'You can only update your own questions.') {
        return res.status(403).json({ error: err.message });
    }
    if (err.message === 'You can only delete your own questions.') {
        return res.status(403).json({ error: err.message });
    }
    if (err.message === "Database table 'quizzes' not found. Please create it.") {
        return res.status(500).json({ error: err.message });
    }
    if (err.message === 'Quiz not found.') {
        return res.status(404).json({ error: err.message });
    }
    if (err.message === 'Recipient user not found.') {
        return res.status(404).json({ error: err.message });
    }
    if (err.message === 'Forbidden: Requires admin privileges.') {
        return res.status(403).json({ error: err.message });
    }
    if (err.message === 'Failed to get Kopo Kopo Access Token') {
        return res.status(500).json({ error: err.message });
    }
    if (err.message === 'Failed to initiate STK Push') {
        return res.status(500).json({ error: err.message });
    }
    if (err.message === 'Invalid webhook data.') {
        return res.status(400).json({ error: err.message });
    }

    // Default to 500 server error
    res.status(500).json({ error: 'An unexpected error occurred.' });
};

module.exports = errorHandler;

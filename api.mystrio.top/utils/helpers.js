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
        email: user.email,
        chosen_question_text: user.chosen_question_text,
        chosen_question_style_id: user.chosen_question_style_id,
        profile_image_path: user.profile_image_path,
        premium_until: user.premium_until ? new Date(user.premium_until).toISOString() : null, // Format as ISO string
        is_admin: user.is_admin, // NEW: Include admin status
    });
    return formattedUser;
};

module.exports = {
    toCamelCase,
    formatUserForResponse
};

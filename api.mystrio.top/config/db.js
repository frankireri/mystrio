const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'mystrio',
    password: process.env.DB_PASSWORD || '@Franko09',
    database: process.env.DB_DATABASE || 'mystrio'
};

module.exports = dbConfig;

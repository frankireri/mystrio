const request = require('supertest');
const app = require('../server');
describe('Auth Endpoints', () => {
    let connection;

    beforeAll(async () => {
        const mysql = require('mysql2/promise');
        const dbConfig = require('../config/db');
        // Use a separate connection to create the database if it doesn't exist
        const rootConnection = await mysql.createConnection({
            host: dbConfig.host,
            user: "root", // Use a user with CREATE DATABASE privileges
            password: "your_actual_root_password" // Replace with your root password
        });
        await rootConnection.execute(`CREATE DATABASE IF NOT EXISTS \`${dbConfig.database}\`;`);
        await rootConnection.end();

        // Establish connection to the test database
        connection = await mysql.createConnection(dbConfig);
        
        // Drop and recreate the users table for a clean state
        await connection.execute('DROP TABLE IF EXISTS users;');
        await connection.execute(`
            CREATE TABLE users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(255) NOT NULL UNIQUE,
                email VARCHAR(255) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                chosen_question_text TEXT,
                chosen_question_style_id INT,
                profile_image_path VARCHAR(255),
                premium_until DATETIME,
                is_admin BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            );
        `);
    });

    afterAll(async () => {
        // Close the database connection
        if (connection) {
            await connection.end();
        }
    });

    it('should register a new user', async () => {
        const res = await request(app)
            .post('/api/signup')
            .send({
                username: 'testuser_signup',
                email: 'test@example.com',
                password: 'password123',
                chosenQuestionText: 'What is your favorite color?',
                chosenQuestionStyleId: 1,
                profileImagePath: null
            });
        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('token');
        expect(res.body.user.email).toEqual('test@example.com');
    });

    it('should login an existing user', async () => {
        const res = await request(app)
            .post('/api/login')
            .send({
                email: 'test@example.com',
                password: 'password123'
            });
        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('token');
        expect(res.body.user.email).toEqual('test@example.com');
    });
});

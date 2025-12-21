const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');

const { JWT_SECRET } = require('../config/constants');
const dbConfig = require('../config/db');

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

const authenticateAdmin = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, async (err, user) => {
    if (err) return res.sendStatus(403);

    let connection;
    try {
      connection = await mysql.createConnection(dbConfig);
      const [rows] = await connection.execute('SELECT is_admin FROM users WHERE id = ?', [user.id]);

      if (rows.length === 0 || !rows[0].is_admin) {
        return res.status(403).json({ error: 'Forbidden: Requires admin privileges.' });
      }

      req.user = user;
      next();
    } catch (error) {
      console.error('Admin authentication error:', error);
      res.status(500).json({ error: 'Failed to verify admin status.' });
    } finally {
      if (connection) await connection.end();
    }
  });
};

const authenticateAdmin = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, async (err, user) => {
    if (err) return res.sendStatus(403);

    let connection;
    try {
      connection = await mysql.createConnection(dbConfig);
      const [rows] = await connection.execute('SELECT is_admin FROM users WHERE id = ?', [user.id]);

      if (rows.length === 0 || !rows[0].is_admin) {
        return res.status(403).json({ error: 'Forbidden: Requires admin privileges.' });
      }

      req.user = user;
      next();
    } catch (error) {
      console.error('Admin authentication error:', error);
      res.status(500).json({ error: 'Failed to verify admin status.' });
    } finally {
      if (connection) await connection.end();
    }
  });
};

const isPremium = async (req, res, next) => {
    // This middleware assumes authenticateToken has already run and req.user is set
    if (!req.user || !req.user.id) {
        return res.status(401).json({ error: 'Authentication required.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT premium_until FROM users WHERE id = ?', [req.user.id]);

        if (rows.length === 0 || rows[0].premium_until == null || new Date(rows[0].premium_until) < new Date()) {
            return res.status(403).json({ error: 'Premium subscription required.' });
        }

        next();
    } catch (error) {
        console.error('Premium status check error:', error);
        res.status(500).json({ error: 'Failed to verify premium status.' });
    } finally {
        if (connection) await connection.end();
    }
};

module.exports = {
  authenticateToken,
  authenticateAdmin,
  isPremium
};

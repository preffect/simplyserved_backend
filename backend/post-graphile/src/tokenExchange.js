const jwt = require("jsonwebtoken");
const { Pool } = require('pg');
const { verifyGoogleToken } = require('./googleAuth.js');

// Create a PostgreSQL connection pool
const pool = new Pool({
  connectionString: `postgres://${process.env.DATABASE_MIGRATE_USER}:${process.env.DATABASE_MIGRATE_PASSWORD}@postgres:5432/${process.env.APPLICATION_DB}`
});

/**
 * Handles token exchange requests
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function handleTokenExchange(req, res) {
  try {
    const authHeader = req.headers["authorization"];
    
    if (!authHeader) {
      return res.status(400).json({ error: 'Authorization header is required' });
    }
    
    const token = authHeader.split(" ")[1]; // Extract Bearer token
    
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }
    
    // Verify the Google token
    const googlePayload = await verifyGoogleToken(token);
    
    if (!googlePayload || !googlePayload.email) {
      return res.status(401).json({ error: 'Invalid Google token' });
    }
    
    // Query the database for the user by email
    const result = await pool.query(
      'SELECT id, email FROM users WHERE email = $1',
      [googlePayload.email]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    
    // Create a custom JWT
    const customToken = jwt.sign(
      { 
        current_user: user.id,
        email: user.email,
        sub: googlePayload.sub,
        name: googlePayload.name,
        aud: "postgraphile"
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({ token: customToken });
  } catch (error) {
    console.error('Token exchange error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

module.exports = {
  handleTokenExchange
};

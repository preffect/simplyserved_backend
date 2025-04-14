const { Pool } = require('pg');

// Create a PostgreSQL connection pool
const pool = new Pool({
  connectionString: `postgres://${process.env.DATABASE_MIGRATE_USER}:${process.env.DATABASE_MIGRATE_PASSWORD}@postgres:5432/${process.env.APPLICATION_DB}`
});

/**
 * Check if a user exists and get their organization
 * @param {string} email - User email address
 * @returns {Promise<Object>} - User and organization information
 */
async function checkUserOrganization(email) {
  try {
    const result = await pool.query(
      'SELECT id, organization_id FROM app_user WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return { appUserId: null, organizationId: null };
    }
    
    const user = result.rows[0];
    return { 
      appUserId: user.id, 
      organizationId: user.organization_id 
    };
  } catch (error) {
    console.error('Error checking user organization:', error);
    throw error;
  }
}

/**
 * Create a new organization and user
 * @param {Object} organizationData - Organization data
 * @param {Object} userData - User data
 * @returns {Promise<Object>} - Created organization and user
 */
async function createOrganization(organizationData, userData) {
  const client = await pool.connect();
  
  try {
    // Start transaction
    await client.query('BEGIN');
    
    // Create organization
    const orgResult = await client.query(
      'INSERT INTO organization (name, description) VALUES ($1, $2) RETURNING id, name, description',
      [organizationData.name, organizationData.description]
    );
    
    const organization = orgResult.rows[0];

    // Log organization details
    console.log('Created organization:', organization);
    
    // Set request.jwt.claims postgres local for the current organization to 
    // the newly created organization
    await client.query(
      'SET LOCAL request.jwt.claims = \'' +
      JSON.stringify({ current_organization_id: organization.id }) + '\''
    );

    // Create user with organization_id and role='owner'
    const userResult = await client.query(
      'INSERT INTO app_user (email, organization_id, role) VALUES ($1, $2, $3) RETURNING id, email, organization_id, role',
      [userData.email, organization.id, 'owner']
      // 'INSERT INTO app_user (first_name, last_name, email, organization_id, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, first_name, last_name, email, organization_id, role',
      // [userData.first_name, userData.last_name, userData.email, organization.id, 'owner']
    );
    
    const user = userResult.rows[0];

    // Log user details
    console.log('Created user:', user);
    
    // Commit transaction
    await client.query('COMMIT');
    
    return {
      organization,
      user
    };
  } catch (error) {
    // Rollback transaction on error
    await client.query('ROLLBACK');
    console.error('Error creating organization:', error);
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Handle check user organization request
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function handleCheckUserOrganization(req, res) {
  try {
    if (!req.jwtClaims || !req.jwtClaims.email) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    const result = await checkUserOrganization(req.jwtClaims.email);
    res.json(result);
  } catch (error) {
    console.error('Check user organization error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

/**
 * Handle create organization request
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function handleCreateOrganization(req, res) {
  try {
    if (!req.jwtClaims || !req.jwtClaims.email) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    // Check if user already exists
    const userCheck = await checkUserOrganization(req.jwtClaims.email);
    
    if (userCheck.appUserId) {
      return res.status(400).json({ 
        error: 'User already exists',
        appUserId: userCheck.appUserId,
        organizationId: userCheck.organizationId
      });
    }
    
    // Validate request body
    const { organization, appUser } = req.body;
    
    if (!organization || !organization.name || !appUser || !appUser.email) {
      return res.status(400).json({ error: 'Invalid request body' });
    }
    
    // Ensure email from token matches request
    if (appUser.email !== req.jwtClaims.email) {
      return res.status(400).json({ error: 'Email mismatch between token and request' });
    }
    
    // Create organization and user
    const result = await createOrganization(organization, appUser);
    
    res.status(201).json(result);
  } catch (error) {
    console.error('Create organization error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

module.exports = {
  checkUserOrganization,
  createOrganization,
  handleCheckUserOrganization,
  handleCreateOrganization
};

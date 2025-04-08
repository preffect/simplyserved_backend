const express = require('express');
const { postgraphile, withPostGraphileContext } = require('postgraphile');
const PgSimplifyInflectorPlugin = require('@graphile-contrib/pg-simplify-inflector');
const jwt = require("jsonwebtoken");
const { googleAuthMiddleware, verifyGoogleToken } = require('./googleAuth.js');
const { corsMiddleware } = require('./corsConfig.js');
const { Pool } = require('pg');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET;

// Create a PostgreSQL connection pool
const pool = new Pool({
  connectionString: `postgres://${process.env.DATABASE_MIGRATE_USER}:${process.env.DATABASE_MIGRATE_PASSWORD}@postgres:5432/${process.env.APPLICATION_DB}`
});

// Apply CORS middleware
app.use(corsMiddleware);

// Parse JSON request bodies
app.use(express.json());

app.use(googleAuthMiddleware);

// Token exchange endpoint
app.post('/token-exchange', async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({ error: 'Token is required' });
    }
    
    // Verify the Google token
    const googlePayload = await verifyGoogleToken(token);
    
    if (!googlePayload || !googlePayload.email) {
      return res.status(401).json({ error: 'Invalid Google token' });
    }
    
    // Query the database for the user by email
    const result = await pool.query(
      'SELECT id, email FROM public.user WHERE email = $1',
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
        name: googlePayload.name
      },
      JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({ token: customToken });
  } catch (error) {
    console.error('Token exchange error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Secret for signing/verifying JWTs


// const jwt = require("express-jwt");
// const jwksRsa = require("jwks-rsa");

// // ...

// // Authentication middleware. When used, the
// // Access Token must exist and be verified against
// // the Auth0 JSON Web Key Set.
// // On successful verification, the payload of the
// // decrypted Access Token is appended to the
// // request (`req`) as a `user` parameter.
// const checkJwt = jwt({
//   // Dynamically provide a signing key
//   // based on the `kid` in the header and
//   // the signing keys provided by the JWKS endpoint.
//   secret: jwksRsa.expressJwtSecret({
//     cache: true,
//     rateLimit: true,
//     jwksRequestsPerMinute: 5,
//     jwksUri: `https://YOUR_DOMAIN/.well-known/jwks.json`,
//   }),

//   // Validate the audience and the issuer.
//   audience: "YOUR_API_IDENTIFIER",
//   issuer: `https://YOUR_DOMAIN/`,
//   algorithms: ["RS256"],
// });
const pgSettings = (req) => ({
  "app.current_tenant": req.jwtClaims?.current_tenant || null,
  "app.current_user": req.jwtClaims?.current_user || null,
//  role: req.jwtClaims?.role || "anonymous",
});

// Construct the connection string using environment variables
const DATABASE_APP_URL = `postgres://${process.env.DATABASE_MIGRATE_USER}:${process.env.DATABASE_MIGRATE_PASSWORD}@postgres:5432/${process.env.APPLICATION_DB}`;

// Add PostGraphile middleware to Express
app.use(
  postgraphile(
    DATABASE_APP_URL,
    'public',
    {
      watchPg: true,
      graphiql: true,
      enhanceGraphiql: true,
      allowExplain: true,
      simpleCollections: 'only',
      exportGqlSchemaPath: '/app/schema/schema.graphql',
      sortExport: true,
      queryDepthLimit: 7,
      appendPlugins: [PgSimplifyInflectorPlugin],
      enableCors: false, // Disable PostGraphile's built-in CORS handling
      // jwtTokenIdentifier: 'simplyserved.jwt_token',
      // jwtSecret: JWT_SECRET,
      graphileBuildOptions: {
        pgOmitListSuffix: true, // Omit the "List" suffix from simple collections
        pgSimplifyPatch: true,          // Use "patch" instead of "userPatch" in updates
        pgSimplifyAllRows: true,        // Keep "allUsers" instead of simplifying to "users"
        pgShortPk: false,                 // Add "ById" suffix for primary key queries/mutations
      },
      pgSettings: pgSettings
    }
  )
);

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express with PostGraphile server running on port ${PORT}`);
});

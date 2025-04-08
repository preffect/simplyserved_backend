const express = require('express');
const { postgraphile } = require('postgraphile');
const PgSimplifyInflectorPlugin = require('@graphile-contrib/pg-simplify-inflector');
const { googleAuthMiddleware } = require('./googleAuth.js');
const { corsMiddleware } = require('./corsConfig.js');
const { handleTokenExchange } = require('./tokenExchange.js');
const { configureTLS } = require('./tlsConfig.js');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET;

// Apply CORS middleware
app.use(corsMiddleware);

// Token exchange endpoint with Google Auth middleware
app.post('/token-exchange', googleAuthMiddleware, express.json(), handleTokenExchange);

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

// Start the server with TLS if certificates are available
configureTLS(app, PORT);

const express = require('express');
const cors = require('cors');
const { postgraphile } = require('postgraphile');
const PgSimplifyInflectorPlugin = require('@graphile-contrib/pg-simplify-inflector');
const jwt = require("jsonwebtoken");
const { googleAuthMiddleware } = require('./googleAuth');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Configure CORS for specific origin
const corsOptions = {
  origin: 'http://conan-devbox3.westus3.cloudapp.azure.com',
  methods: ['GET', 'POST', 'HEAD'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Accept',
    'Authorization',
    'X-Apollo-Tracing',
    'Content-Type',
    'Content-Length',
    'X-PostGraphile-Explain'
  ],
  exposedHeaders: ['X-GraphQL-Event-Stream']
};

// Apply CORS middleware
app.use(cors(corsOptions));

// Secret for signing/verifying JWTs
const JWT_SECRET = process.env.JWT_SECRET;


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

app.use(googleAuthMiddleware);

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

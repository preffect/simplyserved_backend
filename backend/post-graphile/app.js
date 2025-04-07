const express = require('express');
const cors = require('cors');
const { postgraphile } = require('postgraphile');
const PgSimplifyInflectorPlugin = require('@graphile-contrib/pg-simplify-inflector');

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
      appendPlugins: [PgSimplifyInflectorPlugin],
      enableCors: false, // Disable PostGraphile's built-in CORS handling
    }
  )
);

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express with PostGraphile server running on port ${PORT}`);
});

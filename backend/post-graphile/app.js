const express = require('express');
const { postgraphile } = require('postgraphile');
const PgSimplifyInflectorPlugin = require('@graphile-contrib/pg-simplify-inflector');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Construct the connection string using environment variables
const DATABASE_APP_URL = `postgres://${process.env.DATABASE_MIGRATE_USER}:${process.env.DATABASE_MIGRATE_PASSWORD}@postgres:5432/${process.env.APPLICATION_DB}`;

// const allowedOriginPlugin = require('./allowedOriginPlugin');
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
      // appendPlugins: [PgSimplifyInflectorPlugin, allowedOriginPlugin],
      enableCors: true,
    }
  )
);

// Uncomment to use the allowed origin plugin
//app.use(allowedOriginPlugin());

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express with PostGraphile server running on port ${PORT}`);
});

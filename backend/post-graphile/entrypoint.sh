#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Construct the connection string using environment variables
DATABASE_APP_URL="postgres://${DATABASE_MIGRATE_USER}:${DATABASE_MIGRATE_PASSWORD}@postgres:5432/${APPLICATION_DB}"

echo "Starting PostGraphile in watch mode..."

# Start PostGraphile in watch mode
exec postgraphile \
  --connection "$DATABASE_APP_URL" \
  --host 0.0.0.0 \
  --port 5000 \
  --schema public \
  --watch \
  --enhance-graphiql \
  --allow-explain \
  --simple-collections only \
  --export-schema-graphql /app/schema/schema.graphql \
  --sort-export \
  --append-plugins @graphile-contrib/pg-simplify-inflector \
  --cors
  # --append-plugins `pwd`/allowedOriginPlugin.js


#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Construct the connection string using environment variables
DATABASE_APP_URL="postgres://${DATABASE_APP_USER}:${DATABASE_APP_PASSWORD}@postgres:5432/${POSTGRES_DB}"

# Start PostGraphile in watch mode
exec postgraphile \
  --connection "$DATABASE_APP_URL" \
  --port 5000 \
  --schema public \
  --watch \
  --enhance-graphiql \
  --allow-explain \
  --export-schema-graphql /app/schema/schema.graphql

#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Start PostGraphile in watch mode
exec postgraphile \
  --connection "$DATABASE_URL" \
  --port 5000 \
  --schema public \
  --watch \
  --enhance-graphiql \
  --allow-explain \
  --export-schema-graphql /app/schema/schema.graphql

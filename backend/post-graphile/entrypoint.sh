#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

echo "Starting PostGraphile with Express..."

# Start the Express app
exec node /app/app.js


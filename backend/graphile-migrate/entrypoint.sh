#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Initialize graphile-migrate if not already initialized
if [ ! -f /app/migrations/current.sql ]; then
  echo "Initializing graphile-migrate..."
  graphile-migrate init
fi

# Keep container running
tail -f /dev/null

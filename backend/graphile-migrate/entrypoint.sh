#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Check if migrations directory is empty (except for hidden files)
if [ ! "$(ls -A /app/migrations 2>/dev/null | grep -v '^\.')" ]; then
  echo "Migrations directory is empty, initializing graphile-migrate..."
  graphile-migrate init
else
  echo "Migrations directory already exists, skipping initialization..."
fi

# Keep container running
tail -f /dev/null

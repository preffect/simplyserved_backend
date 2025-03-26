#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Copy the .gmrc file to the app directory if it doesn't exist
if [ ! -f "/app/.gmrc" ]; then
  echo "Copying .gmrc file to /app directory"
  cp /.gmrc /app/.gmrc
fi

# Check if migrations directory exists and is empty
if [ -d "/app/migrations" ]; then
  if [ ! "$(ls -A /app/migrations 2>/dev/null | grep -v '^\.')" ]; then
    echo "Migrations directory exists but is empty, initializing graphile-migrate..."
    # Create necessary SQL files
    mkdir -p /app/migrations
    touch /app/migrations/afterReset.sql
    touch /app/migrations/afterAllMigrations.sql
    touch /app/migrations/afterCurrent.sql
    
    echo "Migration structure created in /app/migrations"
  else
    echo "Migrations directory already contains files, skipping initialization..."
  fi
else
  echo "Migrations directory doesn't exist, creating structure..."
  mkdir -p /app/migrations
  touch /app/migrations/afterReset.sql
  touch /app/migrations/afterAllMigrations.sql
  touch /app/migrations/afterCurrent.sql
fi

# Keep container running
tail -f /dev/null

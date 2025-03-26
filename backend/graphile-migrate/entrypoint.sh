#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Check if migrations directory exists and is empty
if [ -d "/app/migrations" ]; then
  if [ ! "$(ls -A /app/migrations 2>/dev/null | grep -v '^\.')" ]; then
    echo "Migrations directory exists but is empty, initializing graphile-migrate..."
    # Create a temporary directory for initialization
    mkdir -p /tmp/migrations_init
    cd /tmp/migrations_init
    
    # Initialize graphile-migrate in the temporary directory
    graphile-migrate init
    
    # Copy the initialization files to the actual migrations directory
    cp -r ./* /app/migrations/
    cp .gmrc /app/
    
    echo "Initialization files copied to /app/migrations"
  else
    echo "Migrations directory already contains files, skipping initialization..."
  fi
else
  echo "Migrations directory doesn't exist, creating and initializing..."
  mkdir -p /app/migrations
  cd /app
  graphile-migrate init
fi

# Keep container running
tail -f /dev/null

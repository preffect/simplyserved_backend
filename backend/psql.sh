#!/bin/bash

# Load environment variables from .env file
if [ -f "./.env" ]; then
  source ./.env
else
  echo "Error: .env file not found"
  exit 1
fi

# Connect to PostgreSQL using the migrate user
PGPASSWORD=$DATABASE_MIGRATE_PASSWORD docker exec -it $(docker ps -qf "name=backend-postgres-1$") psql -U $DATABASE_MIGRATE_USER -d $APPLICATION_DB

echo "Connected to PostgreSQL as $DATABASE_MIGRATE_USER"

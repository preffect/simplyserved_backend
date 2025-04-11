#!/bin/sh

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until nc -z postgres 5432; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done
echo "PostgreSQL is up - starting token-exchange service"

# Start the application
npm start

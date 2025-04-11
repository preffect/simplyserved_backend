#!/bin/sh

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

echo "PostgreSQL is up - starting token-exchange service"

# Start the application
node src/app.js

#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

echo "Starting PostgREST..."

# Replace environment variables in the config file
env_vars=$(env | grep -E '^(DATABASE_|APPLICATION_|JWT_)' | cut -d= -f1)
for var in $env_vars; do
  value=$(eval echo \$$var)
  sed -i "s/\$(${var})/${value}/g" /etc/postgrest.conf
done

# Start PostgREST
exec postgrest /etc/postgrest.conf

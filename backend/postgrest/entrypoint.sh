#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

echo "Starting PostgREST..."

# Start PostgREST
exec postgrest /etc/postgrest.conf

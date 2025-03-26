#!/bin/sh
# wait-for-postgres.sh

set -e

# Extract connection details from DATABASE_MIGRATE_URL
DB_HOST=$(echo $DATABASE_MIGRATE_URL | sed -n 's/.*@\([^:]*\).*/\1/p')
DB_USER=$(echo $DATABASE_MIGRATE_URL | sed -n 's/postgres:\/\/\([^:]*\).*/\1/p')
DB_PASSWORD=$(echo $DATABASE_MIGRATE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\).*/\1/p')
DB_NAME=$(echo $DATABASE_MIGRATE_URL | sed -n 's/.*\/\(.*\)$/\1/p')

until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

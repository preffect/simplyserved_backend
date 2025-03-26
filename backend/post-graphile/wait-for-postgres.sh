#!/bin/sh
# wait-for-postgres.sh

set -e

until PGPASSWORD="$DATABASE_APP_PASSWORD" psql -h postgres -p 5432 -U "$DATABASE_APP_USER" -d "$POSTGRES_DB" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

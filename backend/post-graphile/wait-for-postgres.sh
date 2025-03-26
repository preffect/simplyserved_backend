#!/bin/sh
# wait-for-postgres.sh

set -e

until psql -h $DATABASE_HOST -U "$DATABASE_APP_USER" -d "$DATABASE_APP_PASSWORD" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

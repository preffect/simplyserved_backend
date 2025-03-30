#!/bin/bash
set -e

host="postgres"
user="${POSTGRES_USER:-postgres}"
password="${POSTGRES_PASSWORD:-postgres}"
db="${POSTGRES_DB:-simplyserved}"

until PGPASSWORD=$password psql -h "$host" -U "$user" -d "$db" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

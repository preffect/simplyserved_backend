#!/bin/sh
# wait-for-postgres.sh

set -e

until PGPASSWORD="$DATABASE_APP_PASSWORD" psql -h postgres -p 5432 -U "$DATABASE_APP_USER" -d "$APPLICATION_DB" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"
#!/bin/sh
# wait-for-postgres.sh

set -e

host="postgres"
port="5432"
user="${DATABASE_MIGRATE_USER:-simplyserved_migrate}"
password="${DATABASE_MIGRATE_PASSWORD:-Ip4*Le38jadnf328}"
db="${APPLICATION_DB:-simplyserved}"

echo "Waiting for PostgreSQL..."

until PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$db" -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up"

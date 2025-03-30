#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
/app/wait-for-postgres.sh

# Execute the command passed to docker run
if [ "$1" = "apply" ]; then
  /app/migrate.sh apply
elif [ "$1" = "status" ]; then
  /app/migrate.sh status
elif [ "$1" = "create" ]; then
  /app/migrate.sh create "$2"
elif [ "$1" = "test" ]; then
  /app/migrate.sh test
elif [ "$1" = "rebuild-sandbox" ]; then
  /app/migrate.sh rebuild-sandbox
elif [ "$1" = "init" ]; then
  /app/migrate.sh init
elif [ "$1" = "help" ] || [ -z "$1" ]; then
  echo "Available commands:"
  echo "  apply           - Test migrations in sandbox then apply to main database"
  echo "  status          - Show migration status"
  echo "  create          - Create a new migration (requires name argument)"
  echo "  test            - Test migrations in sandbox database and report results"
  echo "  rebuild-sandbox - Recreate sandbox database and apply all migrations"
  echo "  init            - Initialize main and sandbox databases"
  echo "  help            - Show this help message"
else
  echo "Unknown command: $1"
  exit 1
fi

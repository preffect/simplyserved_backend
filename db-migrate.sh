#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print usage information
usage() {
  echo -e "${GREEN}Database Migration Tool${NC}"
  echo "Usage: $0 COMMAND [ARGS]"
  echo ""
  echo "Commands:"
  echo "  apply                Apply all pending migrations (tests in sandbox first)"
  echo "  status               Show migration status"
  echo "  create NAME          Create a new migration with NAME"
  echo "  test                 Test migrations in sandbox and report results"
  echo "  rebuild-sandbox      Recreate sandbox database with all migrations"
  echo "  help                 Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 status"
  echo "  $0 create add_users_table"
  echo "  $0 test"
  echo "  $0 apply"
}

# Ensure the migrations directory exists
ensure_migrations_dir() {
  mkdir -p ./backend/database/migrations
}

# Main command handler
case "$1" in
  apply)
    ensure_migrations_dir
    echo -e "${YELLOW}Applying pending migrations...${NC}"
    docker compose run --rm db-migrator apply
    ;;
  status)
    ensure_migrations_dir
    echo -e "${YELLOW}Checking migration status...${NC}"
    docker compose run --rm db-migrator status
    ;;
  create)
    if [ -z "$2" ]; then
      echo "Error: Migration name is required"
      echo "Usage: $0 create NAME"
      exit 1
    fi
    ensure_migrations_dir
    echo -e "${YELLOW}Creating new migration: $2${NC}"
    docker compose run --rm db-migrator create "$2"
    ;;
  test)
    ensure_migrations_dir
    echo -e "${YELLOW}Testing migrations in sandbox...${NC}"
    docker compose run --rm db-migrator test
    ;;
  rebuild-sandbox)
    ensure_migrations_dir
    echo -e "${YELLOW}Rebuilding sandbox database...${NC}"
    docker compose run --rm db-migrator rebuild-sandbox
    ;;
  help|"")
    usage
    ;;
  *)
    echo "Unknown command: $1"
    usage
    exit 1
    ;;
esac

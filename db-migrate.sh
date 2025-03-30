#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if db-migrator files have changed and rebuild if necessary
check_rebuild_container() {
  echo -e "${YELLOW}Checking if db-migrator needs rebuilding...${NC}"
  
  # Get the last modified time of the db-migrator files
  local last_modified=$(find ./backend/db-migrator -type f -exec stat -c "%Y" {} \; | sort -nr | head -n1)
  
  # Get the creation time of the db-migrator container if it exists
  local container_id=$(docker ps -aq --filter name=db-migrator)
  local container_created=0
  
  if [ -n "$container_id" ]; then
    container_created=$(docker inspect -f '{{.Created}}' "$container_id" | date -f - +%s)
  fi
  
  # If the container doesn't exist or files were modified after container creation, rebuild
  if [ -z "$container_id" ] || [ "$last_modified" -gt "$container_created" ]; then
    echo -e "${YELLOW}Rebuilding db-migrator container...${NC}"
    docker compose build db-migrator
    echo -e "${GREEN}Container rebuilt successfully${NC}"
  else
    echo -e "${GREEN}No changes detected, using existing container${NC}"
  fi
}

# Main command handler
case "$1" in
  apply)
    ensure_migrations_dir
    check_rebuild_container
    echo -e "${YELLOW}Applying pending migrations...${NC}"
    docker compose run --rm db-migrator apply
    ;;
  status)
    ensure_migrations_dir
    check_rebuild_container
    echo -e "${YELLOW}Checking migration status...${NC}"
    docker compose run --rm db-migrator status
    ;;
  create)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Migration name is required${NC}"
      echo "Usage: $0 create NAME"
      exit 1
    fi
    ensure_migrations_dir
    check_rebuild_container
    echo -e "${YELLOW}Creating new migration: $2${NC}"
    docker compose run --rm db-migrator create "$2"
    ;;
  test)
    ensure_migrations_dir
    check_rebuild_container
    echo -e "${YELLOW}Testing migrations in sandbox...${NC}"
    docker compose run --rm db-migrator test
    ;;
  rebuild-sandbox)
    ensure_migrations_dir
    check_rebuild_container
    echo -e "${YELLOW}Rebuilding sandbox database...${NC}"
    docker compose run --rm db-migrator rebuild-sandbox
    ;;
  help|"")
    usage
    ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    usage
    exit 1
    ;;
esac

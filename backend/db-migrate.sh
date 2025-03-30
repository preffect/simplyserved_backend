#!/bin/bash
set -e

# Colors and symbols for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
INFO="ℹ️"

# Check if docker compose is installed
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ docker compose is not installed. Please install it first.${NC}"
    exit 1
fi

# Print usage information if no arguments provided
if [ $# -eq 0 ]; then
    echo "Database Migration Tool"
    echo ""
    echo "Usage: $0 COMMAND"
    echo ""
    echo "Commands:"
    echo "  apply                Apply all pending migrations (tests in sandbox first)"
    echo "  status               Show migration status"
    echo "  create NAME          Create a new migration with NAME"
    echo "  test                 Test migrations in sandbox and report results"
    echo "  rebuild-sandbox      Recreate sandbox database with all migrations"
    echo "  init                 Initialize sandbox database, and the migrations table in the application database and the sandbox database"
    echo "  help                 Show this help message"
    exit 1
fi

# Ensure the postgres service is running
echo -e "${INFO} Ensuring postgres service is available..."
if ! docker compose ps postgres | grep -q "Up"; then
    echo -e "${INFO} Starting postgres service..."
    docker compose up -d postgres
    
    # Wait for postgres to be ready
    echo -e "${INFO} Waiting for postgres to be ready..."
    sleep 5
fi

# Run the db-migrator container with the command
echo -e "${INFO} Executing command: $@"
docker compose run --rm db-migrator /app/scripts/migrator.sh "$@"

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
    echo "  rollback             Roll back the last applied migration"
    echo "  test                 Test migrations in sandbox and report results"
    echo "  rebuild-sandbox      Recreate sandbox database with all migrations"
    echo "  init                 Initialize sandbox database, and the migrations table in the application database and the sandbox database"
    echo "  apply-sandbox        Apply the next pending migration to the sandbox database"
    echo "  rollback-sandbox     Roll back the last applied migration in the sandbox database"
    echo "  help                 Show this help message"
    exit 1
fi

# Check if db-migrator needs to be rebuilt
REBUILD_NEEDED=false
LAST_BUILD_FILE=".db_migrator_last_build"
HASH_FILE=".db_migrator_hashes"

# Create the files if they don't exist
if [ ! -f "$LAST_BUILD_FILE" ]; then
    touch "$LAST_BUILD_FILE"
    REBUILD_NEEDED=true
fi

if [ ! -f "$HASH_FILE" ]; then
    touch "$HASH_FILE"
    REBUILD_NEEDED=true
fi

# Check if any files in the db-migrator directory have changed since last build
LAST_BUILD_TIME=$(stat -c %Y "$LAST_BUILD_FILE" 2>/dev/null || echo 0)
LATEST_CHANGE=$(find ./backend/db-migrator -type f -exec stat -c %Y {} \; | sort -nr | head -n 1 2>/dev/null || echo 0)

# Check specific files by hash
DOCKERFILE_PATH="./backend/db-migrator/Dockerfile"
MIGRATOR_SCRIPT_PATH="./backend/db-migrator/scripts/migrator.sh"

# Function to calculate file hash
calculate_hash() {
    if [ -f "$1" ]; then
        md5sum "$1" | awk '{print $1}'
    else
        echo "file_not_found"
    fi
}

# Calculate current hashes
CURRENT_DOCKERFILE_HASH=$(calculate_hash "$DOCKERFILE_PATH")
CURRENT_MIGRATOR_HASH=$(calculate_hash "$MIGRATOR_SCRIPT_PATH")

# Read previous hashes
PREV_DOCKERFILE_HASH=$(grep "^dockerfile:" "$HASH_FILE" 2>/dev/null | cut -d':' -f2 || echo "")
PREV_MIGRATOR_HASH=$(grep "^migrator:" "$HASH_FILE" 2>/dev/null | cut -d':' -f2 || echo "")

# Check if hashes have changed
if [ "$CURRENT_DOCKERFILE_HASH" != "$PREV_DOCKERFILE_HASH" ] && [ "$CURRENT_DOCKERFILE_HASH" != "file_not_found" ]; then
    echo -e "${INFO} Changes detected in Dockerfile. Rebuilding container..."
    REBUILD_NEEDED=true
fi

if [ "$CURRENT_MIGRATOR_HASH" != "$PREV_MIGRATOR_HASH" ] && [ "$CURRENT_MIGRATOR_HASH" != "file_not_found" ]; then
    echo -e "${INFO} Changes detected in migrator.sh script. Rebuilding container..."
    REBUILD_NEEDED=true
fi

if [ "$LATEST_CHANGE" -gt "$LAST_BUILD_TIME" ]; then
    echo -e "${INFO} Changes detected in other db-migrator files. Rebuilding container..."
    REBUILD_NEEDED=true
fi

# Rebuild if needed
if [ "$REBUILD_NEEDED" = true ]; then
    echo -e "${INFO} Building db-migrator container..."
    docker compose build db-migrator
    
    # Update the hash file with new hashes
    echo "dockerfile:$CURRENT_DOCKERFILE_HASH" > "$HASH_FILE"
    echo "migrator:$CURRENT_MIGRATOR_HASH" >> "$HASH_FILE"
    
    # Update the last build timestamp
    touch "$LAST_BUILD_FILE"
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

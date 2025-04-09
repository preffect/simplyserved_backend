#!/bin/bash
set -e

# Check if name is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <organization_name> [description]"
    exit 1
fi

# Get parameters
ORG_NAME="$1"
ORG_DESCRIPTION="${2:-}"  # Use empty string if description not provided

# Load environment variables from .env file
if [ -f "./.env" ]; then
    source ./.env
else
    echo "Error: .env file not found in backend directory"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if postgres container is running
if ! docker ps | grep -q postgres; then
    echo "PostgreSQL container is not running. Starting it..."
    docker compose up -d postgres
    
    # Wait for container to be healthy
    echo "Waiting for PostgreSQL to be ready..."
    until docker compose ps postgres | grep -q "healthy"; do
        echo -n "."
        sleep 1
    done
    echo "PostgreSQL is ready!"
fi


SQL_COMMAND="SET jwt.claims.current_tenant_id = 'some-tenant-id';"
SQL_COMMAND="$SQL_COMMAND SET jwt.claims.current_user_id = 'some-user-id';"
# Create SQL command to insert organization
if [ -z "$ORG_DESCRIPTION" ]; then
    SQL_COMMAND="$SQL_COMMAND INSERT INTO organization (name) VALUES ('$ORG_NAME') RETURNING id;"
else
    SQL_COMMAND="$SQL_COMMAND INSERT INTO organization (name, description) VALUES ('$ORG_NAME', '$ORG_DESCRIPTION') RETURNING id;"
fi

# Execute SQL command in postgres container
echo "Creating organization '$ORG_NAME'..."
ORG_ID=$(docker compose exec -T postgres psql -U "$DATABASE_MIGRATE_USER" -d "$APPLICATION_DB" -t -c "$SQL_COMMAND" | tr -d '[:space:]')

if [ -z "$ORG_ID" ]; then
    echo "Error: Failed to create organization"
    exit 1
fi

echo "Organization created successfully!"
echo "Organization ID: $ORG_ID"
echo "Organization Name: $ORG_NAME"
if [ -n "$ORG_DESCRIPTION" ]; then
    echo "Description: $ORG_DESCRIPTION"
fi

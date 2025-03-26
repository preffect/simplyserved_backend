#!/bin/bash
set -e

# Function to check if build is needed
need_rebuild() {
    local service=$1
    local dockerfile_path=$2
    
    # Check if image exists
    if ! docker images | grep -q "${service}"; then
        echo "Image for $service doesn't exist. Build needed."
        return 0
    fi
    
    # Check if Dockerfile or related files have changed
    if [ -n "$(find $(dirname $dockerfile_path) -newer $(docker inspect --format='{{.Created}}' ${service}) -type f 2>/dev/null)" ]; then
        echo "Files for $service have changed. Rebuild needed."
        return 0
    fi
    
    return 1
}

# Check if any services need to be rebuilt
REBUILD=""

if need_rebuild "backend_postgres" "./backend/database/Dockerfile"; then
    REBUILD="$REBUILD postgres"
fi

if need_rebuild "backend_graphile-migrate" "./backend/graphile-migrate/Dockerfile"; then
    REBUILD="$REBUILD graphile-migrate"
fi

if need_rebuild "backend_postgraphile" "./backend/post-graphile/Dockerfile"; then
    REBUILD="$REBUILD postgraphile"
fi

# Rebuild services if needed
if [ -n "$REBUILD" ]; then
    echo "Rebuilding services: $REBUILD"
    docker compose build $REBUILD
fi

# Start all services
echo "Starting all services..."
docker compose up -d

echo "All services are running!"
echo "PostgreSQL: localhost:5432"
echo "GraphQL API: localhost:5000/graphql"

#!/bin/bash
set -e

# Default API service
API_SERVICE="postgrest"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --api)
      API_SERVICE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--api postgraphile|postgrest]"
      exit 1
      ;;
  esac
done

# Validate API service selection
if [[ "$API_SERVICE" != "postgraphile" && "$API_SERVICE" != "postgrest" ]]; then
  echo "Invalid API service: $API_SERVICE"
  echo "Valid options are: postgraphile, postgrest"
  exit 1
fi

echo "Selected API service: $API_SERVICE"

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

docker compose down

# Check if any services need to be rebuilt
REBUILD=""

if need_rebuild "backend_postgres" "./backend/database/Dockerfile"; then
    REBUILD="$REBUILD postgres"
fi

if need_rebuild "backend_token_exchange" "./backend/token-exchange/Dockerfile"; then
    REBUILD="$REBUILD token-exchange"
fi

if [[ "$API_SERVICE" == "postgraphile" ]] && need_rebuild "backend_postgraphile" "./backend/post-graphile/Dockerfile"; then
    REBUILD="$REBUILD postgraphile"
fi

if [[ "$API_SERVICE" == "postgrest" ]] && need_rebuild "backend_postgrest" "./backend/postgrest/Dockerfile"; then
    REBUILD="$REBUILD postgrest"
fi

if need_rebuild "backend_nginx" "./backend/nginx/Dockerfile"; then
    REBUILD="$REBUILD nginx"
fi

# Rebuild services if needed
if [ -n "$REBUILD" ]; then
    echo "Rebuilding services: $REBUILD"
    docker compose build $REBUILD
fi

# Start services
echo "Starting services with $API_SERVICE..."
docker compose up token-exchange postgres db-migrator $API_SERVICE nginx

echo "All services are running!"
echo "PostgreSQL: localhost:5432"
if [[ "$API_SERVICE" == "postgraphile" ]]; then
    echo "GraphQL API: localhost:5000/graphql"
else
    echo "REST API: localhost:3000"
    echo "SSL REST API: https://simplyserved.app:3001"
fi

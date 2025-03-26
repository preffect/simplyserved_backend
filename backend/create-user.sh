#!/bin/bash
set -e

# Check if username and password are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <username> <password> [--migrations]"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
MIGRATIONS=false

# Check if migrations flag is set
if [ "$#" -eq 3 ] && [ "$3" = "--migrations" ]; then
    MIGRATIONS=true
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

# Create SQL command based on migrations flag
if [ "$MIGRATIONS" = true ]; then
    SQL_COMMAND="CREATE USER $USERNAME WITH PASSWORD '$PASSWORD' SUPERUSER;"
else
    SQL_COMMAND="CREATE USER $USERNAME WITH PASSWORD '$PASSWORD'; GRANT ALL PRIVILEGES ON DATABASE simplyserved TO $USERNAME;"
fi

# Execute SQL command in postgres container
echo "Creating user $USERNAME..."
docker compose exec postgres psql -U postgres -d simplyserved -c "$SQL_COMMAND"

# Update .env file with new user credentials
if grep -q "^DATABASE_URL=" ./backend/.env; then
    # Replace existing DATABASE_URL
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgres://$USERNAME:$PASSWORD@postgres:5432/simplyserved|" ./backend/.env
else
    # Add new DATABASE_URL
    echo "DATABASE_URL=postgres://$USERNAME:$PASSWORD@postgres:5432/simplyserved" >> ./backend/.env
fi

echo "User $USERNAME created successfully and .env file updated."

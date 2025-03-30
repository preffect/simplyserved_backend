#!/bin/bash
set -e

MIGRATIONS_DIR="/migrations"
MIGRATIONS_TABLE="schema_migrations"
DB_HOST="postgres"
DB_USER="${DATABASE_MIGRATE_USER:-postgres}"
DB_PASSWORD="${DATABASE_MIGRATE_PASSWORD:-postgres}"
DB_NAME="${APPLICATION_DB:-simplyserved}"

# Ensure migrations directory exists
mkdir -p "$MIGRATIONS_DIR"

# Ensure migrations table exists
ensure_migrations_table() {
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
    CREATE TABLE IF NOT EXISTS $MIGRATIONS_TABLE (
      id SERIAL PRIMARY KEY,
      version VARCHAR(255) NOT NULL UNIQUE,
      name VARCHAR(255) NOT NULL,
      applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  "
}

# Get list of applied migrations
get_applied_migrations() {
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "
    SELECT version FROM $MIGRATIONS_TABLE ORDER BY version;
  " | tr -d ' '
}

# Get list of available migrations
get_available_migrations() {
  find "$MIGRATIONS_DIR" -name "*.sql" | sort | xargs -I{} basename {} .sql
}

# Apply a migration
apply_migration() {
  local version=$1
  local name=$(echo $version | cut -d'_' -f2-)
  
  echo "Applying migration: $version"
  
  # Execute the migration
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f "$MIGRATIONS_DIR/$version.sql"
  
  # Record the migration
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
    INSERT INTO $MIGRATIONS_TABLE (version, name) VALUES ('$version', '$name');
  "
  
  echo "Migration $version applied successfully"
}

# Create a new migration
create_migration() {
  local name=$1
  
  if [ -z "$name" ]; then
    echo "Error: Migration name is required"
    exit 1
  fi
  
  # Get current date in YYYYMMDD format
  local date_prefix=$(date +%Y%m%d)
  
  # Find the next available sequence number for today
  local seq=1
  while [ -f "$MIGRATIONS_DIR/${date_prefix}.$(printf "%03d" $seq)_$name.sql" ]; do
    seq=$((seq + 1))
  done
  
  # Create the migration file
  local version="${date_prefix}.$(printf "%03d" $seq)_$name"
  local filename="$MIGRATIONS_DIR/$version.sql"
  
  cat > "$filename" << EOF
-- Migration: $name
-- Created at: $(date -u +"%Y-%m-%d %H:%M:%S")

-- Write your migration SQL here

-- Up migration

-- Down migration (if needed)
-- To roll back, you would write the SQL to undo the changes here
EOF
  
  echo "Created new migration: $filename"
}

# Show migration status
show_status() {
  ensure_migrations_table
  
  echo "Migration Status:"
  echo "-----------------"
  
  local applied_migrations=$(get_applied_migrations)
  local available_migrations=$(get_available_migrations)
  
  if [ -z "$available_migrations" ]; then
    echo "No migrations found in $MIGRATIONS_DIR"
    return
  fi
  
  for migration in $available_migrations; do
    if echo "$applied_migrations" | grep -q "^$migration$"; then
      echo "[APPLIED] $migration"
    else
      echo "[PENDING] $migration"
    fi
  done
}

# Apply pending migrations
apply_migrations() {
  ensure_migrations_table
  
  local applied_migrations=$(get_applied_migrations)
  local available_migrations=$(get_available_migrations)
  
  if [ -z "$available_migrations" ]; then
    echo "No migrations found in $MIGRATIONS_DIR"
    return
  fi
  
  local pending_count=0
  
  for migration in $available_migrations; do
    if ! echo "$applied_migrations" | grep -q "^$migration$"; then
      apply_migration "$migration"
      pending_count=$((pending_count + 1))
    fi
  done
  
  if [ $pending_count -eq 0 ]; then
    echo "No pending migrations to apply"
  else
    echo "Applied $pending_count migrations"
  fi
}

# Main command handler
case "$1" in
  apply)
    apply_migrations
    ;;
  status)
    show_status
    ;;
  create)
    create_migration "$2"
    ;;
  *)
    echo "Usage: $0 {apply|status|create NAME}"
    exit 1
    ;;
esac

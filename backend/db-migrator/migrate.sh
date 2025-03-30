#!/bin/bash
set -e

MIGRATIONS_DIR="/migrations"
MIGRATIONS_TABLE="schema_migrations"
DB_HOST="postgres"
DB_USER="${DATABASE_MIGRATE_USER:-postgres}"
DB_PASSWORD="${DATABASE_MIGRATE_PASSWORD:-postgres}"
DB_NAME="${APPLICATION_DB:-simplyserved}"
SANDBOX_DB_NAME="${APPLICATION_DB}_sandbox"

# Ensure migrations directory exists
mkdir -p "$MIGRATIONS_DIR"

# Ensure migrations table exists
ensure_migrations_table() {
  local db=$1
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -c "
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
  local db=$1
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -t -c "
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
  local db=$2
  local name=$(echo $version | cut -d'_' -f2-)
  
  echo "Applying migration: $version to $db"
  
  # Execute the migration
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -f "$MIGRATIONS_DIR/$version.sql"
  
  # Record the migration
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -c "
    INSERT INTO $MIGRATIONS_TABLE (version, name) VALUES ('$version', '$name');
  "
  
  echo "Migration $version applied successfully to $db"
}

# Extract down migration from a migration file
extract_down_migration() {
  local version=$1
  local file="$MIGRATIONS_DIR/$version.sql"
  
  # Extract content between "-- Down migration" and the end of file
  local down_sql=$(sed -n '/-- Down migration/,$ p' "$file" | grep -v "^--" | grep -v "^$")
  
  if [ -z "$down_sql" ]; then
    echo "Warning: No down migration found in $file"
    return 1
  fi
  
  echo "$down_sql"
}

# Rollback a migration
rollback_migration() {
  local version=$1
  local db=$2
  
  echo "Rolling back migration: $version from $db"
  
  # Get the down migration SQL
  local down_sql=$(extract_down_migration "$version")
  
  if [ $? -ne 0 ]; then
    echo "Error: Could not extract down migration for $version"
    return 1
  fi
  
  # Execute the down migration
  echo "$down_sql" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db
  
  # Remove the migration record
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -c "
    DELETE FROM $MIGRATIONS_TABLE WHERE version = '$version';
  "
  
  echo "Migration $version rolled back successfully from $db"
}

# Create or recreate sandbox database
create_sandbox_db() {
  echo "Creating sandbox database: $SANDBOX_DB_NAME"
  
  # Connect to postgres database to manage other databases
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -c "
    DROP DATABASE IF EXISTS $SANDBOX_DB_NAME;
    CREATE DATABASE $SANDBOX_DB_NAME;
  "
  
  # Create migrations table in sandbox
  ensure_migrations_table "$SANDBOX_DB_NAME"
  
  echo "Sandbox database created successfully"
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
-- Add your schema changes here


-- Down migration
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks

EOF
  
  echo "Created new migration: $filename"
}

# Show migration status
show_status() {
  ensure_migrations_table "$DB_NAME"
  
  echo "Migration Status:"
  echo "-----------------"
  
  local applied_migrations=$(get_applied_migrations "$DB_NAME")
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
  ensure_migrations_table "$DB_NAME"
  
  # First test in sandbox
  echo "Testing migrations in sandbox database before applying..."
  create_sandbox_db
  
  local applied_migrations=$(get_applied_migrations "$DB_NAME")
  local available_migrations=$(get_available_migrations)
  
  if [ -z "$available_migrations" ]; then
    echo "No migrations found in $MIGRATIONS_DIR"
    return
  fi
  
  local pending_count=0
  local failed=false
  
  # Apply pending migrations to sandbox first
  for migration in $available_migrations; do
    if ! echo "$applied_migrations" | grep -q "^$migration$"; then
      echo "Testing migration in sandbox: $migration"
      if apply_migration "$migration" "$SANDBOX_DB_NAME"; then
        echo "Sandbox test successful for $migration"
      else
        echo "Error: Sandbox test failed for $migration"
        failed=true
        break
      fi
    fi
  done
  
  if [ "$failed" = true ]; then
    echo "Migration testing failed in sandbox. Aborting."
    return 1
  fi
  
  echo "All migrations tested successfully in sandbox. Applying to main database..."
  
  # Apply to main database
  for migration in $available_migrations; do
    if ! echo "$applied_migrations" | grep -q "^$migration$"; then
      apply_migration "$migration" "$DB_NAME"
      pending_count=$((pending_count + 1))
    fi
  done
  
  if [ $pending_count -eq 0 ]; then
    echo "No pending migrations to apply"
  else
    echo "Applied $pending_count migrations"
  fi
}

# Test migrations in sandbox
test_migrations() {
  ensure_migrations_table "$DB_NAME"
  create_sandbox_db
  
  local applied_migrations=$(get_applied_migrations "$DB_NAME")
  local available_migrations=$(get_available_migrations)
  
  if [ -z "$available_migrations" ]; then
    echo "No migrations found in $MIGRATIONS_DIR"
    return
  fi
  
  local pending_count=0
  local test_results=()
  
  echo "Testing migrations in sandbox database..."
  
  for migration in $available_migrations; do
    if ! echo "$applied_migrations" | grep -q "^$migration$"; then
      echo "Testing migration: $migration"
      
      # Test apply
      if apply_migration "$migration" "$SANDBOX_DB_NAME"; then
        echo "✅ Apply test passed for $migration"
        apply_result="PASS"
      else
        echo "❌ Apply test failed for $migration"
        apply_result="FAIL"
      fi
      
      # Test rollback
      if rollback_migration "$migration" "$SANDBOX_DB_NAME"; then
        echo "✅ Rollback test passed for $migration"
        rollback_result="PASS"
      else
        echo "❌ Rollback test failed for $migration"
        rollback_result="FAIL"
      fi
      
      test_results+=("$migration: Apply=$apply_result, Rollback=$rollback_result")
      pending_count=$((pending_count + 1))
    fi
  done
  
  echo ""
  echo "Migration Test Results:"
  echo "----------------------"
  
  if [ $pending_count -eq 0 ]; then
    echo "No pending migrations to test"
  else
    for result in "${test_results[@]}"; do
      echo "$result"
    done
  fi
}

# Rebuild sandbox database with all migrations
rebuild_sandbox() {
  echo "Rebuilding sandbox database..."
  create_sandbox_db
  
  local available_migrations=$(get_available_migrations)
  
  if [ -z "$available_migrations" ]; then
    echo "No migrations found in $MIGRATIONS_DIR"
    return
  fi
  
  local count=0
  
  for migration in $available_migrations; do
    apply_migration "$migration" "$SANDBOX_DB_NAME"
    count=$((count + 1))
  done
  
  echo "Sandbox database rebuilt with $count migrations"
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
  test)
    test_migrations
    ;;
  rebuild-sandbox)
    rebuild_sandbox
    ;;
  *)
    echo "Usage: $0 {apply|status|create NAME|test|rebuild-sandbox}"
    exit 1
    ;;
esac

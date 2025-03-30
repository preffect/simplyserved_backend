#!/bin/bash
set -e

MIGRATIONS_DIR="/migrations"
MIGRATIONS_TABLE="${APPLICATION_DB}_migrations"
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
      filename TEXT NOT NULL UNIQUE,
      hash TEXT NOT NULL,
      date TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  "
}

# Get list of applied migrations
get_applied_migrations() {
  local db=$1
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -t -c "
    SELECT filename FROM $MIGRATIONS_TABLE ORDER BY filename;
  " | tr -d ' '
}

# Get list of available migrations
get_available_migrations() {
  find "$MIGRATIONS_DIR" -name "*.sql" | sort | xargs -I{} basename {} .sql
}

# Calculate hash of a file
calculate_hash() {
  local file=$1
  md5sum "$file" | awk '{print $1}'
}

# Apply a migration
apply_migration() {
  local filename=$1
  local db=$2
  
  echo "Applying migration: $filename to $db"
  
  # Calculate hash of the migration file
  local hash=$(calculate_hash "$MIGRATIONS_DIR/$filename.sql")
  
  # Get the up migration SQL
  local up_sql=$(extract_up_migration "$filename")
  
  if [ $? -ne 0 ]; then
    echo "Error: Could not extract up migration for $filename"
    return 1
  fi
  
  # Execute the up migration
  echo "$up_sql" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db
  
  # Record the migration
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -c "
    INSERT INTO $MIGRATIONS_TABLE (filename, hash, date) VALUES ('$filename', '$hash', NOW());
  "
  
  echo "Migration $filename applied successfully to $db"
}

# Extract up migration from a migration file
extract_up_migration() {
  local version=$1
  local file="$MIGRATIONS_DIR/$version.sql"
  
  # Extract content between "-- Up migration" and "-- Down migration"
  local up_sql=$(sed -n '/-- Up migration/,/-- Down migration/ p' "$file" | grep -v "^-- Down migration" | grep -v "^--" | grep -v "^$")
  
  if [ -z "$up_sql" ]; then
    echo "Warning: No up migration found in $file"
    return 1
  fi
  
  echo "$up_sql"
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
  local filename=$1
  local db=$2
  
  echo "Rolling back migration: $filename from $db"
  
  # Get the down migration SQL
  local down_sql=$(extract_down_migration "$filename")
  
  if [ $? -ne 0 ]; then
    echo "Error: Could not extract down migration for $filename"
    return 1
  fi
  
  # Execute the down migration
  echo "$down_sql" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db
  
  # Remove the migration record
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $db -c "
    DELETE FROM $MIGRATIONS_TABLE WHERE filename = '$filename';
  "
  
  echo "Migration $filename rolled back successfully from $db"
}

# Ensure main database exists
ensure_main_db() {
  echo "Ensuring main database exists: $DB_NAME"
  
  # Check if database exists
  local db_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
  
  # Create the database if it doesn't exist
  if [ "$db_exists" != "1" ]; then
    echo "Creating main database: $DB_NAME"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
  fi
  
  # Create migrations table in main database
  ensure_migrations_table "$DB_NAME"
  
  echo "Main database ready"
}

# Create or recreate sandbox database
create_sandbox_db() {
  echo "Creating sandbox database: $SANDBOX_DB_NAME"
  
  # Check if database exists
  local db_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$SANDBOX_DB_NAME'")
 
  # Drop database if it exists (must be done outside of a transaction)
  if [ "$db_exists" = "1" ]; then
    echo "Sandbox database exists. Dropping: $SANDBOX_DB_NAME"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -c "DROP DATABASE $SANDBOX_DB_NAME;"
  fi
  
  # Create the database
  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -c "CREATE DATABASE $SANDBOX_DB_NAME;"
  
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

# Initialize databases
init_databases() {
  echo "Initializing databases..."
  ensure_main_db
  create_sandbox_db
  echo "Databases initialized successfully"
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
  init)
    init_databases
    ;;
  *)
    echo "Usage: $0 {apply|status|create NAME|test|rebuild-sandbox|init}"
    exit 1
    ;;
esac

#!/bin/bash
set -e

# Colors and symbols for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
SUCCESS="✅"
FAILURE="❌"
WARNING="⚠️"
INFO="ℹ️"

# Load environment variables
source /app/.env 2>/dev/null || true

# Database connection parameters
APP_DB="${APPLICATION_DB}"
SANDBOX_DB="${APPLICATION_DB}_sandbox"
MIGRATE_USER="${DATABASE_MIGRATE_USER}"
MIGRATE_PASSWORD="${DATABASE_MIGRATE_PASSWORD}"
MIGRATIONS_DIR="/app/migrations"
APP_MIGRATIONS_TABLE="${APP_DB}_migrations"
SANDBOX_MIGRATIONS_TABLE="${APP_DB}_sandbox_migrations"

# PostgreSQL connection string
PG_CONN="-h postgres -U ${MIGRATE_USER} -d ${APP_DB}"
export PGPASSWORD="${MIGRATE_PASSWORD}"

# Function to print usage information
print_usage() {
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
}

# Function to initialize the migrations tables
init_migrations() {
    echo -e "${INFO} Initializing migration system..."
    
    # Check if sandbox database exists, if not create it
    if ! psql ${PG_CONN} -lqt | cut -d \| -f 1 | grep -qw "${SANDBOX_DB}"; then
        echo -e "${INFO} Creating sandbox database: ${SANDBOX_DB}"
        psql ${PG_CONN} -c "CREATE DATABASE ${SANDBOX_DB};"
    else
        echo -e "${INFO} Sandbox database already exists"
    fi
    
    # Create migrations table in application database if it doesn't exist
    echo -e "${INFO} Creating migrations table in application database"
    psql ${PG_CONN} -d "${APP_DB}" -c "
    CREATE TABLE IF NOT EXISTS ${APP_MIGRATIONS_TABLE} (
        id serial PRIMARY KEY,
        filename text NOT NULL UNIQUE,
        hash text NOT NULL,
        date timestamptz NOT NULL DEFAULT now()
    );"
    
    # Create migrations table in sandbox database if it doesn't exist
    echo -e "${INFO} Creating migrations table in sandbox database"
    psql ${PG_CONN} -d "${SANDBOX_DB}" -c "
    CREATE TABLE IF NOT EXISTS ${SANDBOX_MIGRATIONS_TABLE} (
        id serial PRIMARY KEY,
        filename text NOT NULL UNIQUE,
        hash text NOT NULL,
        date timestamptz NOT NULL DEFAULT now()
    );"
    
    echo -e "${SUCCESS} Migration system initialized successfully"
}

# Function to rebuild the sandbox database
rebuild_sandbox() {
    echo -e "${INFO} Rebuilding sandbox database..."
    
    # Drop the sandbox database if it exists
    if psql ${PG_CONN} -lqt | cut -d \| -f 1 | grep -qw "${SANDBOX_DB}"; then
        echo -e "${INFO} Dropping existing sandbox database"
        # Terminate all connections to the sandbox database
        psql ${PG_CONN} -c "
        SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE pg_stat_activity.datname = '${SANDBOX_DB}'
        AND pid <> pg_backend_pid();"
        
        psql ${PG_CONN} -c "DROP DATABASE ${SANDBOX_DB};"
    fi
    
    # Create a new sandbox database
    echo -e "${INFO} Creating new sandbox database"
    psql ${PG_CONN} -c "CREATE DATABASE ${SANDBOX_DB};"
    
    # Create migrations table in sandbox database
    echo -e "${INFO} Creating migrations table in sandbox database"
    psql ${PG_CONN} -d "${SANDBOX_DB}" -c "
    CREATE TABLE IF NOT EXISTS ${SANDBOX_MIGRATIONS_TABLE} (
        id serial PRIMARY KEY,
        filename text NOT NULL UNIQUE,
        hash text NOT NULL,
        date timestamptz NOT NULL DEFAULT now()
    );"
    
    echo -e "${SUCCESS} Sandbox database rebuilt successfully"
}

# Function to get migration status
show_status() {
    echo -e "${INFO} Migration Status:"
    
    # Get list of all migration files
    local all_migrations=($(ls -1 ${MIGRATIONS_DIR}/*.sql 2>/dev/null | sort))
    
    if [ ${#all_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No migration files found in ${MIGRATIONS_DIR}"
        return
    fi
    
    # Get list of applied migrations from application database
    local app_applied_migrations=$(psql ${PG_CONN} -d "${APP_DB}" -t -c "SELECT filename FROM ${APP_MIGRATIONS_TABLE} ORDER BY id;")
    
    # Get list of applied migrations from sandbox database
    local sandbox_applied_migrations=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT filename FROM ${SANDBOX_MIGRATIONS_TABLE} ORDER BY id;")
    
    echo "--------------------------------------------------------------"
    printf "%-40s %-15s %-15s\n" "MIGRATION" "APP DB" "SANDBOX DB"
    echo "--------------------------------------------------------------"
    
    for migration in "${all_migrations[@]}"; do
        local filename=$(basename "${migration}")
        local app_status="Not Applied"
        local sandbox_status="Not Applied"
        
        if echo "${app_applied_migrations}" | grep -q "${filename}"; then
            app_status="${GREEN}Applied${NC}"
        else
            app_status="${YELLOW}Not Applied${NC}"
        fi
        
        if echo "${sandbox_applied_migrations}" | grep -q "${filename}"; then
            sandbox_status="${GREEN}Applied${NC}"
        else
            sandbox_status="${YELLOW}Not Applied${NC}"
        fi
        
        printf "%-40s %-15b %-15b\n" "${filename}" "${app_status}" "${sandbox_status}"
    done
    
    echo "--------------------------------------------------------------"
}

# Function to create a new migration
create_migration() {
    local name="$1"
    
    if [ -z "${name}" ]; then
        echo -e "${FAILURE} Migration name is required"
        print_usage
        exit 1
    fi
    
    # Format the name to be URL-friendly (lowercase, replace spaces with underscores)
    name=$(echo "${name}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    
    # Create a timestamp for the migration filename
    local timestamp=$(date -u +"%Y%m%d.%H%M%S")
    local filename="${timestamp}_${name}.sql"
    local filepath="${MIGRATIONS_DIR}/${filename}"
    
    # Create the migration file with the template
    cat > "${filepath}" << EOF
-- Migration: ${name}
-- Created at: $(date -u +"%Y-%m-%d %H:%M:%S")

-- Write your migration SQL here

-- UP MIGRATION START
-- Add your schema changes here


-- UP MIGRATION END

-- DOWN MIGRATION START
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks

-- DOWN MIGRATION END
EOF
    
    echo -e "${SUCCESS} Created new migration: ${filepath}"
}

# Function to extract UP migration from a file
extract_up_migration() {
    local file="$1"
    sed -n '/-- UP MIGRATION START/,/-- UP MIGRATION END/p' "${file}" | grep -v "'-- UP MIGRATION'" | grep -v "^$"
}

# Function to extract DOWN migration from a file
extract_down_migration() {
    local file="$1"
    sed -n '/-- DOWN MIGRATION START/,/-- DOWN MIGRATION END/p' "${file}" | grep -v "'-- DOWN MIGRATION'" | grep -v "^$"
}

# Function to calculate MD5 hash of a file
calculate_hash() {
    local file="$1"
    md5sum "${file}" | awk '{print $1}'
}

# Function to apply a single migration to the sandbox database
apply_migration_to_sandbox() {
    local file="$1"
    local filename=$(basename "${file}")
    local hash=$(calculate_hash "${file}")
    
    # Check if migration has already been applied to sandbox
    local is_applied=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT COUNT(*) FROM ${SANDBOX_MIGRATIONS_TABLE} WHERE filename = '${filename}';")
    
    if [ "$is_applied" -gt 0 ]; then
        echo -e "${INFO} Migration ${filename} already applied to sandbox database"
        return 0
    fi
    
    echo -e "${INFO} Applying migration ${filename} to sandbox database..."
    
    # Extract the UP migration SQL
    local up_sql=$(extract_up_migration "${file}")
    
    if [ -z "${up_sql}" ]; then
        echo -e "${FAILURE} No UP migration found in ${filename}"
        return 1
    fi
    
    # Apply the migration to the sandbox database
    if echo "${up_sql}" | psql ${PG_CONN} -d "${SANDBOX_DB}" -v ON_ERROR_STOP=1; then
        # Record the migration in the sandbox migrations table
        psql ${PG_CONN} -d "${SANDBOX_DB}" -c "
        INSERT INTO ${SANDBOX_MIGRATIONS_TABLE} (filename, hash)
        VALUES ('${filename}', '${hash}');"
        
        echo -e "${SUCCESS} Migration ${filename} applied to sandbox database"
        return 0
    else
        echo -e "${FAILURE} Failed to apply migration ${filename} to sandbox database"
        return 1
    fi
}

# Function to rollback a migration in the sandbox database
rollback_migration_in_sandbox() {
    local file="$1"
    local filename=$(basename "${file}")
    
    # Check if migration has been applied to sandbox
    local is_applied=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT COUNT(*) FROM ${SANDBOX_MIGRATIONS_TABLE} WHERE filename = '${filename}';")
    
    if [ "$is_applied" -eq 0 ]; then
        echo -e "${INFO} Migration ${filename} not applied to sandbox database, nothing to rollback"
        return 0
    fi
    
    echo -e "${INFO} Rolling back migration ${filename} in sandbox database..."
    
    # Extract the DOWN migration SQL
    local down_sql=$(extract_down_migration "${file}")
    
    if [ -z "${down_sql}" ]; then
        echo -e "${FAILURE} No DOWN migration found in ${filename}"
        return 1
    fi
    
    # Apply the rollback to the sandbox database
    if echo "${down_sql}" | psql ${PG_CONN} -d "${SANDBOX_DB}" -v ON_ERROR_STOP=1; then
        # Remove the migration from the sandbox migrations table
        psql ${PG_CONN} -d "${SANDBOX_DB}" -c "
        DELETE FROM ${SANDBOX_MIGRATIONS_TABLE} WHERE filename = '${filename}';"
        
        echo -e "${SUCCESS} Migration ${filename} rolled back in sandbox database"
        return 0
    else
        echo -e "${FAILURE} Failed to roll back migration ${filename} in sandbox database"
        return 1
    fi
}

# Function to apply a single migration to the application database
apply_migration_to_app() {
    local file="$1"
    local filename=$(basename "${file}")
    local hash=$(calculate_hash "${file}")
    
    # Check if migration has already been applied to application database
    local is_applied=$(psql ${PG_CONN} -d "${APP_DB}" -t -c "SELECT COUNT(*) FROM ${APP_MIGRATIONS_TABLE} WHERE filename = '${filename}';")
    
    if [ "$is_applied" -gt 0 ]; then
        echo -e "${INFO} Migration ${filename} already applied to application database"
        return 0
    fi
    
    echo -e "${INFO} Applying migration ${filename} to application database..."
    
    # Extract the UP migration SQL
    local up_sql=$(extract_up_migration "${file}")
    
    if [ -z "${up_sql}" ]; then
        echo -e "${FAILURE} No UP migration found in ${filename}"
        return 1
    fi
    
    # Apply the migration to the application database
    if echo "${up_sql}" | psql ${PG_CONN} -d "${APP_DB}" -v ON_ERROR_STOP=1; then
        # Record the migration in the application migrations table
        psql ${PG_CONN} -d "${APP_DB}" -c "
        INSERT INTO ${APP_MIGRATIONS_TABLE} (filename, hash)
        VALUES ('${filename}', '${hash}');"
        
        echo -e "${SUCCESS} Migration ${filename} applied to application database"
        return 0
    else
        echo -e "${FAILURE} Failed to apply migration ${filename} to application database"
        return 1
    fi
}

# Function to apply all migrations to the sandbox database
apply_all_migrations_to_sandbox() {
    # Get list of all migration files
    local all_migrations=($(ls -1 ${MIGRATIONS_DIR}/*.sql 2>/dev/null | sort))
    
    if [ ${#all_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No migration files found in ${MIGRATIONS_DIR}"
        return 0
    fi
    
    local success=true
    
    for migration in "${all_migrations[@]}"; do
        if ! apply_migration_to_sandbox "${migration}"; then
            success=false
            break
        fi
    done
    
    if [ "${success}" = true ]; then
        echo -e "${SUCCESS} All migrations applied to sandbox database"
        return 0
    else
        echo -e "${FAILURE} Failed to apply all migrations to sandbox database"
        return 1
    fi
}

# Function to apply the next pending migration to the sandbox database
apply_next_migration_to_sandbox() {
    # Get list of all migration files
    local all_migrations=($(ls -1 ${MIGRATIONS_DIR}/*.sql 2>/dev/null | sort))
    
    if [ ${#all_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No migration files found in ${MIGRATIONS_DIR}"
        return 0
    fi
    
    # Get list of applied migrations from sandbox database
    local sandbox_applied_migrations=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT filename FROM ${SANDBOX_MIGRATIONS_TABLE} ORDER BY id;")
    
    local next_migration=""
    
    for migration in "${all_migrations[@]}"; do
        local filename=$(basename "${migration}")
        if ! echo "${sandbox_applied_migrations}" | grep -q "${filename}"; then
            next_migration="${migration}"
            break
        fi
    done
    
    if [ -z "${next_migration}" ]; then
        echo -e "${INFO} No pending migrations to apply to sandbox"
        return 0
    fi
    
    local filename=$(basename "${next_migration}")
    echo -e "${INFO} Applying next migration to sandbox: ${filename}"
    
    if apply_migration_to_sandbox "${next_migration}"; then
        echo -e "${SUCCESS} Migration ${filename} applied to sandbox database"
        return 0
    else
        echo -e "${FAILURE} Failed to apply migration ${filename} to sandbox database"
        return 1
    fi
}

# Function to rollback the last migration in the sandbox database
rollback_last_sandbox_migration() {
    # Get the last applied migration from the sandbox database
    local last_migration=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT filename FROM ${SANDBOX_MIGRATIONS_TABLE} ORDER BY id DESC LIMIT 1;")
    last_migration=$(echo "${last_migration}" | tr -d '[:space:]')
    
    if [ -z "${last_migration}" ]; then
        echo -e "${INFO} No migrations to roll back in sandbox"
        return 0
    fi
    
    echo -e "${INFO} Rolling back migration in sandbox: ${last_migration}"
    
    # Find the migration file
    local migration_file="${MIGRATIONS_DIR}/${last_migration}"
    
    if [ ! -f "${migration_file}" ]; then
        echo -e "${FAILURE} Migration file not found: ${migration_file}"
        return 1
    fi
    
    if rollback_migration_in_sandbox "${migration_file}"; then
        echo -e "${SUCCESS} Migration ${last_migration} rolled back successfully in sandbox"
        return 0
    else
        echo -e "${FAILURE} Failed to roll back migration ${last_migration} in sandbox"
        return 1
    fi
}

# Function to rollback the last migration in the application database
rollback_last_migration() {
    # Get the last applied migration from the application database
    local last_migration=$(psql ${PG_CONN} -d "${APP_DB}" -t -c "SELECT filename FROM ${APP_MIGRATIONS_TABLE} ORDER BY id DESC LIMIT 1;")
    last_migration=$(echo "${last_migration}" | tr -d '[:space:]')
    
    if [ -z "${last_migration}" ]; then
        echo -e "${INFO} No migrations to roll back"
        return 0
    fi
    
    echo -e "${INFO} Rolling back migration: ${last_migration}"
    
    # Find the migration file
    local migration_file="${MIGRATIONS_DIR}/${last_migration}"
    
    if [ ! -f "${migration_file}" ]; then
        echo -e "${FAILURE} Migration file not found: ${migration_file}"
        return 1
    fi
    
    # Extract the DOWN migration SQL
    local down_sql=$(extract_down_migration "${migration_file}")
    
    if [ -z "${down_sql}" ]; then
        echo -e "${FAILURE} No DOWN migration found in ${last_migration}"
        return 1
    fi
    
    # Apply the rollback to the application database
    if echo "${down_sql}" | psql ${PG_CONN} -d "${APP_DB}" -v ON_ERROR_STOP=1; then
        # Remove the migration from the application migrations table
        psql ${PG_CONN} -d "${APP_DB}" -c "
        DELETE FROM ${APP_MIGRATIONS_TABLE} WHERE filename = '${last_migration}';"
        
        echo -e "${SUCCESS} Migration ${last_migration} rolled back successfully"
        
        # Also rollback in sandbox to keep them in sync
        echo -e "${INFO} Rolling back migration in sandbox database to keep in sync..."
        rollback_migration_in_sandbox "${migration_file}"
        
        return 0
    else
        echo -e "${FAILURE} Failed to roll back migration ${last_migration}"
        return 1
    fi
}

# Function to test migrations in sandbox
test_migrations() {
    # Get list of all migration files
    local all_migrations=($(ls -1 ${MIGRATIONS_DIR}/*.sql 2>/dev/null | sort))
    
    if [ ${#all_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No migration files found in ${MIGRATIONS_DIR}"
        return 0
    fi
    
    # Get list of applied migrations from sandbox database
    local sandbox_applied_migrations=$(psql ${PG_CONN} -d "${SANDBOX_DB}" -t -c "SELECT filename FROM ${SANDBOX_MIGRATIONS_TABLE} ORDER BY id;")
    
    local pending_migrations=()
    
    for migration in "${all_migrations[@]}"; do
        local filename=$(basename "${migration}")
        if ! echo "${sandbox_applied_migrations}" | grep -q "${filename}"; then
            pending_migrations+=("${migration}")
        fi
    done
    
    if [ ${#pending_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No pending migrations to test"
        return 0
    fi
    
    echo -e "${INFO} Testing ${#pending_migrations[@]} pending migrations in sandbox database..."
    
    local all_tests_passed=true
    
    for migration in "${pending_migrations[@]}"; do
        local filename=$(basename "${migration}")
        echo -e "${INFO} Testing migration: ${filename}"
        
        # Apply the migration
        echo -e "${INFO} Applying migration..."
        if apply_migration_to_sandbox "${migration}"; then
            echo -e "${SUCCESS} Migration applied successfully"
            
            # Rollback the migration
            echo -e "${INFO} Rolling back migration..."
            if rollback_migration_in_sandbox "${migration}"; then
                echo -e "${SUCCESS} Migration rolled back successfully"
            else
                echo -e "${FAILURE} Failed to roll back migration"
                all_tests_passed=false
            fi
        else
            echo -e "${FAILURE} Failed to apply migration"
            all_tests_passed=false
        fi
        
        echo ""
    done
    
    if [ "${all_tests_passed}" = true ]; then
        echo -e "${SUCCESS} All migration tests passed"
        return 0
    else
        echo -e "${FAILURE} Some migration tests failed"
        return 1
    fi
}

# Function to apply pending migrations
apply_migrations() {
    # Get list of all migration files
    local all_migrations=($(ls -1 ${MIGRATIONS_DIR}/*.sql 2>/dev/null | sort))
    
    if [ ${#all_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No migration files found in ${MIGRATIONS_DIR}"
        return 0
    fi
    
    # Get list of applied migrations from application database
    local app_applied_migrations=$(psql ${PG_CONN} -d "${APP_DB}" -t -c "SELECT filename FROM ${APP_MIGRATIONS_TABLE} ORDER BY id;")
    
    local pending_migrations=()
    
    for migration in "${all_migrations[@]}"; do
        local filename=$(basename "${migration}")
        if ! echo "${app_applied_migrations}" | grep -q "${filename}"; then
            pending_migrations+=("${migration}")
        fi
    done
    
    if [ ${#pending_migrations[@]} -eq 0 ]; then
        echo -e "${INFO} No pending migrations to apply"
        return 0
    fi
    
    echo -e "${INFO} Found ${#pending_migrations[@]} pending migrations"
    
    # First, test all pending migrations in the sandbox
    echo -e "${INFO} Testing migrations in sandbox before applying to application database..."
    
    local sandbox_success=true
    
    for migration in "${pending_migrations[@]}"; do
        local filename=$(basename "${migration}")
        echo -e "${INFO} Testing migration in sandbox: ${filename}"
        
        if apply_migration_to_sandbox "${migration}"; then
            echo -e "${SUCCESS} Migration tested successfully in sandbox"
        else
            echo -e "${FAILURE} Migration failed in sandbox, aborting application to production database"
            sandbox_success=false
            break
        fi
    done
    
    if [ "${sandbox_success}" = false ]; then
        echo -e "${FAILURE} Sandbox testing failed, not applying migrations to application database"
        return 1
    fi
    
    echo -e "${SUCCESS} All migrations tested successfully in sandbox"
    echo -e "${INFO} Applying migrations to application database..."
    
    local app_success=true
    
    for migration in "${pending_migrations[@]}"; do
        if ! apply_migration_to_app "${migration}"; then
            app_success=false
            break
        fi
    done
    
    if [ "${app_success}" = true ]; then
        echo -e "${SUCCESS} All migrations applied to application database"
        return 0
    else
        echo -e "${FAILURE} Failed to apply all migrations to application database"
        return 1
    fi
}

# Main script execution
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
    rollback)
        rollback_last_migration
        ;;
    test)
        test_migrations
        ;;
    rebuild-sandbox)
        rebuild_sandbox
        ;;
    init)
        init_migrations
        ;;
    apply-sandbox)
        apply_next_migration_to_sandbox
        ;;
    rollback-sandbox)
        rollback_last_sandbox_migration
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo -e "${FAILURE} Unknown command: $1"
        print_usage
        exit 1
        ;;
esac

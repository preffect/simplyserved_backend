# Database Migrations

This directory contains database migrations for the SimplyServed application.

## Migration File Format

Migration files follow this naming convention:
```
YYYYMMDD.NNN_descriptive_name.sql
```

Where:
- `YYYYMMDD` is the date in year-month-day format
- `NNN` is a 3-digit sequence number (starting from 001) for that day
- `descriptive_name` is a brief description of what the migration does

## Example Migration

```sql
-- Migration: create_users_table
-- Created at: 2025-03-30 12:00:00

-- Up migration
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Down migration (if needed)
-- DROP TABLE users;
```

## Usage

Use the `db-migrate.sh` script to manage migrations:

```bash
# Show migration status
./db-migrate.sh status

# Create a new migration
./db-migrate.sh create add_users_table

# Apply pending migrations
./db-migrate.sh apply
```

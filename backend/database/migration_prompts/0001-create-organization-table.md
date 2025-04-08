Create a PostgreSQL migration script to create a table for managing organizations. 
These organizations will be the top level entity and used for data tenancy.

The migration should:
1. Create table organization
   - id - UUID
   - name
   - description

2. Create a function for setting audit fields on an entity

```
-- Create a trigger function to set audit fields
CREATE OR REPLACE FUNCTION set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Set created_at to NOW() if this is a new record
    IF TG_OP = 'INSERT' THEN
        NEW.created_at = NOW();
        NEW.created_by = app.current_user
    END IF;
    NEW.modified_at = NOW();
    NEW.modified_by = app.current_user
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets
- use UUID primary keys
- all tables should have audit columns (created_at, modified_at, archived_at, created_by, modified_by, archived_by)
   - All tables should have `BEFORE INSERT OR UPDATE` triggers which call the set_audit_fields() function.
- grant SELECT on this table to user simplyserved
- grant SELECT and DELETE on this table to user simplyserved_org
- grant INSERT and UPDATE to all rows on this table except the audit columns to user simplyserved_org
- migrations should be placed in ./backend/database/migrations

Migration files should be of the following format:

```
-- Migration: $name
-- Created at: $(date -u +"%Y-%m-%d %H:%M:%S")

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;
-- Add your schema changes here
COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks
COMMIT;
-- DOWN MIGRATION END

```

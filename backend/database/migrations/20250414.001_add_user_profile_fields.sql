-- Migration: add_user_profile_fields
-- Created at: 2025-04-14 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;

-- Create the staff_type enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'staff_type') THEN
        CREATE TYPE staff_type AS ENUM ('MANAGER', 'SERVER', 'HOST', 'RUNNER');
    END IF;
END$$;

-- Add columns to app_user table
ALTER TABLE app_user 
    ADD COLUMN first_name VARCHAR(100),
    ADD COLUMN middle_name VARCHAR(100),
    ADD COLUMN last_name VARCHAR(100),
    ADD COLUMN salutation VARCHAR(20),
    ADD COLUMN staff_type staff_type,

-- Add comment to staff_type column
    COMMENT ON COLUMN app_user.staff_type IS 
    'Staff type for the user. Possible values: MANAGER, SERVER, HOST, RUNNER';
-- Add check constraint to ensure staff_type is not null
ALTER TABLE app_user 
    ADD CONSTRAINT staff_type_not_null CHECK (staff_type IS NOT NULL);

-- Grant permissions to simplyserved user
GRANT INSERT (first_name, middle_name, last_name, salutation, staff_type) 
    ON app_user TO simplyserved;

GRANT UPDATE (first_name, middle_name, last_name, salutation, staff_type) 
    ON app_user TO simplyserved;

COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;

-- Remove columns from app_user table
ALTER TABLE app_user 
    DROP COLUMN IF EXISTS first_name,
    DROP COLUMN IF EXISTS middle_name,
    DROP COLUMN IF EXISTS last_name,
    DROP COLUMN IF EXISTS salutation,
    DROP COLUMN IF EXISTS staff_type;

-- Drop the enum type if no other tables are using it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
        JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_catalog.pg_type t ON a.atttypid = t.oid
        WHERE t.typname = 'staff_type'
        AND a.attname != 'staff_type'
    ) THEN
        DROP TYPE IF EXISTS staff_type;
    END IF;
END$$;

COMMIT;
-- DOWN MIGRATION END

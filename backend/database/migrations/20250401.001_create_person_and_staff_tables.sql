-- Migration: create_person_and_staff_tables
-- Created at: 2025-04-01 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
-- Create person_type enum
CREATE TYPE person_type AS ENUM ('STAFF', 'CUSTOMER');

-- Create staff_type enum
CREATE TYPE staff_type AS ENUM ('ADMIN', 'MANAGER', 'SERVER', 'HOST', 'RUNNER');

-- Create person table
CREATE TABLE person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    person_type person_type NOT NULL,
    user_id UUID REFERENCES users(id),
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    modified_by UUID REFERENCES users(id),
    archived_by UUID REFERENCES users(id)
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_person_user_id ON person(user_id);

-- Create index on person_type for filtering
CREATE INDEX idx_person_type ON person(person_type);

-- Create staff_person table
CREATE TABLE staff_person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_type staff_type NOT NULL,
    notes TEXT,
    person_id UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    modified_by UUID REFERENCES users(id),
    archived_by UUID REFERENCES users(id),
    
    -- Ensure person_id is unique to prevent a person from having multiple staff records
    CONSTRAINT unique_person_id UNIQUE (person_id)
);

-- Create index on staff_type for filtering
CREATE INDEX idx_staff_type ON staff_person(staff_type);

-- Create customer table
CREATE TABLE customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    modified_by UUID REFERENCES users(id),
    archived_by UUID REFERENCES users(id),
    
    -- Ensure person_id is unique to prevent a person from having multiple customer records
    CONSTRAINT unique_customer_person_id UNIQUE (person_id)
);

-- Create triggers to update modified_at timestamp
CREATE OR REPLACE FUNCTION update_modified_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER person_modified
BEFORE UPDATE ON person
FOR EACH ROW
EXECUTE FUNCTION update_modified_at();

CREATE TRIGGER staff_person_modified
BEFORE UPDATE ON staff_person
FOR EACH ROW
EXECUTE FUNCTION update_modified_at();

CREATE TRIGGER customer_modified
BEFORE UPDATE ON customer
FOR EACH ROW
EXECUTE FUNCTION update_modified_at();

-- Add constraint to ensure person_type matches the related tables
ALTER TABLE person ADD CONSTRAINT check_person_type_consistency
CHECK (
    (person_type = 'STAFF' AND id IN (SELECT person_id FROM staff_person)) OR
    (person_type = 'CUSTOMER' AND id IN (SELECT person_id FROM customer)) OR
    (archived_at IS NOT NULL)
);
-- UP MIGRATION END

-- DOWN MIGRATION START
-- Drop constraints first
ALTER TABLE person DROP CONSTRAINT IF EXISTS check_person_type_consistency;

-- Drop triggers
DROP TRIGGER IF EXISTS person_modified ON person;
DROP TRIGGER IF EXISTS staff_person_modified ON staff_person;
DROP TRIGGER IF EXISTS customer_modified ON customer;

-- Drop function
DROP FUNCTION IF EXISTS update_modified_at();

-- Drop tables in reverse order
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS staff_person;
DROP TABLE IF EXISTS person;

-- Drop types
DROP TYPE IF EXISTS staff_type;
DROP TYPE IF EXISTS person_type;
-- DOWN MIGRATION END

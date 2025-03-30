-- Migration: create_users_table
-- Created at: 2025-03-30 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
-- Create users table with authentication capabilities
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    modified_at TIMESTAMP WITH TIME ZONE,
    archived_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    modified_by UUID,
    archived_by UUID
);

-- Add unique constraint on email
CREATE UNIQUE INDEX users_email_idx ON users(email) WHERE archived_at IS NULL;

-- Add indexes for performance
CREATE INDEX users_role_idx ON users(role);
CREATE INDEX users_archived_at_idx ON users(archived_at);

-- Add foreign key constraints (self-referential)
ALTER TABLE users 
    ADD CONSTRAINT users_created_by_fkey 
    FOREIGN KEY (created_by) 
    REFERENCES users(id);

ALTER TABLE users 
    ADD CONSTRAINT users_modified_by_fkey 
    FOREIGN KEY (modified_by) 
    REFERENCES users(id);

ALTER TABLE users 
    ADD CONSTRAINT users_archived_by_fkey 
    FOREIGN KEY (archived_by) 
    REFERENCES users(id);

-- Create a trigger function to update modified_at timestamp
CREATE OR REPLACE FUNCTION update_modified_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update modified_at
CREATE TRIGGER update_users_modified_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_modified_at();

-- UP MIGRATION END

-- DOWN MIGRATION START
-- Drop the trigger first
DROP TRIGGER IF EXISTS update_users_modified_at ON users;

-- Drop the trigger function
DROP FUNCTION IF EXISTS update_modified_at();

-- Drop the table (this will also drop the constraints and indexes)
DROP TABLE IF EXISTS users;
-- DOWN MIGRATION END

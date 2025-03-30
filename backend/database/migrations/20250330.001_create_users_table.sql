-- Migration: Create users table with authentication capabilities
-- Description: Adds a users table with email, password hash, and role fields

-- Up Migration
-----------------------------------------

-- Create enum type for user roles
CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');

-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role user_role NOT NULL DEFAULT 'user',
  
  -- Audit columns
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  modified_at TIMESTAMP WITH TIME ZONE,
  archived_at TIMESTAMP WITH TIME ZONE,
  created_by UUID,
  modified_by UUID,
  archived_by UUID
);

-- Add unique constraint on email
CREATE UNIQUE INDEX users_email_idx ON users (email) WHERE archived_at IS NULL;

-- Add indexes for performance
CREATE INDEX users_role_idx ON users (role);
CREATE INDEX users_created_at_idx ON users (created_at);
CREATE INDEX users_archived_at_idx ON users (archived_at);

-- Add foreign key constraints for audit columns
-- These will initially reference the same table (self-referential)
ALTER TABLE users
  ADD CONSTRAINT users_created_by_fkey
  FOREIGN KEY (created_by)
  REFERENCES users (id);

ALTER TABLE users
  ADD CONSTRAINT users_modified_by_fkey
  FOREIGN KEY (modified_by)
  REFERENCES users (id);

ALTER TABLE users
  ADD CONSTRAINT users_archived_by_fkey
  FOREIGN KEY (archived_by)
  REFERENCES users (id);

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

-- Down Migration
-----------------------------------------

-- Drop trigger first
DROP TRIGGER IF EXISTS update_users_modified_at ON users;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_modified_at();

-- Drop table (will cascade to constraints and indexes)
DROP TABLE IF EXISTS users;

-- Drop enum type
DROP TYPE IF EXISTS user_role;

-- Migration: create_app_user_table
-- Created at: 2025-03-30 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create app_user table with authentication capabilities
CREATE TABLE app_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
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

CREATE COMMENT ON TABLE app_user IS 
    $$This table to store user information for the SimplyServed application and
    is also used for authentication and authorization purposes.$$

-- Insert system user
INSERT INTO app_user (id, organization_id, email, password_hash, role, created_at, modified_at, archived_at, created_by, modified_by, archived_by)
VALUES (system_user_id(), system_organization_id(), 'system-user@simplyserved.app',
        crypt('system-user-password', gen_salt('bf')), 'admin', NOW(), NOW(), NULL, system_user_id(), system_user_id(), NULL);

-- Add unique constraint on email
CREATE UNIQUE INDEX app_user_email_idx ON app_user(email) WHERE archived_at IS NULL;

-- Add indexes for performance
CREATE INDEX app_user_role_idx ON app_user(role);
CREATE INDEX app_user_archived_at_idx ON app_user(archived_at);

-- Add foreign key constraints (self-referential)
ALTER TABLE app_user 
    ADD CONSTRAINT app_user_organization_id_fkey 
    FOREIGN KEY (organization_id)
    REFERENCES organization(id); 

ALTER TABLE app_user 
    ADD CONSTRAINT app_user_created_by_fkey 
    FOREIGN KEY (created_by) 
    REFERENCES app_user(id);

ALTER TABLE app_user 
    ADD CONSTRAINT app_user_modified_by_fkey 
    FOREIGN KEY (modified_by) 
    REFERENCES app_user(id);

ALTER TABLE app_user 
    ADD CONSTRAINT app_user_archived_by_fkey 
    FOREIGN KEY (archived_by) 
    REFERENCES app_user(id);

-- Create trigger for audit fields
CREATE TRIGGER set_user_audit_fields
BEFORE INSERT OR UPDATE ON app_user
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

-- Create function to get current organization ID from JWT claims
CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS $$
  SELECT nullif(current_setting('request.jwt.claims', true)::json->>'current_user_id', '')::uuid;
$$ LANGUAGE SQL stable;

-- Enable row level security
ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;

-- Force the use of RLS
ALTER TABLE app_user FORCE ROW LEVEL SECURITY;

-- Create policy for organization-based access
CREATE POLICY app_user_organization_isolation_policy ON app_user
  USING (organization_id = current_organization_id());

-- Grant permissions to roles
GRANT SELECT ON app_user TO simplyserved;
GRANT INSERT, UPDATE (organization_id, email, password_hash, role) ON app_user TO simplyserved;

-- Create function to set organization_id
CREATE OR REPLACE FUNCTION set_organization_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Set the organization_id to the current organization ID from JWT claims
    NEW.organization_id := current_organization_id();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add before insert trigger to set organization_id
CREATE TRIGGER set_organization_id
BEFORE INSERT ON app_user
FOR EACH ROW
EXECUTE PROCEDURE set_organization_id();

COMMIT;

-- UP MIGRATION END

-- DOWN MIGRATION START

BEGIN;

-- Drop the trigger first
DROP TRIGGER IF EXISTS set_user_audit_fields ON app_user;

DROP TRIGGER IF EXISTS set_organization_id ON app_user;

-- Drop policies
DROP POLICY IF EXISTS app_user_organization_isolation_policy ON app_user;

-- Disable RLS
ALTER TABLE app_user DISABLE ROW LEVEL SECURITY;

-- Drop the table (this will also drop the constraints and indexes)
DROP TABLE IF EXISTS app_user CASCADE;
DROP POLICY IF EXISTS app_user_organization_isolation_policy ON app_user;
DROP FUNCTION IF EXISTS set_organization_id;
DROP FUNCTION IF EXISTS current_user_id;

COMMIT;

-- DOWN MIGRATION END

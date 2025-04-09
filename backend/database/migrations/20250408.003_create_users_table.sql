-- Migration: create_users_table
-- Created at: 2025-03-30 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START

-- Create users table with authentication capabilities
CREATE TABLE users (
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

-- Insert system user
INSERT INTO users (id, organization_id, email, password_hash, role, created_at, modified_at, archived_at, created_by, modified_by, archived_by)
VALUES (system_user_id(), system_tenant_id(), "system-user@simplyserved.ap",
        crypt('system-user-password', gen_salt('bf')), 'admin', NOW(), NOW(), NULL, system_user_id(), system_user_id(), NULL);

-- Add unique constraint on email
CREATE UNIQUE INDEX users_email_idx ON users(email) WHERE archived_at IS NULL;

-- Add indexes for performance
CREATE INDEX users_role_idx ON users(role);
CREATE INDEX users_archived_at_idx ON users(archived_at);

-- Add foreign key constraints (self-referential)
ALTER TABLE users 
    ADD CONSTRAINT users_organization_id_fkey 
    FOREIGN KEY (organization_id)
    REFERENCES organization(id); 

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

-- Create trigger for audit fields
CREATE TRIGGER set_user_audit_fields
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

-- UP MIGRATION END

-- DOWN MIGRATION START
-- Drop the trigger first
DROP TRIGGER IF EXISTS set_user_audit_fields ON users;

-- Drop the table (this will also drop the constraints and indexes)
DROP TABLE IF EXISTS users CASCADE;

-- DOWN MIGRATION END

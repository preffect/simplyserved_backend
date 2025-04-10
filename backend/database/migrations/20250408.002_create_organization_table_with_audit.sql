-- Migration: create_organization_table_with_audit
-- Created at: 2025-04-08 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create organization table
CREATE TABLE organization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    
    -- Audit columns
    created_at TIMESTAMP WITH TIME ZONE,
    modified_at TIMESTAMP WITH TIME ZONE,
    archived_at TIMESTAMP WITH TIME ZONE,
    created_by TEXT,
    modified_by TEXT,
    archived_by TEXT
);

-- Create trigger for audit fields
CREATE TRIGGER set_organization_audit_fields
BEFORE INSERT OR UPDATE ON organization
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

-- Set the current tenant and user IDs in the JWT claims for creating the system tenant
SET LOCAL jwt.claims.current_organization_id = system_organization_id;
SET LOCAL jwt.claims.current_user_id = system_user_id;

INSERT INTO organization (id, name, description, created_at, modified_at, archived_at )
VALUES
    (system_organization_id(), 'SYSTEM TENANT', 'SYSTEM TENANT', NOW(), NOW(), NULL );

-- Grant permissions
GRANT SELECT ON organization TO simplyserved;
GRANT DELETE ON organization TO simplyserved_org;
GRANT INSERT, UPDATE (id, name, description) ON organization TO simplyserved_org;

-- Create function to get current organization ID from JWT claims
CREATE FUNCTION current_organization_id() RETURNS UUID AS $$
  SELECT nullif(current_setting('jwt.claims.current_organization_id', true), '')::uuid;
$$ LANGUAGE SQL stable;

-- Enable row level security
ALTER TABLE organization ENABLE ROW LEVEL SECURITY;

-- Create policy for organization access
CREATE POLICY organization_tenant_isolation_policy ON organization
  USING (id = current_organization_id());

-- Allow system user to bypass RLS
-- ALTER TABLE organization FORCE ROW LEVEL SECURITY;


COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START

BEGIN;

-- Drop the organization table
DROP TABLE IF EXISTS organization CASCADE;

-- Drop the audit function if no other tables are using it
-- Note: In a real scenario, you might want to check if other tables use this function
DROP TRIGGER IF EXISTS set_organization_audit_fields ON organization;
DROP FUNCTION IF EXISTS current_organization_id;

COMMIT;
-- DOWN MIGRATION END

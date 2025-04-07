-- Migration: create_organization_table
-- Created at: 2025-04-07 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;

-- Create organization table
CREATE TABLE organization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ,
    modified_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_by UUID,
    modified_by UUID,
    archived_by UUID
);

-- Create a trigger function to set audit fields
CREATE OR REPLACE FUNCTION set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Set created_at to NOW() if this is a new record
    IF TG_OP = 'INSERT' THEN
        NEW.created_at = NOW();
        NEW.created_by = current_setting('app.current_user', true)::UUID;
    END IF;
    NEW.modified_at = NOW();
    NEW.modified_by = current_setting('app.current_user', true)::UUID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on organization table
CREATE TRIGGER set_organization_audit_fields
BEFORE INSERT OR UPDATE ON organization
FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

-- Enable Row Level Security on organization table
ALTER TABLE organization ENABLE ROW LEVEL SECURITY;

-- Create policy to restrict access based on tenant
CREATE POLICY organization_tenant_isolation ON organization
    USING (id = current_setting('app.current_tenant', true)::UUID);

-- Grant permissions to use the organization table
GRANT SELECT, DELETE ON organization TO simplyserved;
GRANT INSERT, UPDATE (id, name, description) ON organization TO simplyserved;

COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;

-- Drop policy
DROP POLICY IF EXISTS organization_tenant_isolation ON organization;

-- Drop trigger
DROP TRIGGER IF EXISTS set_organization_audit_fields ON organization;

-- Drop function (only if not used by other tables)
-- DROP FUNCTION IF EXISTS set_audit_fields();

-- Drop table
DROP TABLE IF EXISTS organization;

COMMIT;
-- DOWN MIGRATION END

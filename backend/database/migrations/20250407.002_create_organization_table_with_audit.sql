-- Migration: create_organization_table_with_audit
-- Created at: 2025-04-07 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;

-- Create a trigger function to set audit fields
CREATE OR REPLACE FUNCTION set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Set created_at to NOW() if this is a new record
    IF TG_OP = 'INSERT' THEN
        NEW.created_at = NOW();
        NEW.created_by = current_setting('app.current_user', true);
    END IF;
    NEW.modified_at = NOW();
    NEW.modified_by = current_setting('app.current_user', true);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- Grant permissions
GRANT SELECT ON organization TO simplyserved;
GRANT DELETE ON organization TO simplyserved_org;
GRANT INSERT, UPDATE (id, name, description) ON organization TO simplyserved_org;

COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;

-- Drop the organization table
DROP TABLE IF EXISTS organization;

-- Drop the audit function if no other tables are using it
-- Note: In a real scenario, you might want to check if other tables use this function
DROP FUNCTION IF EXISTS set_audit_fields();

COMMIT;
-- DOWN MIGRATION END

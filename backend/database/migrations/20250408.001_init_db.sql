-- Migration: init_db
-- Created at: 2025-04-08 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE FUNCTION system_tenant_id() RETURNS UUID AS $$
  SELECT 'dfdb8f1c-14e7-11f0-952a-7c1e52225885'::UUID;
$$ LANGUAGE SQL stable;

CREATE FUNCTION system_user_id() RETURNS UUID AS $$
  SELECT 'fe64beb8-14e7-11f0-9158-7c1e52225885'::UUID;
$$ LANGUAGE SQL stable;

CREATE FUNCTION current_user_id() RETURNS UUID AS $$
  SELECT nullif(current_setting('jwt.claims.current_user_id', true), '')::uuid;
$$ LANGUAGE SQL stable;

-- create a trigger function to set audit fields
CREATE OR REPLACE FUNCTION set_audit_fields()
RETURNS trigger AS $$
BEGIN
    -- set created_at to now() if this is a new record
    IF tg_op = 'insert' THEN
        new.created_at = now();
        new.created_by = current_setting('app.current_user_id', true);
        new.organization_id = current_setting('app.current_tenant_id', true);
    END IF;
    new.modified_at = now();
    new.modified_by = current_setting('app.current_user_id', true);
    RETURN new;
END;
$$ LANGUAGE plpgsql;

COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;

-- drop the audit function if no other tables are using it
-- note: in a real scenario, you might want to check if other tables use this function
DROP FUNCTION IF EXISTS set_audit_fields;
DROP FUNCTION IF EXISTS system_tenant_id;
DROP FUNCTION IF EXISTS system_user_id;
DROP FUNCTION IF EXISTS current_tenant_id;
DROP FUNCTION IF EXISTS current_user_id;

COMMIT;
-- DOWN MIGRATION END

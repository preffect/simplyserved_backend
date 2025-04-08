-- Migration: create_organization_table_with_audit
-- Created at: 2025-04-07 00:00:00

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;

CREATE TYPE simplyserved.jwt_token AS (
  role TEXT,
  exp INTEGER,
  user_id UUID,
  email VARCHAR
);

create function simplyserved.generate_jwt(
  user_id UUID,
) returns simplyserved.jwt_token as $$
declare
  user_account simplyserved.user;
begin
  select u.* into user 
    from simplyserved.user as u
    where u.id = user_id;

  if user_account.email = email then
    return (
      'person_role',
      extract(epoch from now() + interval '7 days'),
      user_account.id,
      user_account.email
    )::my_public_schema.jwt_token;
  else
    return null;
  end if;
end;
$$ language plpgsql strict security definer;

create function current_tenant_id() returns integer as $$
  select u.organization_id from user u where u.id = nullif(current_setting('jwt.claims.user_id', true), '')::integer;
$$ language sql stable;

create function current_user_id() returns integer as $$
  select nullif(current_setting('jwt.claims.user_id', true), '')::integer;
$$ language sql stable;

COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;

DROP TYPE IF EXISTS simplyserved.jwt_token;

-- Drop the organization table
DROP TABLE IF EXISTS organization;

-- Drop the audit function if no other tables are using it
-- Note: In a real scenario, you might want to check if other tables use this function
DROP FUNCTION IF EXISTS set_audit_fields();
drop function if exists simplyserved.generate_jwt;
drop function if exists simplyserved.current_tenant_id;
drop function if exists simplyserved.current_user_id;

COMMIT;
-- DOWN MIGRATION END

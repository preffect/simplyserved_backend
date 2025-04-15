# AI Prompt Template for Database Migrations

Use this template when asking an AI to help you create a new database migration.

## Template

```
Create a PostgreSQL migration script to [add the following columns to the appUser table].

The migration should:
1. Add columns
- first_name
- middle_name
- last_name
- salutation
- staff_type, ENUM [MANAGER, SERVER, HOST, RUNNER]

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- grant INSERT to all new rows on this table except the audit columns to user simplyserved
- grant UPDATE to all new rows on this table except the audit columns and organization_id to user simplyserved
- migrations should be placed in ./backend/database/migrations

Migration files should be of the following format:

```
-- Migration: $name
-- Created at: $(date -u +"%Y-%m-%d %H:%M:%S")

-- Write your migration SQL here

-- UP MIGRATION START
BEGIN;
-- Add your schema changes here
COMMIT;
-- UP MIGRATION END

-- DOWN MIGRATION START
BEGIN;
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks
COMMIT;
-- DOWN MIGRATION END

```

## IGNORE EVERYTHING BELOW THIS LINE

## How to Use This Template

1. Copy the template above
2. Fill in your specific requirements
3. Provide context about existing schema
4. Run the migration creation command:
   ```bash
   ./db-migrate.sh create your_migration_name
   ```
5. Paste the AI-generated SQL into the created migration file
6. Review and adjust the SQL as needed
7. Apply the migration:
   ```bash
   ./db-migrate.sh apply
   ```

## Best Practices for Migrations

- Keep migrations focused on a single logical change
- Test migrations in development before applying to production
- Consider data volume when adding/removing indexes
- Include comments explaining complex operations
- Always include a way to roll back changes ("down" migration)
- Use transactions to ensure migrations are atomic

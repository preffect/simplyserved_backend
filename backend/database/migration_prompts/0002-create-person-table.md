```
Create a PostgreSQL migration script to add a base Person table, and a StaffPerson table.

The migration should:
1. create a person table with first_name, last_name, address, phone, personType, user_id
   - user_id is nullable and foreign key to the user table
   - personType is a non-nullable enum [STAFF, CUSTOMER]
2. create a staffPerson table staffType, notes, person_id
   - person_id is non-nullable foreign key to person table
   - staffType is non-nullable enum [ADMIN, MANAGER, SERVER, HOST, RUNNER]
2. create a customer table
3. [SPECIFIC REQUIREMENT 3]

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets

Current database schema includes:
a users table with fields for email and password hash

Example usage of this feature:
Person is a base table and will be extended with staffPerson, and customerPreson

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- place the migration file in /backend/database/migrations/
- use UUID primary keys
- all tables should have audit columns (created_at, modified_at, archived_at, created_by, modified_by, archived_by)
- created_by, modified_by, archived_by fields should be foreign keys to the users table
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets
- migrations should be placed in ./backend/database/migrations


Migration files should be of the following format. Update migrate.sh to extract the Up migration when applying, and extract the Down migration when rolling back:

-- Migration: $name
-- Created at: $(date -u +"%Y-%m-%d %H:%M:%S")

-- Write your migration SQL here

-- UP MIGRATION START
-- Add your schema changes here
-- UP MIGRATION END

-- DOWN MIGRATION START
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks
-- DOWN MIGRATION END

```

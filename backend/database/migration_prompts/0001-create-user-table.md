Create a PostgreSQL migration script to add a users table with authentication capabilities.

The migration should:
1. Create a users table with fields for email, password hash
2. Add appropriate indexes for fast lookups
3. Ensure email is unique
4. Add a role field with default permissions

Technical details:
- Database: PostgreSQL 15
- place the migration file in /backend/database/migrations/
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- use UUID primary keys
- all tables should have audit columns (created_at, modified_at, archived_at, created_by, modified_by, archived_by)
- created_by, modified_by, archived_by fields should be foreign keys to the users table
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets
- migrations should be placed in ./backend/database/migrations

Current database schema includes:
No existing tables yet, this is the first migration.

Example usage of this feature:
The users table will be used for authentication and authorization in the application. Users will register with email and password, and the system will store password hashes securely. 

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
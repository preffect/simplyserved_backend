# AI Prompt Template for Database Migrations

Use this template when asking an AI to help you create a new database migration.

## Template

```
Create a PostgreSQL migration script to [DESCRIBE YOUR GOAL].

The migration should:
1. [SPECIFIC REQUIREMENT 1]
2. [SPECIFIC REQUIREMENT 2]
3. [SPECIFIC REQUIREMENT 3]

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets

Current database schema includes:
[DESCRIBE EXISTING TABLES/SCHEMA THAT ARE RELEVANT]

Example usage of this feature:
[DESCRIBE HOW THIS MIGRATION WILL BE USED IN THE APPLICATION]
```

## Example

```
Create a PostgreSQL migration script to add a users table with authentication capabilities.

The migration should:
1. Create a users table with fields for username, email, password hash, and timestamps
2. Add appropriate indexes for fast lookups
3. Ensure email and username are unique
4. Add a role field with default permissions

Technical details:
- Database: PostgreSQL 15
- Migration naming convention: YYYYMMDD.NNN_descriptive_name.sql
- Include both "up" migration (changes to apply) and "down" migration (how to roll back)
- Follow best practices for PostgreSQL schema design
- Consider performance implications for large datasets

Current database schema includes:
No existing tables yet, this is the first migration.

Example usage of this feature:
The users table will be used for authentication and authorization in the application. Users will register with email and password, and the system will store password hashes securely.
```

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

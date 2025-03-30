-- Migration: sample_migration
-- Created at: 2025-03-30 12:00:00

-- Write your migration SQL here

-- UP MIGRATION START
-- Add your schema changes here
CREATE TABLE IF NOT EXISTS sample_table (
    id serial PRIMARY KEY,
    name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
-- UP MIGRATION END

-- DOWN MIGRATION START
-- Add SQL to revert the changes made in the Up migration
-- This section is required for testing and rollbacks
DROP TABLE IF EXISTS sample_table;
-- DOWN MIGRATION END

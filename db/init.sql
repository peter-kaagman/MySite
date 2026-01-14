# PostgreSQL init script for MySite
# This file runs automatically when PostgreSQL container starts for the first time

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set default encoding
SET client_encoding = 'UTF8';

-- You can add your schema here, or let Dancer2/DBIC handle it
-- For now, this is just a placeholder for future initialization

-- Example: Create a simple health check table
CREATE TABLE IF NOT EXISTS health_check (
    id SERIAL PRIMARY KEY,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO health_check (checked_at) VALUES (CURRENT_TIMESTAMP);

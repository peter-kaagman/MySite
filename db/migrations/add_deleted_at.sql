-- Add deleted_at column for soft delete functionality
-- Migration for issue #60: Implement article deletion functionality

ALTER TABLE article ADD COLUMN deleted_at DATETIME NULL;

-- Add index for performance on deleted_at queries
CREATE INDEX idx_article_deleted_at ON article(deleted_at);

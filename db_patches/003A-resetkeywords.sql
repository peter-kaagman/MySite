.bail on

PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

-- Eerst de koppeltabel leegmaken vanwege foreign keys
DELETE FROM article_keyword;

-- Daarna de keywords zelf leegmaken
DELETE FROM keyword;

-- Cardinaliteit herstellen:
-- Een artikel mag een keyword maar 1 keer gekoppeld hebben.
CREATE UNIQUE INDEX IF NOT EXISTS article_keyword_unique
ON article_keyword(articleid, keywordid);

COMMIT;

-- Controle
SELECT COUNT(*) AS article_keyword_count
FROM article_keyword;

SELECT COUNT(*) AS keyword_count
FROM keyword;

PRAGMA index_list('article_keyword');
-- Voeg SEO flags toe aan pages

ALTER TABLE page
ADD COLUMN include_in_sitemap INTEGER NOT NULL DEFAULT 1;

ALTER TABLE page
ADD COLUMN allow_indexing INTEGER NOT NULL DEFAULT 1;

-- Login niet in sitemap en niet indexeerbaar
UPDATE page
SET include_in_sitemap = 0,
    allow_indexing    = 0
WHERE slug = 'login';

-- Homepage wordt apart toegevoegd aan sitemap
-- maar moet wel indexeerbaar blijven
UPDATE page
SET include_in_sitemap = 0,
    allow_indexing    = 1
WHERE slug = 'index';
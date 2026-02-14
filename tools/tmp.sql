UPDATE wp_options
SET option_value = REPLACE(option_value, 'https://www.bilbos-stekkie.com', 'https://bilbo.prjv.nl')
WHERE option_name IN ('siteurl', 'home');

UPDATE wp_posts
SET guid = REPLACE(guid, 'https://www.bilbos-stekkie.com', 'https://bilbo.prjv.nl');

UPDATE wp_posts
SET post_content = REPLACE(post_content, 'https://www.bilbos-stekkie.com', 'https://bilbo.prjv.nl');


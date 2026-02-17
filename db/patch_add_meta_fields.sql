
ALTER TABLE article ADD COLUMN meta_title VARCHAR(255);
ALTER TABLE article ADD COLUMN meta_description TEXT;

ALTER TABLE page ADD COLUMN meta_title VARCHAR(255);
ALTER TABLE page ADD COLUMN meta_description TEXT;

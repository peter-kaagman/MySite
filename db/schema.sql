CREATE TABLE IF NOT EXISTS "category" (
  "category_id" INTEGER PRIMARY KEY NOT NULL,
  "title" text NOT NULL,
  "desc" text,
  "created" timestamp DEFAULT current_timestamp,
  "slug" text
, meta_title text, meta_description  text);
CREATE UNIQUE INDEX "category_slug_unique" ON "category" ("slug");
CREATE UNIQUE INDEX "category_title_unique" ON "category" ("title");
CREATE TABLE IF NOT EXISTS "keyword" (
  "keyword_id" INTEGER PRIMARY KEY NOT NULL,
  "title" text NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "slug" text
);
CREATE UNIQUE INDEX "keyword_slug_unique" ON "keyword" ("slug");
CREATE UNIQUE INDEX "keyword_title_unique" ON "keyword" ("title");
CREATE TABLE IF NOT EXISTS "role" (
  "role_id" INTEGER PRIMARY KEY NOT NULL,
  "name" text NOT NULL
);
CREATE TABLE IF NOT EXISTS "user" (
  "user_id" INTEGER PRIMARY KEY NOT NULL,
  "source" text NOT NULL,
  "username" text NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "avatar" text,
  "roleid" integer NOT NULL,
  "name" text DEFAULT 'unknown',
  FOREIGN KEY ("roleid") REFERENCES "role"("role_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "user_idx_roleid" ON "user" ("roleid");
CREATE UNIQUE INDEX "user_username_unique" ON "user" ("username");

CREATE TABLE IF NOT EXISTS "page" (
  "page_id" INTEGER PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "authorid" integer NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "abstract" text NOT NULL,
  "meta_title" varchar(255),
  "meta_description" text,
  FOREIGN KEY ("authorid") REFERENCES "user"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "page_idx_authorid" ON "page" ("authorid");
CREATE UNIQUE INDEX "page_name_unique" ON "page" ("name");
CREATE UNIQUE INDEX "page_slug_unique" ON "page" ("slug");
CREATE TABLE IF NOT EXISTS "article" (
  "article_id" INTEGER PRIMARY KEY NOT NULL,
  "title" text NOT NULL,
  "slug" text NOT NULL,
  "slugtitle" integer DEFAULT 1,
  "authorid" integer NOT NULL,
  "categoryid" integer NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "published" timestamp,
  "abstract" text NOT NULL,
  "meta_title" varchar(255),
  "meta_description" text,
  "deleted_at" datetime,
  FOREIGN KEY ("authorid") REFERENCES "user"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("categoryid") REFERENCES "category"("category_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "article_idx_authorid" ON "article" ("authorid");
CREATE INDEX "article_idx_categoryid" ON "article" ("categoryid");
CREATE UNIQUE INDEX "article_slug_unique" ON "article" ("slug");
CREATE UNIQUE INDEX "article_title_unique" ON "article" ("title");
CREATE TABLE IF NOT EXISTS "page_content" (
  "page_content_id" INTEGER PRIMARY KEY NOT NULL,
  "pageid" integer NOT NULL,
  "version" integer NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "published" timestamp,
  "editorid" integer NOT NULL,
  "content" text NOT NULL,
  FOREIGN KEY ("editorid") REFERENCES "user"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("pageid") REFERENCES "page"("page_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "page_content_idx_editorid" ON "page_content" ("editorid");
CREATE INDEX "page_content_idx_pageid" ON "page_content" ("pageid");
CREATE TABLE IF NOT EXISTS "article_content" (
  "article_content_id" INTEGER PRIMARY KEY NOT NULL,
  "articleid" integer NOT NULL,
  "version" integer NOT NULL,
  "editorid" integer NOT NULL,
  "created" timestamp DEFAULT current_timestamp,
  "content" text NOT NULL,
  FOREIGN KEY ("articleid") REFERENCES "article"("article_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("editorid") REFERENCES "user"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "article_content_idx_articleid" ON "article_content" ("articleid");
CREATE INDEX "article_content_idx_editorid" ON "article_content" ("editorid");
CREATE TABLE IF NOT EXISTS "article_keyword" (
  "articleid" integer NOT NULL,
  "keywordid" integer NOT NULL,
  FOREIGN KEY ("articleid") REFERENCES "article"("article_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("keywordid") REFERENCES "keyword"("keyword_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX "article_keyword_idx_articleid" ON "article_keyword" ("articleid");
CREATE INDEX "article_keyword_idx_keywordid" ON "article_keyword" ("keywordid");

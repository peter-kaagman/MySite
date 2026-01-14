--
-- Role table
Drop Table If Exists `role`;
CREATE TABLE  `role` (
	`role_id` integer primary key AutoIncrement,
	`name` TEXT NOT NULL
);
--
-- User table
Drop Table If Exists `user`;
CREATE TABLE IF NOT EXISTS `user` (
	`user_id` INTEGER Primary Key AutoIncrement,
	`source` TEXT NOT NULL,
	`username` Text NOT NULL UNIQUE,
    `created` TimeStamp Default CURRENT_TIMESTAMP,
	`avatar` TEXT,
	`roleid` INTEGER NOT NULL,
	`name` TEXT Default 'unknown',
	FOREIGN KEY(`roleid`) REFERENCES `role`(`role_id`)
);
--
-- Page table
Drop Table If Exists `page`;
CREATE TABLE  `page` (
	`page_id` integer primary key AutoIncrement,
	`name` TEXT NOT NULL UNIQUE,
	`slug` TEXT NOT NULL UNIQUE,
	`authorid` INTEGER NOT NULL,
	`created` TimeStamp Default CURRENT_TIMESTAMP,
	`abstract` TEXT NOT NULL,
	FOREIGN KEY(`authorid`) REFERENCES `user`(`user_id`)
);
--
-- Page_Content table
Drop Table If Exists `page_content`;
CREATE TABLE `page_content` (
	`page_content_id` integer primary key AutoIncrement,
	`pageid` INTEGER NOT NULL,
	`version` INTEGER NOT NULL,
    `created` TimeStamp Default CURRENT_TIMESTAMP,
    `published` TimeStamp,
	`editorid` INTEGER NOT NULL,
	`content` TEXT NOT NULL,
	FOREIGN KEY(`pageid`) REFERENCES `page`(`page_id`),
	FOREIGN KEY(`editorid`) REFERENCES `user`(`user_id`)
);
--
-- Category table
Drop Table If Exists `category`;
CREATE TABLE `category` (
	`category_id` integer primary key AutoIncrement,
	`title` TEXT NOT NULL UNIQUE,
	`desc` Text,
    `created` TimeStamp Default CURRENT_TIMESTAMP
);
--
-- Keyword table
Drop Table If Exists `keyword`;
CREATE TABLE `keyword` (
	`keyword_id` integer primary key AutoIncrement,
	`title` TEXT NOT NULL UNIQUE,
    `created` TimeStamp Default CURRENT_TIMESTAMP
);
--
-- Article table
Drop Table If Exists `article`;
CREATE TABLE `article` (
	`article_id` integer primary key AutoIncrement,
	`title` TEXT NOT NULL UNIQUE,
	`slug` TEXT NOT NULL UNIQUE,
	`slugtitle` INTEGER Default 1,
	`authorid` INTEGER NOT NULL,
	`categoryid` INTEGER NOT NULL,
	`created` TimeStamp Default CURRENT_TIMESTAMP,
	`published` TimeStamp,
	`abstract` TEXT NOT NULL,
	FOREIGN KEY(`authorid`) REFERENCES `user`(`user_id`),
	Foreign Key('categoryid') References `category`(`category_id`)
);
-- Article_Content table
Drop Table If Exists `article_content`;
CREATE TABLE `article_content` (
	`article_content_id` integer primary key AutoIncrement,
	`articleid` INTEGER NOT NULL,
	`version` INTEGER NOT NULL,
	`editorid` INTEGER NOT NULL,
	`created` TimeStamp Default CURRENT_TIMESTAMP,
	`content` TEXT NOT NULL,
FOREIGN KEY(`articleid`) REFERENCES `article`(`article_id`),
FOREIGN KEY(`editorid`) REFERENCES `user`(`user_id`)
);
--
-- Article_KeyWord tabel
Drop Table If Exists `article_keyword`;
CREATE TABLE  `article_keyword` (
	`articleid` INTEGER NOT NULL,
	`keywordid` INTEGER NOT NULL,
FOREIGN KEY(`articleid`) REFERENCES `article`(`article_id`),
FOREIGN KEY(`keywordid`) REFERENCES `keyword`(`keyword_id`)
);

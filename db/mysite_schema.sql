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
	`sourceuser` INTEGER NOT NULL UNIQUE,
    `created` TimeStamp Not Null,
	`avatar` TEXT NOT NULL,
	`roleid` INTEGER NOT NULL,
	`name` TEXT NOT NULL,
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
	`created` TimeStamp NOT NULL,
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
    `created` TimeStamp Not Null,
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
    `created` TimeStamp Not Null
);
--
-- Article table
Drop Table If Exists `article`;
CREATE TABLE `article` (
	`article_id` integer primary key AutoIncrement,
	`title` TEXT NOT NULL UNIQUE,
	`slug` TEXT NOT NULL UNIQUE,
	`authorid` INTEGER NOT NULL,
	`created` TimeStamp NOT NULL,
	`abstract` TEXT NOT NULL,
	FOREIGN KEY(`authorid`) REFERENCES `user`(`user_id`)
);
-- Article_Content table
Drop Table If Exists `article_content`;
CREATE TABLE `article_content` (
	`article_content_id` integer primary key AutoIncrement,
	`articleid` INTEGER NOT NULL,
	`version` INTEGER NOT NULL,
	`editorid` INTEGER NOT NULL,
	`created` TimeStamp NOT NULL,
	`published` TimeStamp NOT NULL,
	`content` TEXT NOT NULL,
FOREIGN KEY(`articleid`) REFERENCES `article`(`article_id`),
FOREIGN KEY(`editorid`) REFERENCES `user`(`user_id`)
);
--
-- Article_Category tabel
Drop Table If Exists `article_category`;
CREATE TABLE  `article_category` (
	`articleid` INTEGER NOT NULL,
	`categoryid` INTEGER NOT NULL,
FOREIGN KEY(`articleid`) REFERENCES `article`(`article_id`),
FOREIGN KEY(`categoryid`) REFERENCES `category`(`category_id`)
);
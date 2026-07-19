--
-- Add created and updated timestamps to user_profile table
--
ALTER TABLE "user_profile"
ADD COLUMN "created" timestamp;

ALTER TABLE "user_profile"
ADD COLUMN "updated" timestamp;

--
-- Set default values for created and updated timestamps
--
Update "user_profile" SET "created" = CURRENT_TIMESTAMP, "updated" = CURRENT_TIMESTAMP;

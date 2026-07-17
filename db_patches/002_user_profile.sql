--
-- User krijgt een publieke identifier.
--
ALTER TABLE "user"
ADD COLUMN "slug" TEXT NOT NULL DEFAULT '';

ALTER TABLE "user"
ADD COLUMN "is_trusted" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "user"
ADD COLUMN "is_banned" INTEGER NOT NULL DEFAULT 0;


--
-- Avatar verdwijnt uit user.
--
ALTER TABLE "user"
DROP COLUMN "avatar";


--
-- Auteurprofiel (1:1).
--
CREATE TABLE IF NOT EXISTS "user_profile" (
    "user_id" INTEGER PRIMARY KEY NOT NULL,
    "public_profile" INTEGER NOT NULL DEFAULT 0,
    "display_name" TEXT,
    "tagline" TEXT,
    "email" TEXT NOT NULL,
    "bio" TEXT,
    "meta_description" TEXT,

    FOREIGN KEY ("user_id")
        REFERENCES "user"("user_id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--
-- Socials (N:1).
--
CREATE TABLE IF NOT EXISTS "user_socials" (
    "social_id" INTEGER PRIMARY KEY NOT NULL,
    "user_id" INTEGER NOT NULL,
    "display_order" INTEGER NOT NULL DEFAULT 1,
    "social_name" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "social_url" TEXT NOT NULL,

    FOREIGN KEY ("user_id")
        REFERENCES "user"("user_id")
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--
-- Data aanpassingen
--

--
-- User Slugs en trusted status.
--
UPDATE "user"
SET "slug" = 'peter-kaagman', 
    "is_trusted" = 1
WHERE "user_id" = 1;

UPDATE "user"
SET "slug" = 'rita-menkhorst',
    "is_trusted" = 1
WHERE "user_id" = 2;

UPDATE "user"
SET "slug" = 'frank-kohne',
    "is_trusted" = 1
WHERE "user_id" = 3;


--
-- Peter profiel.
--
INSERT INTO "user_profile" (
    "user_id",
    "public_profile",
    "display_name",
    "email",
    "bio",
    "meta_description"
) VALUES (
    1,
    1,
    'Peter Kaagman',
    'prjv.kaagman@gmail.com',
    'Ik ben Peter Kaagman, geboren in 1962. Reken zelf maar uit hoe oud ik ben ;)

Hoewel ik mijn eerste wiskunde-examen ooit maakte met een [logaritmische rekenlineaal](https://nl.wikipedia.org/wiki/Rekenliniaal), zijn computers en programmeren altijd mijn passie geweest. Of eigenlijk nog specifieker: het analyseren van gegevens.

In 1979 begon ik met programmeren in [MECC](https://en.wikipedia.org/wiki/MECC) Basic op een timesharing-systeem van school, dat werkte nog met schrapkaarten (een soort ponskaarten). Daarna volgde een lange reis via C64 Basic en [Turbo Pascal](https://nl.wikipedia.org/wiki/Turbo_Pascal). Toen ontdekte ik [Slackware Linux](http://www.slackware.com/) en werd Perl jarenlang mijn vanzelfsprekende keuze voor scripting. Door mijn werk is daar later ook [PowerShell](https://nl.wikipedia.org/wiki/PowerShell) bij gekomen.

De laatste jaren houd ik me steeds meer bezig met Microsoft 365, Entra ID, cloudtechnologie, observability, automatisering en softwareontwikkeling. Zo heb ik bijvoorbeeld een systeem ontwikkeld om Microsoft Teams voor schoolklassen automatisch te faciliteren: [EduTeams](https://github.com/peter-kaagman/eduteams).

[MySite](https://github.com/peter-kaagman/mysite) gebruik ik als publicatiekanaal én als leerplatform voor de technieken, experimenten en projecten waar ik mee bezig ben. Ik geloof sterk in leren door te bouwen, fouten te maken en vervolgens uit te zoeken hoe het beter kan. Want beter kan het altijd.',
    'Peter Kaagman schrijft op MySite over Linux, Perl, Microsoft 365, observability, automatisering en de projecten waarmee hij zich bezighoudt.'
);

--
-- Social links.
--
INSERT INTO "user_socials" (
    "user_id",
    "social_name",
    "display_order",
    "display_name",
    "social_url"
)
VALUES
(
    1,
    'GitHub',
    1,
    'Peter Kaagman | GitHub',
    'https://github.com/peter-kaagman'
),
(
    1,
    'LinkedIn',
    2,
    'Peter Kaagman | LinkedIn',
    'https://www.linkedin.com/peterkaagman'
),
(
    1,
    'StackOverflow',
    3,
    'Peter Kaagman | StackOverflow',
    'https://stackoverflow.com/users/5513253/peter'
)
;

--
-- Nu pas de constraint op slug
--
--
-- Verzekeren dat de slug uniek is.
--
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_slug 
ON "user"("slug");

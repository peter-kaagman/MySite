-- Page data
Insert Into page (`page_id`, `name`, `slug`, `authorid`, `created`, `abstract`) VALUES
	((SELECT IFNULL(MAX(page_id),0)+1 FROM page), 'Index','index',1, DATETIME('NOW'),'Landing page')
;
--
-- Page_Content data
Insert Into page_content (`page_content_id`, `pageid`, `version`, `created`, `published`, `editorid`, `content`) VALUES
	((SELECT IFNULL(MAX(page_content_id),0)+1 FROM page_content),(SELECT last_insert_rowid()),1,DATETIME('NOW'),DATETIME('NOW'),1,'
Dit is mijn plek om ideeën en praktijkervaring te delen rondom IT, platformen en automatisering.

Geen marketingverhalen, maar werkende oplossingen, denkmodellen en experimenten uit de praktijk.

Onderwerpen variëren van Microsoft 365 en identity tot eigen projecten en microcontrollers.
Centraal staat steeds dezelfde vraag:

**Hoe houd je systemen begrijpelijk, beheersbaar en reproduceerbaar?**


Waar ik momenteel mee bezig ben:


## Cloud & Governance

Denkmodellen en experimenten om cloudplatformen te begrijpen.
Thema’s zijn onder andere governance, automatisering en herleidbaarheid — maar vooral: begrijpen.

[→ mprjv65](/category/mprjv65)


## MySite

Deze site is een project op zich. Waar ik voorheen met WordPress werkte, bouw ik nu een eigen CMS met Perl en Dancer2.

Een leertraject om webtechniek, architectuur en observability echt te begrijpen.

[→ MySite](/category/mysite)


## EduTeams

Automatisering van Teams provisioning op basis van onze onderwijsomgeving.

Van een eigen framework naar orkestratie via HelloID, met integraties tussen Magister en Microsoft 365.

[→ EduTeams](/category/eduteam)


## ESP32

Experimenteren met microcontrollers en hardware.

Momenteel vooral bezig met een time‑lapse camera, ontstaan vanuit een andere hobby: desem brood bakken.

[→ ESP32](/category/ptl)


## Brood

Desem brood bakken als tegenwicht voor IT.

Techniek, experimenteren en vooral: rust.

[→ Brood](/category/brood)
    ');
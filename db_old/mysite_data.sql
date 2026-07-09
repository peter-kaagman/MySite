--
-- Role data
Insert Into role (`role_id`,`name`) VALUES
	(1, 'Admin'),
	(2, 'Editor'),
	(3, 'Writer'),
	(4, 'Visitor')
;
--
-- User data
Insert Into user (`user_id`,`source`,`username`,`created`,`roleid`,`name`,`avatar`) VALUES
	(1,'google','prjv.kaagman@gmail.com',DATETIME('NOW'),'1','Peter/Google','https://lh3.googleusercontent.com/a-/ALV-UjUxjenJjnbze-yYos3gmj6a_oZFfCeSeGjNLrbCG-cKrCq5m6I=s96-c') --,
	-- (2,'github','peter-kaagman',DATETIME('NOW'),'1','Peter/GitHub','https://avatars.githubusercontent.com/u/42913077?v=4')
;
--
-- Page data
Insert Into page (`page_id`, `name`, `slug`, `authorid`, `created`, `abstract`) VALUES
	(1, 'About','about',1, DATETIME('NOW'),'About page'),
	(2, 'Privacy','privacy',1, DATETIME('NOW'),'Privacy page'),
	(3, 'Login','login',1, DATETIME('NOW'),'Login page'),
	(4, 'License','license',1, DATETIME('NOW'),'MIT License for MySite')
;
--
-- Page_Content data
Insert Into page_content (`page_content_id`, `pageid`, `version`, `created`, `published`, `editorid`, `content`) VALUES
	(1,1,1,DATETIME('NOW'),DATETIME('NOW'),1,'
# About
Niet veel hier
	'),
	(2,2,1,DATETIME('NOW'),DATETIME('NOW'),2,'
# Privacyverklaring

Deze site respecteert jouw privacy. Hieronder lees je wat er gebeurt met jouw gegevens:

- **Login en gebruikersgegevens:**  
  Je kunt inloggen via Google of GitHub. Bij het inloggen wordt alleen je gebruikersnaam, e-mailadres en (indien beschikbaar) avatar opgeslagen. Er worden geen extra gegevens verzameld of gedeeld met derden.

- **Cookies:**  
  Er worden alleen functionele cookies gebruikt om je sessie te bewaren tijdens het gebruik van de site. Er worden geen tracking- of advertentiecookies geplaatst.

- **Data-opslag:**  
  Je gegevens worden opgeslagen in een beveiligde database. Alleen de beheerder heeft toegang tot deze gegevens.

- **Analytics:**  
  Er wordt geen externe analytics of tracking gebruikt.

- **Contact:**  
  Voor vragen of verzoeken tot inzage/verwijdering van je gegevens kun je contact opnemen via [prjv.kaagman@gmail.com](mailto:prjv.kaagman@gmail.com).

- **Wijzigingen:**  
  Deze privacyverklaring kan worden aangepast. De actuele versie is altijd beschikbaar op deze pagina.
	'),
	(3,3,1,DATETIME('NOW'),DATETIME('NOW'),1,'
<p>Gebruik één van de volgende diensten om in te loggen. De userid van de gekozen service wordt gebruikt om hier in te loggen of een account voor je te maken.</p>
<ul>
    <li><a href="/auth/google">Google</a></li>
    <li><a href="/auth/github">GitHub</a></li>
</ul>
<p><emp>Let op:</emp><br>Diensten als Google en GitHub geven een verschillende userid terug. Gebruik dus altijd dezelfde dienst.</p>
	')
,
	(4,4,1,DATETIME('NOW'),DATETIME('NOW'),1,'
# MIT License

Copyright (c) 2026 Peter Kaagman

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
')
;

-- Privacy page content update (Markdown)
Insert Into page_content (`page_content_id`, `pageid`, `version`, `created`, `published`, `editorid`, `content`) VALUES
	((SELECT IFNULL(MAX(page_content_id),0)+1 FROM page_content), 2, 4, DATETIME('NOW'), DATETIME('NOW'), 1, '
')
;
--
-- Category data
Insert Into category (`category_id`, `title`, `desc`,`created`) VALUES
	(1, 'EduTeam',    'Articles about EduTeams',        DATETIME('NOW')),
	(2, 'MySite' ,    'Creating MySite',                DATETIME('NOW')),
	(3, 'Electronics','About mini controllers and such.',DATETIME('NOW'))
;
--
-- Keyword data
Insert Into keyword (`keyword_id`, `title`,`created`) VALUES
	(1, 'MS Graph',DATETIME('NOW')),
	(2, 'Perl'    ,DATETIME('NOW')),
	(3, 'Magister',DATETIME('NOW'))
;
--
-- Article data
Insert Into article (`article_id`, `title`, `slug`, `authorid`, `categoryid`, `created`,`published`, `abstract`) VALUES
	(1,'Artikel 1','artikel_1',1,1,'2024-11-20 14:23:21',DATETIME('NOW'),'Abstract artikel 1'),
	(2,'Artikel 2','artikel_2',2,2,'2024-11-21 14:23:21',DATETIME('NOW'),'Abstract artikel 2'),
	(3,'Artikel 3','artikel_3',1,3,'2024-11-22 14:23:21',DATETIME('NOW'),'Abstract artikel 3'),
	(4,'Artikel 4','artikel_4',1,1,'2024-11-23 14:23:21',DATETIME('NOW'),'Abstract artikel 4')
;
--
-- Article_Content data
Insert Into article_content (`article_content_id`,`articleid`,`version`,`editorid`,`created`,`content`) VALUES
	(1,1,1,1,'2024-11-20 14:23:21','Inhoud artikel 1'),
	(5,1,2,1,'2024-11-20 15:23:21','Inhoud artikel 1 versie 2'),
	(2,2,1,2,'2024-11-20 14:23:21','Inhoud artikel 2'),
	(3,3,1,1,'2024-11-20 14:23:21','Inhoud artikel 3'),
	(4,4,1,1,'2024-11-20 14:23:21','Inhoud artikel 4')
;
--
-- Article_Keyword data
Insert Into article_keyword (`articleid`,`keywordid`) VALUES
	(1,1),
	(1,2),
	(2,3),
	(3,1),
	(4,2)
;

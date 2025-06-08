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
	(3, 'Login','login',1, DATETIME('NOW'),'Login page')
;
--
-- Page_Content data
Insert Into page_content (`page_content_id`, `pageid`, `version`, `created`, `published`, `editorid`, `content`) VALUES
	(1,1,1,DATETIME('NOW'),DATETIME('NOW'),1,'
<h1>About</h1>
<p>Niet veel hier. Ben een beetje aan het knoeien met een eigen CMS. Gemaakt met:</p>
<ul>
  <li>Catalyst als webframework.</li>
  <li>SQLite (met DBIC als ORM) als database.</li>
  <li>Flexbox CSS layout, mobile first</li>
  <li>Waarschijnlijk Javascript voor de client side</li>
</ul>
<p>Als het even kan dan zal ik zaken als JQuery en Bootstrap proberen te vermijden. Back to basics</p>
<p>Mocht je de "nitty gritty" willen weten check dan mijn <a href="https://github.com/peter-kaagman/MySite">GitHub</p>
	'),
	(2,2,1,DATETIME('NOW'),DATETIME('NOW'),2,'
<h1>Privacy</h1>
<p>Niet veel hier. Maar hier ga ik iets vertellen over cookies en jouw data.</p>
	'),
	(3,3,1,DATETIME('NOW'),DATETIME('NOW'),1,'
<p>Gebruik één van de volgende diensten om in te loggen. De userid van de gekozen service wordt gebruikt om hier in te loggen of een account voor je te maken.</p>
<ul>
    <li><a href="/auth/google">Google</a></li>
    <li><a href="/auth/github">GitHub</a></li>
</ul>
<p><emp>Let op:</emp><br>Diensten als Google en GitHub geven een verschillende userid terug. Gebruik dus altijd dezelfde dienst.</p>
	')
;
--
-- Category data
Insert Into category (`category_id`, `title`, `slug`, `desc`,`created`) VALUES
	(1, 'EduTeam',    'eduteams','   Articles about EduTeams',        DATETIME('NOW')),
	(2, 'MySite' ,    'mysite' ,    'Creating MySite',                DATETIME('NOW')),
	(3, 'Electronics','electronics','About mini controllers and such.',DATETIME('NOW'))
;
--
-- Keyword data
Insert Into keyword (`keyword_id`, `title`, `slug`,`created`) VALUES
	(1, 'MS Graph','msgraph',DATETIME('NOW')),
	(2, 'Perl'    ,'perl',DATETIME('NOW')),
	(3, 'Magister','magister',DATETIME('NOW'))
;
--
-- Article data
Insert Into article (`article_id`, `title`, `slug`, `authorid`, `categoryid`, `created`, `abstract`) VALUES
	(1,'Artikel 1','artikel_1',1,'1','2024-11-20 14:23:21','Abstract artikel 1'),
	(2,'Artikel 2','artikel_2',2,'2','2024-11-21 14:23:21','Abstract artikel 2'),
	(3,'Artikel 3','artikel_3',1,'3','2024-11-22 14:23:21','Abstract artikel 3'),
	(4,'Artikel 4','artikel_4',1,'1','2024-11-23 14:23:21','Abstract artikel 4')
;
--
-- Article_Content data
Insert Into article_content (`article_content_id`,`articleid`,`version`,`editorid`,`created`,`published`,`content`) VALUES
	(1,1,1,1,'2024-11-20 14:23:21',DATETIME('NOW'),'Inhoud artikel 1'),
	(5,1,2,1,'2024-11-20 14:23:21',DATETIME('NOW'),'Inhoud artikel 1 versie 2'),
	(2,2,1,2,'2024-11-20 14:23:21',DATETIME('NOW'),'Inhoud artikel 2'),
	(3,3,1,1,'2024-11-20 14:23:21',DATETIME('NOW'),'Inhoud artikel 3'),
	(4,4,1,1,'2024-11-20 14:23:21',DATETIME('NOW'),'Inhoud artikel 4')
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

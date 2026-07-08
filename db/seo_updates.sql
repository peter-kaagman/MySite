update page
set
    meta_title = 'Over MySite - Bouwen, Testen en Documenteren',
    meta_description = 'Een persoonlijk technisch logboek over Linux, infrastructuur, automatisering, Kubernetes, ESP32-projecten en alles wat ontstaat uit nieuwsgierigheid en experimenteren.'
where slug = 'about';

update page
set
    meta_title = 'Privacyverklaring - MySite',
    meta_description = 'Lees hoe MySite omgaat met persoonsgegevens, Google-login, cookies, gegevensopslag en privacy.'
where slug = 'privacy';

update page
set
    meta_title = 'Contact - MySite',
    meta_description = 'Neem contact op met Peter Kaagman voor vragen, ideeën of discussie over IT, automatisering, softwareontwikkeling en platform design.'
where slug = 'contact';

update page
set
    meta_title = 'IT, Kubernetes en Automatisering - MySite',
    meta_description = 'Praktijkervaringen en experimenten rond Kubernetes, cloudplatformen, automatisering, observability, Microsoft 365, IAM en softwareontwikkeling.'
where slug = 'index';
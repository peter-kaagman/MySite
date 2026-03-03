## 2026-02-28 - Besluit: geen CSRF-plugin, eigen implementatie

**Besluit:**
- Na uitgebreide analyse van Dancer2::Plugin::CSRF en Dancer2::Plugin::CSRFI is besloten om voorlopig geen CSRF-plugin te gebruiken.
- Beide plugins zijn niet actief onderhouden of bieden geen volledige dekking voor moderne webapps met veel JSON/AJAX.
- Voor nu draait de applicatie zonder CSRF-bescherming.
- In de toekomst wordt een eigen CSRF-implementatie of custom plugin overwogen voor maximale controle en transparantie.

**Reden:**
- Eigen implementatie biedt meer zekerheid, eenvoud en onderhoudbaarheid dan afhankelijk zijn van verouderde of onvolledige plugins.

## 2026-02-28 - CSRF-plugins, AJAX/JSON en security

**Bevindingen:**
- Migratie uitgevoerd van Dancer2::Plugin::CSRF naar Dancer2::Plugin::CSRFI (actief onderhouden, 2022).
- CSRFI werkt direct voor traditionele forms (POST met form-encoded/multipart-data), maar **niet automatisch voor AJAX/JSON-POSTs** (content-type: application/json).
- Voor AJAX/JSON-POSTs moet handmatig `validate_csrf(request_header('X-CSRF-Token'))` worden aangeroepen in elke relevante route of via een before hook.
- Zonder deze extra check zijn API-routes kwetsbaar voor CSRF-aanvallen via aangepaste JavaScript of tools als curl/Postman.
- De plugin genereert en bewaart CSRF-tokens correct in de session en templates.
- Frontend (JS) kan het token veilig uitlezen uit een meta-tag en meesturen als header.

**Lessons learned:**
- Vertrouw niet blind op automatische CSRF-bescherming bij moderne webapps met veel JSON/AJAX.
- Controleer altijd of je backend daadwerkelijk requests zonder token blokkeert.
- Overweeg een eigen CSRF-check of een universele before hook voor volledige dekking.

## 2026-02-24 - Refactor en standaardisatie JavaScript modules (ES6-methodiek)

## 2026-02-27 - CSRF fix: Memcached firewall & Docker network

**Probleem:**
- CSRF-bescherming faalde in productie doordat Memcached niet bereikbaar was; firewall blokkeerde verbinding tussen app-container en Memcached.

**Oplossing:**
- Firewall-regels aangepast zodat containers via het Docker netwerk communiceren.
- Memcached is nu bereikbaar vanuit de app-container.
- CSRF-bescherming (Dancer2::Plugin::CSRF) werkt weer correct in productie.

**Resultaat:**
- Security is hersteld; POST requests en login zijn weer beschermd tegen CSRF.
- Productie draait nu met volledige CSRF-bescherming.

**Lessons learned:**
- Container networking en firewall-regels moeten altijd getest worden in een representatieve omgeving.
- Security features (zoals CSRF) zijn afhankelijk van correcte netwerkconfiguratie.

---
**Onderwerpen:**
- Grote opschoning en modernisering van article_edit.js: alle field managers (TitleManager, SearchCombo, SimpleFieldManager, ToastWrapper) worden nu als ES6 modules geïmporteerd en als class geïnitialiseerd, zonder window-prefix.
- Oude SimpleMDE/legacy-code verwijderd; Toast UI Editor volledig geïntegreerd via een nieuwe ToastWrapper-module.
- ToastWrapper beheert nu meerdere editors (content, abstract) generiek, inclusief save/cancel-handlers.
- Consistente initialisatie van alle managers, met duidelijke scheiding van verantwoordelijkheden.
- Projectregels nageleefd: alle issues direct via GitHub aangemaakt, geen losse issue-bestanden.
- Issue aangemaakt voor standaardisatie van het gebruik van article_id in managers (#56).

**ES6-methodiek voor modules:**
- Alle modules worden als ES6 modules geïmporteerd (import { ... } from ...).
- Geen gebruik meer van globale window-objecten voor managers of helpers.
- Functies en klassen worden direct geïmporteerd en aangeroepen.
- typeof-checks op window zijn niet meer nodig; als de import werkt, bestaat de functie/klasse.
- Dit zorgt voor betere testbaarheid, onderhoudbaarheid en consistentie in de codebase.

**Resultaat:**
- article_edit.js is nu overzichtelijk, efficiënt en volledig ES6-conform.
- Toast UI Editor werkt weer correct: toast_editor.js wordt nu altijd vóór toastWrapper geladen en zet ToastEditor expliciet op window, zodat initialisatie vanuit ToastWrapper altijd werkt.
- De codebase is klaar voor verdere uitbreiding en modernisering.
- Volgende stap: standaardisatie van het gebruik van article_id in alle managers.
# 2026-02-23 - Opschonen editor dependencies
- @toast-ui/editor npm dependency verwijderd; project gebruikt nu alleen CDN voor Toast UI Editor.
- Project is nu volledig opgeschoond van oude en onnodige editor dependencies.
23-02-2026: Feature request voor meertalige content en fallback aangemaakt als GitHub issue #52 (https://github.com/peter-kaagman/MySite/issues/52), zie ook ISSUE_meertaligheid_github.md.
## 2026-02-23 - Field managers laden niet in productie

**Probleem:**
- De title, category en keyword managers (TitleManager, SearchCombo, SimpleFieldManager) werden niet geladen in de productieomgeving.
- Geen foutmeldingen in de browserconsole.
- typeof-checks in article_edit.js faalden, vermoedelijk omdat de ES6 modules niet correct op window werden gezet of niet goed geladen werden.
- Pogingen om de klassen op window te zetten en script-tags aan te passen (type="module") losten het probleem niet op.
- Lint- en syntaxfouten zijn inmiddels opgelost, maar het functionele probleem bleef bestaan.

**Actie:**
- Oplossen en verder debuggen is verplaatst naar de development-omgeving.
- Geen verdere wijzigingen in productie tot het probleem in devel is opgelost.

**Besluit:**
- Issue is gesloten op productie, verder onderzoek volgt op devel.
## 2026-02-10 - Debug logging OAuth callback_url

**Onderwerp:**
- Debug-logregels toegevoegd aan User.pm om bij het opstarten van de app te tonen welke callback_url voor Google en Github daadwerkelijk uit de config geladen wordt.

**Resultaat:**
- In de logs is nu direct zichtbaar of de juiste (https) callback_url actief is in de productieomgeving.
## 2026-02-10 - npm postinstall, symlinks en Docker

**Onderwerp:**
- Symlinks naar node_modules werkten niet in Docker (public/css/vendor en public/javascripts/vendor).
- Bestaande symlinks/bestanden verwijderd om conflicts te voorkomen.

**Resultaat:**
- npm install werkt nu altijd, zowel lokaal als in Docker, en de benodigde bestanden zijn altijd beschikbaar zonder symlinks.

## 2026-02-10 - HTTPS, vhost, mixed content & OAuth productieconfig

**Onderwerpen:**
- Apache vhost configuratie voor Docker/Plack reverse proxy
- HTTPS redirect en statische bestanden via ProxyPass uitzonderingen
- Mixed content opgelost door root-relatieve paden in main.tt
- Analyse van alle templates op mixed content risico's
- Uitleg developer console (Network tab) voor CSS/JS laadsucces
- OAuth callback-URL probleem: intern http, extern https
- Oplossing: expliciete callback_url in Dancer2::Plugin::Auth::OAuth
- Per omgeving (production.yml) juiste callback instellen
- Docker compose productieomgeving laadt automatisch de juiste config (PLACK_ENV=production)
- Best practice: secrets in config_local.yml, omgevingsspecifiek in environments/production.yml

**Resultaat:**
- Site werkt nu correct via HTTPS, zonder mixed content
- OAuth werkt correct in productie dankzij expliciete callback_url in production.yml
- Documentatie en configuratie zijn up-to-date en gescheiden per omgeving

## 2026-02-10 - Migratieplan: Auth::Extensible voor OAuth

**Motivatie:**
- De huidige Dancer2::Plugin::Auth::OAuth plugin biedt te weinig flexibiliteit: de callback_url kan niet via de config worden ingesteld, waardoor problemen ontstaan met reverse proxies en HTTPS/HTTP-mismatches.
- Auth::Extensible is beter onderhoudbaar, ondersteunt meerdere authenticatieproviders en maakt configuratie van OAuth (inclusief callback) eenvoudiger en explicieter.
- Toekomstbestendig: eenvoudiger uitbreiden met extra providers (Github, Microsoft, etc.) en betere integratie met rollen/permissions.

**Migratieplan:**
1. **Dependencies toevoegen**
   - Voeg `Dancer2::Plugin::Auth::Extensible` en `Dancer2::Plugin::Auth::Extensible::Provider::OAuth` toe aan de cpanfile en installeer deze.
2. **Configuratie aanpassen**
   - Voeg een nieuw blok toe aan config.yml/production.yml:
     ```yaml
     plugins:
       Auth::Extensible:
         realms:
           - provider: OAuth
             module: Dancer2::Plugin::Auth::Extensible::Provider::OAuth
             client_id: ...
             client_secret: ...
             authorize_url: ...
             token_url: ...
             user_info_url: ...
             redirect_uri: ...
             scopes: ...
     ```
   - Verwijder oude Auth::OAuth config.
3. **Routes en login-flow aanpassen**
   - Pas login/logout-routes aan naar de conventies van Auth::Extensible (`/login`, `/logout`, `/auth/callback`).
   - Herschrijf bestaande login-logica (_login, _ok, _failed) naar de nieuwe flow.
4. **Session en user handling**
   - Gebruik de helpers van Auth::Extensible (`logged_in_user`, `user_roles`, etc.) voor authenticatie en autorisatie.
   - Pas profiel- en gebruikerslogica aan waar nodig.
5. **Templates updaten**
   - Update login- en foutmeldingen-templates voor de nieuwe flow.
6. **Testen**
   - Test alle authenticatie-gerelateerde functionaliteit (login, logout, profiel, rechten).
7. **Documentatie**
   - Documenteer de nieuwe setup en eventuele breaking changes in het projectlog en de README.

**Resultaat:**
- Flexibele, toekomstbestendige OAuth-authenticatie met volledige controle over callback-URL en providers.
- Minder afhankelijk van workarounds en expliciete codewijzigingen bij omgevingswissels.
- Eenvoudiger beheer en uitbreiding van authenticatie in de toekomst.

**Afspraak tijdens migratie:**
- Oude authenticatiecode en configuratie zoveel mogelijk uitcommentariëren in plaats van direct verwijderen. Dit maakt terugvallen, vergelijken en reviewen eenvoudiger tijdens de overgangsfase.

## 2026-02-12 - Grote opruimactie & documentatie

**Onderwerpen:**
- Kubernetes (k8s) map en alle YAML-bestanden verwijderd
- nginx map en configuratie verwijderd
- Oude Dockerfiles (alpine, distroless) verwijderd
- Alleen Dockerfile en docker-compose.prod.yml behouden
- Overbodige docker-compose.yml en docker-compose.simple.yml verwijderd
- UBUNTU_SETUP.md en SYNOLOGY_SETUP.md verwijderd (Ubuntu instructies geïntegreerd)
- test_log4perl.pl verwijderd
- DOCKER_PRODUCTION.md volledig herschreven en samengevoegd met Ubuntu-setup
- Nieuwe locatie voor Docker handleiding: ProjectDoc/DOCKER_PRODUCTION.md
- Artikelen/Eerste induk.md herschreven en voorzien van abstract
- Issue aangemaakt op GitHub met alle directe verbeterpunten uit het artikel 'Eerste indruk'

## 2026-02-14 - Verbeterde Markdown-ondersteuning

**Onderwerp:**
- Text::Markdown vervangen door Text::Markdown::Hoedown in Utils.pm.
- Standaardextensies geactiveerd: fenced code blocks, tables, autolink, strikethrough, footnotes, highlight, superscript.
- Reden: Text::Markdown ondersteunt geen moderne GitHub Markdown-features zoals fenced code blocks (```).

**Resultaat:**
- Artikelen en pagina's met moderne Markdown-features worden nu correct weergegeven.
- Codeblokken, tabellen en andere GitHub-style Markdown werken nu zoals verwacht.


**Onderwerp:**
- Migratie vereist aanpassing van JavaScript-integratie en mogelijk templates. Niet direct op productie doorvoeren, maar plannen en testen in een aparte branch.

**Resultaat:**
- Issue staat open voor toekomstige migratie en modernisering van de Markdown-editor.

## 2026-02-14 - Sitemap-functionaliteit

**Onderwerpen:**
- Sitemap-route toegevoegd aan Index.pm
- Sitemap bevat nu alle artikelen en pages
- lastmod voor artikelen gebaseerd op nieuwste ArticleContent-versie
- lastmod voor pages gebaseerd op nieuwste PageContent-versie
- base_url uit config gebruikt indien aanwezig, anders request->base
- robots.txt aangemaakt met verwijzing naar sitemap
- Foutafhandeling verbeterd voor datumvelden (string/object)
- Sitemap getest en gevalideerd

**To do / ideeën:**
- Eventueel uitbreiden met prioriteit/frequentie per url
- Automatische update bij content-wijzigingen

## 2026-02-15 - Moderne Markdown-weergave met highlighting en copy-knop

**Onderwerp:**
- Pandoc als Markdown-parser geïntegreerd in Utils.pm voor uitgebreide (GFM) ondersteuning.
- Highlight.js en copy-knop toegevoegd voor codeblokken in de artikelweergave.
- Nieuwe module codeblock_tools.js aangemaakt voor highlighting en copy-functionaliteit.
- Entry point content_show.js toegevoegd en alleen geladen als de boolean key `show_content` aan het template wordt meegegeven.
- show_content wordt nu in de controller gezet voor artikelweergave, en kan eenvoudig ook voor andere templates gebruikt worden.

**Resultaat:**
- Artikelen tonen nu moderne, fraai gestylede codeblokken met syntax highlighting en een copy-knop.
- De functionaliteit is generiek en kan eenvoudig op andere contentpagina's worden toegepast door `show_content => 1` mee te geven aan het template.

## Bugfix: UI Sync gebruikt verkeerde veldnaam voor update

**Datum:** 2026-02-17

### Probleem
Bij het opslaan van velden werd het event 'article-field-saved' getriggerd met de databaseveldnaam als field. De UI synchronisatie (uiSync.js) verwachtte echter het input-id van het HTML-element, waardoor de UI niet correct werd bijgewerkt.

### Oorzaak
- De functie handleSave in api.js dispatchte het event met field: dbField (databaseveld).
- Alle aanroepen van handleSave gaven alleen het databaseveld door.
- uiSync.js gebruikte field als id om het juiste element te updaten.

### Oplossing
- handleSave accepteert nu een vierde argument: inputID (het id van het inputveld).
- Het event 'article-field-saved' wordt nu getriggerd met field: inputID.
- Alle aanroepen van handleSave zijn aangepast zodat het input-id wordt meegegeven.

### Gewijzigde aanroepen
- **modules/simple_field.js**: saveField(newValue) → handleSave(this.articleId, { value: newValue }, this.dbField, this.fieldInput?.id)
- **article_edit.js**: saveBtn click handler → handleSave(articleId, data, 'content', 'contentmde')
- **modules/title_slug.js**: handleChange → handleSave(article, {value: newValue}, field, 'edit_slug')

### Resultaat
De UI wordt nu correct gesynchroniseerd na het opslaan van velden, omdat het juiste input-id wordt gebruikt bij het updaten van de elementen.

## 2026-02-22 - Nieuwe artikelen, database, CSS en footer

- Nieuwe artikelen toegevoegd:
  - Artikelen/GedroogdeDesem.md
  - Artikelen/basisbrood.md
- current_schema.sql toegevoegd
- Nieuwe afbeeldingen toegevoegd in public/images/site/
- Databasebestanden bijgewerkt:
  - db/mysite.sqlite
  - db/mysite_schema.sql
  - db/mysite (nieuw)
- CSS aangepast: public/css/style.css
- Footer-template bijgewerkt: views/includes/footer.tt
- Oude patch verwijderd: db/patch_add_meta_fields.sql

Deze commit bevat content- en structuurwijzigingen voor artikelen, database, styling en templates.

## 2026-02-25 - Nieuwe category logo functionaliteit, template refactor en projectregels update

**Onderwerpen:**
- Toevoeging van dynamische category logo's bij artikelen:
  - Nieuwe CSS voor `.category-logo-wrapper` en `.category-logo-img` (responsive, centraal uitgelijnd).
  - Nieuwe `logo`-methode in Category.pm bepaalt automatisch het juiste logo-pad.
  - list.tt toont nu per artikel het logo van de categorie.
- Template refactor:
  - list.tt gebruikt nu nieuwe methoden (`articleURL`, `categoryURL`, `userURL`, `keywordURL`).
  - sidebar.tt toont nu de echte naam van de gebruiker.
- DBIC schema updates:
  - Methoden als `returnURL` hernoemd naar `articleURL`, `categoryURL`, `userURL`, `keywordURL`.
- Kleine codewijzigingen:
  - Debugregel in Index.pm uitgecommentarieerd.
  - Stijlaanpassingen in style.css (o.a. abstracts, readmore, layout).
- Documentatie:
  - ProjectDoc/GenericProjectRules.md volledig herzien en uitgebreid.
  - ProjectDoc/ContestPrompt.md verwijderd.
- Database:
  - db/mysite.sqlite gewijzigd (mogelijk nieuwe data of structuur).
- Nieuwe assets:
  - Nieuwe category logo's toegevoegd in public/images/categories/ (o.a. mysite.png).

**Resultaat:**
- Artikellijst toont nu per categorie een eigen logo, volledig responsive.
- Codebase is consistenter qua methodenamen en template-aanroepen.
- Projectregels zijn duidelijker en uitgebreider vastgelegd.
- Documentatie en code zijn opgeschoond en voorbereid op verdere uitbreiding.

## 2026-02-25 - Structurele oplossing databasepad (issue #62)

**Onderwerp:**
- Structurele oplossing voor databasepad-complexiteit (zie issue #62, opvolger van issue #34).
- Probleem: SQLite databasepad stond als relatief pad in config.yml, wat leidde tot fouten bij verschillende werkdirectories (systemd, Docker, etc).

**Oplossing:**
- In config.yml blijft het relatieve pad voor development.
- In environments/production.yml is nu een absoluut pad opgenomen (bijv. /app/db/mysite.sqlite).
- De Perl-code in MySite.pm die het pad runtime aanpaste is verwijderd; geen padmanipulatie meer in de code.

**Resultaat:**
- Applicatie start nu altijd correct, ongeacht werkdirectory of deployment-methode.
- Configuratie is transparant en onderhoudbaar per omgeving.
- Geen hacks of workarounds meer nodig in de Perl-code.

## 2026-02-26 - Deployment problemen: CSRF, container conflicts, diskspace

**Problemen:**
- Tijdens deployment naar productie traden meerdere issues op:
  - CSRF-bescherming faalde: login en POST requests werden geweigerd door Dancer2::Plugin::CSRF, ondanks correcte config. Debugging wees uit dat de session manager (Memcached) correct draaide, maar de CSRF-token niet werd geaccepteerd in productie.
  - Container conflicts: Bij het rebuilden van Docker Compose ontstonden conflicts door oude containers die niet correct verwijderd werden. Dit veroorzaakte port binding errors en onvolledige service restarts.
  - Diskspace: Productiecontainer liep vast door onvoldoende diskspace, met als gevolg incomplete database writes en foutmeldingen bij het starten van services.

**Acties:**
- CSRF-fout is verplaatst naar de development-omgeving voor verdere debug. Productie draait tijdelijk zonder CSRF-bescherming tot fix is gevonden.
- Container conflicts opgelost door alle containers te verwijderen vóór rebuild (`docker compose down --remove-orphans`).
- Diskspace opgeschoond en monitoring ingesteld.
- Branch opnieuw gedeployed na cleanup; Memcached-container draait, healthcheck status ok.

**Lessons learned:**
- Environment separation is cruciaal: productie/development moeten volledig gescheiden configs en containers hebben.
- Container management vereist expliciete cleanup bij rebuilds.
- Security features (CSRF) moeten altijd getest worden in een representatieve omgeving vóór deployment.
- Monitoring van diskspace en healthchecks voorkomt onverwachte downtime.

**Status:**
- CSRF-bescherming pending fix; debugging loopt in development.
- Productie is stabiel, alle containers draaien correct.
- Log entry toegevoegd voor referentie en toekomstige troubleshooting.


## 2026-02-27 - CSRF frontend integratie en fix

**Acties:**
- CSRF-bescherming opnieuw geactiveerd in productie na fix van Memcached/firewall.
- CSRF-token als meta-tag toegevoegd aan main.tt voor JavaScript toegang.
- Utility getCsrfToken() gemaakt in utils.js om het token uit de meta-tag te lezen.
- Alle POST-fetch calls in modules/api.js sturen nu automatisch het CSRF-token mee als header ("X-CSRF-Token").
- article_edit.js, article_add.js en andere modules zijn nu CSRF-proof zonder extra imports.

**Lessons learned:**
- Frontend moet altijd het CSRF-token meesturen bij POST/PUT/DELETE requests.
- Centralisatie van fetch-calls in api.js maakt security eenvoudig en onderhoudbaar.
- Documentatie en logging van security fixes zijn essentieel voor troubleshooting.


**Onderwerpen:**
- Nieuwe header en menubalk (navbar) geïmplementeerd, met duidelijke scheiding tussen header (branding) en navigatie.
- CSS opgeschoond: layout-gerelateerde regels verplaatst naar layout.css, overige component/utility CSS in style.css.
- Oude, dubbele en conflicterende CSS verwijderd voor voorspelbare layout en eenvoudiger onderhoud.
- Category-logo nu compact en responsive gemaakt.
- Diverse uitlijn- en paddingproblemen opgelost in content, sidebar en navbar.

**Gedachte:**
- Overwogen om het Bootstrap grid systeem volledig te vervangen door een eigen minimal CSS grid (zonder externe afhankelijkheden).
- Voordeel: maximale controle, minimale CSS, geen ongebruikte klassen of overrides.
- Besloten om dit eerst in een los experiment te proberen voordat het in MySite wordt geïntegreerd.

**Resultaat:**
- De site heeft nu een strakke, overzichtelijke layout met duidelijke structuur.
- CSS is overzichtelijker en eenvoudiger te onderhouden.
- Bootstrap blijft voorlopig actief, maar een bootstraploze oplossing wordt onderzocht.
## [2026-03-03] Image uploader: grote refactor en uitbreidingen

- Multi-resize op basis van config (thumb, medium, large) met aspect ratio behoud
- WebP-generatie voor alle formaten
- Originele bestandsnaam en copyright automatisch in metadata (EXIF/IPTC/XMP) voor JPEG/PNG
- Copyright wordt alleen toegevoegd als er nog geen copyright aanwezig is
- Automatische aanmaak van een JSON-bestand per upload met:
    - Originele bestandsnaam
    - Upload-tijdstip
    - Copyright
    - Alle gegenereerde formaten (pad, type, afmetingen)
- Paden in JSON zijn relatief t.o.v. public/
- Toast UI Editor:
    - Upload blokkeert tijdens upload (spinner/overlay)
    - Na upload kan gebruiker kiezen welk formaat (original, thumb, medium, large) wordt ingevoegd
    - Eenvoudige modale keuzedialoog (uitbreidbaar naar Bootstrap)
- Robuuste validatie en foutafhandeling
- Code opgeschoond, debug verwijderd, toekomstbestendig voor gallery/AI


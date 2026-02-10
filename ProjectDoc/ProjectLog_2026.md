## 2026-02-10 - Debug logging OAuth callback_url

**Onderwerp:**
- Debug-logregels toegevoegd aan User.pm om bij het opstarten van de app te tonen welke callback_url voor Google en Github daadwerkelijk uit de config geladen wordt.

**Resultaat:**
- In de logs is nu direct zichtbaar of de juiste (https) callback_url actief is in de productieomgeving.
## 2026-02-10 - npm postinstall, symlinks en Docker

**Onderwerp:**
- Symlinks naar node_modules werkten niet in Docker (public/css/vendor en public/javascripts/vendor).
- Oplossing: npm postinstall-script toegevoegd dat benodigde JS- en CSS-bestanden van bootstrap en simplemde fysiek kopieert naar de juiste vendor directories.
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
# MySite Development Log - Deel 2 (2026)

## 2026-02-09 - Refactor & Modularisatie Analyse (Projectorganisatie)

### Gesprek: Opsplitsen van Article.pm en generieke utils

**Aanleiding:**
- Article.pm is te groot geworden en bevat meerdere verantwoordelijkheden (CRUD, keywords, categorieën, validatie, routing, template rendering).
- Vraag: Kan deze logischer worden opgesplitst?

**Analyse:**
- Article.pm bevat:
  - CRUD-logica voor artikelen
  - Keyword- en categoriebeheer
  - Validatie en error handling
  - Route-definities
  - Template rendering
- Probleem: Mix van business logica, DB-logica, en Dancer2 routing. Moeilijk te testen en te refactoren.

**Advies voor opsplitsing:**
- Controller (routes): Alleen route-definities en request handling (bijv. ArticleController.pm)
- Model/Service: DB-logica, validatie, business rules (bijv. ArticleService.pm)
- Helpers: Utility-functies (slugify, markdown, trim, etc.) in ArticleUtils.pm of generiek in Utils.pm

**Generieke utils:**
- Functies als `slugify`, `render_markdown`, `trim` zijn breder inzetbaar (bijv. user, comments, categorieën).
- Advies: Zet deze in een generieke Utils.pm module en importeer waar nodig.

**Concrete vervolgstap:**
- Lijst maken van alle functies in Article.pm en aangeven welke generiek kunnen.
- Projectorganisatie: Documenteren van deze refactor in het log, zodat toekomstige uitbreidingen en onderhoud eenvoudiger worden.

**Status:**
- Analyse en advies genoteerd. Volgende stap: migratieplan en concrete opsplitsing.


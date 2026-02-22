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

## 2026-02-14 - Issue aangemaakt: SimpleMDE vervangen

**Onderwerp:**
- GitHub issue aangemaakt om SimpleMDE te vervangen door een moderne Markdown-editor gebaseerd op CodeMirror 6 (bijv. Milkdown).
- Reden: SimpleMDE wordt niet langer actief onderhouden en voldoet niet meer aan moderne eisen.
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
- **modules/editor.js**: editor toolbar save → handleSave(articleId, data, field, editor.element?.id || 'contentmde')
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


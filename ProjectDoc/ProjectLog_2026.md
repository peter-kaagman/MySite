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


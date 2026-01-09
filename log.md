# MySite Development Log

## 2026-01-09 (issue #23) - Slug Validatie & UI Synchronisatie

### ✅ Slug Validatie & Normalisatie Geïmplementeerd

**DBIC Schema Validatie:**
- `lib/MySite/Schema/Result/Article.pm`: `insert()` en `update()` methods toegevoegd met `_validate_slug()`
- Valideert bij elke database operatie:
  - ❌ Geen spaties toegestaan
  - ❌ Alleen lowercase
  - ❌ Alleen a-z, 0-9, hyphens, underscores
- Gooit exception met duidelijke foutmelding bij invalid slug

**Route Handler Normalisatie:**
- `lib/MySite/Article.pm` `_field_update()`: Specifieke handler voor slug updates toegevoegd
- Gebruikt `slugify()` om user input automatisch te normaliseren
- Ook title+slug sync path aangepast om `slugify()` te gebruiken i.p.v. handmatige regex
- **UX verbetering**: Gebruiker krijgt geen error, slug wordt automatisch gecorrigeerd

**Utils Wijziging:**
- `lib/MySite/Utils.pm` `slugify()`: Aangepast om **underscores** te gebruiken i.p.v. hyphens
  - "My Article" → `my_article` (was `my-article`)
  - Consistent met bestaande database slugs

### ✅ Event-Driven UI Synchronisatie

**Architectuur:**
Volledig automatische UI synchronisatie via custom events - geen handmatige updates meer nodig.

**Backend Response:**
Route handlers geven nu **normalized values** terug in JSON response:
```json
{
  "success": 1,
  "slug": "my_article",  // Genormaliseerde waarde
  "message": "Slug updated successfully"
}
```

**Frontend Implementatie:**

1. **api.js** - Event Dispatch
   - `handleSave()` dispatcht `article-field-saved` event met:
     - Field name, article ID, originele waarde, server response
   - Alle modules die `handleSave()` gebruiken krijgen automatisch UI sync

2. **uiSync.js** (NIEUW) - Centrale Event Handler
   - Luistert naar `article-field-saved` events
   - Update automatisch DOM elementen met server values
   - Speciale behandeling per field type:
     - **slug**: Toont notificatie als genormaliseerd
     - **title**: Update ook slug als meegeleverd in response
     - **content**: Update version indicator
   - Visuele feedback: groene flash animatie op geupdate velden
   - Console logging voor debugging (`🔄 Syncing UI for field: ...`)

3. **article_edit.js** - Initialisatie
   - Import `initUISync()` en aanroep bij DOMContentLoaded
   - Eén regel code, alles automatisch werkend

4. **style.css** - Visuele Feedback
   - `.field-updated`: Groene flash animatie (0.5s pulse)
   - `.sync-notification`: Toast-style notificatie rechtsboven
   - Smooth transitions voor professionele UX

**Voordelen:**
- ✅ **Zero boilerplate**: Modules hoeven geen UI update code te bevatten
- ✅ **Consistent**: Alle field updates werken hetzelfde
- ✅ **Forget-proof**: Automatisch voor alle `handleSave()` calls
- ✅ **Debuggable**: Console logs tonen exact wat er gebeurt
- ✅ **User feedback**: Visuele indicatie van updates
- ✅ **UI/DB sync**: Gebruiker ziet altijd de database-werkelijkheid

**Test Scenario's:**
- Slug "Test   Artikel!!!" → UI toont `test_artikel` + notificatie
- Title wijzigen → beide title én slug velden updaten automatisch
- Content save → version number increment zichtbaar met animatie

---

## 2026-01-09 (issue #23) - Openstaande Issues

### ✅ ~~OPGELOST - Slug validatie~~
~~Slug validatie in `_field_update`~~ → **OPGELOST** via DBIC validatie + normalisatie

### 🟡 SECUNDAIR - Validatie hiaten
- **Lege waarden in content/abstract**: `/article/update/field/:id` accepteert lege waarden voor `content` en `abstract`
  - Geen trim+check op `$data->{value}` na `trim()`
  - **Fix nodig**: Voeg validatie toe dat `trim($data->{value})` niet leeg is voor deze velden
  - **Impact**: UI/UX - gebruiker kan per ongeluk content/abstract legen

###  TESTEN NODIG - SearchCombo keywords
- SearchCombo voor categories werkt, maar keywords nog niet volledig getest
- Waarschijnlijk al in orde door vandaag's wijzigingen in `user_can_edit_article`
- **Action**: Manual test in browser checken

### 📋 COSMETIC - UI/UX
- SearchCombo selectedItems Bootstrap layout is niet perfect
- Functionaliteit werkt, maar spacing/alignment kan beter
- **Action**: Laag prioriteit, later oppakken

---

## 2026-01-09 (issue #23)

### Article.pm Security & Code Quality Review

#### Security Audit - Route Authorization
Volledig overzicht van alle routes in `Article.pm` op autorisatie:

| Route | Methode | Handler | Auth Check | Status |
|-------|---------|---------|-----------|--------|
| `/article/keywords` | GET | `_get_keywords` | ❌ Geen | ✅ Opzettelijk (publiek) |
| `/article/categories` | GET | `_get_categories` | ❌ Geen | ✅ Opzettelijk (publiek) |
| `/article/new` | GET | `_get_article_new` | ✅ Rol-check | 🟢 OK |
| `/article/edit/:id` | GET | `_get_article_edit` | ✅ Auth + Eigendom/Rol | 🟢 OK |
| `/article/delete/:id` | GET | `_article_delete` | ✅ Auth + Eigendom/Rol | 🟢 OK |
| `/article/:category/:slug` | GET | `_article` | ❌ Geen | ✅ OK (publiek artikel) |
| `/article/add` | POST | `_post_article_new` | ✅ Rol-check | 🟢 OK |
| `/article/update/:field/:id` | POST | `_field_update` | ✅ Auth + Eigendom/Rol | 🟢 OK |
| `/article/keyword` | POST | `_handle_keyword` | ✅ Auth + Eigendom/Rol | 🟢 OK |
| `/article/category` | POST | `_handle_category` | ✅ Auth + Eigendom/Rol | 🟢 OK |

**Conclusie:** Alle routes correct beveiligd. Keywords/Categories zijn opzettelijk publiek (autocomplete endpoints).

#### Code Quality Improvements
- Route definitions vertically aligned (fat arrows) voor betere leesbaarheid
- `_field_update` refactored: meerdere return statements samengebracht tot één single exit point
- Redundante `content_type` calls verwijderd (Dancer2 `to_json()` zet dit automatisch)

#### Bug Fixes in `Utils.pm`
- **user_can_edit_article** uitgebreid om 'new article' scenario te ondersteunen:
  - Voorheen faalde check altijd als `$author = undef` (voor nieuwe artikelen)
  - Nu: als `!$author`, wordt alleen rol gecontroleerd (Admin/Editor/Writer)
  - Bestaande artikelen: rol + ownership check (Owner role moet ingesteld zijn)
- Dit maakt `_get_article_new` correcte authz possible met `user_can_edit_article($user, undef, \@allowed_roles)`

#### Parameter Order Fix
- `_handle_keyword` en `_handle_category` hadden verkeerde parameter volgorde voor `user_can_edit_article`
  - Was: `user_can_edit_article($user, $article, $author_obj)` → ❌ Fout (article object lacks username method)
  - Nu: `user_can_edit_article($user, $author_obj, \@allowed_roles)` → ✅ Correct

---

## 2026-01-07 (issue #23)

### Auth & Utils Update
- Utils teruggebouwd naar `Exporter` i.p.v. `Exporter::Tiny`; geen `qw(...)` meer gebruikt.
- "Odd/Uneven number of elements in hash assignment" melding is weg.
- Authenticatie-methodes aan het stroomlijnen: Utils alleen voor pure logica, geen UI/response afhandeling.
- Responsafhandeling per context: HTML-responders in routes/templates; JSON-responders in API-handlers.

### Auth::Extensible integratie (custom SessionOAuth provider)
- Dependency toegevoegd: `Dancer2::Plugin::Auth::Extensible` (cpanfile, versie >= 0.701) en geïnstalleerd met `carton install`.
- Config: realm `users` met provider `MySite::Auth::Provider::SessionOAuth` in `config.yml`.
- Provider: `lib/MySite/Auth/Provider/SessionOAuth.pm` gebruikt nu `Dancer2::Plugin::Auth::Extensible::Role::Provider` i.p.v. de deprecated `Provider::Base`.
- Session alignment: in OAuth callback wordt nu `logged_in_user` + `logged_in_user_realm` in de sessie gezet voor Extensible helpers.
- `MySite.pm`: plugin switch naar Auth::Extensible en `requires_login` gebruikt voor secured route.
- Article model: helper `is_owned_by($user)` toegevoegd voor resource-level checks.

Volgende stappen (optioneel):
- Voeg `requires_login`/`requires_any_role(Admin Editor Writer)` toe aan artikel create/edit routes in `Article.pm`.
- Vervang ad-hoc helpers door `logged_in_user()` + `user_has_role()` + `is_owned_by()` binnen handlers.
- Splits HTML vs JSON gedrag per route (of Accept-header) i.p.v. in Utils.
- Test: `carton exec plackup bin/app.psgi`, login via OAuth, check dat guarded routes werken; oefen 401/403 responses op API-routes.

---

## 2026-01-05 (issue #23)

### Auth & Utils Refactor
- Utils.pm switched to Exporter::Tiny (explicit import override) so helpers export correctly without Dancer2 shadowing import.
- Auth helpers `_require_user_logged_in` and `_user_can_edit_article` moved into Utils and exported; Article.pm now imports via `:all`.
- Keyword/Category endpoints now enforce the same auth check (owner/Admin/Editor) using the shared helper.
- Slug helpers `_slugify` and `_unique_slug` centralized in Utils; Article.pm uses them for create/update.
- Dependency added: Exporter::Tiny recorded in cpanfile; run `carton install` to fetch.

### Status Update - Edit Functionaliteit (bijna) Compleet

✅ **Article Edit is nu ( bijna ) volledig functioneel:**
- SearchCombo werkt correct met keywords (multi-select, add/remove via junction table)
- SearchCombo werkt correct met category (single-select via foreign key)
- MD content wordt correct opgeslagen en verwerkt (nieuwe versie per edit)
- MD abstract wordt correct opgeslagen en verwerkt
- Title/Slug manager werkt (auto-sync toggle, uniqueness check)

**JSON Serialization Fixes:**
- Alle API endpoints in `Article.pm` nu gefixed om `to_json()` te gebruiken:
  - `/article/keyword` (POST) - keyword toggle
  - `/article/category` (POST) - category update
  - `/article/keywords` (GET) - autocomplete search
  - `/article/categories` (GET) - autocomplete search
  - `/article/update/:field/:id` (POST) - field updates (content, title, abstract, slug)
- Proper volgorde: `status 200` → `content_type 'application/json'` → `return to_json(...)`

**Volgende stap: Article Create aligneren met Edit structuur**

### Bekend Probleem - Title/Slug Handling

⚠️ **Title/Slug validation:** 
- Als slug zelfstandig wordt geupdate (i.p.v. via title sync), accepteert het systeem spaties in de slug.
- Dit mag niet - slug moet altijd lowercase, hyphens voor spaties, geen spaties bevatten.
- TODO: Validatie toevoegen op backend `/article/update/slug/:id` endpoint (of op frontend in JS validation).

**Compleet overzicht: validatie in alle update routes in `Article.pm`:**

| Route | Autorisatie | Validatie Input | Validatie Slug | Opmerking |
|-------|-------------|-----------------|----------------|-----------|
| `POST /article/add` | ✅ (rol check) | ✅ (title, abstract, content, category required) | ✅ (via _unique_slug) | Nieuw artikel |
| `POST /article/update/:field/:id` - content | ✅ | ❌ | - | Geen check op lege waarde |
| `POST /article/update/:field/:id` - title+slug | ✅ | ❌ | ✅ (via regex) | Alleen als slugtitle=1 |
| `POST /article/update/:field/:id` - generic (slug) | ✅ | ❌ | ❌ **GEEN VALIDATIE** | **Spaties worden geaccepteerd** |
| `POST /article/update/:field/:id` - generic (abstract) | ✅ | ❌ | - | Geen check op lege waarde |
| `POST /article/keyword` | ❌ | ❌ | - | Geen user/article eigenaar check |
| `POST /article/category` | ❌ | ❌ | - | Geen user/article eigenaar check |
| `GET /article/keywords` | ❌ | ❌ | - | Search endpoint, info disclosure |
| `GET /article/categories` | ❌ | ❌ | - | Search endpoint, info disclosure |

**Security Fixes Nodig:**
- 🔴 `/article/keyword` en `/article/category`: **Autorisatie check toevoegen** (user moet eigenaar/editor/admin zijn van artikel)
- 🔴 `/article/update/slug/:id`: **Slug validatie toevoegen** (lowercase, hyphens, geen spaties)
- 🟡 `/article/update/content/:id` en `/article/update/abstract/:id`: **Validatie op niet-lege waarden**

---

### Debug Sessie - JSON Serialization

Actielijst (bewust parkeren tot edit klaar is):
- Afmaken edit-flow met SearchCombo modules voor category en keywords (MD-formaat blijft leidend).
- Daarna create-aligneren met edit-structuur (zelfde JS-modules voor category/keywords, zelfde Markdown aanpak).
- Pas zodra edit stabiel is: create herwerken en backend create uitbreiden met keywords/category wiring.

- Debug: "Odd number of elements in hash assignment" blijft komen bij Dancer2 import in 2.0.1. Geprobeerd: `with => {}` op alle `use Dancer2` statements, JSON serializer uit, template hashrefs opgeschoond; warning blijft (Dancer2 bug?), app werkt verder. Later opnieuw oppakken of upgraden zodra bugfixed release beschikbaar is.

---

## 2026-01-04 (issue #23)

- SearchCombo module verder uitgewerkt:
  - JSON parsing van hidden fields verbeterd met error handling
  - Logica toegevoegd om single object automatisch in array te wrappen
  - Ondersteuning voor lege/null data (defaults naar lege array)
  - Init method simplificatie: element IDs worden nu samengesteld uit field parameter met suffixes
    - In plaats van meerdere ID parameters door te geven, construeert de code nu bijvoorbeeld:
      - `article_id`, `${field}_data`, `${field}Container`
    - Dit maakt de init aanroep veel schoner en minder foutgevoelig
- Status:
  - ✅ De huidige category wordt getoond in het SearchCombo veld
  - 🔄 TODO: Nog testen of dit ook werkt voor keywords
  - ✅ OPGELOST: Lijst met beschikbare categorieën werd niet getoond
    - Oorzaak: `article_edit.js` gebruikte `'categoryid'` als field parameter
    - `searchItems()` verwachtte echter `'category'` of `'keyword'`
    - Fix: Parameter aangepast naar `'category'` → zoekopdracht werkt nu correct
  - 🔄 IN PROGRESS: Aanpassingen voor object format `{title, id}` in `loadItems()` en `addItemToList()`
    - Werken aan: huidige category actief maken in de beschikbare lijst
    - Voorstel gemaakt maar nog niet geïmplementeerd (geen zin meer vandaag)

---

## 2026-01-03 18:21 (issue #23)

- Category en keywords data worden nu als JSON strings doorgegeven aan het template:
  - Backend aangepast in `Article.pm`:
    - Keywords: `my @keyword_data = map { { title => $_->title, id => $_->keyword_id } } @keywords;`
    - Category: `my $category_data = { title => $category_obj->title, id => $category_obj->category_id };`
  - Beide worden geconverteerd naar JSON: `to_json(\@keyword_data)` en `to_json($category_data)`
  - Template ontvangt nu zowel ID als title voor category en keywords
  - Deze data wordt in hidden fields opgeslagen voor gebruik in JavaScript
- Voordeel: JavaScript kan nu met volledige data werken (ID + title) voor zowel initialisatie als updates

---

## 2026-01-03 17:10 (issue #23)

- Database probleem opgelost: applicatie gebruikt `db/mysite.sqlite` maar we initialiseerden `db/mysite`.
- Keywords worden nu correct opgehaald via DBIC `many_to_many` relatie (`$article->keywords->all`).
- Category en keyword data worden nu via template doorgegeven aan JavaScript:
  - `'category' => $categorie` (category title)
  - `'keywords' => \@keyword_titles` (array van keyword titles)
- Voordeel: geen extra API calls nodig vanuit JavaScript voor initiële waarden.

---

## 2026-01-02 18:45 (issue #23)

- Category waarde ophalen via JavaScript bleek problemen te geven:
  - Field parameter 'Category' vs database kolom 'categoryid' mismatch opgelost.
  - Backend aangepast: `_get_field` handler geeft nu category title terug i.p.v. ID (via DBIC relatie).
- Conclusie: betere aanpak is waarschijnlijk om initiële waarden via hidden velden in het template door te geven, in plaats van extra API calls vanuit JavaScript.

---

## 2026-01-01 17:05 (issue #23)

- Vraag genoteerd: in `api.js` nagaan of `handleSave` redundantie vertoont met `saveKeywordChange` en of één van beide kan worden vereenvoudigd.
  - Betrokken endpoints:
    - `POST /article/update/{field}/{article}` (gebruikt door `handleSave` voor content/meta)
    - `POST /article/keyword` (gebruikt door `saveKeywordChange` voor keywords)
  - Conclusie: niet redundant. Keywords heeft toggle-logica (many-to-many relatie), terwijl field update algemene veld-updates doet.

---

## 2026-01-01 16:30 (issue #23)

- SearchCombo verder uitgewerkt voor categories:
  - Typo in Article.pm gerepareerd: `vallues` → `values` in JSON response van `/article/categories` endpoint.
  - categoryManager.init parameters gecheckt en bevestigd (4 parameters: field, label, containerId, multiSelect).
  - SearchCombo container issue onderzocht en error handling toegevoegd.
  - Momenteel bezig met het tonen van de huidige category in het veld.

---

## 2026-01-01 09:15 - TODO List (issue #23)

### Todo:
- [ ] SearchCombo - HTML-elementen dynamisch aanmaken
- [ ] SearchCombo - Initialisatie afmaken (container element issue)
- [ ] SearchCombo - Werkend maken voor categories
- [ ] SearchCombo - Werkend maken voor keywords
- [ ] Meta data velden - Verder uitwerken
- [ ] Article create - Implementeren

---

## 2025-12-31 17:45 (issue #23)

- Doorontwikkeling van de SearchCombo-module:
  - De SearchCombo maakt nu zelfstandig alle benodigde HTML-elementen aan via JavaScript.
  - De input voor geselecteerde items en de zoekinterface worden dynamisch opgebouwd, inclusief Bootstrap row/col-structuur en label.
  - Eventlisteners voor interactie (toggle, focus) zijn centraal in de init-methode geplaatst.
  - De zichtbaarheid van de zoekinterface wordt nu via een CSS-class geregeld voor betere compatibiliteit met externe stylesheets.
  - Robuustheid toegevoegd: duidelijke foutmelding als de container niet gevonden wordt.
  - Er is nog een openstaand probleem: het netjes tonen van het selectedItems-veld in kolommen met labels (volgens de gewenste Bootstrap-structuur) werkt nog niet volledig naar wens.


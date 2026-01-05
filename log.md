# MySite Development Log

## 2026-01-05 (issue #23)

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


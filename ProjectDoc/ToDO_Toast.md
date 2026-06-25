## ToDo: Image verwerking verbeteringen

- [ ] Automatische thumbnail-generatie (bijv. 400x400 px) bij upload
- [ ] EXIF-rotatie: afbeeldingen automatisch rechtzetten op basis van EXIF-data
- [x] WebP-ondersteuning toevoegen (naast JPEG/PNG)
- [x] Bestandsgrootte optimaliseren (jpegoptim/optipng of Imager-opties)
- [x] Watermerk/copyright-overlay toevoegen (optioneel)
- [x] Uitgebreidere foutafhandeling en logging bij image processing
- [ ] Configuratie uitbreiden voor thumbnails/optimalisatie/watermerk
- [x] Content-type/magic-bytes check bij upload (niet alleen extensie/mime)

## ToDo: Generieke functies voor Article + Page

### Fase 1: Shared helpers (laag risico)

- [ ] `unique_slug` generiek maken met model/resultset parameter (Article + Page)
- [ ] Helper toevoegen voor "laatste content" ophalen met configureerbare relation/filter/order
- [ ] Helper toevoegen voor SEO/template context (canonical URL, title, meta_description)
- [ ] `to_iso8601` utility toevoegen in `Utils` (vervangen lokale closure in Article)

### Fase 2: Route/service refactor

- [ ] `_get_article` omzetten naar nieuwe shared helper-flow
- [ ] `/page/:slug` omzetten naar dezelfde shared helper-flow
- [ ] Gemeenschappelijke foutafhandeling voor "not found" en DB-fouten in beide handlers

### Fase 3: Generic update en versioning

- [ ] Generic payload parser + trim + non-empty validatie voor update endpoints
- [ ] Generic field update helper met optionele slug-sync hook (title -> slug)
- [ ] Generic content-version helper maken (werkt voor ArticleContent en PageContent)

### Fase 4: Auth en ownership hergebruik

- [x] Wrapper/helper voor edit-permissie checks (user + role + owner)
- [x] Toepassen op article edit/update paden
- [ ] Voorbereiden voor toekomstige page edit/update routes

### Acceptatiecriteria

- [ ] Bestaande article routes blijven functioneel (view/edit/update/new)
- [ ] Page route rendert identiek output voor bestaande content
- [ ] Geen regressie in canonical URL en meta velden
- [ ] Slug uniekheidscontrole werkt voor zowel Article als Page
- [ ] Testdekking toegevoegd voor shared helpers (minimaal unit-level)

### Validatie (carton context)

- Uitgevoerd: `carton exec -- perl -c lib/MySite/Utils.pm`
- Uitgevoerd: `carton exec -- perl -Ilib -c lib/MySite/Article.pm`
- Uitgevoerd: `carton exec -- prove -l t/001_base.t t/002_index_route.t`

### Bestaande tests (huidig)

- `t/001_base.t`
- `t/002_index_route.t`

## ToDo: Article.pm opsplitsen (technische schuld)

- [ ] `Article.pm` opdelen in kleinere modules (bijv. read/list/write of service + routes)
- [ ] Route-definities dun houden; query/business-logica verplaatsen naar helpers/service-laag
- [ ] Legacy routes en aliases behouden tijdens refactor (geen URL-regressies)
- [ ] Bestaande route-tests laten slagen en uitbreiden met dekking voor lijst/detail/edit-paden

# MySite Development Log

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
- Voordeel: geen extra API calls nodig vanuit JavaScri      pt voor initiële waarden.

---

## 2026-01-02 18:45 (issue #23)

- Category waarde ophalen via JavaScript bleek problemen te geven:
  - Field parameter 'Category' vs database kolom 'categoryid' mismatch opgelost.
  - Backend aangepast: `_get_field` handler geeft nu category title terug i.p.v. ID (via DBIC relatie).
- Conclusie: betere aanpak is waarschijnlijk om initiële waarden via hidden velden in het template door te geven, in plaats van extra API calls vanuit JavaScript.

---

## 2026-01-02 13:00 (issue #23)

- Besluit na analyse handlers in Article.pm:
  - Keywords is inderdaad speciaal omdat het een toggle heeft (add/remove relatie). Dit blijft via `POST /article/keyword` lopen.
  - Category zou echter via normale field update moeten kunnen (`POST /article/update/{field}/{article}`).
  - Volgende stap: logic toevoegen om de initiële waarde van category op te kunnen vragen (voor tonen in SearchCombo).

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


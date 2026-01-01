# MySite Development Log

## 2026-01-01 09:15 - TODO List (issue #23)

### Todo:
- [ ] SearchCombo - HTML-elementen dynamisch aanmaken
- [ ] SearchCombo - Initialisatie afmaken (container element issue)
- [ ] SearchCombo - Werkend maken voor categories
- [ ] SearchCombo - Werkend maken voor keywords
- [ ] Meta data velden - Verder uitwerken
- [ ] Article create - Implementeren

---

## 2026-01-01 16:30 (issue #23)

- SearchCombo verder uitgewerkt voor categories:
  - Typo in Article.pm gerepareerd: `vallues` → `values` in JSON response van `/article/categories` endpoint.
  - categoryManager.init parameters gecheckt en bevestigd (4 parameters: field, label, containerId, multiSelect).
  - SearchCombo container issue onderzocht en error handling toegevoegd.
  - Momenteel bezig met het tonen van de huidige category in het veld.

---

## 2025-12-31 17:45 (issue #23)

- Doorontwikkeling van de SearchCombo-module:
  - De SearchCombo maakt nu zelfstandig alle benodigde HTML-elementen aan via JavaScript.
  - De input voor geselecteerde items en de zoekinterface worden dynamisch opgebouwd, inclusief Bootstrap row/col-structuur en label.
  - Eventlisteners voor interactie (toggle, focus) zijn centraal in de init-methode geplaatst.
  - De zichtbaarheid van de zoekinterface wordt nu via een CSS-class geregeld voor betere compatibiliteit met externe stylesheets.
  - Robuustheid toegevoegd: duidelijke foutmelding als de container niet gevonden wordt.
  - Er is nog een openstaand probleem: het netjes tonen van het selectedItems-veld in kolommen met labels (volgens de gewenste Bootstrap-structuur) werkt nog niet volledig naar wens.


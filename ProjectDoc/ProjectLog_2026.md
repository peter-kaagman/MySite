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


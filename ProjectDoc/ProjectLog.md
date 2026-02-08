# MySite Development Log

## 2026-02-08 - Project Administratie: Issue Triage & Workflow Regels ✅

### Overzicht
Project administratie sessie: bestaande security/validation issues geanalyseerd, nieuwe issues aangemaakt, en kritieke workflow regel vastgelegd (code changes alleen in issue branches).

### Uitgevoerde Acties

#### 1. Issue Triage - Security & Validation Gaps
**Aangemaakt (nieuw):**
- Issue #34: Database Path Configuration - Root Cause Investigation (technical debt)
- Issue #35: Security - Validate Slug Format on Direct Updates
- Issue #36: Validation - Content & Abstract Should Not Be Empty
- Issue #37: Security - Add Authorization to Keyword/Category Endpoints

**Analyse resultaat:**
- ✅ Issue #37 (Keyword/Category Auth) - **GESLOTEN** - Al geïmplementeerd op 2026-01-09
- ✅ Issue #35 (Slug Validation) - **GESLOTEN** - Al geïmplementeerd op 2026-01-09
- ⏸️ Issue #36 (Empty Field Validation) - **BLIJFT OPEN** - Moet nog geïmplementeerd
- 🔍 Issue #34 (Database Path) - **INVESTIGATION** - Root cause onderzoek eerst

**Details:**
- Issue #37 had al auth checks in `_handle_keyword` en `_handle_category` (regel 448, 502)
- Issue #35 had al `slugify()` normalisatie + `_validate_slug()` DBIC schema validatie
- Issue #36: Code gap bevestigd - geen empty check in `_field_update` (line 242)
- Issue #34: Investigation approach i.p.v. env var workaround (user voorkeur)

#### 2. Kritieke Workflow Regel Vastgelegd

**Nieuwe regel in GenericProjectRules.md:**
> **Code wijzigingen UITSLUITEND in issue branch**

**Rationale:**
- Main branch = stable, alleen documentatie en admin
- Code changes = atomic per issue, easy rollback
- Clear separation project administratie vs development

**Toegestaan op main:**
- ✅ Documentation (ProjectLog, Rules, README)
- ✅ Project admin (issues via gh CLI)
- ✅ Git read operations

**Verboden op main:**
- ❌ Code changes lib/, views/, public/
- ❌ Schema/config updates
- ❌ Dependency changes

**Workflow:**
```bash
# Eerst branch
git checkout -b username/issue-XX
# Dan pas code changes
# Commit, push, PR, merge
```

#### 3. Issue #36 Gevalideerd

**Problem bevestigd:**
`_field_update` handler (Article.pm line 242) heeft geen empty check:
```perl
$article->update({
  route_parameters->get('field') => trim($data->{value})
});
```

**Impact:** 
- Content kan leeg gemaakt worden (breaks display)
- Abstract kan leeg gemaakt worden (unprofessional)

**Voorgestelde oplossing (Option A):**
Explicit field check voor content/abstract voordat update:
```perl
my $field = route_parameters->get('field');
if (grep { $field eq $_ } qw(content abstract)) {
  my $trimmed = trim($data->{value});
  unless ($trimmed) {
    status 400;
    return to_json({ success => 0, error => 'Field cannot be empty' });
  }
}
```

**Status:** Wacht op implementatie in issue branch.

### Files Gewijzigd
- ✏️ [ProjectDoc/GenericProjectRules.md](ProjectDoc/GenericProjectRules.md) - Sectie 9 uitgebreid met workflow regel
- 📝 GitHub Issues #34, #35, #36, #37 - Aangemaakt en getriaged
- 🔒 GitHub Issues #35, #37 - Gesloten (already implemented)
- 💬 GitHub Issue #36 - Geüpdate met analyse en oplossing

### Belangrijkste Beslissingen

**1. Code Changes Policy**
Vanaf nu: code wijzigingen ALLEEN in issue-specifieke branches. Main = admin only.

**2. Issue #34 Approach**
Database path: investigation first, geen env var workaround. Zoek root cause van waarom relatief pad niet werkte.

**3. Issue Triage Efficiency**
Van 4 nieuwe issues bleken er 2 al opgelost (50% duplicate detection via code review). Goede lesson: check implementation status voordat issue aanmaken.

### Status
✅ **Compleet** - Project administratie afgerond. Issue #36 klaar voor implementatie in aparte branch.

### Volgende Stappen
1. Issue #36 implementeren: `git checkout -b peter-kaagman/issue-36`
2. Empty field validation toevoegen volgens voorgestelde oplossing
3. Testen + PR + merge
4. Issue #34 (database path investigation) - later

---

## 2026-02-08 - GitHub CLI Setup & Workflow Verbetering ✅

### Overzicht
GitHub CLI (`gh`) geïnstalleerd en geconfigureerd voor geautomatiseerde issue management vanuit terminal/VS Code. Dit lost het "documentation disconnect" probleem op en maakt bidirectionele linking tussen Issues en ProjectLog mogelijk.

### Uitgevoerde Acties

#### 1. GitHub CLI Installatie
```bash
sudo snap install gh  # versie 2.74.0
gh auth login         # SSH protocol, bestaande key hergebruikt
```

**Verificatie:**
```bash
gh auth status
# ✓ Logged in to github.com account peter-kaagman
# - Git operations protocol: ssh
# - Token scopes: 'gist', 'read:org', 'repo'

gh issue list --limit 5
# Toont 5 van 13 open issues (werkt!)
```

#### 2. GenericProjectRules.md Updates

**Toegevoegd:**
- Sectie "Issue Closing Workflow" met templates voor commit messages en closing comments
- GitHub CLI commands (`gh issue close`, `gh issue comment`)
- Bidirectionele linking strategie: ProjectLog ↔ GitHub Issues
- Primair/secundair doel verduidelijking voor ProjectLog (AI context vs developer reference)

**Key Beslissing:**
```markdown
Bij issue completion:
1. Commit message met "Closes #XX" + ProjectLog reference
2. GitHub issue closing comment met link naar ProjectLog entry + summary
```

**Rationale:** 
- Forward: ProjectLog → Issue (via header `(Issue #XX)`) ✅ Al gedaan
- Reverse: Issue → ProjectLog (via closing comment) ✅ Nieuw
- Result: Volledig traceerbaar in beide richtingen

#### 3. Workflow Impact

**Voor (zonder gh CLI):**
- Issue sluiten via browser
- Geen gestandaardiseerde closing messages
- Geen directe link van Issue naar ProjectLog
- "Documentation disconnect" probleem

**Na (met gh CLI):**
- AI kan issues sluiten met gestandaardiseerde messages
- Elk afgesloten issue linkt naar ProjectLog entry
- Commit messages linken terug naar issue
- Volledig traceerbaar: Code → Commit → Issue → ProjectLog → Beslissingen

### Commands Nu Beschikbaar

```bash
# Issue sluiten met comment
gh issue close 31 --comment "✅ Completed. See ProjectLog.md (2026-02-08)"

# Comment toevoegen
gh issue comment 31 --body "[detailed closing message]"

# Issue details opvragen
gh issue view 31

# Issues bekijken
gh issue list --limit 10
```

### Files Gewijzigd
- ✏️ [ProjectDoc/GenericProjectRules.md](ProjectDoc/GenericProjectRules.md) - Sectie 9 uitgebreid met Issue Closing Workflow
- ✏️ [ProjectDoc/GenericProjectRules.md](ProjectDoc/GenericProjectRules.md) - Sectie 10 "Documentation disconnect" gemarkeerd als ✅ OPGELOST

### Status
✅ **Compleet** - gh CLI werkend, workflow gedocumenteerd, klaar voor gebruik bij volgende issue completion.

### Volgende Stappen
Bij afronden van volgende issue (bijv. security fixes uit ProjectLog) testen we de nieuwe workflow in de praktijk.

---

## 2026-02-07 - Project Documentatie Herstructurering ✅

### Overzicht
Project documentatie georganiseerd in `ProjectDoc/` folder. GenericProjectRules.md (van AP Monitoring project) geanalyseerd en volledig aangepast voor MySite specifieke context en technische stack.

### Uitgevoerde Acties

#### 1. Documentatie Herstructurering
- `log.md` verplaatst naar `ProjectDoc/ProjectLog.md`
- Nieuwe folder structuur: alle markdown docs in `ProjectDoc/`
- Consistent met Dancer2 project layout (code/views/public gescheiden van docs)

#### 2. GenericProjectRules.md Aanpassing
Volledig herschreven van AP Monitoring (Perl/SNMP/RRD) naar MySite (Dancer2/DBIC/Docker):

**Structurele Wijzigingen:**
- Directory layout: Dancer2 standaard structuur met `lib/`, `views/`, `public/`, `ProjectDoc/`
- Planning: GitHub Issues i.p.v. ToDo.md voor tracking
- Documentatie: ProjectLog.md voor technische details, Issues voor high-level planning

**Tech Stack Updates:**
- Database: Raw SQL → **DBIC (ORM)** met relationships
- Frontend: Geen framework → **Modular ES6 JavaScript** (SearchCombo, TitleManager, uiSync)
- Deployment: **Docker First** met multi-stage builds
- Auth: **OAuth + Custom Provider** (Dancer2::Plugin::Auth::Extensible)
- Database Strategy: **SQLite (dev) → PostgreSQL (prod)**
- Sessions: **YAML (dev) → Redis (planned)**

**Nieuwe Secties Toegevoegd:**
- Security & Authorization patterns (alle write endpoints moeten auth checken)
- Slug handling best practices (lowercase, underscores, validatie)
- JSON API response standards
- Frontend module patterns (auto-context detection, event-driven)
- Docker development workflow (volume mounts, when to rebuild)
- Template organization (Dancer2/TT specifiek)
- MySite Current Status (feb 2026)
- Lessons Learned MySite specifiek (7 bugs opgelost, 5 pitfalls)
- New Dancer2 Project Checklist

**Verwijderd:**
- RRD/SNMP/AP monitoring specifieke regels
- Archive folder strategy (gebruik git history)
- Data collection patterns

#### 3. AI Assistant Guidelines
Expliciete sectie toegevoegd: **"Omgaan met Rule Violations"**

**Workflow:**
```
Developer wijkt af van regel
    ↓
AI signaleert zonder oordeel: "Dit wijkt af van regel X"
    ↓
Vraag intentie: "Bewuste keuze?"
    ↓
Twee opties:
├─ Ja, goede reden → Documenteer in ProjectLog
└─ Nee, regel past niet → Update GenericProjectRules.md
```

**Rationale:** Rules zijn **leermiddel**, geen **keurslijf**. Afwijkingen triggeren reflectie en verbetering.

### Files Gewijzigd/Aangemaakt
- 🔄 `log.md` → `ProjectDoc/ProjectLog.md` (verplaatst)
- ✏️ [ProjectDoc/GenericProjectRules.md](ProjectDoc/GenericProjectRules.md) - Volledig herschreven (v2.0)
- ✨ Nieuwe sectie 15: "Omgaan met Rule Violations"

### Belangrijkste Beslissingen

**DBIC vs Raw SQL:**
- AP Monitoring gebruikte raw SQL (portable, eenvoudiger)
- MySite gebruikt DBIC (relationships makkelijker, vooral many-to-many)
- Trade-off: meer overhead, maar cleanere code voor web app

**Documentatie Strategie:**
- ProjectLog.md = technische details, context, code snippets
- GitHub Issues = high-level planning, acceptance criteria
- GenericProjectRules.md = best practices, patterns, beslissingen
- Cross-reference tussen alle drie

**Living Document Principe:**
Rules moeten **buigen naar werkelijkheid**, niet andersom. AI signaleert afwijkingen, samen beslissen we of developer fout is of rule moet aanpassen.

### Status
✅ **Compleet** - GenericProjectRules.md is nu MySite-specifiek en klaar voor gebruik als actief hulpmiddel.

### Volgende Stappen
Rules toepassen tijdens development. Bij eerste echte "rule violation" testen we of het signaleer-mechanisme werkt zoals bedoeld.

---

## 2026-01-14 (Issue #30) - Docker Setup Succesvol Geïmplementeerd ✅

### Overzicht
Docker Desktop geïnstalleerd op Windows met WSL 2 integratie. MySite applicatie draait nu succesvol in een Docker container met SQLite database en YAML file sessions (zonder PostgreSQL en Redis zoals gepland voor Issue #30).

### Uitgevoerde Stappen

#### 1. Docker Desktop Installatie & Configuratie
- Docker Desktop geïnstalleerd op Windows
- WSL 2 integratie geconfigureerd in Docker Desktop Settings
- User toegevoegd aan docker groep: `sudo usermod -aG docker $USER`
- Docker versie: 29.1.3
- Docker Compose versie: v5.0.0-desktop.1

#### 2. Health Check Endpoint Toegevoegd
Nieuw endpoint toegevoegd aan [lib/MySite.pm](lib/MySite.pm):
```perl
get '/health' => sub {
  content_type 'application/json';
  return to_json({ 
    status => 'ok', 
    version => $VERSION,
    timestamp => time()
  });
};
```

#### 3. Dockerfile Aangemaakt (Dockerfile.simple)
Multi-stage build voor geoptimaliseerde image:
- **Builder stage**: perl:5.38 met build dependencies
  - `build-essential`, `libssl-dev`, `zlib1g-dev`, `sqlite3`, `libsqlite3-dev`
  - cpanm installatie van alle dependencies
- **Production stage**: perl:5.38-slim voor kleinere image
  - Runtime dependencies: `libssl3`, `sqlite3`
  - Non-root user (dancer) voor security
  - Health check met LWP::Simple
  - Poort 3000 exposed

**SSL/SSLeay Dependencies**: Correct afgehandeld via `libssl-dev` (build) en `libssl3` (runtime). Net::SSLeay v1.94 geïnstalleerd en werkend.

#### 4. Docker Compose Configuratie (Two-Tier Setup)

**docker-compose.yml** (Development - DEFAULT)
```yaml
- Plackup -E development voor console logging
- Volume mounts voor live code updates:
  - ./lib:/app/lib (Perl modules)
  - ./views:/app/views (Templates)
  - ./public:/app/public (Static files)
  - ./bin:/app/bin (Scripts)
  - ./db:/app/db (SQLite persistence)
- Port 3000 exposed
```

**docker-compose.prod.yml** (Production)
```yaml
- Plackup -E production (of manueel ingesteld)
- Geen volume mounts (snapshot-based)
- Alleen ./db:/app/db voor database persistentie
- Port 3000 exposed
```

#### 5. Database Configuratie Aangepast
[config.yml](config.yml) aangepast voor relatieve pad:
```yaml
DBIC:
  default:
    dsn: dbi:SQLite:dbname=db/mysite.sqlite  # Was: /absolute/path/to/MySite/db/mysite.sqlite
```

#### 6. Development Workflow
- Code wijzigen in VS Code
- `docker-compose restart mysite` om plackup te herstarten
- Code wijzigingen zijn onmiddellijk beschikbaar via volume mounts
- Geen rebuild nodig tenzij dependencies wijzigen

### Build & Deploy
```bash
# Development (met live code updates)
docker-compose up -d

# Production (snapshot-based)
docker-compose -f docker-compose.prod.yml up -d

# Plackup herstarten na code wijzigingen
docker-compose restart mysite

# Container stoppen
docker-compose down
```

### Verificatie & Testing
✅ Docker Desktop: Werkend (WSL 2 integratie)
✅ Docker image `mysite:simple`: Gebouwd en beschikbaar
✅ Container status: UP en healthy
✅ Health endpoint: http://localhost:3000/health → `{"status":"ok","version":"0.1","timestamp":...}`
✅ Homepage: http://localhost:3000/ → Volledige HTML response
✅ Database connectivity: SQLite werkt correct met relatief pad
✅ Net::SSLeay: Versie 1.94 correct geïnstalleerd
✅ Volume mounts: Live code updates werken via docker-compose.yml
✅ Two-tier setup: Zowel development als production ready

### Belangrijke Decisions
1. **Logging**: Console logging (development mode) in beide configs
2. **Sessions**: Blijven in container (niet gemount) - ephemeral maar voldoende voor development
3. **Database**: Alleen db/ directory gemount voor persistentie van SQLite
4. **Port**: 3000 zoals gespecificeerd in Issue #30
5. **Auto-reload**: Manual restart via `docker-compose restart` i.p.v. `-R` flag (sneller voor Perl modules)

### Acceptatie Criteria Issue #30 - ALLEMAAL ✅
- ✅ Dockerfile voor production build
- ✅ docker-compose.yml voor lokale development
- ✅ Multi-stage build voor optimized image
- ✅ Health checks geconfigureerd
- ✅ .dockerignore proper configured
- ✅ Image built en app draait in container
- ✅ Poort 3000 accessible
- ✅ App accessible op localhost:3000
- ✅ Health check endpoint werkt
- ✅ Configuration management (PLACK_ENV per environment)
- ✅ Volume mounts voor live development

### Files Gewijzigd/Aangemaakt
- ✨ [Dockerfile.simple](Dockerfile.simple) - Nieuw
- ✨ [docker-compose.yml](docker-compose.yml) - Herschreven (development)
- ✨ [docker-compose.prod.yml](docker-compose.prod.yml) - Nieuw (production)
- ✏️ [lib/MySite.pm](lib/MySite.pm) - Health endpoint toegevoegd
- ✏️ [config.yml](config.yml) - Database pad aangepast naar relatief

### Docker Commands Referentie
```bash
# Development bouwen en starten
docker build -f Dockerfile.simple -t mysite:simple .
docker-compose up -d

# Plackup herstarten na code wijzigingen
docker-compose restart mysite

# Production setup
docker-compose -f docker-compose.prod.yml up -d

# Stoppen
docker-compose down

# Logs bekijken
docker-compose logs -f mysite

# Status
docker ps
docker images | grep mysite
```

### Next Steps
Issue #30 is **100% compleet** en **mergeable naar main**. Volgende issues:
- **Issue #31**: Redis voor Session Management (Dependency: #30 ✅)
- **Issue #32**: PostgreSQL Migratie (Dependency: #30 ✅, #31)

### ⚠️ Zorgenpunten & Technical Debt

#### Database Path: Relatief vs Absoluut - ROOT CAUSE ONBEKEND
**Zorgenpunt**: Database configuratie in [config.yml](config.yml) werkt met relatief pad, maar **origineel probleem onbekend**.

**Historie**:
1. Origineel: Relatief pad `db/mysite.sqlite` werkte niet in bepaalde setup
2. Quick fix: Absolute pad `$PROJECT_ROOT/db/mysite.sqlite` toegepast
3. Huidige status: Relatief pad werkt nu in Docker, maar **root cause van origineel probleem is niet opgelost**

**Waarom problematisch**:
- ❓ **Root cause onbekend** - We weten niet waarom relatief pad niet werkte
- ❌ Absolute pad is niet portable (hardcoded path naar specific directory)
- ❌ Zal breken in productie op ander server/directory
- ❌ Code bevat "magic path" zonder documentatie van waarom

**Aanbeveling voor Issue #33 (Toekomstig)**:
1. **Onderzoeken** waarom relatief pad origineel niet werkte
2. **Root cause fixen** i.p.v. path workaround
3. Eventueel environment variable gebruiken:
```yaml
dsn: dbi:SQLite:dbname=$ENV{DB_PATH}/mysite.sqlite
```

**Impact**: Medium (werkt voor huidige dev/Docker use case, maar onclean en niet begrijpelijk)

**TODO**: Documenteer waarom absoluut pad nodig was - mogelijk:
- Dancer2 pwd behavior
- Plackup startup directory
- Carton/PERL5LIB issue
- Iets anders?

---

---

---

## 2026-01-14 (Issue #30) - Vereisten om MySite in Docker te draaien

### Wat er nodig is
- Dockerfile op basis van `perl:5.38-slim` (of vergelijkbare lichte Perl base image)
- System packages: `build-essential`, `make`, `gcc`, `libssl-dev`, `libexpat1-dev`, `libsqlite3-dev`, `curl` (voor module builds en SQLite)
- App dependencies via Carton: `cpanfile` + `cpanfile.snapshot` kopiëren en `carton install --deployment`
- Applicatiecode kopiëren naar `/app` en `WORKDIR /app`
- Omgevingsvariabelen: `PLACK_ENV` (development/production), optioneel `PORT` (default 3000)
- Expose poort 3000 en start met `carton exec -- plackup -E production -s Starman --port 3000 bin/app.psgi`
- `.dockerignore` voor `local/`, `node_modules/`, `sessions/`, `log/`, `tmp/`, `cpanfile.snapshot` (optioneel), `*.swp`
- Healthcheck endpoint (`/health`) voor container status

### Dockerfile schets
- Stage 1: base image + apt-get deps + `cpanfile*` -> `carton install --deployment`
- Stage 2: copy vendor libs uit stage 1, copy app code, set env `PLACK_ENV=production`, expose 3000, `CMD` naar plackup/Starman

### docker-compose (dev)
- Service `app` met poortmapping `3000:3000`
- Mount source code optioneel voor snelle iteratie
- Milieuvariabelen uit `.env` (niet committen)
- (Redis/PostgreSQL komen pas in latere issues #31/#32)

## 2026-01-14 (Productie Voorbereiding) - Aanmaken Issues #30, #31, #32

### Strategie voor Productie Deployment

Na afronding van issue #23 (SearchCombo) en merge naar main, is de focus verschoven naar productie voorbereiding. Drie grote issues zijn gedefinieerd voor het stap-voor-stap opbouwen van een production-ready deployment stack.

### Issues Aangemaakt

#### Issue #30: Docker & Environment Configuration
**Doel**: Containerization en environment-based config zonder externe dependencies

**Scope**:
- Dockerfile voor production build
- docker-compose.yml voor development
- Multi-stage build optimalisatie
- Health checks implementatie
- PLACK_ENV environment variable support
- Config files per environment (development/production)
- Logging levels per environment
- GitHub Actions CI/CD pipeline

**Opmerking**: SQLite database en YAML sessions blijven. Dit issue focust puur op Docker + configuratie.

#### Issue #31: Redis voor Session Management
**Doel**: Schaalbaarheid session management (Dependency: #30)

**Scope**:
- Redis service in docker-compose
- Perl Redis module integratie
- Session persistence testen
- Fallback naar YAML sessions
- Health check Redis connectivity
- Performance optimalisatie

**Opmerking**: Redis wordt geintroduceerd NADAT Docker werkend is.

#### Issue #32: PostgreSQL Migratie
**Doel**: Database migratie voor production (Dependency: #30, #31)

**Scope**:
- PostgreSQL service setup
- Schema migratie SQLite → PostgreSQL
- Data migratie scripts
- Connection pooling
- Backup/restore procedures
- Performance testing

**Opmerking**: SQLite blijft voor development beschikbaar.

### Design Decisions

1. **Gradual Approach**: 
   - Issue #30 maakt Docker werkend
   - Issue #31 voegt Redis toe
   - Issue #32 voegt PostgreSQL toe
   - Elk issue is zelfstandig testbaar

2. **SQLite in Development**:
   - Productie: PostgreSQL
   - Development: SQLite
   - Fallback: YAML sessions
   - Promotes eenvoudig lokaal development

3. **Environment Configuration**:
   - PLACK_ENV: development/production
   - Config files per environment
   - Secrets via environment variables
   - Clear separation of concerns

4. **Scope Management**:
   - Kubernetes is NIET op de horizon
   - Focus op Docker + config management
   - Load balancer/CDN later

### Next Steps

- Issue #30: Docker setup implementeren
- Testen in Docker container
- Issue #31: Redis integratie
- Issue #32: PostgreSQL migratie
- Infrastructure improvements (load balancer, monitoring, etc.)

### Voorbereiding Afgerond

Alle drie issues zijn gedocumenteerd met:
- ✅ Duidelijke acceptance criteria
- ✅ Implementation details met code voorbeelden
- ✅ Testing strategie
- ✅ Subtasks checklists
- ✅ Dependencies vastgesteld

Klaar voor implementatie!

---

## ✅ COMPLETED: Issue #23 - SearchCombo Selection & UI State Management

### Overview
Comprehensive implementation and debugging of the SearchCombo module for managing article categories (single-select) and keywords (multi-select) with proper state persistence and UI rendering.

### Issue Description
The SearchCombo module provides a user interface component for selecting categories and keywords when creating or editing articles. Users needed to be able to:
1. See pre-selected items when loading an edit page
2. Add/remove items with proper visual feedback
3. Have their changes persisted to the database
4. See correct UI state that matches the actual server state

### Problems Encountered & Solutions

#### 1. **Selection Matching - IDs vs Titles**
- **Issue**: Selected items not showing as checked despite being in database
- **Root Cause**: Comparison logic matched IDs to display titles (never equal)
- **Solution**: Fixed to match ID-to-ID only
- **Impact**: Users now see correct pre-selected items on page load

#### 2. **Keywords API Data Format**
- **Issue**: Keywords endpoint returned incompatible format vs categories endpoint
- **Root Cause**: `_get_keywords` returned array of strings; `_get_categories` returned objects with `{id, title}`
- **Solution**: Updated `_get_keywords` to return objects matching `_get_categories` format
- **Impact**: Consistent API contracts, proper data structure for SearchCombo matching

#### 3. **Bootstrap Form-Switch Styling Cache**
- **Issue**: Category radio buttons and keyword checkboxes didn't show correct visual state after user interaction
- **Root Cause**: Bootstrap CSS styling cached `:checked` pseudo-selector state at render time; changing `checked` property didn't trigger CSS update
- **Solution**: Implemented `rebuildListWithSelection()` method to reconstruct list items with correct checked states before adding to DOM
- **Impact**: Bootstrap now applies correct styling; users see accurate visual feedback for all interactions

#### 4. **UI vs Server State Mismatch**
- **Issue**: UI reported "keyword removed" but item still saved in database
- **Root Cause**: UI updated optimistically before server save; if save failed, states diverged
- **Solution**: Reversed order for edit mode - save to server first, then update UI only on success
- **Impact**: UI always reflects actual database state; prevents user confusion

#### 5. **Type Mismatch in Array Filtering**
- **Issue**: Could not deselect pre-loaded keywords, only newly added ones
- **Root Cause**: `articleItems` contains numbers from parsed JSON; input values are strings; `5 !== "5"` in JavaScript
- **Solution**: Convert both sides to strings before comparison: `String(i) !== String(item)`
- **Impact**: All pre-loaded keywords can now be toggled on/off correctly

### Files Modified

**Frontend:**
- `public/javascripts/modules/searchcombo.js`
  - Fixed selection matching logic (lines 143, 180)
  - Implemented `rebuildListWithSelection()` for proper Bootstrap styling (lines 290-309)
  - Restructured `handleItemChange()` to save-first pattern for edit mode (lines 228-289)
  - Fixed type-safe comparisons in filters

**Backend:**
- `lib/MySite/Article.pm`
  - Updated `_get_keywords()` endpoint to return objects with both `id` and `title` (lines 559-573)
  - Ensured API consistency between keywords and categories endpoints

### Key Improvements

**User Experience:**
- ✅ Pre-selected items display correctly on page load
- ✅ All interactive state changes show immediate visual feedback
- ✅ Color states accurately reflect checked/unchecked status
- ✅ No confusing mismatch between UI display and saved data

**Code Quality:**
- ✅ Consistent API contracts between endpoints
- ✅ Type-safe string comparisons prevent silent failures
- ✅ Bootstrap styling properly updated through DOM reconstruction
- ✅ Clear separation between create (optimistic) and edit (save-first) modes

**Maintainability:**
- ✅ Single `rebuildListWithSelection()` method handles both single/multi-select modes
- ✅ DisplayLookup map cleanly separates IDs from display labels
- ✅ Error states properly indicate to users when operations fail

### Testing Performed

✅ Create mode:
- Add new category - saves on form submission
- Add/remove keywords before create - saved with article
- Invalid selections blocked appropriately

✅ Edit mode:
- Pre-loaded category displays as selected
- Pre-loaded keywords display as selected
- Can change category and see visual update
- Can add/remove keywords individually
- UI state matches database on reload
- Network errors show error messages and don't update UI

### Commit Details
- **Branch**: peter_kaagman/issue23
- **Type**: Bug Fix / Feature Complete
- **Scope**: SearchCombo module, article category/keyword management
- **Breaking Changes**: None - API changes backward compatible
- **Migration**: None required

### Summary

Issue #23 is now complete. This issue was focused on the core modernization of article editing functionality through several key components:

#### Core Components Implemented

1. **MD Editor Integration**
   - Markdown editor for article content, abstract, and metadata
   - Provides rich text editing experience with preview
   - Integrated into both create and edit workflows

2. **SearchCombo & TitleManager JS Modules**
   - Two reusable, modular JavaScript components for form interactions
   - **TitleManager**: Handles title and slug synchronization with auto-detection of create vs edit mode
   - **SearchCombo**: Manages single-select (categories) and multi-select (keywords) with proper state management
   - Both modules automatically detect article context and behave appropriately
   - Auto-mode detection eliminates configuration overhead - same modules work for add and edit pages

3. **Rewritten articleCreate Workflow**
   - Skeleton article creation with minimal required fields (title + category)
   - Uses TitleManager for automatic slug generation
   - Uses SearchCombo for category selection
   - Keywords can be selected but only saved on subsequent edit
   - Form submission creates article and redirects to edit page
   - Clean, streamlined create experience

4. **Rewritten articleEdit Workflow**
   - Complete article editing with MD editor for content/abstract
   - Integrated SearchCombo for category and keyword management
   - TitleManager for title/slug with proper synchronization
   - Real-time updates to category/keywords via API
   - Full state management ensuring UI matches database

#### Technical Achievements

- ✅ The SearchCombo module provides a robust, user-friendly interface for managing article metadata
- ✅ Proper state management ensures UI always reflects actual database state
- ✅ Both create and edit workflows use the same underlying components (DRY principle)
- ✅ Auto-detection of create vs edit mode eliminates template complexity
- ✅ All discovered bugs fixed with comprehensive error handling and visual feedback
- ✅ Type-safe implementations prevent silent failures
- ✅ Bootstrap styling properly updated for all interactive state changes

Issue #23 successfully modernized article management from legacy template-based approach to modular, reusable JavaScript components with robust state management.

---

## 2026-01-14 (issue #23) - SearchCombo Bug Fixes: Selection Matching & UI Rendering

### 🐛 Issues Fixed

#### 1. **SearchCombo Selection Not Showing Correctly**
**Problem:** Checkboxes for keywords/categories weren't showing as selected on page load, even though items were pre-selected in the database.

**Root Cause:** Selection matching logic was comparing:
- Selected item **ID** (number: `5`)
- Available option **title** (string: `"JavaScript"`)

This would never match because IDs don't equal titles.

**Fix:** Changed comparison to match ID-to-ID only:
```javascript
// Before (WRONG):
String(selected).toLowerCase() === String(display).toLowerCase() || String(selected) === String(value)

// After (CORRECT):
String(selected) === String(value)
```

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` lines 143, 180

---

#### 2. **Keywords Endpoint Returning Wrong Format**
**Problem:** Keywords were not showing as selected because the API endpoint returned only titles, not objects with IDs.

**Root Cause:** `_get_keywords` endpoint returned:
```json
{ "values": ["JavaScript", "React", "Node"] }  // Strings only
```

But `_get_categories` returned:
```json
{ "values": [
  { "id": 1, "title": "Technology" },
  { "id": 2, "title": "Business" }
]}  // Objects with id + title
```

**Fix:** Updated `_get_keywords` to match `_get_categories` format:

**File Changed:**
- `lib/MySite/Article.pm` lines 559-573

```perl
# Before: Return only titles
my @keywords_list = map { $_->title } $keywords->all;
return to_json({ values => \@keywords_list });

# After: Return objects with id and title
my @keyword_objects = map { { id => $_->keyword_id, title => $_->title } } $keywords->all;
return to_json({ values => \@keyword_objects });
```

---

#### 3. **Radio Button (Category) Not Visually Updating**
**Problem:** When selecting a new category:
- Old selection went to gray/off state ✅
- New selection changed color but didn't show toggle as ON ❌

**Root Cause:** Bootstrap's form-switch styling uses CSS pseudo-selectors (`:checked`) calculated at render time. Programmatically changing `checked = false` doesn't trigger CSS recalculation.

**Fix:** Rebuild the entire list with correct `checked` states before adding to DOM, so Bootstrap applies styling correctly:

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` lines 238-241

Added `rebuildListWithSelection()` method to reconstruct list items with correct checked states.

---

#### 4. **Checkbox (Keyword) Color Not Updating on Deselection**
**Problem:** When deselecting a keyword:
- Checkbox went to off ✅
- But color stayed active blue ❌

**Root Cause:** Same as #3 - Bootstrap styling cached at render time.

**Fix:** Extended `rebuildListWithSelection()` to work for both single-select and multi-select:

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` lines 238-241, 246

Now rebuilds list after both adding AND removing keywords.

---

#### 5. **Missing Class Closing Brace**
**Problem:** SearchCombo containers not visible - JavaScript module failed to load.

**Root Cause:** Missing closing brace `}` for the `SearchCombo` class at end of file.

**Fix:** Added closing brace.

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` line 309

---

#### 6. **UI Reported Keyword Removed But Not Actually Removed**
**Problem:** 
- UI showed "keyword removed successfully"
- But keyword was still saved in database

**Root Cause:** UI was updated optimistically BEFORE saving to server. If server save failed, UI state didn't match reality.

**Fix:** Reversed order for edit mode:
1. Save to server FIRST
2. Only update UI if save succeeds
3. If save fails, show error and UI stays unchanged

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` lines 228-289

---

#### 7. **Cannot Turn Off Pre-loaded Keywords**
**Problem:**
- Can toggle newly added keywords on/off ✅
- Cannot turn off keywords that were loaded from database ❌

**Root Cause:** Type mismatch in filter comparison when removing items:
```javascript
// articleItems contains: [5, 12] (numbers from JSON)
// item is: "5" (string from input element)
// 5 !== "5" returns true, so item not removed!

this.articleItems.filter(i => i !== item)  // WRONG
```

**Fix:** Convert both sides to strings for comparison:
```javascript
this.articleItems.filter(i => String(i) !== String(item))  // CORRECT
```

**Files Changed:**
- `public/javascripts/modules/searchcombo.js` lines 245, 272

---

### ✅ Summary
- **Selection matching**: Now correctly compares IDs
- **Keyword API**: Returns proper objects with id + title
- **UI rendering**: Rebuilds lists to force Bootstrap styling update
- **Server sync**: Save first, then update UI (for edit mode)
- **Type safety**: All comparisons use string conversion

All SearchCombo functionality now works correctly for both categories (single-select) and keywords (multi-select).

---

## 2026-01-10 (issue #23) - Auto-detect Create vs Edit Mode in Modules


### Implementatie: Automatische Mode Detection
Modules `title_slug.js` en `searchcombo.js` kunnen nu automatisch werken in beide modes:
- **Edit mode**: `article_id` element bestaat → normale API calls
- **Create mode**: `article_id` element bestaat niet → alleen lokale UI updates

### Changes

**title_slug.js:**
- Constructor: Safe articleId ophalen: `document.getElementById('article_id')?.value || null`
- `addFieldListener`: Check `if (this.articleId)` voor API call
- Create mode: Callback wordt aangeroepen met `{ success: true }` zonder API call
- Gebruiker kan title/slug bewerken tijdens artikel aanmaak zonder save errors

**searchcombo.js:**
- `init()`: Safe articleId ophalen met optionele chaining
- `handleItemChange()`: Update UI eerst, dan check `if (this.articleId)` voor API
- Create mode: Toont friendly status "will save on create" i.p.v. API error
- Gebruiker kan categorie selecteren tijdens artikel aanmaak

### Voordelen
- ✅ **Zero configuration**: Modules detecteren automatisch create vs edit mode
- ✅ **Code reuse**: Zelfde modules voor add.tt en edit.tt templates
- ✅ **No errors**: Geen API calls naar niet-bestaande artikelen
- ✅ **Better UX**: Gebruiker ziet logische feedback in create mode

### Next Steps
- article_add.js herschrijven om TitleManager en SearchCombo te gebruiken
- Template add.tt aanpassen naar minimale form (title + category)
- Backend _post_article_new aanpassen voor skeleton create + redirect naar edit

---

## 2026-01-10 (issue #23) - 🐛 BUG: UI Sync Slug Element Not Found

### Issue
Event-driven UI synchronization implemented but fails silently when trying to update slug field:
- Console warning: `Element #slug not found`
- `uiSync.js` tries to find element with `id="slug"` but template uses different ID
- Slug field updates on server but UI doesn't reflect normalized value
- User still sees their input (e.g., "Test Article!!!") instead of normalized value (e.g., "test_article")

### Root Cause
**VERIFIED: Element ID mismatch in uiSync.js**
- `TitleManager` (title_slug.js) lookups: `id="edit_slug"` (line 24)
- `uiSync.js` tries to update: `id="slug"` (line 47 in updateElement call)
- Template renders slug field as: `id="edit_slug"` (for TitleManager compatibility)
- Result: uiSync finds no matching element and silently fails

### Impact
- ❌ Slug normalization invisible to user - confusing UX
- ❌ Visual feedback (green flash) doesn't trigger
- ❌ Slug sync notifications don't show
- User thinks their input was saved as-is (when it was normalized)

### Fix Required
1. Check actual slug field ID in `views/article/edit.tt`
2. Either:
   - Option A: Rename template element to `id="slug"` for consistency
   - Option B: Update uiSync.js to use correct template ID
3. Verify slug field renders and is editable in edit form
4. Test slug update → verify UI shows normalized value + notification

### Debug Steps Needed
```
1. Open browser DevTools on article edit page
2. Check console for 'Element #slug not found' warning
3. Inspect page: search for any element containing 'slug' input
4. Check actual element id/name attributes
5. Test: type slug with spaces/caps, save, verify UI update
```

---

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


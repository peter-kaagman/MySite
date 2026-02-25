
# MySite Projectregels & Best Practices

**TL;DR: Belangrijkste regels**

1. Issues altijd via GitHub aanmaken (gh CLI of web), nooit als los bestand.
2. Codewijzigingen alleen in issue branches, nooit direct op main.
3. Elke significante wijziging loggen in ProjectLog.md, met issue-nummer.
4. Bidirectionele linking: ProjectLog ↔ Issue (zie workflow).
5. Commit messages zijn duidelijk, bevatten issue-nummer en context.
6. Documentatie en logs in ProjectDoc/, code in lib/, views/, public/.
7. Security: altijd authorization checks op write endpoints.
8. Planning en status via GitHub Issues, niet via losse todo-lijsten.
9. Afwijken van regels? Documenteer waarom in ProjectLog.md.

---

## Inhoudsopgave
1. [Projectstructuur & Bestanden](#projectstructuur--bestanden)
2. [Documentatie & Logging](#documentatie--logging)
3. [Workflow & Git](#workflow--git)
4. [Technische Keuzes & Best Practices](#technische-keuzes--best-practices)
5. [Planning & Scope](#planning--scope)
6. [Communicatie & AI](#communicatie--ai)
7. [Lessons Learned & Templates](#lessons-learned--templates)
8. [Status & Review](#status--review)

---

## 1. Projectstructuur & Bestanden

Zie onderstaand schema voor de standaard indeling. Houd je aan deze structuur voor vindbaarheid en consistentie.

```
MySite/
├── ProjectDoc/            # Documentatie & logs
├── lib/                   # Perl modules (Dancer2 app + DBIC schema)
├── views/                 # Templates
├── public/                # Static assets (CSS, JS, images)
├── db/                    # Database files (SQLite dev)
├── bin/                   # Startup scripts
├── t/                     # Tests
├── environments/          # Configs
├── sessions/              # Session storage
├── logs/                  # Application logs
└── [docker/k8s/nginx]     # Infra/config
```

**Rationale:**
- Duidelijke scheiding frontend/backend
- ProjectDoc voor markdown documentatie
- Geen archive folder (gebruik git history)

---

## 2. Documentatie & Logging

### ProjectLog.md
- Log elke significante wijziging, met datum en issue-nummer.
- Gebruik vaste structuur:
    - Bevindingen/Beslissingen
    - Implementatie
    - Status (✅/🔄/⏸️/❌)
- Link naar relevante issues en bestanden.

### GitHub Issues
- Gebruik voor alle planning, tracking, en status.
- Issue-format: Description, Acceptance Criteria, Implementation Details, Dependencies, Testing Strategy.
- Sluit issues altijd met een verwijzing naar de relevante ProjectLog entry.

### Bidirectionele linking
- ProjectLog → Issue: `(Issue #XX)` in header
- Issue → ProjectLog: "Completed. See ProjectLog.md (YYYY-MM-DD)"

---

## 3. Workflow & Git

### Branches
- `main` = alleen documentatie/admin, nooit codewijzigingen
- Feature branches: `username/issue-XX` of `feature/omschrijving`
- Hotfix branches: `hotfix/omschrijving`

### Commit messages
- Formaat: `<type>: <omschrijving> (Issue #XX)`
- Duidelijk, contextvol, geen vage teksten

### Pull Requests
- Altijd via PR naar main
- Squash merge aanbevolen
- Branch verwijderen na merge

### Issue closing
- Sluit issue met comment: "✅ Completed. See ProjectLog.md (YYYY-MM-DD)"

### Allowed op main:
- ✅ Documentatie, ProjectLog, administratie
- ❌ Code, schema, dependencies, configs

---

## 4. Technische Keuzes & Best Practices

### Database
- DBIx::Class (DBIC) als ORM
- SQLite voor dev, PostgreSQL voor productie (zie migraties)

### Frontend
- ES6 modules, geen framework
- Event-driven, single responsibility per module

### Containerization
- Docker als standaard, compose voor dev/prod

### Security
- Altijd authorization checks op write endpoints
- Server-side validatie verplicht

### API & Templates
- JSON responses: vaste structuur (success, message/data, error)
- Templates: DRY, feature folders, minimale logica

---

## 5. Planning & Scope

### Issue-based planning
- Gebruik GitHub Issues, geen vaste fases
- Dependencies expliciet maken (#31 requires #30)

### Status markers
- ✅ Completed, 🔄 In Progress, ⏸️ Waiting, ❌ Blocked

### Scope clarification
- Bij onduidelijkheid: maak aanname, documenteer in ProjectLog, implementeer, verifieer

---

## 6. Communicatie & AI

### Taalgebruik
- Nederlands voor uitleg, Engels voor technische termen
- Geen geforceerde vertalingen

### AI assistant gedrag
- Direct handelen, kort en technisch correct
- Signaleer afwijkingen van regels, vraag intentie, documenteer

---

## 7. Lessons Learned & Templates

### Lessons Learned
- Zie sectie "Wat goed werkte" en "Wat beter kan" voor concrete verbeterpunten

### Project Start Checklist (Dancer2)
- Zie template onderaan voor nieuwe projecten

---

## 8. Status & Review

### Living document
- Deze regels zijn leidraad, geen wet. Pas aan als de praktijk daarom vraagt en documenteer waarom.
- Volgende review: bij completion Issue #32 (PostgreSQL migratie)

---

**Voor details, rationale, voorbeelden en volledige uitwerking: zie de secties verderop in dit bestand.**

---

<!-- De volledige originele secties, voorbeelden, rationale, en templates blijven behouden onder deze samenvatting voor naslag en verdieping. -->

---
...existing code...

## 1. Project Structuur

### Database-bestanden (SQLite)

- Standaard wordt `db/mysite.sqlite` **niet getrackt** (staat in `.gitignore`).
- Wil je de database toch committen (bijvoorbeeld voor een specifieke migratie of test), doe dan:
    1. Verwijder `db/mysite.sqlite` tijdelijk uit `.gitignore` of gebruik `git add -f db/mysite.sqlite`.
    2. Commit de wijziging.
    3. Zet daarna `db/mysite.sqlite` weer terug in `.gitignore`.
- Zo voorkom je merge-conflicten en blijft de workflow flexibel.

### Directory Layout
```
MySite/
├── ProjectDoc/            # Alle project documentatie
│   ├── ProjectLog.md      # Chronologisch implementatie logboek
│   ├── GenericProjectRules.md  # Dit bestand (project regels)
│   └── [toekomstig: ToDo.md, CommandReference.md, etc.]
├── lib/                   # Perl modules (Dancer2 app + DBIC schema)
│   └── MySite/            # Applicatie modules
│       ├── Schema/        # DBIC schema classes
│       └── Auth/          # Auth providers
├── views/                 # Template Toolkit templates
├── public/                # Static assets (CSS, JavaScript, images)
│   ├── css/
│   ├── javascripts/
│   │   └── modules/       # Reusable JS modules (SearchCombo, TitleManager, etc.)
│   └── images/
├── db/                    # Database files (SQLite voor dev)
├── bin/                   # Startup scripts (app.psgi)
├── t/                     # Tests
├── environments/          # Environment configs (development.yml, production.yml)
├── sessions/              # Session storage (YAML files voor dev)
├── logs/                  # Application logs
├── nginx/                 # Nginx config files
├── k8s/                   # Kubernetes manifests (future)
└── [docker files]         # Dockerfile, docker-compose.yml, etc.
```

**Rationale:**
- Dancer2 standaard structuur gerespecteerd
- ProjectDoc voor alle markdown documentatie
- Duidelijke scheiding frontend (public/) en backend (lib/)
- JavaScript modules georganiseerd in public/javascripts/modules/
- Geen archive folder (gebruik git history)

---

## 2. Documentatie Strategie

### A. ProjectLog.md - Implementatie Logboek

**Primair doel:** AI context na onderbreking - volledige technische historie voor session continuïteit.

**Secundair doel:** Developer reference - waar zijn we gebleven, wat is besloten, waarom.

**Format per entry:**
```markdown
## YYYY-MM-DD (Issue #XX) - [Onderwerp]

### Bevindingen/Beslissingen
- Wat ontdekt/besloten
- Waarom belangrijk

### Implementatie
- Wat gedaan
- Hoe werkt het
- Welke files gewijzigd

### Status
✅ Compleet / 🔄 In Progress / ⏸️ Waiting / ❌ Blocked
```

**Gebruik:**
- Elke significante wijziging loggen
- Technische details vastleggen (met code snippets waar relevant)
- Context voor toekomstige sessions
- Link naar GitHub issues waar van toepassing

**NIET gebruiken voor:**
- Kleine bug fixes zonder context
- Triviale code cleanup
- Persoonlijke notities

**MySite specifiek:**
- Reference files met markdown links: `[lib/MySite.pm](lib/MySite.pm)`
- Include line numbers waar relevant: `[file.js](file.js#L42)`
- Tag security issues duidelijk met 🔴
- Tag technical debt met ⚠️

---

### B. GitHub Issues - Planning & Tracking

**Doel:** Planning en progress tracking via GitHub Issues.

**MySite gebruikt GitHub Issues voor:**
- Feature requests en enhancements
- Bug tracking
- Milestone planning
- Issue dependencies (#30 → #31 → #32)

**Issue Format:**
```markdown
## Description
[Wat moet er gebeuren]

## Acceptance Criteria
- [ ] Criterium 1
- [ ] Criterium 2

## Implementation Details
[Code voorbeelden, architectuur beslissingen]

## Dependencies
- Requires: #XX (andere issue)

## Testing Strategy
[Hoe te testen]
```

**Status tracking:**
- Open issues = To Do
- Assigned + In Progress label = 🔄 In Progress  
- Closed = ✅ Completed
- Blocked label = ❌ Blocked

**Cruciale regel - Documentation Linking:**
> **Bij issue completion: Reference ProjectLog entry in closing message**

**Format:**
```markdown
✅ Completed

Implementation details: ProjectLog.md (2026-XX-XX entry)

Technical summary:
- [Bullet points van key changes]
- [Files modified]
- [Known issues/limitations if any]
```

**Voorbeeld:**
```markdown
Closing Issue #31 - Redis Session Implementation

✅ Completed and merged to main

Implementation details: ProjectLog.md (2026-02-08 entry)

Key changes:
- Redis connection pool configured
- Session handler migrated from YAML to Redis
- Fallback to YAML for development mode
- docker-compose.yml updated with redis service

Files: lib/MySite.pm, config.yml, docker-compose.yml
```

**Rationale:**
- ProjectLog → Issue (via header) ✅ Already done
- Issue → ProjectLog (via closing message) ✅ **This makes bidirectional linking complete**
- Future reference: "Hoe was dit geïmplementeerd?" → check issue → link naar details

---

### C. Development Workflow Documentation

**Doel:** Praktische handleiding voor development en deployment.

**Key workflows te documenteren:**

1. **Local Development**
   ```bash
   # Without Docker
   carton exec -- plackup -R lib,views bin/app.psgi
   
   # With Docker (development mode)
   docker-compose up -d
   docker-compose restart mysite  # After code changes
   ```

2. **Testing**
   ```bash
   carton exec -- prove -lv t/
   ```

3. **Docker Operations**
   ```bash
   # Build
   docker build -f Dockerfile.simple -t mysite:simple .
   
   # Development
   docker-compose up -d
   docker-compose logs -f mysite
   
   # Production
   docker-compose -f docker-compose.prod.yml up -d
   
   # Cleanup
   docker-compose down
   ```

4. **Database Operations**
   ```bash
   # SQLite (development)
   sqlite3 db/mysite.sqlite
   
   # Schema updates (DBIC)
   # [Document wanneer PostgreSQL migratie (issue #32) klaar is]
   ```

**Format per command:**
- Command syntax met voorbeelden
- Wanneer gebruiken (development/production/testing)
- Common options
- Expected output/behavior

---

## 3. Workflow Afspraken

### Synchronisatie GitHub Issues ↔ ProjectLog.md

**Regel: Bidirectionele linking verplicht**

**ProjectLog → Issue (forward reference):**
```markdown
## 2026-02-08 (Issue #31) - Redis Implementation
[Technical details...]
```
✅ Issue number in header

**Issue → ProjectLog (reverse reference bij closing):**
```markdown
✅ Completed
Implementation details: ProjectLog.md (2026-02-08 entry)
```
✅ Log entry date in closing message

**Workflow:**
1. Start issue → create ProjectLog entry met `(Issue #XX)` in header
2. Implementeer feature → update ProjectLog met details tijdens werk
3. Complete → close issue met reference naar ProjectLog entry
4. Result: volledig traceerbaar in beide richtingen

**Triggers voor log update:**
- Issue start (initial entry met context)
- Technische beslissing tijdens implementatie
- Bug fix die context verdient (met root cause)
- Security issue discovery
- Issue completion (final summary)

**NIET loggen bij:**
- Kleine refactoring binnen bestaande scope
- Typo fixes
- Code cleanup zonder functionaliteit wijziging

---

### Git Workflow

**Branch Strategy:**
- `main` = stable, werkende code
- Feature branches: `username/issue-number` of `feature/description`
- Merge via Pull Requests (verplicht voor code changes)

**Complete Workflow:**
```bash
# 1. Create issue branch
git checkout -b peter-kaagman/issue-XX

# 2. Implement & commit
git add <files>
git commit -m "fix/feat: Description (Issue #XX)"

# 3. Push branch
git push origin peter-kaagman/issue-XX

# 4. Create Pull Request
gh pr create --base main --head peter-kaagman/issue-XX \
  --title "Fix/Feat: Title" \
  --body "Resolves #XX\n\n## Changes\n- ...\n\n## Testing\n- ✅ ..."

# 5. Merge PR (squash merge recommended)
gh pr merge XX --squash --delete-branch

# 6. Sync local main
git checkout main
git pull origin main

# 7. Close issue with reference
gh issue close XX --comment "✅ Completed. See ProjectLog.md (YYYY-MM-DD)"
```

**Commit Messages:**
```bash
# Good
git commit -m "feat: Add Redis session support (Issue #31)"
git commit -m "fix: Keyword authorization check (Security, Issue #XX)"
git commit -m "docs: Update ProjectLog with Issue #XX completion"

# Bad  
git commit -m "Update file"
git commit -m "Fix bug"
```

**Rules:**
- Commit messages moeten standalone begrijpelijk zijn zonder context
- Altijd PR maken voor code changes (branch → main)
- Squash merge voor cleane history
- Delete branch na merge (automatisch met --delete-branch)
- Pull main na merge om lokaal sync te houden

---

## 4. Technische Beslissingen - MySite

### Database: DBIC (ORM) Approach

**Beslissing:** DBIx::Class voor database abstraction laag.

**Rationale:**
- Object-relational mapping voor cleanere code
- Schema versioning en migrations
- Relationship handling (articles ↔ keywords, users ↔ articles)
- Portable query syntax
- Type checking en validation

**Trade-offs:**
- ❌ Meer overhead dan raw SQL
- ❌ Learning curve steiler
- ✅ Maar: cleaner code, makkelijker te onderhouden
- ✅ Relationships (many-to-many) veel eenvoudiger

**Best Practices:**
```perl
# Good: Use DBIC relationships
my @keywords = $article->keywords->all;

# Avoid: Raw SQL tenzij performance critical
my $sth = $dbh->prepare("SELECT ...");
```

---

### Frontend Architecture: Modular JavaScript

**Beslissing:** Reusable ES6 modules zonder framework (geen React/Vue).

**Current Modules:**
- `SearchCombo` - Multi/single-select met autocomplete
- `TitleManager` - Title/slug synchronization
- `uiSync` - Event-driven UI updates
- `api` - Centralized API communication

**Design Principles:**
- Auto-detection van context (create vs edit mode)
- Event-driven communication tussen modules
- Single responsibility per module
- No jQuery dependency (vanilla JS)

**Rationale:**
- Lightweight (geen framework overhead)
- Makkelijk te begrijpen en onderhouden
- Reusable across templates
- Performance: geen virtual DOM overhead

---

### Containerization: Docker First

**Beslissing:** Docker als primary deployment method.

**Current Setup:**
- Multi-stage builds (builder + runtime)
- Two-tier compose files (dev + prod)
- Volume mounts voor development
- Health checks geïntegreerd

**Rationale:**
- Consistent environments (dev = prod)
- Easy deployment
- Scalability via Kubernetes (future)
- Dependency isolation

**Future:**
- PostgreSQL container (Issue #32)
- Redis container (Issue #31)
- Nginx reverse proxy
- Multi-container orchestration

---

### Session Management: Phased Approach

**Current:** YAML file sessions (development)

**Planned Migration:**
1. **Issue #31**: Redis voor session storage (scalability)
2. **Future**: Session replication voor HA

**Rationale:**
- Start simple (YAML = zero setup)
- Migrate when needed (Redis = horizontal scaling)
- Don't over-engineer early

---

### Database Strategy: SQLite → PostgreSQL

**Current:** SQLite (development, single-user)

**Planned (Issue #32):** PostgreSQL (production, multi-user)

**Migration Strategy:**
- DBIC abstracts differences (mostly)
- Schema identical except AutoIncrement handling
- Data migration script via DBIC
- Dual support: SQLite for dev, PostgreSQL for prod

**Rationale:**
- SQLite = fast development iteration
- PostgreSQL = production robustness, concurrency
- DBIC makes migration easier than raw SQL

---

### Authentication: OAuth + Custom Provider

**Current:** Custom OAuth provider (`MySite::Auth::Provider::SessionOAuth`)

**Integration:** Dancer2::Plugin::Auth::Extensible

**Features:**
- Session-based authentication
- Role-based authorization (Admin, Editor, Writer)
- Resource ownership checks (`is_owned_by()`)

**Security Pattern:**
```perl
# Route authorization
get '/article/edit/:id' => sub {
    my $user = logged_in_user();
    my $article = schema->resultset('Article')->find($id);
    
    # Check ownership OR admin role
    redirect '/denied' unless user_can_edit_article($user, $article);
    
    # ... render edit page
};
```

---

## 5. Communicatie & Taal

### Nederlands/Engels Mix

**Regel:**
- **Nederlands** voor algemene communicatie
- **Engels** voor technische termen waar dat natuurlijker is
- **Geen geforceerde vertalingen** ("klaar weg" vermijden)

**Voorbeelden goed:**
- "SQL query" (niet "SQL zoekopdracht")
- "Database schema updaten"
- "Client count" (niet "cliënt telling")

### AI Assistant Gedrag

**Verwachtingen:**
- Direct handelen, niet eindeloos vragen
- Beknopte antwoorden (1-3 zinnen tenzij complex)
- Technisch correct maar begrijpelijk
- Geen emojis tenzij gevraagd (of in logs waar het context geeft)

---

## 6. Logging & Status

### Waiting Periods

**Regel:** Log pauzes/waiting periods expliciet.

**Rationale:**
- Context voor toekomstige sessions
- Voorkomt vragen "waarom doen we niks?"
- Duidelijk wanneer hervatten

**Format:**
```markdown
## [Project] - YYYY-MM-DD - HH:MM - Data Collection Waiting Period

**Status:** [Wat voltooid], wachten op [wat nodig]
**Reden:** [Waarom wachten]
**Resume:** [Wanneer hervatten]
```

---

### Status Markers Consistent

**Gebruik overal:**
- ✅ Completed
- 🔄 In Progress
- ⏸️ Waiting/Paused
- ❌ Failed/Blocked
- ❓ Unclear/TBD

---

## 7. Project Planning & Scope

### Issue-Based Planning

**Regel:** Gebruik GitHub Issues voor planning, niet vaste "fases".

**MySite Voorbeeld:**
- Issue #23: SearchCombo & Article Editing
- Issue #30: Docker setup  
- Issue #31: Redis voor Session Management
- Issue #32: PostgreSQL migratie
- Issue #33: Database path investigation

**Voordelen:**
- Flexibel (issues kunnen parallel)
- Dependencies expliciet (#31 requires #30)
- Atomic (elke issue is testbaar)
- Trackable (open/closed status)

**NIET:** Rigide fase structuur die aanpassing tegenwerkt.

**Rationale:** Issues reflecteren werk beter dan abstracte fases.

---

### Scope Clarification

**Regel:** Bij onduidelijkheid over scope/requirements:
1. Maak expliciete aanname
2. Document aanname in ProjectLog
3. Implementeer op basis van aanname
4. Verifieer achteraf (of na demo)

**NIET:** Eindeloos vragen stellen voordat beginnen.

**Voorbeeld:**
```markdown
## 2026-02-07 - Slug Validation Implementation

**Aanname:** Slugs moeten lowercase + underscores (niet hyphens)
**Rationale:** Bestaande database data gebruikt underscores
**Verification:** Checked db/mysite.sqlite, confirmed pattern

[Implementation details...]
```

**Als aanname verkeerd blijkt:** Documenteer waarom, pas aan, leer ervan.

---

## 8. MySite Specifieke Best Practices

### Security & Authorization

**Regel:** Alle write endpoints moeten authorization checken.

**Pattern:**
```perl
# Check 1: User is logged in
my $user = logged_in_user();
redirect '/login' unless $user;

# Check 2: User can edit this resource
my $article = schema->resultset('Article')->find($id);
return send_error("Forbidden", 403) 
    unless user_can_edit_article($user, $article, \@allowed_roles);

# Check 3: Validate input
return send_error("Invalid slug", 400)
    unless $slug =~ /^[a-z0-9_-]+$/;
```

**Common pitfalls:**
- ❌ Forgetting auth on API endpoints (keyword/category POST routes)
- ❌ Client-side validation alleen (altijd server-side!)
- ❌ Generic error messages (information disclosure)

**Verification checklist:**
```bash
# Audit all POST/PUT/DELETE routes
grep -E "^(post|put|del) " lib/MySite/*.pm

# Check authorization
grep -A5 "^post " lib/MySite/Article.pm | grep -E "(logged_in_user|user_can)"
```

---

### Slug Handling

**Rules:**
1. Only lowercase letters, numbers, hyphens, underscores
2. No spaces allowed
3. Normalize on server-side (never trust client)
4. Check uniqueness before INSERT/UPDATE

**Implementation:**
```perl
# Utils.pm
sub slugify {
    my $text = shift;
    $text = lc($text);
    $text =~ s/\s+/_/g;      # Spaces to underscores
    $text =~ s/[^a-z0-9_-]//g;  # Remove invalid chars
    return $text;
}

# Always use in route handlers
my $slug = slugify($params->{slug});
```

**Validation:**
```perl
# DBIC Result class
sub insert {
    my $self = shift;
    $self->_validate_slug($self->slug);
    return $self->next::method(@_);
}

sub _validate_slug {
    my ($self, $slug) = @_;
    die "Invalid slug" unless $slug =~ /^[a-z0-9_-]+$/;
}
```

---

### JSON API Responses

**Standard format:**
```perl
# Success
to_json({
    success => 1,
    message => "Operation completed",
    data => { ... },     # Optional
});

# Error
status 400;  # or 403, 404, 500
to_json({
    success => 0,
    error => "Error message",
});
```

**Order matters:**
```perl
# Correct
status 200;
content_type 'application/json';
return to_json({ ... });

# Wrong - content_type after status might not work
return to_json({ ... });
status 200;
```

---

### Frontend Module Patterns

**Auto-context detection:**
```javascript
// Detect create vs edit mode
constructor() {
    this.articleId = document.getElementById('article_id')?.value || null;
    
    if (this.articleId) {
        // Edit mode: make API calls
    } else {
        // Create mode: local UI only
    }
}
```

**Event-driven updates:**
```javascript
// Module dispatches event
document.dispatchEvent(new CustomEvent('article-field-saved', {
    detail: { field, articleId, value, response }
}));

// uiSync.js listens and updates UI
document.addEventListener('article-field-saved', (e) => {
    updateElement(e.detail.field, e.detail.response[field]);
});
```

**Benefits:**
- Zero config (auto-detection)
- Loose coupling (events)
- Reusable (same module for add.tt and edit.tt)

---

### Docker Development Workflow

**Rule:** Always use development compose file for coding.

**Volume mounts enable live reload:**
```yaml
volumes:
  - ./lib:/app/lib          # Perl changes
  - ./views:/app/views      # Template changes
  - ./public:/app/public    # Frontend changes
```

**After code changes:**
```bash
# Restart plackup to pick up Perl changes
docker-compose restart mysite

# No restart needed for:
# - Template changes (Template Toolkit auto-reloads)
# - JavaScript/CSS changes (static files)
```

**When to rebuild:**
```bash
# Only rebuild when:
# - cpanfile dependencies change
# - Dockerfile changes
# - System package changes

docker-compose down
docker build -f Dockerfile.simple -t mysite:simple .
docker-compose up -d
```

---

### Template Organization

**Structure:**
```
views/
├── layouts/
│   └── main.tt           # Base layout
├── includes/
│   ├── header.tt         # Shared components
│   ├── footer.tt
│   └── navbar.tt
├── article/
│   ├── add.tt            # Article creation
│   ├── edit.tt           # Article editing
│   ├── article.tt        # Article display
│   └── list.tt           # Article listing
└── user/
    ├── profile.tt
    └── loginfailed.tt
```

**Principles:**
- DRY: shared components in includes/
- Feature folders (article/, user/)
- Minimal logic in templates (push to Perl)
- Data prep in route handlers, not templates

---

## 9. Git/Version Control

### Commit Strategy

**Regel:** Commit per logische unit, niet per file.

**Goed:**
- `"Add Redis session support (Issue #31)"`
- `"Fix keyword authorization check (Security)"`
- `"Implement SearchCombo module with multi-select"`

**Slecht:**
- `"Update file"`
- `"Fix bug"`
- `"Changes"`

**Commit message format:**
```
<type>: <description> [(<context>)]

Examples:
feat: Add health check endpoint (Issue #30)
fix: Validate slug format on direct updates
refactor: Extract slug normalization to Utils
docs: Update ProjectLog with Docker implementation
security: Add authorization to keyword endpoints
```

---

### Branch Strategy

**MySite gebruikt:**
- `main` = stable, werkende code (protected)
- Feature branches: `username/issue-XX` of `feature/description`
- Hotfix branches: `hotfix/critical-bug`

**🔴 CRITICAL RULE: Code Changes ONLY in Issue Branches**

> **CODE WIJZIGINGEN UITSLUITEND IN ISSUE BRANCH**
> 
> Main branch = alleen voor documentatie en project administratie.
> Code changes = altijd een issue branch eerst!

**Workflow:**
```bash
# 1. Start issue - checkout branch FIRST
git checkout -b peter-kaagman/issue-36

# 2. NOW you can make code changes
# Edit files, implement feature...

# 3. Commit changes
git add <files>
git commit -m "fix: Implement empty field validation (Issue #36)"

# 4. Push branch to GitHub
git push origin peter-kaagman/issue-36

# 5. Create Pull Request
gh pr create --base main --head peter-kaagman/issue-36 \
  --title "Fix(Issue #36): Empty field validation" \
  --body "Resolves #36..."

# 6. Merge PR (squash merge preferred for clean history)
gh pr merge 36 --squash --delete-branch

# 7. Switch back to main and sync
git checkout main
git pull origin main

# 8. Close issue with reference to ProjectLog
gh issue close 36 --comment "✅ Completed. See ProjectLog.md (YYYY-MM-DD)"
```

**Toegestaan op main branch:**
- ✅ Documentation updates (ProjectLog.md, GenericProjectRules.md)
- ✅ README updates
- ✅ Project administratie (issues aanmaken/updaten via gh CLI)
- ✅ Git read operations (status, log, diff)

**Verboden op main branch:**
- ❌ Code changes in lib/, views/, public/
- ❌ Schema updates
- ❌ Dependency changes (cpanfile)
- ❌ Config changes (config.yml, environments/)

**Rationale:** 
- Main blijft stable
- Code changes zijn atomic per issue
- Easy rollback als issue mislukt
- Clear separation tussen admin en development

**Issue Closing Workflow:**

Bij afronden van een issue, AI stelt voor:

**1. Commit Message Template:**
```bash
git commit -m "<type>: <description> (Issue #XX)

Implementation details:
- Key change 1
- Key change 2
- Key change 3

Closes #XX
See ProjectLog.md (YYYY-MM-DD) for full technical details"
```

**2. GitHub Issue Closing Comment** (via `gh` CLI of browser):
```markdown
✅ Completed and merged to main

Implementation details: ProjectLog.md (YYYY-MM-DD entry)

Key changes:
- [Bullet point 1]
- [Bullet point 2]
- [Bullet point 3]

Files modified: [file1.pm, file2.js, ...]
Branch: username/issue-XX
```

**GitHub CLI Commands:**
```bash
# Close with comment
gh issue close 31 --comment "✅ Completed. See ProjectLog.md (2026-02-08)"

# Or add comment first, close later
gh issue comment 31 --body "[paste closing message]"
gh issue close 31
```

**Rationale:** "Closes #XX" in commit auto-links. Closing comment geeft toekomstige developers direct pointer naar details.

**Pull Request Guidelines:**
- Link GitHub issue in beschrijving
- Summarize wat gedaan is
- Note breaking changes (if any)
- Include testing notes

---

### Git Best Practices

**Preferred:**
- Small, focused commits (makkelijk te reviewen)
- Descriptive commit messages
- Reference issue numbers: `(Issue #31)`
- Test before commit

**Avoid:**
- Committing broken code op main
- Huge commits (1000+ lines zonder structuur)
- Vague messages: "misc changes"
- Secrets/credentials in repo (use .gitignore!)

---

## 10. Lessons Learned - MySite Project

### Wat Goed Werkte

1. **DBIC voor relationships** - Many-to-many (articles ↔ keywords) veel eenvoudiger dan raw SQL
2. **Event-driven frontend** - Modules loosely coupled, easy to test en debug
3. **Docker vanaf dag 1** - Consistent environments, easy deployment
4. **Modular JavaScript** - Reusable components zonder framework overhead
5. **ProjectLog.md met code snippets** - Context bewaard, bugs sneller reproduceren
6. **Phased approach** - SQLite → Redis → PostgreSQL (niet alles tegelijk)
7. **Root cause analysis** - Niet alleen "fix", maar ook "waarom kapot?"

### Wat Beter Kan

1. **Security audit eerder** - Authorization gaps pas laat ontdekt (keyword/category endpoints)
2. **Validation consistency** - Sommige endpoints wel, andere niet (slug validatie)
3. **Technical debt tracking** - Database path issue geïdentificeerd maar root cause niet onderzocht
4. **Testing** - Weinig automated tests (future: add integration tests)
5. **~~Documentation disconnect~~** - ✅ **OPGELOST** (2026-02-08): Bidirectionele linking Issue ↔ ProjectLog via closing messages

### Specifieke Pitfalls

1. **Bootstrap CSS caching** - `:checked` pseudo-selector blijft cached
   - **Fix:** Rebuild DOM elements i.p.v. toggle properties
   
2. **Type coercion bugs** - Numbers vs strings in JavaScript arrays
   - **Fix:** Explicit `String()` conversions bij vergelijkingen
   
3. **ID vs title confusion** - Search matching IDs tegen display titles
   - **Fix:** Consistent data format: always `{id, title}` objects

4. **Optimistic UI updates** - UI update voor server save → state mismatch
   - **Fix:** Save-first pattern voor edit mode

5. **API format inconsistency** - `/keywords` vs `/categories` endpoints verschillend
   - **Fix:** Standardize op `{values: [{id, title}, ...]}`

### Verbeterpunten Volgend Project

1. **Security checklist vanaf start** - Niet achteraf auditen
2. **API contract documentation** - OpenAPI/Swagger spec voor consistency
3. **Automated testing** - Integration tests voor critical paths
4. **Database decisions vroeg** - SQLite vs PostgreSQL implicaties (AutoIncrement, etc)
5. **Environment parity** - Dev moet production benaderen (Redis, PostgreSQL)

---

## 11. Template: New Dancer2 Project Checklist

Gebruik dit bij start nieuw Dancer2/Perl web project:

```markdown
### Project Setup
- [ ] `dancer2 gen -a ProjectName` (scaffold initial app)
- [ ] ProjectDoc/ directory aanmaken
- [ ] ProjectLog.md initiëren met project context
- [ ] GenericProjectRules.md kopiëren en aanpassen
- [ ] README.md met project overview
- [ ] .gitignore aanmaken (sessions/, logs/, local/, db/*.sqlite)
- [ ] GitHub repository initiëren + push

### Dependencies
- [ ] cpanfile maken met core dependencies
- [ ] `carton install` uitvoeren
- [ ] cpanfile.snapshot committen (reproducible builds)
- [ ] Document Perl version requirement

### Docker Setup
- [ ] Dockerfile aanmaken (multi-stage build)
- [ ] docker-compose.yml (development)
- [ ] docker-compose.prod.yml (production)
- [ ] Health check endpoint implementeren
- [ ] Test: `docker-compose up -d`

### Database
- [ ] Kies database (SQLite dev, PostgreSQL prod?)
- [ ] DBIC schema classes genereren
- [ ] init.sql voor schema creation
- [ ] seed data script (optioneel)
- [ ] Test connectivity

### Authentication (if needed)
- [ ] Auth provider implementeren
- [ ] Session management configureren
- [ ] Login/logout routes
- [ ] Authorization helpers (roles, ownership checks)
- [ ] Test auth flow

### Frontend
- [ ] CSS framework kiezen (Bootstrap, Tailwind, custom?)
- [ ] JavaScript module structure opzetten
- [ ] Template structure (layouts, includes, feature folders)
- [ ] Static asset organization

### Testing
- [ ] Basic route tests (t/001_base.t, t/002_index_route.t)
- [ ] Test database setup (test.db)
- [ ] CI/CD pipeline (GitHub Actions?)

### Documentation
- [ ] First ProjectLog entry: "Project Setup"
- [ ] Command reference (development workflow)
- [ ] API documentation (if building API)
- [ ] Deployment instructions

### First Issue/Feature
- [ ] GitHub issue aanmaken voor eerste feature
- [ ] Branch maken
- [ ] Implementeren
- [ ] ProjectLog updaten
- [ ] PR + merge
```

---

## 13. MySite Current Status (Feb 2026)

**Completed:**
- ✅ Issue #23: SearchCombo & Article Editing (volledig functioneel)
- ✅ Issue #30: Docker setup (development + production configs)

**In Progress:**
- 🔄 Security gaps fix (keyword/category authorization)
- 🔄 Slug validation fix (direct updates)

**Planned:**
- 📋 Issue #31: Redis voor Session Management
- 📋 Issue #32: PostgreSQL migratie
- 📋 Issue #33: Database path root cause onderzoek

**Technical Debt:**
- ⚠️ Database path configuratie (relatief vs absoluut - root cause onbekend)
- 🔴 Authorization missing op `/article/keyword` en `/article/category` POST
- 🔴 Slug validatie missing bij directe updates
- 🟡 Content/abstract validation (lege waarden geaccepteerd)

**Stack:**
- Backend: Perl 5.38, Dancer2, DBIx::Class
- Frontend: Vanilla JavaScript (ES6 modules), Bootstrap 5
- Database: SQLite (dev), PostgreSQL (planned)
- Sessions: YAML files (dev), Redis (planned)
- Deployment: Docker, docker-compose

---

## 14. Dynamische Aard van Projectregels

> **WAARSCHUWING:** Deze rules zijn **geen wet**, maar **richtlijnen die moeten buigen naar werkelijkheid**.

De wereld is dynamisch. Projecten zijn dynamisch. Je leert tijdens uitvoering. Daarom:

**Rules moeten aangepast worden aan situatie:**
- Wat werkt voor een klein CRUD project verschilt van enterprise applicatie
- Wat werkt solo verschilt van team project
- Wat werkt in experimentele fase verschilt van production maintenance

**Hoe omgaan met afwijkingen:**
1. Merk op dat situatie van regel verschilt
2. Probeer aangepaste benadering
3. Documenteer waarom je afwijkt (in ProjectLog)
4. Update dit document als het beter werkt
5. Volgende project profiteert van inzicht

**Voorbeelden:**
- Prototype → formele planning schadelijk, iterate snel
- Production bug → skip tests, fix fast, test later
- Learning project → over-documenteer (leerdoel)
- Maintenance mode → minimize changes, stability > features

**De meta-regel:**
Volg regels **intentioneel**, niet **automatisch**. Elke regel heeft een reden. Snap die reden, dan kun je beslissen of regel past.

---

## 15. Context voor AI Assistant

Dit document dient verschillende doelen:

**Voor AI (primair):**
- ProjectLog.md = **volledige context na onderbreking** (technische details, beslissingen, code snippets)
- GitHub Issues = high-level planning en tracking
- GenericProjectRules.md = project-specifieke best practices en patterns

**Voor Developer (secundair):**
- ProjectLog.md = **waar zijn we gebleven** (status check, technische historie)
- GitHub Issues = planning en acceptance criteria
- GenericProjectRules.md = refresher van beslissingen en patronen

**Rationale:** AI heeft geen geheugen tussen sessions - ProjectLog is cruciaal voor continuïteit. Developer kan vaak uit geheugen werken.

**Verwachtingen van AI:**
- Direct handelen op basis van deze rules
- **Signaleer afwijkingen van rules door developer** (zonder oordeel)
- Afwijken MAG, maar documenteer waarom
- Beknopte antwoorden (1-3 zinnen tenzij complex)
- Technisch correct maar begrijpelijk
- Security-first mindset (vraag bij twijfel)

**Omgaan met Rule Violations:**

Wanneer developer afwijkt van rules:
1. **Signaleer de afwijking**: *"Dit wijkt af van regel X (zie sectie Y)"*
2. **Vraag intentie**: *"Is dit opzettelijk? Werkt de regel niet voor deze situatie?"*
3. **Twee outcomes:**
   - Developer heeft goede reden → documenteer afwijking in ProjectLog
   - Rule past niet → update GenericProjectRules.md met nieuwe inzichten

**Voorbeelden:**
```
❌ Slecht: "Je doet het fout, dit moet anders"
✅ Goed: "Dit gebruikt raw SQL. Regel 4 stelt DBIC voor. Bewuste keuze (performance)?"

❌ Slecht: Stilletjes accepteren zonder signaleren
✅ Goed: Signaleren, samen beslissen, documenteren
```

**Rationale:** Rules zijn **leermiddel**, geen **keurslijf**. Afwijkingen zijn vaak signaal dat regel verbeterd moet worden.

**Leerproces:**
Dit document zelf is voorbeeld van consolidatie. Nadenken over "wat werkte goed?" en "wat kan beter?" helpt meer dan alleen implementeren.

---

**Version:** 2.0 (aangepast voor MySite)  
**Created:** 2026-02-05 (AP Monitoring - generic rules)  
**Adapted:** 2026-02-07 (MySite specific)  
**Project:** MySite - Dancer2 Blog/CMS Platform  
**Author:** Peter Kaagman (met AI assistent)  
**Status:** Living document - verwacht aanpassingen per project fase

**Next Review:** Bij completion Issue #32 (PostgreSQL migratie) - review database patterns

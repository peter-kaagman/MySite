# MySite Project Documentation

Welkom bij de MySite project documentatie. Deze folder bevat alle technische documentatie, beslissingen, en project regels.

---

## 📚 **Documentatie Overzicht**

### [ProjectLog.md](ProjectLog.md)
**Chronologisch implementatie logboek** - Alle technische beslissingen en implementaties.

**Primair doel:** AI context na onderbreking (volledige technische historie)  
**Secundair doel:** Developer reference (waar zijn we gebleven, wat is besloten)

**Format:** Reverse chronological (nieuwste eerst)  
**Inhoud:**
- Implementatie details met code snippets
- Root cause analysis van bugs
- Technische beslissingen met rationale
- Files modified per entry
- Status markers (✅ ❌ 🔄 ⏸️)

**Updates:** Bij elke significante wijziging, issue completion, of technische beslissing

---

### [GenericProjectRules.md](GenericProjectRules.md)
**Project regels en best practices** - MySite-specifieke workflows en patronen.

**Doel:** Template voor consistent werken, referentie voor beslissingen

**Belangrijkste secties:**
1. **Project Structuur** - Directory layout, Dancer2 conventions
2. **Documentatie Strategie** - ProjectLog, GitHub Issues, workflow
3. **Git Workflow** - Branch strategy, **CODE ONLY IN ISSUE BRANCHES**
4. **Technische Beslissingen** - DBIC, Docker, Modular JS, Auth patterns
5. **MySite Best Practices** - Security, slug handling, JSON APIs, frontend patterns
6. **Lessons Learned** - Wat werkte, wat beter kan

**Updates:** Bij nieuwe inzichten, workflow wijzigingen, of belangrijke beslissingen

---

### GitHub Issues
**Planning en tracking** - High-level work items met acceptance criteria.

**Link:** [MySite GitHub Issues](https://github.com/peter-kaagman/MySite/issues)

**Issue Format:**
- Description met context
- Acceptance criteria (checklist)
- Implementation notes
- Dependencies (requires #XX)
- Testing strategy

**Workflow:**
- Open = To Do
- In Progress label = 🔄 Actief
- Closed = ✅ Compleet (met closing comment + ProjectLog reference)

---

## 🔄 **Workflow: Documentation Synchronization**

### Bij Issue Start
1. Maak GitHub Issue aan met acceptance criteria
2. Eerste ProjectLog entry: `## YYYY-MM-DD (Issue #XX) - [Title]`

### Tijdens Development
1. Update ProjectLog met technische details
2. Update issue comments bij belangrijke beslissingen
3. Link beide: issue nummer in ProjectLog, log entry date in issue

### Bij Issue Completion
1. Sluit issue met closing comment:
   ```
   ✅ Completed
   Implementation details: ProjectLog.md (YYYY-MM-DD entry)
   ```
2. Final ProjectLog update met status ✅ en summary

**Resultaat:** Bidirectionele linking - vanuit issue naar log, vanuit log naar issue

---

## 🔴 **Critical Rules**

### Code Changes ONLY in Issue Branches
```bash
# WRONG: code changes on main
git checkout main
# edit lib/MySite.pm  ❌
git commit -m "Fix bug"

# CORRECT: branch first
git checkout -b peter-kaagman/issue-36  ✅
# NOW edit code
git commit -m "Add validation (Issue #36)"
```

**Main branch = Documentation + Admin only**

### Issue Closing with GitHub CLI
```bash
gh issue close 36 --comment "✅ Completed. See ProjectLog.md (2026-02-08)"
```

Zie [GitHub CLI Setup entry](ProjectLog.md) voor details.

---

## 📊 **Current Project Status** (Feb 2026)

### Completed
- ✅ Issue #23: SearchCombo & Article Editing
- ✅ Issue #30: Docker setup (dev + prod)
- ✅ GitHub CLI integration
- ✅ Project documentation herstructurering

### In Progress
- 🔄 Issue #36: Empty field validation (ready for branch)

### Planned
- 📋 Issue #31: Redis voor Session Management
- 📋 Issue #32: PostgreSQL migratie
- 📋 Issue #34: Database path investigation

### Technical Debt
- ⚠️ Database path configuration (relatief vs absoluut - root cause onbekend)

---

## 🛠️ **Tech Stack**

**Backend:**
- Perl 5.38
- Dancer2 web framework
- DBIx::Class (ORM)
- Template Toolkit

**Frontend:**
- Vanilla JavaScript (ES6 modules)
- Bootstrap 5
- Custom modules: SearchCombo, TitleManager, uiSync

**Database:**
- SQLite (development)
- PostgreSQL (planned for production)

**Sessions:**
- YAML files (development)
- Redis (planned)

**Deployment:**
- Docker + docker-compose
- Multi-stage builds

**Auth:**
- OAuth + Custom Provider
- Dancer2::Plugin::Auth::Extensible

---

## 📖 **Quick Reference**

**Start new issue:**
```bash
gh issue create --title "Feature X" --body "Description..."
```

**Log something:**
Add entry to ProjectLog.md with format:
```markdown
## YYYY-MM-DD (Issue #XX) - [Title]

### Overzicht
[What was done]

### Files Gewijzigd
- ✏️ [file.pm](file.pm) - Description
```

**Check current issues:**
```bash
gh issue list --limit 10
```

**Close an issue:**
```bash
gh issue close XX --comment "✅ Completed. See ProjectLog.md (date)"
```

---

## 🔍 **Finding Information**

**"Hoe implementeerden we X?"**
→ Search ProjectLog.md voor feature naam

**"Waarom besloten we Y?"**
→ Check GenericProjectRules.md sectie 4 (Technische Beslissingen)

**"Wat staat er nog open?"**
→ `gh issue list` of check GitHub Issues online

**"Welke files zijn belangrijk?"**
→ Check GenericProjectRules.md sectie 1 (Project Structuur)

---

**Laatste update:** 2026-02-08  
**Maintainer:** Peter Kaagman  
**Status:** Living documentation - verwacht updates bij nieuwe inzichten

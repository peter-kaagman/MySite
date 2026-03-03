# Git & GitHub Richtlijnen

Afspraken over branching, PR's, commit conventies, issue templates en release-strategie.

## Branches
- `main`: alleen documentatie/admin, nooit codewijzigingen
- Feature branches: `username/issue-XX` of `feature/omschrijving`
- Hotfix branches: `hotfix/omschrijving`

## Commit messages
- Formaat: `<type>: <omschrijving> (Issue #XX)`
- Duidelijk, contextvol, geen vage teksten

## Pull Requests
- Altijd via PR naar main
- Squash merge aanbevolen
- Branch verwijderen na merge

## Issue closing
- Sluit issue met comment: "✅ Completed. See ProjectLog.md (YYYY-MM-DD)"

## Issue-format
- Description, Acceptance Criteria, Implementation Details, Dependencies, Testing Strategy

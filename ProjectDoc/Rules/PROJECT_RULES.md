# Projectspecifieke Regels

Dit document bevat afspraken die specifiek gelden voor dit project: architectuur, workflow, loggingstructuur, deployment, map-indeling, enz.

## Inhoudsopgave
- Projectstructuur
- Workflow & Git
- Logging
- Branches & PR's
- Status markers

---

## Projectstructuur
- Zie het schema in deze map voor de standaard indeling van de projectmappen.
- Documentatie en logs in ProjectDoc/, code in lib/, views/, public/.

## Workflow & Git
- Issues altijd via GitHub aanmaken (gh CLI of web), nooit als los bestand.
- Codewijzigingen alleen in issue branches, nooit direct op main.
- Commit messages zijn duidelijk, bevatten issue-nummer en context.
- Branches: `main` alleen voor documentatie/admin, nooit codewijzigingen.
- Feature branches: `username/issue-XX` of `feature/omschrijving`.
- Hotfix branches: `hotfix/omschrijving`.
- Altijd via PR naar main, squash merge aanbevolen.
- Branch verwijderen na merge.

## Logging
- Voor elk issue wordt een apart logbestand bijgehouden in ProjectDoc/ (naam: `Issue-XX.md`).
- Tijdens het werken aan een issue log je voortgang, beslissingen en implementatiedetails in het bijbehorende bestand.
- Na afronding van een issue maak je een korte samenvatting in het globale ProjectLog.md, met verwijzing naar het issue-log.
- ProjectLog.md bevat alleen samenvattingen van afgeronde issues, met datum en issue-nummer.
- Gebruik vaste structuur: Bevindingen/Beslissingen, Implementatie, Status (✅/🔄/⏸️/❌).
- Link naar relevante issues en bestanden.

## Status markers
- ✅ Completed, 🔄 In Progress, ⏸️ Waiting, ❌ Blocked

## Afwijken van regels
- Afwijken? Documenteer waarom in ProjectLog.md.

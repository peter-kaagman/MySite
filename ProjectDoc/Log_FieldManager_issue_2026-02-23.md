# Logentry: Field managers laden niet in productie

Datum: 2026-02-23

Probleem:
- De title, category en keyword managers (TitleManager, SearchCombo, SimpleFieldManager) worden niet geladen in de productieomgeving.
- Geen foutmeldingen in de browserconsole.
- typeof-checks in article_edit.js falen, vermoedelijk omdat de ES6 modules niet correct op window worden gezet of niet goed geladen worden.
- Pogingen om de klassen op window te zetten en script-tags aan te passen (type="module") lossen het probleem niet op.
- Lint- en syntaxfouten zijn inmiddels opgelost, maar het functionele probleem blijft bestaan.

Actie:
- Oplossen en verder debuggen wordt verplaatst naar de development-omgeving.
- Geen verdere wijzigingen in productie tot het probleem in devel is opgelost.

Besluit:
- Issue wordt gesloten op productie, verder onderzoek volgt op devel.

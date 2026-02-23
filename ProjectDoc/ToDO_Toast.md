# Log 2026-02-23 (afsluiting issue46):
- Toast UI Editor volledig geïntegreerd voor content en abstract, inclusief save/cancel-functionaliteit en documentatie.
- Herbruikbaarheid, styling en dependencies getest en geborgd.
- CRUD-problemen en gebruikersinstellingen als losse GitHub issues aangemaakt.
- Zie enhancement issue #54 voor het configureerbaar maken van editor-instellingen via het user profile: https://github.com/peter-kaagman/MySite/issues/54
# Log 2026-02-23 (vervolg):
- Issue aangemaakt: controleer en verbeter CRUD-functionaliteit voor meta_title en meta_description (zie ISSUE_crud_meta_title_description.md).
# Log 2026-02-23: 
- Content-editor en abstract-editor werken beide met Toast UI Editor, inclusief save/cancel-knoppen.
- Abstract-editor toont nu correct, maar de content van abstract ontbreekt of is verwisseld met meta_description.
- Oorzaak: in de backend (Perl controller) wordt 'article.abstract' correct doorgegeven aan de template, maar mogelijk wordt bij het opslaan of tonen van de abstract per ongeluk het veld meta_description gebruikt i.p.v. abstract.
- Actiepunt: Controleer in JS en Perl of overal het veld 'abstract' wordt gebruikt voor de abstract-editor en niet 'meta_description'.
# Checklist: Toast UI Editor-module integratie

1. Nieuwe module aanmaken
   - Maak een nieuw bestand aan, bijvoorbeeld `public/javascripts/modules/toast_editor.js`.

2. Module-structuur bepalen
   - Exporteer een class of functie, bijvoorbeeld `ToastEditor`.
   - Zorg voor een duidelijke API: constructor, get/setValue, destroy, events/callbacks.

3. Initialisatie
   - In de constructor: accepteer opties zoals `containerId`, `fieldName`, `initialValue`, `onChange`, `onSave`.
   - Initialiseer de Toast UI Editor op de opgegeven div.

4. Waarde ophalen en instellen
   - Implementeer `getValue()` en `setValue()` methoden.
   - Synchroniseer eventueel met een hidden textarea voor form submits.

5. Event-afhandeling
   - Ondersteun callbacks/events voor wijzigingen (`onChange`), opslaan (`onSave`), validatie, enz.

6. Integratie in `article_edit.js`
   - Importeer `ToastEditor`.
   - Maak per veld/div een nieuwe ToastEditor aan met de juiste opties.
   - Koppel save/cancel/dirty events aan je eigen logica.

7. Styling en dependencies
   - Zorg dat de Toast UI Editor JS/CSS via CDN of lokaal geladen is vóór de module.
   - Voeg eventueel extra CSS toe voor knoppen of layout.

8. Herbruikbaarheid testen
   - Gebruik de module voor meerdere velden (content, abstract, pages).
   - Controleer of meerdere instanties naast elkaar werken.

9. Documentatie
   - Voeg een korte uitleg toe aan het begin van `toast_editor.js` over gebruik en opties.

import { initEditors } from './modules/editor.js';
import { SearchCombo } from './modules/searchcombo.js';
import { TitleManager } from './modules/title_slug.js';
// import { registerFieldHandlers } from './modules/fields.js'; // refactoring out
// import { fieldDefinitions } from './modules/fieldDefinitions.js'; // refactoring out

document.addEventListener('DOMContentLoaded', function() {

    window.addEventListener("beforeunload", function (e) {
        if (this.window.unsavedChanges) {
            e.preventDefault();
            e.returnValue = ""; // Required for Chrome
        }
    });

    let unsavedChanges = false;
    initEditors();
    // registerFieldHandlers(fieldDefinitions); // refactoring out
    const titleManager = new TitleManager();
    titleManager.init();
    const keywordManager = new SearchCombo();
    keywordManager.init('article_id', 'list_keywords', 'search_keywords', 'selected_keywords', true);
});
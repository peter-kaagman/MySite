import { initEditors } from './modules/editor.js';
import { SearchCombo } from './modules/searchcombo.js';
import { TitleManager } from './modules/title_slug.js';
// import { registerFieldHandlers } from './modules/fields.js'; // refactoring out
// import { fieldDefinitions } from './modules/fieldDefinitions.js'; // refactoring out

document.addEventListener('DOMContentLoaded', function() {

    window.addEventListener("beforeunload", function (e) {
        if (window.unsavedChanges) {
            e.preventDefault();
            e.returnValue = ""; // Required for Chrome
        }
    });

    // Init editors and expose for debugging
    const editors = initEditors();
    // registerFieldHandlers(fieldDefinitions); // refactoring out
    
    // Title manager
    const titleManager = new TitleManager();
    titleManager.init();

    // Category manager
    // Could be done with a droprdown, but keeping consistent with keywords for now
    const categoryManager = new SearchCombo();
    // categoryManager.init('article_id', 'list_categories', 'search_category', 'selected_categories', false);
    categoryManager.init('article_id','category', 'Categorie:','categoryContainer', false);
    
    // Keyword manager
    // const keywordManager = new SearchCombo();
    // keywordManager.init('article_id', 'list_keywords', 'search_keywords', 'selected_keywords', true);

    // Save button for content (if not already in toolbar)
    const saveBtn = document.getElementById('save-content');
    if (saveBtn && editors && editors.contentmde) {
        saveBtn.addEventListener('click', async () => {
            const articleId = document.getElementById('article_id').value;
            const data = { value: editors.contentmde.value() };
            try {
                await import('./modules/api.js').then(({ handleSave }) => handleSave(articleId, data, 'content'));
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Content saved', 'success');
                }
            } catch (err) {
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Error saving content', 'error');
                }
            }
        });
    }
});
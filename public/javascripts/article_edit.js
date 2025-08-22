import { initEditors } from './modules/editor.js';
import { registerFieldHandlers } from './modules/fields.js';
import { KeywordManager } from './modules/keywords.js';
import { fieldDefinitions } from './modules/fieldDefinitions.js';

document.addEventListener('DOMContentLoaded', function() {

    window.addEventListener("beforeunload", function (e) {
        if (this.window.unsavedChanges) {
            e.preventDefault();
            e.returnValue = ""; // Required for Chrome
        }
    });

    let unsavedChanges = false;
    initEditors();
    registerFieldHandlers(fieldDefinitions);
    const keywordManager = new KeywordManager();
    keywordManager.init();
});
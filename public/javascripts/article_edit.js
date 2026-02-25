import { SearchCombo } from './modules/searchcombo.js';
import { TitleManager } from './modules/title_slug.js';
import { initUISync } from './modules/uiSync.js';
import { SimpleFieldManager } from './modules/simple_field.js';
import './modules/toast_editor.js';
import { ToastWrapper } from './modules/toastWrapper.js';
import { saveItemChange } from './modules/api.js';
import { setSaveStatus } from './modules/utils.js';

document.addEventListener('DOMContentLoaded', function() {

window.addEventListener("beforeunload", function (e) {
        if (window.unsavedChanges) {
            e.preventDefault();
            e.returnValue = ""; // Required for Chrome
        }
    });
    // Initialize UI synchronization (listens to article-field-saved events)
    initUISync();


    // Get articleId from DOM once
    const articleId = document.getElementById('article_id')?.value || null;

    // Title manager
    const titleManager = new TitleManager(articleId);
    titleManager.init();

    // Category manager
    const categoryManager = new SearchCombo();
    categoryManager.init(articleId, 'category', 'Categorie:', false);

    // Keyword manager
    const keywordManager = new SearchCombo();
    keywordManager.init(articleId, 'keywords', 'Keywords:', true);

    // Meta_title manager
    const metaTitleManager = new SimpleFieldManager();
    metaTitleManager.init(articleId, 'edit_meta_title', 'meta_title');

    // Meta_description manager
    const metaDescriptionManager = new SimpleFieldManager();
    metaDescriptionManager.init(articleId, 'edit_meta_description', 'meta_description');

    // --- ToastWrapper integratie ---
    const toastWrapper = new ToastWrapper();
    // Content editor
    toastWrapper.initEditor('content_editor', 'content', 'content_editor_hidden', articleId);
    toastWrapper.bindSave('content', 'save-content');
    toastWrapper.bindCancel('content', 'cancel-content', document.getElementById('content_editor_hidden')?.value || '');
    // Abstract editor
    toastWrapper.initEditor('abstract_editor', 'abstract', 'abstract_editor_hidden', articleId);
    toastWrapper.bindSave('abstract', 'save-abstract');
    toastWrapper.bindCancel('abstract', 'cancel-abstract', document.getElementById('abstract_editor_hidden')?.value || '');

    // Delete button functionality
    const deleteButton = document.getElementById('delete-article');
    if (deleteButton && articleId) {
        deleteButton.addEventListener('click', async () => {
            if (confirm('Weet je zeker dat je dit artikel wilt verwijderen? Dit kan niet ongedaan worden gemaakt.')) {
                setSaveStatus('Bezig met verwijderen...', 'info');
                try {
                    await saveItemChange('deleted_at', articleId, new Date().toISOString(), true);
                    setSaveStatus('Artikel verwijderd', 'success');
                    setTimeout(() => {
                        window.location.href = '/';
                    }, 1000);
                } catch (error) {
                    setSaveStatus('Fout bij verwijderen', 'error');
                }
            }
        });
    }

});
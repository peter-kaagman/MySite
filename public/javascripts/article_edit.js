// LEGACY SimpleMDE setup (niet meer in gebruik)
// import { initEditors } from './modules/editor.js';
// Zorg dat alle benodigde modules klassiek geladen zijn via <script> tags in de layout
// import { registerFieldHandlers } from './modules/fields.js'; // refactoring out
// import { fieldDefinitions } from './modules/fieldDefinitions.js'; // refactoring out


document.addEventListener('DOMContentLoaded', function() {

    window.addEventListener("beforeunload", function (e) {
        if (window.unsavedChanges) {
            e.preventDefault();
            e.returnValue = ""; // Required for Chrome
        }
    });
    // Initialize UI synchronization (listens to article-field-saved events)
    if (typeof window.initUISync === 'function') window.initUISync();


    // Title manager
    if (typeof window.TitleManager === 'function') {
        const titleManager = new window.TitleManager();
        titleManager.init();
    }

    // Category manager
    if (typeof window.SearchCombo === 'function') {
        const categoryManager = new window.SearchCombo();
        categoryManager.init();
        categoryManager.init('article_id','category', 'Categorie:', false);
    }

    // Keyword manager
    if (typeof window.SearchCombo === 'function') {
        const keywordManager = new window.SearchCombo();
        keywordManager.init('article_id', 'keywords', 'Keywords:', true);
    }

    // Meta_title manager
    if (typeof window.SimpleFieldManager === 'function') {
        const metaTitleManager = new window.SimpleFieldManager();
        metaTitleManager.init('article_id', 'edit_meta_title', 'meta_title');
    }

    // Meta_description manager
    if (typeof window.SimpleFieldManager === 'function') {
        const metaDescriptionManager = new window.SimpleFieldManager();
        metaDescriptionManager.init('article_id', 'edit_meta_description', 'meta_description');
    }


    // --- ToastEditor integratie ---
    // Initialiseer ToastEditor voor content
    const initialContent = document.getElementById('content_editor_hidden')?.value || '';
    const contentEditor = new window.ToastEditor({
        containerId: 'content_editor',
        fieldName: 'content',
        initialValue: initialContent,
        onChange: () => { window.unsavedChanges = true; }
    });
    // Initialiseer ToastEditor voor abstract
    const initialAbstract = document.getElementById('abstract_editor_hidden')?.value || '';
    const abstractEditor = new window.ToastEditor({
        containerId: 'abstract_editor',
        fieldName: 'abstract',
        initialValue: initialAbstract,
        onChange: () => { window.unsavedChanges = true; }
    });
    window.editors = window.editors || {};
    window.editors.content = contentEditor;
    window.editors.abstract = abstractEditor;

    // Save button voor content
    const saveBtn = document.getElementById('save-content');
    if (saveBtn && contentEditor) {
        saveBtn.addEventListener('click', async () => {
            const articleId = document.getElementById('article_id').value;
            const data = { value: contentEditor.getValue() };
            try {
                await import('./modules/api.js').then(({ handleSave }) => handleSave(articleId, data, 'content', 'toast_editor'));
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Content saved', 'success');
                }
                window.unsavedChanges = false;
            } catch (err) {
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Error saving content', 'error');
                }
            }
        });
    }

    // Cancel button voor content
    const cancelBtn = document.getElementById('cancel-content');
    if (cancelBtn && contentEditor) {
        cancelBtn.addEventListener('click', () => {
            if (confirm('Wijzigingen ongedaan maken?')) {
                contentEditor.setValue(initialContent);
                window.unsavedChanges = false;
            }
        });
    }

    // Save button voor abstract
    const saveAbstractBtn = document.getElementById('save-abstract');
    if (saveAbstractBtn && abstractEditor) {
        saveAbstractBtn.addEventListener('click', async () => {
            const articleId = document.getElementById('article_id').value;
            const data = { value: abstractEditor.getValue() };
            try {
                await import('./modules/api.js').then(({ handleSave }) => handleSave(articleId, data, 'abstract', 'toast_editor'));
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Abstract saved', 'success');
                }
                window.unsavedChanges = false;
            } catch (err) {
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Error saving abstract', 'error');
                }
            }
        });
    }

    // Cancel button voor abstract
    const cancelAbstractBtn = document.getElementById('cancel-abstract');
    if (cancelAbstractBtn && abstractEditor) {
        cancelAbstractBtn.addEventListener('click', () => {
            if (confirm('Wijzigingen ongedaan maken?')) {
                abstractEditor.setValue(initialAbstract);
                window.unsavedChanges = false;
            }
        });
    }

});
// editor.js - SimpleMDE setup and tab refresh
import { handleSave } from "./api.js";

export function initEditors() {
    // Initialize the SimpleMDE editor for text areas
    function initEditor(elementId, field) {
        const el = document.getElementById(elementId);
        if (!el) return null;
        return new SimpleMDE({
            element: el,
            spellChecker: false,
            autosave: {
                enabled: false,
                // uniqueId: article_id + '_' + field,
                // delay: 1000
            },
            toolbar: [
                // ...toolbar items...
                "bold", "italic", "heading", "|",
                "quote", "unordered-list", "ordered-list", "|",
                "link", "image", "|",
                "preview", "side-by-side", "fullscreen", "|",
                {
                    name: "save",
                    action: async function(editor) {
                        // Find the save button in the toolbar
                        const toolbar = editor.toolbarElements;
                        const saveBtn = toolbar && toolbar.save;
                        if (saveBtn) {
                            saveBtn.disabled = true;
                        }
                        const data = { value: editor.value() };
                        try {
                            await handleSave(data, field);
                            if (typeof window.setSaveStatus === 'function') {
                                window.setSaveStatus('Changes saved successfully', 'success');
                            }
                        } catch (err) {
                            console.error(`Error saving ${field}:`, err);
                            if (typeof window.setSaveStatus === 'function') {
                                window.setSaveStatus(`Error saving changes: ${err}`, 'error');
                            }
                        } finally {
                            if (saveBtn) {
                                saveBtn.disabled = false;
                            }
                        }
                    },
                    className: "fa fa-save",
                    title: "Save changes"
                },
                // ...cancel...
                {
                    name: "cancel",
                    action: function(abstracteditor) {
                        console.log("Cancel button clicked");
                        // Reload the page to discard changes
                        window.location.reload();
                    },
                    className: "fa fa-times",
                    title: "Cancel changes"
                }
            ]
        });
    }

    const abstractmde = initEditor("abstract_editor", "abstract");
    const contentmde = initEditor("content_editor", "content");

    // Add event listeners for tab changes to refresh the editor
    // Helper to combine tab refresh and change tracking
    function setupEditorEvents(editor, tabId) {
        document.getElementById(tabId).addEventListener('shown.bs.tab', function () {
            editor.codemirror.refresh();
        });
        editor.codemirror.on("change", () => { 
            window.unsavedChanges = true; 
            if (typeof window.setSaveStatus === 'function') {
                window.setSaveStatus('Unsaved changes in ' + editor.options.element.id, 'info');
            }
        });
    }

    setupEditorEvents(abstractmde, "tab-abstract");
    setupEditorEvents(contentmde, "tab-content");

    return { abstractmde, contentmde };

}

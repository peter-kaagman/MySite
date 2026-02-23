// editor.js - SimpleMDE setup and tab refresh

// handleSave wordt verwacht op window (globaal)


function initEditors() {
    function initEditor(elementId, field) {
        const el = document.getElementById(elementId);
        if (!el) return null;
        // Debugging: check welke globale Toast UI Editor-namen beschikbaar zijn
        console.log('window.toastui:', window.toastui);
        console.log('window.toastui && window.toastui.Editor:', window.toastui && window.toastui.Editor);
        console.log('window.Editor:', window.Editor);
        console.log('window.toastuiEditor:', window.toastuiEditor);
        // Detecteer de juiste globale Editor-constructor
        let EditorCtor = null;
        if (window.toastui && window.toastui.Editor) {
            EditorCtor = window.toastui.Editor;
            console.log('Toast UI Editor gevonden als window.toastui.Editor');
        } else if (window.Editor) {
            EditorCtor = window.Editor;
            console.log('Toast UI Editor gevonden als window.Editor');
        } else if (window.toastuiEditor) {
            EditorCtor = window.toastuiEditor;
            console.log('Toast UI Editor gevonden als window.toastuiEditor');
        }
        if (!EditorCtor) {
            console.error('Toast UI Editor library is not loaded or global constructor not found.');
            return null;
        }
        const editor = new EditorCtor({
            el,
            height: '400px',
            initialEditType: 'markdown', // of 'wysiwyg'
            previewStyle: 'vertical',
            toolbarItems: [
                'heading', 'bold', 'italic', 'strike', 'divider',
                'hr', 'quote', 'divider',
                'ul', 'ol', 'task', 'indent', 'outdent', 'divider',
                'table', 'image', 'link', 'divider',
                'code', 'codeblock'
            ]
        });

        // Save button (custom)
        const saveBtn = document.createElement('button');
        saveBtn.textContent = 'Save';
        saveBtn.className = 'toastui-editor-save-btn';
        saveBtn.onclick = async () => {
            const articleIdInput = document.getElementById('article_id');
            const articleId = articleIdInput ? articleIdInput.value : null;
            saveBtn.disabled = true;
            const data = { value: editor.getMarkdown() };
            try {
                if (typeof window.handleSave === 'function') {
                    await window.handleSave(articleId, data, field, elementId);
                } else if (typeof handleSave === 'function') {
                    await handleSave(articleId, data, field, elementId);
                } else {
                    throw new Error('handleSave is not defined');
                }
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus('Changes saved successfully', 'success');
                }
            } catch (err) {
                if (typeof window.setSaveStatus === 'function') {
                    window.setSaveStatus(`Error saving changes: ${err}`, 'error');
                }
            } finally {
                saveBtn.disabled = false;
            }
        };
        el.parentNode.appendChild(saveBtn);

        // Cancel button (custom)
        const cancelBtn = document.createElement('button');
        cancelBtn.textContent = 'Cancel';
        cancelBtn.className = 'toastui-editor-cancel-btn';
        cancelBtn.onclick = () => window.location.reload();
        el.parentNode.appendChild(cancelBtn);

        return editor;
    }

    const abstractEditor = initEditor("abstract_editor", "abstract");
    const contentEditor = initEditor("content_editor", "content");

    function setupEditorEvents(editor, tabId) {
        const tab = document.getElementById(tabId);
        if (!tab || !editor) return;
        tab.addEventListener('shown.bs.tab', function () {
            editor.refresh();
        });
        editor.on('change', () => {
            window.unsavedChanges = true;
            if (typeof window.setSaveStatus === 'function') {
                window.setSaveStatus('Unsaved changes', 'info');
            }
        });
    }

    setupEditorEvents(abstractEditor, "tab-abstract");
    setupEditorEvents(contentEditor, "tab-content");

    return { abstractEditor, contentEditor };
}

// Zet initEditors op window zodat het overal beschikbaar is
window.initEditors = initEditors;

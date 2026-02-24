// toastWrapper.js - Wrapper voor Toast UI Editor
// Vergelijkbare methodiek als SimpleFieldManager

import { handleSave } from './api.js';
import { setSaveStatus } from './utils.js';

export class ToastWrapper {
    constructor() {
        this.editors = {};
    }

    /**
     * Initialiseer een ToastEditor voor een veld
     * @param {string} containerId - ID van de div
     * @param {string} fieldName - veldnaam (content, abstract, etc.)
     * @param {string} hiddenTextareaId - ID van de hidden textarea (optioneel)
     * @param {string} articleId - artikel ID
     */
    initEditor(containerId, fieldName, hiddenTextareaId, articleId) {
        if (!window.ToastEditor) {
            console.error('ToastEditor is niet geladen');
            return null;
        }
        let initialValue = '';
        if (hiddenTextareaId) {
            const el = document.getElementById(hiddenTextareaId);
            if (el) {
                initialValue = el.value || el.textContent || '';
            }
        }
        const editor = new window.ToastEditor({
            containerId,
            fieldName,
            initialValue,
            onChange: () => { window.unsavedChanges = true; }
        });
        this.editors[fieldName] = editor;
        this.articleId = articleId;
        return editor;
    }

    /**
     * Handler voor save-knop
     * @param {string} fieldName - veldnaam (content, abstract)
     * @param {string} buttonId - ID van de save button
     */
    bindSave(fieldName, buttonId) {
        const saveBtn = document.getElementById(buttonId);
        const editor = this.editors[fieldName];
        if (saveBtn && editor) {
            saveBtn.addEventListener('click', async () => {
                const data = { value: editor.getValue() };
                try {
                    await handleSave(this.articleId, data, fieldName, 'toast_editor');
                    setSaveStatus(`${fieldName} saved`, 'success');
                    window.unsavedChanges = false;
                } catch (err) {
                    setSaveStatus(`Error saving ${fieldName}`, 'error');
                }
            });
        }
    }

    /**
     * Handler voor cancel-knop
     * @param {string} fieldName - veldnaam (content, abstract)
     * @param {string} buttonId - ID van de cancel button
     * @param {string} initialValue - initiële waarde om te herstellen
     */
    bindCancel(fieldName, buttonId, initialValue) {
        const cancelBtn = document.getElementById(buttonId);
        const editor = this.editors[fieldName];
        if (cancelBtn && editor) {
            cancelBtn.addEventListener('click', () => {
                if (confirm('Wijzigingen ongedaan maken?')) {
                    editor.setValue(initialValue);
                    window.unsavedChanges = false;
                }
            });
        }
    }
}

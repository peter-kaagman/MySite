
/**
 * toast_editor.js - Herbruikbare Toast UI Editor module
 *
 * Gebruik:
 *   // Vereist: Toast UI Editor JS/CSS via CDN of lokaal geladen vóór deze module.
 *   // Maak een nieuwe editor aan voor een div:
 *   const editor = new window.ToastEditor({
 *     containerId: 'content_editor', // id van de div
 *     fieldName: 'content',          // veldnaam (voor evt. save)
 *     initialValue: '...',           // (optioneel) initiële waarde
 *     onChange: (val) => { ... },    // (optioneel) callback bij wijziging
 *     onSave: (val) => { ... }       // (optioneel) callback bij opslaan
 *   });
 *
 * API:
 *   - getValue():   Haal huidige markdown op
 *   - setValue(v):  Zet de waarde van de editor
 *   - destroy():    Vernietig de editor instance
 *
 * Zie ProjectDoc/ToDO_Toast.md voor checklist en afspraken.
 */

class ToastEditor {
    constructor({ containerId, fieldName, initialValue = '', onChange = null, onSave = null }) {
        this.containerId = containerId;
        this.fieldName = fieldName;
        this.onChange = onChange;
        this.onSave = onSave;
        this.editor = null;
        this._init(initialValue);
    }

    _init(initialValue) {
        const el = document.getElementById(this.containerId);
        if (!el) {
            console.error(`ToastEditor: container #${this.containerId} not found.`);
            return;
        }
        // Controleer of Toast UI Editor geladen is
        const EditorCtor = (window.toastui && window.toastui.Editor)
            || window.Editor
            || window.toastuiEditor;
        if (!EditorCtor) {
            console.error('Toast UI Editor library is not loaded or global constructor not found.');
            return;
        }
        this.editor = new EditorCtor({
            el,
            height: '400px',
            initialEditType: 'markdown',
            previewStyle: 'tab',
            initialValue: initialValue || ''
        });
        // Event: onChange
        if (typeof this.onChange === 'function') {
            this.editor.on('change', () => {
                this.onChange(this.getValue());
            });
        }
    }

    getValue() {
        return this.editor ? this.editor.getMarkdown() : '';
    }

    setValue(value) {
        if (this.editor) {
            this.editor.setMarkdown(value || '');
        }
    }

    focus() {
        if (this.editor) {
            this.editor.focus();
        }
    }

    destroy() {
        if (this.editor) {
            this.editor.destroy();
            this.editor = null;
        }
    }
}

// Globaal beschikbaar maken (klassiek gebruik)
window.ToastEditor = ToastEditor;

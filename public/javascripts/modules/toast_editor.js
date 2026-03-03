
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
            initialValue: initialValue || '',
            hooks: {
                addImageBlobHook: async (blob, callback) => {
                    // Ophalen van restricties via JSON endpoint
                    let config;
                    try {
                        const resp = await fetch('/api/upload-image-config');
                        config = await resp.json();
                    } catch (e) {
                        alert('Kan uploadrestricties niet ophalen.');
                        return;
                    }
                    const maxSize = config.max_size || 2 * 1024 * 1024;
                    const allowedExtArr = config.allowed_ext || ['.jpg','.jpeg','.png','.gif','.webp'];
                    const allowedMimeArr = config.allowed_mime || ['image/jpeg','image/png','image/gif','image/webp'];
                    // Regex voor extensies
                    const allowedExt = new RegExp('(' + allowedExtArr.map(e => e.replace('.', '\\.')).join('|') + ')$', 'i');
                    // Regex voor mime
                    const allowedMime = new RegExp('^(' + allowedMimeArr.map(m => m.replace('/', '\\/')).join('|') + ')$', 'i');
                    const name = blob.name || 'upload.png';
                    const ext = name.match(/\.[^.]+$/) ? name.match(/\.[^.]+$/)[0] : '';
                    if (!allowedExt.test(ext)) {
                        alert('Ongeldig bestandstype. Alleen ' + allowedExtArr.join(', ') + ' toegestaan.');
                        return;
                    }
                    if (!allowedMime.test(blob.type)) {
                        alert('Ongeldig mime-type. Alleen ' + allowedMimeArr.join(', ') + ' toegestaan.');
                        return;
                    }
                    if (blob.size > maxSize) {
                        alert('Bestand te groot (max ' + Math.round(maxSize/1024/1024) + 'MB).');
                        return;
                    }
                    const formData = new FormData();
                    formData.append('image', blob, name);
                    try {
                        const response = await fetch('/api/upload-image', {
                            method: 'POST',
                            body: formData,
                            credentials: 'same-origin'
                        });
                        const result = await response.json();
                        if (result.success && result.url) {
                            callback(result.url, name);
                            // Reset file input (indirect, want Toast UI beheert deze intern)
                            // Focus de editor na upload
                            setTimeout(() => { this.focus && this.focus(); }, 100);
                        } else {
                            alert('Upload mislukt: ' + (result.error || 'Onbekende fout'));
                        }
                    } catch (err) {
                        alert('Upload error: ' + err);
                    }
                }
            }
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
if (typeof window !== 'undefined') window.ToastEditor = ToastEditor;

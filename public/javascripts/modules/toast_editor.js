
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
        this._busy = false;
        this._init(initialValue);
    }

    _init(initialValue) {
        const el = document.getElementById(this.containerId);
        if (!el) {
            console.error(`ToastEditor: container #${this.containerId} not found.`);
            return;
        }
        // Overlay element voor visuele feedback
        this._overlay = document.createElement('div');
        this._overlay.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;background:rgba(255,255,255,0.7);z-index:10;display:none;align-items:center;justify-content:center;font-size:2em;';
        this._overlay.innerHTML = '<span class="toast-upload-spinner" style="display:inline-block;width:2em;height:2em;border:4px solid #ccc;border-top:4px solid #333;border-radius:50%;animation:spin 1s linear infinite;"></span> Uploaden...';
        el.style.position = 'relative';
        el.appendChild(this._overlay);
        // Spinner animatie toevoegen
        if (!document.getElementById('toast-upload-spinner-style')) {
            const style = document.createElement('style');
            style.id = 'toast-upload-spinner-style';
            style.innerHTML = '@keyframes spin{0%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}';
            document.head.appendChild(style);
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
                    if (this._busy) {
                        alert('Er is al een upload bezig. Wacht tot deze klaar is.');
                        return;
                    }
                    this._busy = true;
                    this._overlay.style.display = 'flex';
                    // Ophalen van restricties via JSON endpoint
                    let config;
                    try {
                        const resp = await fetch('/api/upload-image-config');
                        config = await resp.json();
                    } catch (e) {
                        alert('Kan uploadrestricties niet ophalen.');
                        this._busy = false;
                        this._overlay.style.display = 'none';
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
                        this._busy = false;
                        this._overlay.style.display = 'none';
                        return;
                    }
                    if (!allowedMime.test(blob.type)) {
                        alert('Ongeldig mime-type. Alleen ' + allowedMimeArr.join(', ') + ' toegestaan.');
                        this._busy = false;
                        this._overlay.style.display = 'none';
                        return;
                    }
                    if (blob.size > maxSize) {
                        alert('Bestand te groot (max ' + Math.round(maxSize/1024/1024) + 'MB).');
                        this._busy = false;
                        this._overlay.style.display = 'none';
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
                            // Zoek JSON-bestand bij image
                            const jsonUrl = result.url.replace(/\.[^.]+$/, '.json');
                            try {
                                const metaResp = await fetch(jsonUrl);
                                if (metaResp.ok) {
                                    const meta = await metaResp.json();
                                    // Toon keuzedialoog
                                    const options = meta.formats.map(f => ({
                                        label: `${f.type} (${f.width}x${f.height})`,
                                        value: f.path
                                    }));
                                    let keuze = null;
                                    if (window.ToastEditor && typeof window.ToastEditor._showImageChoiceDialog === 'function') {
                                        keuze = await window.ToastEditor._showImageChoiceDialog(options);
                                    } else {
                                        // Fallback: prompt
                                        const labels = options.map((o,i) => `${i+1}: ${o.label}`).join('\n');
                                        const idx = prompt('Kies formaat voor invoegen:\n' + labels, '1');
                                        const i = parseInt(idx,10)-1;
                                        keuze = (i>=0 && i<options.length) ? options[i].value : options[0].value;
                                    }
                                    callback(keuze, name);
                                } else {
                                    // Geen JSON, val terug op origineel
                                    callback(result.url, name);
                                }
                            } catch (e) {
                                callback(result.url, name);
                            }
                            setTimeout(() => { this.focus && this.focus(); }, 100);
                        } else {
                            alert('Upload mislukt: ' + (result.error || 'Onbekende fout'));
                        }
                    // Optioneel: fancy keuzedialoog (kan later uitgebreid worden)
                    window.ToastEditor = window.ToastEditor || {};
                    window.ToastEditor._showImageChoiceDialog = async function(options) {
                        return new Promise(resolve => {
                            // Simpele modale dialog
                            const dlg = document.createElement('div');
                            dlg.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(0,0,0,0.4);z-index:9999;display:flex;align-items:center;justify-content:center;';
                            const inner = document.createElement('div');
                            inner.style.cssText = 'background:#fff;padding:2em;border-radius:8px;box-shadow:0 2px 16px #0003;min-width:300px;';
                            inner.innerHTML = '<h3>Kies afbeeldingsformaat</h3>';
                            options.forEach(opt => {
                                const btn = document.createElement('button');
                                btn.textContent = opt.label;
                                btn.style = 'display:block;width:100%;margin:0.5em 0;padding:0.5em;font-size:1em;';
                                btn.onclick = () => {
                                    document.body.removeChild(dlg);
                                    resolve(opt.value);
                                };
                                inner.appendChild(btn);
                            });
                            dlg.appendChild(inner);
                            document.body.appendChild(dlg);
                        });
                    };
                    } catch (err) {
                        alert('Upload error: ' + err);
                    }
                    this._busy = false;
                    this._overlay.style.display = 'none';
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

import { setSaveStatus } from './utils.js';
import { handleSave } from './api.js';

// Local slugify helper (client-side, mirrors backend slugify)
function localSlugify(text) {
    if (!text) return 'artikel';
    return text
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '')
        || 'artikel';
}

export class TitleManager {
    addFieldListener(input, eventType, field, getValue, callback) {
        input.addEventListener(eventType, async () => {
            const value = getValue();
            
            // Only save if article exists (edit mode)
            if (this.articleId) {
                const result = await TitleManager.handleChange(this.articleId, value, field);
                if (callback) {
                    callback(result, value);
                }
            } else {
                // Create mode: just update local state, no API call
                if (callback) {
                    callback({ success: true }, value);
                }
            }
        });
    }
    constructor() {
        // Safe retrieval of article_id (may not exist in create mode)
        const articleIdEl = document.getElementById('article_id');
        this.articleId = articleIdEl?.value || null;
        
        // Title
        this.titleInput = document.getElementById('edit_title');
        this.initialTitle = this.titleInput?.value || '';
        
        // Slugtitle
        this.slugtitleInput = document.getElementById('edit_slugtitle');
        this.initialSlugtitle = this.slugtitleInput ? (this.slugtitleInput.checked ? '1' : '0') : '0';
        
        // Slug
        this.slugInput = document.getElementById('edit_slug');
        this.initialSlug = this.slugInput?.value || '';
    }
    // ...existing code...
    async init() {
        // Early return if required elements are missing
        if (!this.titleInput || !this.slugtitleInput || !this.slugInput) {
            console.warn('TitleManager: Required form elements not found');
            return;
        }
        // Set the initial readonly state of slug
        if (this.initialSlugtitle === '1') {
            this.slugInput.setAttribute("readonly", "readonly");
        } else {
            this.slugInput.removeAttribute("readonly");  
        }
        // Helper to update readonly state
        const updateSlugReadonly = () => {
            if (this.slugtitleInput.checked) {
                this.slugInput.setAttribute("readonly", "readonly");
            } else {
                this.slugInput.removeAttribute("readonly");
            }
        };
        // Generic event listeners using addFieldListener
        // slugtitleInput change listener
        this.addFieldListener(
            this.slugtitleInput,
            "change",
            "slugtitle",
            () => this.slugtitleInput.checked ? '1' : '0',
            (result, value) => {
                // Als van onwaar naar waar: slug = title
                if (value === '1' && this.initialSlugtitle === '0') {
                    if (this.titleInput && this.slugInput) {
                        this.slugInput.value = this.titleInput.value.trim();
                        // Trigger blur event om direct op te slaan
                        this.slugInput.dispatchEvent(new Event('blur'));
                    }
                }
                updateSlugReadonly();
                if (result.success) {
                    setSaveStatus('SlugTitle succesvol opgeslagen.', 'success');
                    this.initialSlugtitle = value;
                } else {
                    setSaveStatus('Fout bij opslaan van SlugTitle.', 'error');
                    this.slugtitleInput.checked = this.initialSlugtitle === '1';
                    updateSlugReadonly();
                }
            }
        );
        // titleInput blur listener
        this.addFieldListener(
            this.titleInput,
            "blur",
            "title",
            () => this.titleInput.value.trim(),
            (result, newTitle) => {
                // Create mode: no articleId, just sync slug locally
                if (!this.articleId) {
                    this.initialTitle = newTitle;
                    if (this.slugtitleInput && this.slugtitleInput.checked && this.slugInput) {
                        this.slugInput.value = localSlugify(newTitle);
                    }
                    return;
                }
                // Edit mode (API result available)
                if (result.success) {
                    setSaveStatus('Titel succesvol opgeslagen.', 'success');
                    this.initialTitle = newTitle;
                    if (this.slugtitleInput && this.slugtitleInput.checked && result.data && result.data.slug) {
                        this.slugInput.value = result.data.slug;
                    }
                } else {
                    setSaveStatus('Fout bij opslaan van titel.', 'error');
                }
            }
        );
        // slugInput blur listener
        this.addFieldListener(
            this.slugInput,
            "blur",
            "slug",
            () => this.slugInput.value.trim(),
            (result, newSlug) => {
                // Create mode: only local update
                if (!this.articleId) {
                    this.initialSlug = newSlug;
                    this.slugInput.value = localSlugify(newSlug);
                    return;
                }
                if (result.success) {
                    setSaveStatus('Slug succesvol opgeslagen.', 'success');
                    this.initialSlug = newSlug;
                } else {
                    setSaveStatus('Fout bij opslaan van slug.', 'error');
                }
            }
        );
    }
    static async handleChange(article, newValue, field) {
        try {
            const result = await handleSave(article, {value: newValue}, field, 'edit_slug');
            if (result && result.success) {
                return { success: true, data: result };
            } else {
                console.error('API error:', result && result.error);
                return { success: false, error: result && result.error };
            }
        } catch (err) {
            console.error('Network error:', err);
            return { success: false, error: err.message };
        }
    }
}
// Zorg dat de class beschikbaar is op window voor legacy code
window.TitleManager = TitleManager;
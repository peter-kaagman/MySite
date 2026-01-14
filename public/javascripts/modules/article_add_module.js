// article_add.js - Modular JS for adding an article
import { setSaveStatus } from './utils.js';
// import { addArticle } from './api.js';
import { KeywordManager } from './keywords.js';


export class ArticleAddManager {
    constructor() {
        this.articleId = document.getElementById('article_id').value;
        this.form = document.getElementById('add-article-form');
        this.titleInput = document.getElementById('title');
        this.slugtitleInput = document.getElementById('slugtitle');
        this.slugInput = document.getElementById('slug');
        this.saveDiv = document.getElementById('save-status');
        this.form.addEventListener('submit', (e) => this.handleSubmit(e));
        const keywordManager = new KeywordManager();
        keywordManager.init();    }

    async handleSubmit(e) {
        e.preventDefault();
        const title = this.titleInput.value.trim();
        const content = this.editor.value().trim();
        if (!title || !content) {
            setSaveStatus('Titel en inhoud zijn verplicht.', 'error', this.statusDiv);
            return;
        }
        try {
            const result = await addArticle({ title, content });
            if (result.success) {
                setSaveStatus('Artikel succesvol toegevoegd!', 'success', this.statusDiv);
                // Optioneel: redirect of formulier reset
            } else {
                setSaveStatus(result.error || 'Fout bij toevoegen.', 'error', this.statusDiv);
            }
        } catch (err) {
            setSaveStatus('Netwerkfout.', 'error', this.statusDiv);
        }
    }
}

// Initialisatie (bijvoorbeeld in main.js of direct in de template)
// document.addEventListener('DOMContentLoaded', () => new ArticleAddManager());

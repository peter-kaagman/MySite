import { setSaveStatus } from './modules/utils.js';
import { TitleManager } from './modules/title_slug.js';
import { SearchCombo } from './modules/searchcombo.js';

document.addEventListener('DOMContentLoaded', async () => {
    const form = document.getElementById('add-article-form');
    const cancelButton = document.getElementById('cancel_button');

    if (!form) return;

    // Initialize TitleManager (auto-detects create mode - no article_id element)
    const titleManager = new TitleManager();
    await titleManager.init();

    // Initialize Category SearchCombo (auto-detects create mode)
    const categoryManager = new SearchCombo();
    await categoryManager.init(null, 'category', 'Categorie:', false);

    // Initialize Keywords SearchCombo (auto-detects create mode)
    const keywordManager = new SearchCombo();
    await keywordManager.init(null, 'keywords', 'Keywords:', true);

    // Form submission: Create skeleton article
    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        // Validate required fields
        const title = titleManager.titleInput?.value.trim();
        const category = categoryManager.articleItems[0]; // First selected category

        if (!title) {
            setSaveStatus('Titel is verplicht.', 'error');
            return;
        }

        if (!category) {
            setSaveStatus('Categorie is verplicht.', 'error');
            return;
        }

        setSaveStatus('Bezig met aanmaken artikel...', 'info');

        try {
            const payload = {
                title: title,
                slug: titleManager.slugInput?.value.trim() || '',
                slugtitle: titleManager.slugtitleInput?.checked ? 1 : 0,
                categoryid: category, // Category is title string, but API expects ID
                keywords: keywordManager.articleItems, // Array of keyword strings
            };

            const response = await fetch('/article/add', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });

            const data = await response.json().catch(() => ({}));

            if (response.ok && data.success) {
                setSaveStatus('Artikel aangemaakt. Verder bewerken...', 'success');
                // Redirect to edit page with new article ID
                if (data.article_id) {
                    setTimeout(() => {
                        window.location.href = `/article/edit/${data.article_id}`;
                    }, 600);
                } else if (data.url) {
                    setTimeout(() => {
                        window.location.href = data.url;
                    }, 600);
                }
            } else {
                setSaveStatus(data.error || 'Aanmaken mislukt.', 'error');
            }
        } catch (err) {
            setSaveStatus('Netwerkfout: ' + err, 'error');
        }
    });

    if (cancelButton) {
        cancelButton.addEventListener('click', () => {
            window.history.back();
        });
    }
});

import { setSaveStatus } from '/javascripts/modules/utils.js';

function slugify(text) {
    return text
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '')
        .replace(/--+/g, '-')
        || 'artikel';
}

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('add-article-form');
    const titleInput = document.getElementById('title');
    const slugInput = document.getElementById('slug');
    const slugtitleInput = document.getElementById('slugtitle');
    const categorySelect = document.getElementById('categoryid');
    const abstractInput = document.getElementById('abstract');
    const contentInput = document.getElementById('content');
    const cancelButton = document.getElementById('cancel_button');

    if (!form) return;

    const syncSlug = () => {
        if (slugtitleInput.checked) {
            slugInput.value = slugify(titleInput.value.trim());
            slugInput.setAttribute('readonly', 'readonly');
        } else {
            slugInput.removeAttribute('readonly');
        }
    };

    titleInput.addEventListener('input', syncSlug);
    slugtitleInput.addEventListener('change', syncSlug);
    syncSlug();

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            title: titleInput.value.trim(),
            slug: slugInput.value.trim(),
            slugtitle: slugtitleInput.checked ? 1 : 0,
            categoryid: categorySelect.value,
            abstract: abstractInput.value.trim(),
            content: contentInput.value.trim(),
        };

        if (!payload.title || !payload.abstract || !payload.content || !payload.categoryid) {
            setSaveStatus('Titel, abstract, inhoud en categorie zijn verplicht.', 'error');
            return;
        }

        setSaveStatus('Bezig met opslaan...', 'info');
        try {
            const response = await fetch('/article/add', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });

            const data = await response.json().catch(() => ({}));

            if (response.ok && data.success) {
                setSaveStatus('Artikel succesvol aangemaakt.', 'success');
                if (data.url) {
                    setTimeout(() => { window.location.href = data.url; }, 600);
                }
            } else {
                setSaveStatus(data.error || 'Opslaan mislukt.', 'error');
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

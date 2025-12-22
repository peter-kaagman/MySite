// api.js - Centralized API calls
import { setSaveStatus } from './utils.js';

// Function to handle saving data
export async function handleSave(article, data, field) {
    if (!article || !data || !field) {
        console.error("Invalid article, data or field for saving");
        setSaveStatus("Invalid article, data or field for saving", "error");
        throw new Error("Invalid article, data or field for saving");
    }
    setSaveStatus("Saving...", "info");
    try {
        const response = await fetch(`/article/update/${field}/${article}`, {
            method: "POST",
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(data)
        });
        if (response.status === 200) {
            window.unsavedChanges = false;
            setSaveStatus("Changes saved successfully", "success");
            return await response.json();
        } else {
            setSaveStatus(`Error saving changes: ${response.statusText}`, "error");
            throw new Error(response.statusText);
        }
    } catch (err) {
        setSaveStatus("Network error: " + err, "error");
        throw err;
    }
}

export async function searchKeywords(query) {
    try {
        const response = await fetch(`/article/keywords?query=${encodeURIComponent(query)}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();
        return data.vallues || [];
    } catch (error) {
        console.error('Error fetching keywords:', error);
        return [];
    }
}

// Function to handle keyword changes
export async function saveKeywordChange(article_id, keyword, checked) {
    window.unsavedChanges = true;
    setSaveStatus(`Keyword ${keyword} ${checked ? 'added' : 'removed'}`, "info");
    const data = {
        article_id,
        keyword,
        checked
    };
    try {
        const response = await fetch('/article/keyword', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const result = await response.json();
        window.unsavedChanges = false;
        return result;
    } catch (error) {
        setSaveStatus(`Error ${checked ? 'adding' : 'removing'} keyword ${keyword}`, "error");
        console.error('Error sending keyword data:', error);
        throw error;
    }
}

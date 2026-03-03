// api.js - Centralized API calls
import { setSaveStatus, getCsrfToken } from './utils.js';

// Function to handle saving data
export async function handleSave(article, data, field, inputID) {
    if (!article || !data || !field || !inputID) {
        console.error("Invalid article, data or field for saving");
        setSaveStatus("Invalid article, data or field for saving", "error");
        throw new Error("Invalid article, data or field for saving");
    }
    setSaveStatus("Saving...", "info");
    try {
        // SABOTAGE: CSRF-token niet meesturen
        const token = getCsrfToken();
        console.debug('CSRF-token (sabotage test):', token);
        const response = await fetch(`/article/update/${field}/${article}`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
                // 'X-CSRF-Token': token // tijdelijk uitgeschakeld
            },
            body: JSON.stringify(data)
        });
        if (response.status === 200) {
            window.unsavedChanges = false;
            const result = await response.json();
            setSaveStatus("Changes saved successfully", "success");
            
            // Dispatch custom event for UI synchronization
            // Do not do this on delete, there is no visual element to update
            // console.log(`Dispatching article-field-saved event for field: ${field}, article: ${article}`);
            if(field !== 'deleted_at'){
                document.dispatchEvent(new CustomEvent('article-field-saved', {
                    detail: {
                        fieldId: inputID,
                        dbField: field,
                        articleId: article,
                        originalValue: data.value,
                        responseData: result
                    }
                }));
            }
            
            return result;
        } else {
            setSaveStatus(`Error saving changes: ${response.statusText}`, "error");
            throw new Error(response.statusText);
        }
    } catch (err) {
        setSaveStatus("Network error: " + err, "error");
        throw err;
    }
}

// // Get a specific field value
// export async function getField(field, article_id) {
//     try {
//         const response = await fetch(`/article/field/${article_id}/${field}`, {
//             method: 'GET',
//             headers: { 'Accept': 'application/json' }
//         });
//         if (!response.ok) throw new Error('Network response was not ok');
//         const data = await response.json();
//         return data.value || '';
//     } catch (error) {
//         console.error(`Error fetching field ${field}:`, error);
//         return '';
//     }
// }

// Search for keywords or categories
export function searchItems(field,query) {
    if (field === 'keywords') {
        console.log(`Searching keywords for field: ${field}, query: ${query}`);
        return searchKeywords(query);
    } else if (field === 'category') {
        return searchCategories(query);
    }
    return Promise.resolve([]); // Return empty array for unknown fields
}
// Function to search categories
async function searchCategories(query) {
    try {
        console.log("Fetching categories for query:", query);
        const response = await fetch(`/article/categories?query=${encodeURIComponent(query)}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();
        return data.values || [];
    } catch (error) {
        console.error('Error fetching categories:', error);
        return [];
    }
}
// Function to search keywords
async function searchKeywords(query) {
    try {
        const response = await fetch(`/article/keywords?query=${encodeURIComponent(query)}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();
        return data.values || [];
    } catch (error) {
        console.error('Error fetching keywords:', error);
        return [];
    }
}

// Save keyword or category changes
export function saveItemChange(field, article_id, item, checked) {
    if (field === 'category') {
        return saveCategoryChange(article_id, item, checked);
    }else{
        return saveKeywordChange(article_id, item, checked);
    }
}
// Function to handle keyword changes
async function saveKeywordChange(article_id, keyword, checked) {
    console.log('Saving keyword change:', article_id, keyword, checked);
    window.unsavedChanges = true;
    setSaveStatus(`Item ${keyword} ${checked ? 'added' : 'removed'}`, "info");
    const data = {
        article_id,
        keyword,
        checked
    };
    try {
        // SABOTAGE: CSRF-token niet meesturen
        const token = getCsrfToken();
        console.debug('CSRF-token (sabotage test):', token);
        const response = await fetch('/article/keyword', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
                // 'X-CSRF-Token': token // tijdelijk uitgeschakeld
            },
            body: JSON.stringify(data)
        });
        console.log('Keyword change response status:', response.status);
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

// Function to handle category changes (single select)
async function saveCategoryChange(article_id, category, checked) {
    window.unsavedChanges = true;
    setSaveStatus(`Category ${category} ${checked ? 'selected' : 'updated'}`, "info");
    const data = {
        article_id,
        category,
        checked
    };
    try {
        // SABOTAGE: CSRF-token niet meesturen
        const token = getCsrfToken();
        console.debug('CSRF-token (sabotage test):', token);
        const response = await fetch('/article/category', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
                // 'X-CSRF-Token': token // tijdelijk uitgeschakeld
            },
            body: JSON.stringify(data)
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const result = await response.json();
        window.unsavedChanges = false;
        return result;
    } catch (error) {
        setSaveStatus(`Error setting category ${category}`, "error");
        console.error('Error sending category data:', error);
        throw error;
    }
}

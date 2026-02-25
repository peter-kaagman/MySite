/**
 * UI Synchronization Module
 * Automatically updates UI elements based on server responses
 * Listens to 'article-field-saved' events
 */

/**
 * Initialize UI synchronization
 * Call this once on page load to enable automatic UI updates
 */
export function initUISync() {
    document.addEventListener('article-field-saved', (event) => {
        // Log het volledige event object voor debuggen
        console.log('🟢 article-field-saved event ontvangen:', event);
        const { fieldId, dbField, responseData, originalValue } = event.detail;

        console.log('🔄 Syncing UI for field:', dbField, responseData);

        if (!responseData || !responseData.success) {
            console.warn('No success in response, skipping UI sync');
            return;
        }

        // Update the primary field
        if (Object.prototype.hasOwnProperty.call(responseData, dbField)) {
            updateElement(fieldId, responseData[dbField]);
        } else {
            console.warn(`Response did not include expected field '${dbField}', skipping UI update to avoid clearing input`);
        }

        // Handle special cases per field type
        switch(dbField) {
            case 'title':
                // If title update also returns slug, update that too
                if (responseData.slug) {
                    updateElement('edit_slug', responseData.slug);
                    showNotification('Title and slug updated');
                }
                break;

            case 'slug':
                // Show normalized slug value
                updateElement('edit_slug', responseData.slug);
                if (responseData.slug !== originalValue) {
                    showNotification(`Slug normalized to: ${responseData.slug}`);
                }
                break;
                
            case 'content':
                // Update version indicator
                if (responseData.version) {
                    const versionEl = document.getElementById('content-version');
                    if (versionEl) {
                        versionEl.textContent = `Version ${responseData.version}`;
                        versionEl.classList.add('updated');
                        setTimeout(() => versionEl.classList.remove('updated'), 2000);
                    }
                }
                break;
                
            case 'abstract':
                // Abstract update
                updateElement('abstract', responseData.abstract);
                break;
        }
    });
    
    console.log('✅ UI Sync initialized - listening for article-field-saved events');
}

/**
 * Update a DOM element with a new value
 * @param {string} fieldId - The ID of the element to update
 * @param {*} value - The new value
 */
function updateElement(fieldId, value) {
    const element = document.getElementById(fieldId);
    if (!element) {
        console.warn(`Element #${fieldId} not found`);
        return;
    }
    
    const oldValue = element.tagName === 'INPUT' || element.tagName === 'TEXTAREA' ? element.value : element.textContent;
    
    // Skip if value hasn't changed
    if (oldValue === value) {
        return;
    }
    
    // Update based on element type
    if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
        element.value = value || '';
    } else {
        element.textContent = value || '';
    }
    
    // Visual feedback: flash element to show it was updated
    element.classList.add('field-updated');
    setTimeout(() => element.classList.remove('field-updated'), 1000);
    
    console.log(`✏️  Updated #${fieldId}:`, oldValue, '→', value);
}

/**
 * Show a subtle notification to the user
 * @param {string} message - The message to display
 */
function showNotification(message) {
    // Check if notification already exists
    let notification = document.getElementById('sync-notification');
    
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'sync-notification';
        notification.className = 'sync-notification';
        document.body.appendChild(notification);
    }
    
    notification.textContent = message;
    
    // Trigger animation
    notification.classList.remove('show');
    setTimeout(() => notification.classList.add('show'), 10);
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
        notification.classList.remove('show');
    }, 3000);
}

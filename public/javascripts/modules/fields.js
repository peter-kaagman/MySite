// fields.js - Field change handlers and validation
import { setSaveStatus, debounce } from './utils.js';
import { handleSave } from './api.js';





export function registerFieldHandlers(fieldDefinitions) {
    // Register handlers
    fieldDefinitions.forEach(def => {
        if (def.type === "checkbox") {
            handleCheckboxChange(def.id, def.field, def.callback);
        } else if (def.type === "text") {
            handleTextInputChange(def.id, def.field, def.validate, def.callback);
        } else if (def.type === "select") {
            handleSelectChange(def.id, def.field, def.callback);
        }
    });  
}

// Function to handle changes for a checkbox, uses async/await and no misleading Promise
function handleCheckboxChange(checkboxId, field, callback) {
    const checkboxEl = document.getElementById(checkboxId);
    if (!checkboxEl) {
        console.error(`Checkbox element with id '${checkboxId}' not found`);
        return;
    }
    checkboxEl.addEventListener("change", async () => {
        window.unsavedChanges = true; // Set unsaved changes flag
        const data = {
            value: checkboxEl.checked ? '1' : '0'
        };
        console.log(`Checkbox ${field} changed: ${data.value}`);
        try {
            const result = await handleSave(data, field);
            if (typeof callback === "function") {
                callback(result, checkboxEl);
            }
            window.unsavedChanges = false; // Reset unsaved changes flag
            setSaveStatus("SlugTitle changes saved successfully", "success");
        } catch (err) {
            console.error(`Error saving ${field}: ${err}`);
            setSaveStatus(`Error saving ${field}: ${err}`, "error");
        }
    });
}

// Function to handle text input changes, returns a Promise
async function handleTextInputChange(inputId, field, validate, callback) {
    const inputEl = document.getElementById(inputId);
    if (!inputEl) {
        console.error(`Input element with id '${inputId}' not found`);
        throw new Error(`Input element with id '${inputId}' not found`);
    }
    let initialValue = inputEl.value;
    inputEl.addEventListener("blur", async () => {
        if (initialValue === inputEl.value) {
            console.log(`No change detected for ${field}`);
            return; // No change, no save
        }
        console.log(`Change detected for ${field}: ${inputEl.value}`);
        if (typeof validate === "function") {
            const error = validate(inputEl.value);
            if (error) {
                console.error(`Validation error for ${field}: ${error}`);
                setSaveStatus(`Validation error for ${field}: ${error}`, "error");
                // window.alert(`Validation error for ${field}: ${error}`);
                throw new Error(error);
            }
        }
        // Set unsaved changes flag
        window.unsavedChanges = true;
        console.log(`Unsaved changes detected for ${field}`);
        // Prepare data object
        const data = {
            value: inputEl.value
        };
        try {
            const result = await handleSave(data, field);
            if (typeof callback === "function") {
                callback(result, inputEl);
            }
            window.unsavedChanges = false; // Reset unsaved changes flag
            // Update the slug if necessary
            const slugtitleCheckbox = document.getElementById('edit_slugtitle');
            if (slugtitleCheckbox && slugtitleCheckbox.checked && result.slug) {
                const edit_slug = document.getElementById('edit_slug');
                if (edit_slug) {
                    edit_slug.value = result.slug;
                }
            }
            // Log the result and set save status
            console.log(`Saved ${field}: ${JSON.stringify(result)}`);
            setSaveStatus(`Changes saved for ${field}`, "success");
            // Update the initial value after save
            initialValue = inputEl.value;
        } catch (err) {
            console.error(`Error saving ${field}: ${err}`);
            setSaveStatus(`Error saving ${field}: ${err}`, "error");
            // window.alert(`Error saving ${field}: ${err}`);
            throw err;
        }
    });
}

// General function to handle changes for a select element, returns a Promise
function handleSelectChange(selectId, field, callback) {
    const selectEl = document.getElementById(selectId);
    if (!selectEl) {
        console.error(`Select element with id '${selectId}' not found`);
        throw new Error(`Select element with id '${selectId}' not found`);
    }
    selectEl.addEventListener("change", async () => {
        const data = {
            value: selectEl.value
        };
        window.unsavedChanges = true;
        try {
            const result = await handleSave(data, field);
            if (typeof callback === "function") {
                callback(result, selectEl);
            }
            console.log(`Saved ${field}: ${JSON.stringify(result)}`);
            window.unsavedChanges = false; // Reset unsaved changes flag
            setSaveStatus(`Changes saved for ${field}`, "success");
        } catch (err) {
            console.error(`Error saving ${field}: ${err}`);
            setSaveStatus(`Error saving ${field}: ${err}`, "error");
            // window.alert(`Error saving ${field}: ${err}`);
            throw err;
        }
    });
}




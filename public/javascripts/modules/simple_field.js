// simple_field.js - generiek opslaan van simpele tekstvelden via blur of enter
import { setSaveStatus } from './utils.js';
import { handleSave } from './api.js';


export class SimpleFieldManager{  
  // addFieldListener(input, eventType, field, getValue, callback) {
  //   input.addEventListener(eventType, async () => {
  //     const value = getValue();
      
  //     // Only save if article exists (edit mode)
  //     if (this.articleId) {
  //       const result = await SimpleFieldManager.handleChange(this.articleId, value, field);
  //       if (callback) {
  //           callback(result, value);
  //       }
  //     } else {
  //       // Create mode: just update local state, no API call
  //       if (callback) {
  //           callback({ success: true }, value);
  //       }
  //     }
  //   });
  // }
  async handleChange() {
    if (this.isSaving) {
        return;
    }
    const newValue = this.fieldInput.value;
    if (newValue === this.currentValue) {
        return; // No change, do nothing
    }

    if (!this.articleId) {
        console.warn('SimpleFieldManager: No article ID, cannot save field');
        return;
    }

    try {
        this.isSaving = true;
        // Prevent blur-triggered double save while request is in flight
        this.currentValue = newValue;
        await handleSave(this.articleId, { value: newValue }, this.dbField, this.fieldInput?.id);
        setSaveStatus(`${this.dbField} saved`, 'success');
    } catch (err) {
        // Revert optimistic update so user can retry saving
        this.currentValue = this.fieldInput.value;
        setSaveStatus(`Error saving ${this.dbField}`, 'error');
    } finally {
        this.isSaving = false;
    }
  }

  async init(articleId, elementId, dbField) {
    // Bail out if required parameters are missing
    if (!elementId || !dbField) {
        console.warn('SimpleFieldManager: Missing required parameters for init');
        return;
    }

    console.log(`Initializing SimpleFieldManager for ${elementId} (db field: ${dbField}) for article #${articleId}`);

    this.articleId = articleId;
    if (!this.articleId) {
        console.warn('SimpleFieldManager: article_id not found, field will not be saved');
    }

    this.elementId = elementId;
    this.fieldInput = document.getElementById(this.elementId);
    if (!this.fieldInput) {
        console.warn(`SimpleFieldManager: Input element with id ${elementId} not found`);
        return;
    }

    this.dbField = dbField;

    this.currentValue = this.fieldInput.value;
    this.isSaving = false;

    // Add event listeners for blur and enter key
    this.fieldInput.addEventListener('blur', () => this.handleChange());
    this.fieldInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            this.handleChange();
        }
    });

    console.log(`SimpleFieldManager: Article ID: ${this.articleId}, Element ID: ${this.elementId}, DB Field: ${this.dbField}`);

    }
}
// Zorg dat de class beschikbaar is op window voor legacy code
window.SimpleFieldManager = SimpleFieldManager;




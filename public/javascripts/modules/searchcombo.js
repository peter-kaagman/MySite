// keywords.js - Keyword search, add/remove, and UI
import { setSaveStatus } from './utils.js';
import { searchItems, saveItemChange } from './api.js';

export class SearchCombo {
    constructor() {
        this.displayLookup = new Map(); // value -> display label
    }
 
    async init(articleId, field, label, multiSelect) {
        this.field = field;
        this.multiSelect = multiSelect;
        this.label = label;
        // Store articleId directly (no DOM lookup)
        this.articleId = articleId;
        
        // Parse selected items data with error handling
        // const dataElement = document.getElementById(selectedItemDataId);
        const dataElement = document.getElementById(field + '_data');
        let parsedData = null;
        
        try {
            if (dataElement && dataElement.value && dataElement.value.trim()) {
                parsedData = JSON.parse(dataElement.value);
            }
        } catch (e) {
            console.error('Failed to parse selected items data:', e);
        }
        
        // Ensure selectedItemsData is always an array
        if (!parsedData) {
            this.selectedItemsData = [];
        } else if (Array.isArray(parsedData)) {
            this.selectedItemsData = parsedData;
        } else {
            this.selectedItemsData = [parsedData];
        }

        // Build a normalized list of selected item ids (or fall back to title)
        this.articleItems = this.selectedItemsData
            .map(item => item && typeof item === 'object' ? (item.id ?? item.value ?? item.title) : item)
            .filter(Boolean);

        // Seed display lookup from parsed data
        this.selectedItemsData.forEach(item => {
            if (item && typeof item === 'object') {
                const val = item.id ?? item.value;
                const disp = item.title ?? item.value ?? '';
                if (val) this.displayLookup.set(String(val), disp);
            }
        });
        
        this.container = document.getElementById(field + 'Container');

        
        this.setupElements();

        // Luister naar zowel 'input' als 'keyup'
        ['input', 'keyup'].forEach(eventType => {
            this.searchBox.addEventListener(eventType, (e) => this.handleSearchBox(e));
        });
        
        this.selectedItems.addEventListener('click', () => {
            console.log('Selected items input clicked');
            if (this.searchWrapper.style.display === 'none' || this.searchWrapper.style.display === '') {
                console.log('Showing search box');
                this.searchWrapper.style.display = 'block';
                this.searchBox.focus();
            } else {
                console.log('Hiding search box');
                this.searchWrapper.style.display = 'none';
                this.selectedItems.focus();
            }
        });

        // // Fetch current items for the article
        // await this.fetchCurrentItems();

        // Load items, to set up search box
        await this.loadItems();
    }

    // Setup HTML elements
    setupElements() {
        // Create row for label and selectedItems
        const row = document.createElement('div');
        row.className = 'row mb-3';

        // Label column
        const labelCol = document.createElement('div');
        labelCol.className = 'col-sm-2';
        const label = document.createElement('label');
        label.setAttribute('for', 'selected_items');
        label.className = 'form-label';
        label.textContent = this.label;
        labelCol.appendChild(label);
        row.appendChild(labelCol);

        // Input column
        const inputCol = document.createElement('div');
        inputCol.className = 'col-sm-10';
        this.selectedItems = document.createElement('input');
        this.selectedItems.type = 'text';
        this.selectedItems.id = 'selected_items';
        this.selectedItems.value = this.selectedItemsData.map(item => item.title).join(',');
        this.selectedItems.classList.add('form-control', 'mb-2');
        inputCol.appendChild(this.selectedItems);
        row.appendChild(inputCol);
        this.container.appendChild(row);

        // Create wrapper div for searchBox and list
        this.searchWrapper = document.createElement('div');
        this.searchWrapper.style.display = 'none'; // Initially hidden
        this.container.appendChild(this.searchWrapper);

        // Create search box
        this.searchBox = document.createElement('input');
        this.searchBox.type = 'text';
        this.searchBox.classList.add('form-control', 'mb-2');
        this.searchBox.placeholder = 'Search or add items...';
        this.searchWrapper.appendChild(this.searchBox);

        // Create list container
        this.list = document.createElement('div');
        // this.list.id = 'item-list';
        this.searchWrapper.appendChild(this.list);
    }

    // Load items from server
    // This is for the search box
    async loadItems() {
        console.log('Loading items for field:', this.field);
        const items = await searchItems(this.field, '');
        if (this.list) {
            console.log('Loaded items:', items);
            items.forEach(item => {
                const display = item && typeof item === 'object' ? item.title : item;
                const value   = item && typeof item === 'object' ? item.id    : item;
                if (value) this.displayLookup.set(String(value), display);
                const checked = this.articleItems.some(selected => String(selected) === String(value));
                this.addItemToList(display, value, checked);
            });
        }
    }

    // Add a item to the list
    addItemToList(display,value,checked) {
        const div = document.createElement('div');
        div.classList.add('form-check','form-switch');
        const input = document.createElement('input');
        input.classList.add('form-check-input');
        input.type = this.multiSelect ? 'checkbox' : 'radio';
        if (!this.multiSelect) {
            input.name = `${this.field}_choice`; // group radios together
        }
        input.id = value;
        input.value = value;
        input.checked = checked;
        input.addEventListener('change', (event) => {
            window.unsavedChanges = true; // Set unsaved changes flag
            setSaveStatus(`Item ${display} ${event.target.checked ? 'added' : 'removed'}`, "info");
            this.handleItemChange(value ?? display, event.target.checked);
        });
        const label = document.createElement('label')
        label.htmlFor = value;
        label.classList.add('form-check-label');
        label.textContent = display;
        div.appendChild(input);
        div.appendChild(label);
        this.list.appendChild(div);
    }

    //Search item box handler
    async handleSearchBox(e) {
        console.log('Event:', e.type, 'Value:', this.searchBox.value);
        console.log('Event object:', e);
        if (e.type === 'input') {
            const query = this.searchBox.value.trim();
            console.log("Searching keywords for:", query);
            const keywords = await searchItems(this.field, query);
            console.log("Search results:", keywords);
            if (this.list) {
                this.list.innerHTML = '';
                // Zorg dat de class beschikbaar is op window voor legacy code
                window.SearchCombo = SearchCombo;
                keywords.forEach(item => {
                    const display = item && typeof item === 'object' ? item.title : item;
                    const value   = item && typeof item === 'object' ? item.id    : item;
                    if (value) this.displayLookup.set(String(value), display);
                    const checked = this.articleItems.some(selected => String(selected) === String(value));
                    this.addItemToList(display, value, checked);
                });
            }
        } else if (e.type === 'keyup') {
            const query = this.searchBox.value.trim();
            if (e.key === 'Enter' || e.key === 'Tab') {
                console.log("Enter or tab on:", query);
                if (query.length > 3){
                    console.log("Query is longer than 3 characters");
                    const inArray = this.articleItems.some(item => item.toLowerCase() === query.toLowerCase());
                    if (inArray) {
                        console.log("Query is an existing keyword");
                        const inputEl = document.querySelector(`input[value="${query}"]`);
                        if (inputEl) {
                            if (this.multiSelect) {
                                inputEl.checked = !inputEl.checked;
                            } else {
                                inputEl.checked = true;
                            }
                            inputEl.dispatchEvent(new Event('change'));
                        }
                    } else {
                        console.log("Query is a new keyword");
                        setSaveStatus(`${query} added as a new keyword`, "info");
                        // this.articleItems.push(query);
                        if (this.list) {
                            this.addItemToList(query, query, true);
                            this.handleItemChange(query, true);
                        }
                    }
                }else{
                    console.log("Query is 3 characters or shorter");
                    setSaveStatus(`${query} is considered too short to search`, "warning");
                }
            }
        }
    }
    // Handle item change
    async handleItemChange(item, checked) {
        window.unsavedChanges = true; // Set unsaved changes flag
        setSaveStatus(`Item ${item} ${checked ? 'adding' : 'removing'}...`, "info");
        
        // Only save to server if article exists (edit mode)
        if (!this.articleId) {
            // Create mode: just update UI immediately
            if (checked) {
                if (this.multiSelect) {
                    this.articleItems.push(item);
                    this.rebuildListWithSelection(null);
                } else {
                    this.articleItems = [item];
                    this.rebuildListWithSelection(item);
                }
            } else {
                if (this.multiSelect) {
                    this.articleItems = this.articleItems.filter(i => String(i) !== String(item));
                    this.rebuildListWithSelection(null);
                } else {
                    this.articleItems = [];
                }
            }
            // Render selected items
            this.selectedItems.value = this.articleItems
                .map(val => this.displayLookup.get(String(val)) || val)
                .join(',');
            
            setSaveStatus(`Item ${item} ${checked ? 'selected' : 'deselected'} (will save on create)`, "success");
            window.unsavedChanges = false;
            return;
        }
        
        // Edit mode: save to server first, then update UI
        const itemToSend = this.displayLookup.get(String(item)) || item;
        try {
            const result = await saveItemChange(this.field, this.articleId, itemToSend, checked);
            
            // Only update UI after successful save
            if (checked) {
                if (this.multiSelect) {
                    this.articleItems.push(item);
                    this.rebuildListWithSelection(null);
                } else {
                    this.articleItems = [item];
                    this.rebuildListWithSelection(item);
                }
            } else {
                if (this.multiSelect) {
                    this.articleItems = this.articleItems.filter(i => String(i) !== String(item));
                    this.rebuildListWithSelection(null);
                } else {
                    this.articleItems = [];
                }
            }
            // Render selected items
            this.selectedItems.value = this.articleItems
                .map(val => this.displayLookup.get(String(val)) || val)
                .join(',');
            
            setSaveStatus(`Item ${itemToSend} ${checked ? 'added' : 'removed'} successfully`, "success");
            window.unsavedChanges = false;
        } catch (error) {
            setSaveStatus(`Error ${checked ? 'adding' : 'removing'} item ${itemToSend}`, "error");
            console.error('Error sending item data:', error);
        }
    }
        // Add more methods as needed    

    // For single-select: uncheck all other inputs when a new one is chosen
    uncheckOtherInputs(selectedItem) {
        if (this.multiSelect || !this.list) return;
        const inputs = this.list.querySelectorAll('input');
        inputs.forEach(input => {
            if (input.value !== selectedItem) {
                input.checked = false;
            }
        });
    }

    // For single/multi-select: rebuild the list to properly update Bootstrap styling
    rebuildListWithSelection(selectedItem) {
        if (!this.list) return;
        // Get all current items from the list
        const items = [];
        this.list.querySelectorAll('input').forEach(input => {
            items.push({
                value: input.value,
                display: input.nextElementSibling?.textContent || input.value,
                checked: this.multiSelect 
                    ? this.articleItems.some(sel => String(sel) === String(input.value))
                    : String(input.value) === String(selectedItem)
            });
        });
        
        // Rebuild the list with correct checked states
        this.list.innerHTML = '';
        items.forEach(item => {
            this.addItemToList(item.display, item.value, item.checked);
        });
    }}
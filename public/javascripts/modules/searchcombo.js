// keywords.js - Keyword search, add/remove, and UI
import { setSaveStatus } from './utils.js';
import { searchItems, saveItemChange } from './api.js';

export class SearchCombo {
    constructor() {
    }

    async init(article_id, field, label, multiSelect) {
        this.field = field;
        this.multiSelect = multiSelect;
        this.label = label;
        // Reading hidden fields
        this.articleId = document.getElementById(article_id).value;
        
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

        // Build a normalized list of selected item strings for checkbox state
        this.articleItems = this.selectedItemsData
            .map(item => item && typeof item === 'object' ? item.title ?? item.value ?? '' : item)
            .filter(Boolean);
        
        this.container = document.getElementById(field + 'Container');

        
        this.setupElements();

        // Luister naar zowel 'input' als 'keyup'
        ['input', 'keyup'].forEach(eventType => {
            this.searchBox.addEventListener(eventType, (e) => this.handleSearchBox(e));
        });
        
        this.selectedItems.addEventListener('click', () => {
            if (this.searchWrapper.style.display === 'none' || this.searchWrapper.style.display === '') {
                this.searchWrapper.style.display = 'block';
                this.searchBox.focus();
            } else {
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
                const checked = this.articleItems.some(selected => selected.toLowerCase() === item.toLowerCase());
                this.addItemToList(item,checked);
            });
        }
    }

    // Add a item to the list
    addItemToList(item,checked) {
        const div = document.createElement('div');
        div.classList.add('form-check','form-switch');
        const input = document.createElement('input');
        input.classList.add('form-check-input');
        input.type = this.multiSelect ? 'checkbox' : 'radio';
        if (!this.multiSelect) {
            input.name = `${this.field}_choice`; // group radios together
        }
        input.id = item;
        input.value = item;
        input.checked = checked;
        input.addEventListener('change', (event) => {
            window.unsavedChanges = true; // Set unsaved changes flag
            setSaveStatus(`Item ${item} ${event.target.checked ? 'added' : 'removed'}`, "info");
            this.handleItemChange(item, event.target.checked);
        });
        const label = document.createElement('label')
        label.htmlFor = item;
        label.classList.add('form-check-label');
        label.textContent = item;
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
                keywords.forEach(keyword => {
                    const checked = this.articleItems.some(selected => selected.toLowerCase() === keyword.toLowerCase());
                    this.addItemToList(keyword,checked);
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
                            this.addItemToList(query, true);
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
        setSaveStatus(`Item ${item} ${checked ? 'added' : 'removed'}`, "info");
        try {
            const result = await saveItemChange(this.field, this.articleId, item, checked);
            if (checked) {
                if (this.multiSelect) {
                    this.articleItems.push(item); // Add item to the list
                } else {
                    this.articleItems = [item]; // Single selection
                    this.uncheckOtherInputs(item);
                }
                setSaveStatus(`Item ${item} added successfully`, "success");
            } else {
                if (this.multiSelect) {
                    this.articleItems = this.articleItems.filter(i => i !== item); // Remove item from the list
                } else {
                    this.articleItems = [];
                }
                setSaveStatus(`Item ${item} removed successfully`, "success");
            }
            this.selectedItems.value = this.articleItems.join(',');
            window.unsavedChanges = false; // Reset unsaved changes flag
        } catch (error) {
            setSaveStatus(`Error ${checked ? 'adding' : 'removing'} item ${item}`, "error");
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
}

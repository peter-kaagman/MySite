// keywords.js - Keyword search, add/remove, and UI
import { setSaveStatus } from './utils.js';
import { searchItems, saveItemChange } from './api.js';

export class SearchCombo {
    constructor() {
    }

    async init(article_id,field, label, containerId, multiSelect) {
        this.field = field;
        this.multiSelect = multiSelect;
        this.label = label;
        this.articleId = document.getElementById(article_id).value;
        this.container = document.getElementById(containerId);
        // Initialize articleKeywords array
        this.articleItems = [];
        this.setupElements();

        // Luister naar zowel 'input' als 'keyup'
        ['input', 'keyup'].forEach(eventType => {
            this.searchBox.addEventListener(eventType, (e) => this.handleSearchBox(e));
        });
        
        this.selectedItems.addEventListener('click', () => {
            console.log('Selected items clicked');
            console.log('Current display style:', this.searchWrapper.style.display);
            if (this.searchWrapper.style.display === 'none' || this.searchWrapper.style.display === '') {
                this.searchWrapper.style.display = 'block';
                this.searchBox.focus();
            } else {
                console.log('Hiding search wrapper');
                this.searchWrapper.style.display = 'none';
                this.selectedItems.focus();
            }
        });

        // Fetch current items for the article
        await this.fetchCurrentItems();

        // Load items, set up search box
        console.log('Loading items for field:', this.field);
        await this.loadItems();
    }

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
        this.selectedItems.value = '';
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

        // // Initialize articleKeywords array
        // this.articleKeywords = [];
    }

    // Load keywords from server
    async loadItems() {
        console.log('Loading items for field:', this.field);
        const items = await searchItems(this.field, '');
        if (this.list) {
            items.forEach(item => {
                this.addItemToList(item,this.articleItems.includes(item));
            });
        }
    }

    // Add a item to the list
    addItemToList(item,checked) {
        const div = document.createElement('div');
        div.classList.add('form-check','form-switch');
        const input = document.createElement('input');
        input.classList.add('form-check-input');
        input.type = 'checkbox';
        input.id = item;
        input.checked = checked; //this.articleItems.includes(item);
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

    //Search keyword
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
                    this.addKeywordToList(keyword,this.articleKeywords.includes(keyword));
                });
            }
        } else if (e.type === 'keyup') {
            const query = this.searchBox.value.trim();
            if (e.key === 'Enter' || e.key === 'Tab') {
                console.log("Enter or tab on:", query);
                if (query.length > 3){
                    console.log("Query is longer than 3 characters");
                    const inArray = this.articleKeywords.some(item => item.toLowerCase() === query.toLowerCase());
                    if (inArray) {
                        console.log("Query is an existing keyword");
                        const checkbox = document.querySelector(`input[type="checkbox"][value="${query}"]`);
                        if (checkbox) {
                            checkbox.checked = !checkbox.checked;
                        }
                    } else {
                        console.log("Query is a new keyword");
                        setSaveStatus(`${query} added as a new keyword`, "info");
                        // this.articleKeywords.push(query);
                        if (this.list) {
                            this.addKeywordToList(query, true);
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
                this.articleItems.push(item); // Add item to the list
                setSaveStatus(`Item ${item} added successfully`, "success");
            } else {
                this.articleItems = this.articleItems.filter(i => i !== item); // Remove item from the list
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
}

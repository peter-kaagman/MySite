// keywords.js - Keyword search, add/remove, and UI
import { setSaveStatus } from './utils.js';
import { searchKeywords, saveKeywordChange } from './api.js';

export class searchCombo {
    constructor() {
    }

    async init(field, listId, searchId, selectedId, multiSelect) {
        this.multiSelect = multiSelect;
        this.articleId = document.getElementById(field).value;
        this.list = document.getElementById(listId);
        this.searchBox = document.getElementById(searchId);
        this.selectedKeywords = document.getElementById(selectedId);
        this.articleKeywords = this.selectedKeywords.value.split(',').map(kw => kw.trim()).filter(kw => kw !== "" );
        // Luister naar zowel 'input' als 'keyup'
        ['input', 'keyup'].forEach(eventType => {
            this.searchBox.addEventListener(eventType, (e) => this.handleSearchBox(e));
        });
        // Load keywords, set up search box, register listeners
        await this.loadKeywords();
    }

    async loadKeywords() {
        const keywords = await searchKeywords('');
        if (this.list) {
            keywords.forEach(keyword => {
                this.addKeywordToList(keyword,this.articleKeywords.includes(keyword));
            });
        }
    }

    // Add a keyword to the list
    addKeywordToList(keyword,checked) {
        const div = document.createElement('div');
        div.classList.add('form-check','form-switch');
        const input = document.createElement('input');
        input.classList.add('form-check-input');
        input.type = 'checkbox';
        input.id = keyword;
        input.checked = checked; //this.articleKeywords.includes(keyword);
        input.addEventListener('change', (event) => {
            window.unsavedChanges = true; // Set unsaved changes flag
            setSaveStatus(`Keyword ${keyword} ${event.target.checked ? 'added' : 'removed'}`, "info");
            this.handleKeywordChange(keyword, event.target.checked);
        });
        const label = document.createElement('label')
        label.htmlFor = keyword;
        label.classList.add('form-check-label');
        label.textContent = keyword;
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
            const keywords = await searchKeywords(query);
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
                            this.handleKeywordChange(query, true);
                        }
                    }
                }else{
                    console.log("Query is 3 characters or shorter");
                    setSaveStatus(`${query} is considered too short to search`, "warning");
                }
            }
        }
    }
    // Handle keyword change
    async handleKeywordChange(keyword, checked) {
        window.unsavedChanges = true; // Set unsaved changes flag
        setSaveStatus(`Keyword ${keyword} ${checked ? 'added' : 'removed'}`, "info");
        try {
            const result = await saveKeywordChange(this.articleId, keyword, checked);
            if (checked) {
                this.articleKeywords.push(keyword); // Add keyword to the list
                setSaveStatus(`Keyword ${keyword} added successfully`, "success");
            } else {
                this.articleKeywords = this.articleKeywords.filter(kw => kw !== keyword); // Remove keyword from the list
                setSaveStatus(`Keyword ${keyword} removed successfully`, "success");
            }
            this.selectedKeywords.value = this.articleKeywords.join(',');
            window.unsavedChanges = false; // Reset unsaved changes flag
        } catch (error) {
            setSaveStatus(`Error ${checked ? 'adding' : 'removing'} keyword ${keyword}`, "error");
            console.error('Error sending keyword data:', error);
        }
    }
        // Add more methods as needed    
}

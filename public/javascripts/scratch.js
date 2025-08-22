document.addEventListener("DOMContentLoaded", function() {



    // Handle keyword change
    function handleKeywordChange(keyword, checked) {
        console.log(`Keyword ${keyword} is now ${checked ? 'checked' : 'unchecked'}`);
        unsavedChanges = true; // Set unsaved changes flag
        setSaveStatus(`Keyword ${keyword} ${checked ? 'added' : 'removed'}`, "info");
        const data = {
            article_id: article_id,
            keyword: keyword,
            checked: checked
        };
        // Send the data to the server or process it as needed
        fetch('/article/keyword', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        })
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        })
        .then(result => {
            // Handle the server response
            if(checked) {
                articleKeywords.push(keyword); // Add keyword to the list
                setSaveStatus(`Keyword ${keyword} added successfully`, "success");
            } else {
                articleKeywords = articleKeywords.filter(kw => kw !== keyword); // Remove keyword from the list
                setSaveStatus(`Keyword ${keyword} removed successfully`, "success");
            }
            // Update the selected keywords input
            document.getElementById('selected_keywords').value = articleKeywords.join(','); 
            unsavedChanges = false; // Reset unsaved changes flag
            console.log(`Server response for ${keyword}:`, result);
        })
        .catch(error => {
            setSaveStatus(`Error ${checked ? 'adding' : 'removing'} keyword ${keyword}`, "error");
            console.error('Error sending keyword data:', error);
        });
    }

    // Add a keyword to the list
    function addKeywordToList(list, keyword) {
        const div = document.createElement('div');
        div.classList.add('form-check','form-switch');
        const input = document.createElement('input');
        input.classList.add('form-check-input');
        input.type = 'checkbox';
        input.id = keyword;
        input.checked = articleKeywords.includes(keyword);
        input.addEventListener('change', (event) => {
            console.log(`Checkbox ${keyword} is now ${event.target.checked ? 'checked' : 'unchecked'}`);
            unsavedChanges = true; // Set unsaved changes flag
            setSaveStatus(`Keyword ${keyword} ${event.target.checked ? 'added' : 'removed'}`, "info");
            handleKeywordChange(keyword, event.target.checked);
        });
        const label = document.createElement('label')
        label.htmlFor = keyword;
        label.classList.add('form-check-label');
        label.textContent = keyword;
        div.appendChild(input);
        div.appendChild(label);
        list.appendChild(div);
    }
    
    //Search keyword
    function searchKeywords(query) {
        return fetch(`/article/keywords?query=${encodeURIComponent(query)}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        })
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        }).then(data => {
            return data.vallues || []; // Return an empty array if no keywords found
        }).catch(error => { 
            console.error('Error fetching keywords:', error);
        });
    }

    let articleKeywords = document.getElementById('selected_keywords').value.split(',').map(kw => kw.trim()).filter(kw => kw !== "" );
    console.log("Article keywords:", articleKeywords);
    // const allKeywords = searchKeywords('');
    // allKeywords.then(keywords => {
    searchKeywords('').then(keywords => {
        console.log("All keywords loaded:", keywords);
        const list = document.getElementById('list_keywords');
        if (list) {
            keywords.forEach(keyword => {
                addKeywordToList(list, keyword);
            });
        }

    });

    const searchBox = document.getElementById('search_keywords');
    function handleSearchBox(e) {
        console.log('Event:', e.type, 'Value:', searchBox.value);
        console.log('Event object:', e);
        if (e.type === 'input') {
            // Handle input event
            const query = searchBox.value.trim();
            console.log("Searching keywords for:", query);
            searchKeywords(query).then(keywords => {
                console.log("Search results:", keywords);
                const list = document.getElementById('list_keywords');
                if (list) {
                    list.innerHTML = ''; // Clear the list
                    keywords.forEach(keyword => {
                        addKeywordToList(list, keyword);
                    });
                }
            });
        } else if (e.type === 'keyup') {
            // Handle keyup event enter or tab
            const query = searchBox.value.trim();
            if (e.key === 'Enter' || e.key === 'Tab') {
                console.log("Enter or tab on:", query);
                if (query.length > 3){
                    console.log("Query is longer than 3 characters");
                    const inArray = articleKeywords.some(item => item.toLowerCase() === query.toLowerCase());
                    if (inArray) {
                        console.log("Query is an existing keyword");
                        // Toggle the checkbox value
                        const checkbox = document.querySelector(`input[type="checkbox"][value="${query}"]`);
                        if (checkbox) {
                            checkbox.checked = !checkbox.checked;
                        }
                    } else {
                        console.log("Query is a new keyword");
                        setSaveStatus(`${query} added as a new keyword`, "info");
                        // Add new keyword to the list
                        articleKeywords.push(query);
                        const list = document.getElementById('list_keywords');
                        if (list) {
                            addKeywordToList(list, query);
                            handleKeywordChange(query, true); // Call the function to handle keyword change
                        }
                    }
                }else{
                    console.log("Query is 3 characters or shorter");
                }
            }
        }
    }

    // Luister naar zowel 'input' als 'keyup'
    ['input', 'keyup'].forEach(eventType => {
    searchBox.addEventListener(eventType, handleSearchBox);
    });

    
});
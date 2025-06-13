document.addEventListener("DOMContentLoaded", function() {

    const article_id = document.getElementById('article_id').value;
    // Initialize Quill editor
    const quill = new Quill('#article_editor', {
        theme: 'snow'
    });
    let dirty = false
    quill.on('text-change', (delta,oDelta,source) =>{
        dirty = true;
    });
    
    const edit_title = document.getElementById('edit_title');
    const initialTitle = edit_title.value;
    edit_title.addEventListener("blur", ()=>{
        console.log(`Org title ${initialTitle}`);
        console.log(`value in eventhandler: ${edit_title.value}`);
        if (initialTitle.localeCompare(edit_title.value) != 0){
            console.log("changed");
            const data = {
                value: edit_title.value
            }
            console.log(JSON.stringify(data));
            fetch(`/article/update/title/${article_id}`, {
                method: "POST",
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(data)
            })
            .then(res => {
                // console.log("Request completed, respone: ", res);
                if (res.status == 200){
                    initialTitle = edit_title.value;
                }else{
                   window.alert(`HTTP status: ${res.status}, ${res.statusText} `); 
                }
            });
        }else{
            console.log("upate not required");
        }
    });
    
    document.getElementById('cancel').addEventListener("mouseup", ()=>{
        console.log("Cancel mouse up");
        this.location.reload();
    });

    document.getElementById('save').addEventListener("mouseup", ()=>{
        console.log("Save mouse up");
        // const newContents = quill.getContents();
        // const hasChanged = _.isEqual(initialContents.ops, newContents.ops);
        // console.log(hasChanged);
        if(dirty){
            // Need an article id
            console.log(`update required # ${article_id}`);

            const data = {content: quill.getSemanticHTML()};
            console.log(JSON.stringify(data))
            fetch(`/article/update/${article_id}`, {
                method: "POST",
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(data)
            })
            .then(res => {
                // console.log("Request completed, respone: ", res);
                if (res.status == 200){
                    dirty = false
                }else{
                   window.alert(`HTTP status: ${res.status}, ${res.statusText} `); 
                }
            });
        }else{
            console.log("upate not required");
        }
    });



});
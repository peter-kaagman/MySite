document.addEventListener("DOMContentLoaded", function() {

    // Initialize Quill editor
    const quill = new Quill('#article_editor', {
        theme: 'snow'
    });
    let dirty = false
    quill.on('text-change', (delta,oDelta,source) =>{
        dirty = true;
    });
    // const initialContents = quill.getContents();

    const cancel = document.getElementById('cancel');
    cancel.addEventListener("mouseup", (event)=>{
        console.log("Cancel mouse up");
        this.location.reload();
    });

    const save = document.getElementById('save');
    save.addEventListener("mouseup", (event)=>{
        console.log("Save mouse up");
        // const newContents = quill.getContents();
        // const hasChanged = _.isEqual(initialContents.ops, newContents.ops);
        // console.log(hasChanged);
        if(dirty){
            // Need an article id
            const article_id = document.getElementById('article_id').value;
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
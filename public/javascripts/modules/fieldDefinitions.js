// fieldDefinitions.js - Example field definitions


export const fieldDefinitions = [
    {
        type: "checkbox",
        id: "edit_slugtitle",
        field: "slugtitle",
        callback: (result, el) => {
            // This code runs every time the checkbox changes and save completes
            const edit_slug = document.getElementById('edit_slug');
            if (edit_slug) {
                edit_slug.readOnly = result.slugtitle === '1';
            }
        }
    },
    {
        type: "text",
        id: "edit_title",
        field: "title",
        validate: (value) => {
            if (value.trim() === "") {
                return "Title cannot be empty";
            }
            return null; // Valid value
        },
        callback: (result, el) => {
            if (result.slug) {
                const edit_slug = document.getElementById('edit_slug');
                const slugtitleCheckbox = document.getElementById('edit_slugtitle');
                if (edit_slug && slugtitleCheckbox && slugtitleCheckbox.checked) {
                    edit_slug.value = result.slug;
                }
            }
            document.title = el.value;
        }
    },
    {
        type: "text",
        id: "edit_slug",
        field: "slug",
        validate: (value) => {
            if (value.trim() === "") {
                return "Slug cannot be empty";
            }
            return null; // Valid value
        }
    },
    {
        type: "select",
        id: "edit_category",
        field: "categoryid",
    }
    // Add more field definitions as needed
];

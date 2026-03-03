// utils.js - Utility functions

// Haal CSRF-token uit meta-tag
export function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
}
export function setSaveStatus(msg, type = 'info') {
    const status = document.getElementById('save-status');
    if (!status) return;
    status.style.display = 'block';
    status.textContent = msg;
    status.className = type;
    if (type === 'success') {
        setTimeout(() => { status.style.display = 'none'; }, 1500);
        console.log(msg);
    } else if (type === 'error') {
        console.error(msg);
    } else {
        console.info(msg);
    }
}

// Debounce utility: delays function execution until after wait ms have elapsed since last call
export function debounce(fn, wait) {
    let timer;
    return function(...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), wait);
    };
}

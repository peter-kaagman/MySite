// codeblock_tools.js - Highlight.js en copy-knop voor codeblokken (Pandoc output)
export function initCodeblockTools() {
  document.querySelectorAll('div.sourceCode pre, pre.sourceCode').forEach(function (block) {
    if (window.hljs) {
      window.hljs.highlightElement(block);
    }
    // Copy-knop toevoegen
    if (!block.parentElement.querySelector('.copy-btn')) {
      const button = document.createElement('button');
      button.innerText = 'Copy';
      button.className = 'copy-btn';
      button.style = 'position:absolute;top:8px;right:8px;z-index:10;';
      button.onclick = function () {
        const code = block.querySelector('code') ? block.querySelector('code').innerText : block.innerText;
        navigator.clipboard.writeText(code);
        button.innerText = 'Copied!';
        setTimeout(() => button.innerText = 'Copy', 1500);
      };
      block.parentElement.style.position = 'relative';
      block.parentElement.appendChild(button);
    }
  });
}

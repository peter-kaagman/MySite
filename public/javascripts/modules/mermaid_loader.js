// mermaid_loader.js - Zet <pre class="mermaid">...</pre> om naar SVG met mermaid.js

// Zorg dat mermaid geladen is (via CDN in layout)
export function initMermaidBlocks() {
  if (typeof mermaid === 'undefined') return;
  const blocks = document.querySelectorAll('pre.mermaid');
  blocks.forEach((block, idx) => {
    const code = block.textContent;
    const id = 'mermaid-auto-' + idx + '-' + Date.now();
    // Maak een tijdelijke div voor de SVG
    const temp = document.createElement('div');
    temp.className = 'mermaid-rendered';
    temp.id = id;
    // Render met mermaid
    mermaid.mermaidAPI.render(id, code, (svgCode) => {
      temp.innerHTML = svgCode;
      block.replaceWith(temp);
    }, block);
  });
}

// content_show.js - Entry point voor content weergave (highlighting & copy)
import { initCodeblockTools } from './modules/codeblock_tools.js';
import { initMermaidBlocks } from './modules/mermaid_loader.js';

document.addEventListener('DOMContentLoaded', () => {
  initCodeblockTools();
  initMermaidBlocks();
});

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run preview` - Preview production build

## Architecture

This is a Vite-based shader playground for experimenting with GLSL shaders.

**Key configuration:**
- Uses `vite-plugin-glsl` to import `.glsl`, `.vert`, `.frag` shader files directly as ES modules
- Entry point: `index.html` → `src/main.js`

**Shader imports:** Import shaders directly in JavaScript:
```js
import fragmentShader from './shaders/fragment.glsl'
import vertexShader from './shaders/vertex.glsl'
```

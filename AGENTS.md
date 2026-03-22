# AGENTS.md

This repo is a Vite-based WebGL (WebGL 1.0 / GLSL ES 1.0) shader playground: a collection of pages, each running one or more fullscreen fragment shaders in the browser.

This file is written for agentic coding tools. Keep changes small, keep pages working, and prefer following existing patterns over introducing new frameworks.

## Quickstart

```bash
npm install
npm run dev
```

- Dev server: Vite prints a local URL (commonly `http://localhost:5173/`).
- Pages are routed by folder entrypoints (see `vite.config.js`). Examples: `/`, `/playground/`, `/whitney/`, `/fluid/`.

## Build / Lint / Test

From repo root:

```bash
npm run dev       # start Vite dev server
npm run build     # production build
npm run preview   # preview production build
npm run lint      # eslint src
```

### Lint a single file

```bash
npx eslint src/shader-page.js
```

### Tests

No test runner is configured in `package.json` (no `test` script).

If you add tests later (e.g. Vitest), also add:

- `npm run test`
- `npm run test -- <pattern>` for a single test file / name

Until then, treat these as the repo's "tests":

- `npm run build`
- manual smoke check: `npm run dev` and load the affected page(s)

## Repo Architecture

### Multi-page Vite app

- `vite.config.js` defines many HTML entrypoints via `build.rollupOptions.input`.
- Each page has a `*/index.html` that loads one JS module from `src/`.

Examples:

- `index.html` -> `src/home.js`
- `playground/index.html` -> `src/main.js`
- `whitney/index.html` -> `src/whitney.js`

### Shader imports

- `vite-plugin-glsl` is enabled so you can import shader sources as strings.

```js
import vertexShader from './shaders/vertex.glsl'
import fragmentShader from './shaders/effects/ripple.glsl'
```

Reference: `CLAUDE.md`.

### Shared runtime helpers

- `src/shader-page.js`: reusable boilerplate for fullscreen shader pages.
  - program creation per effect
  - effect switching (buttons + keyboard)
  - uniform location caching
  - resize handling
  - render loop with `requestAnimationFrame`
  - hooks: `onRender`, `onSwitch`
- `src/webgl.js`: compile/link helpers, fullscreen quad, and minimal matrix math.
- `src/controls.js`: `SliderManager`, `MouseTracker`, `setupRecording()`.
- `src/recorder.js`: MP4 recording using WebCodecs + `mp4-muxer`.

Some pages intentionally bypass `createShaderPage()` and implement custom ping-pong/framebuffer pipelines (e.g. `src/fluid.js`).

## Conventions / Code Style

### JavaScript

- Module system: ESM (`"type": "module"` in `package.json`).
- Formatting (match existing `src/*.js`):
  - 4-space indentation
  - single quotes
  - no semicolons
- Naming:
  - variables: `camelCase`; classes `PascalCase`
  - shader uniforms: `u_<name>`

### Uniform naming and `createShaderPage()`

- `createShaderPage({ uniforms: [...] })` expects *base names* and looks up locations as `u_<name>`.
  - Example: passing `time` maps to `uniform float u_time;` in GLSL.
- `MouseTracker.applyUniform()` sets a `vec2` mouse uniform (canvas-space).
- `SliderManager` defaults to uniform name `u_<sliderName>` unless overridden.

### GLSL (WebGL 1.0 / GLSL ES 1.0)

- Use `precision` qualifiers in fragment shaders (`mediump`/`highp`) as needed.
- Stick to GLSL ES 1.0 syntax:
  - `attribute`/`varying` (not `in`/`out`)
  - `gl_FragColor` (not user-defined outputs)
- Extensions:
  - If a shader uses derivatives (`dFdx/dFdy/fwidth`), request `OES_standard_derivatives` on that page.
  - Float textures require `OES_texture_float` and sometimes `OES_texture_float_linear`.

### CSS / UI

- Controls are plain HTML in each page's `index.html` + page CSS imported from JS.
- Keep UI lightweight; the canvas remains fullscreen.

## Error Handling / Safety

- WebGL context acquisition can fail; pages usually show a message and/or adjust background.
- Shader compile/link failures should log info logs and fail gracefully.
- Recording uses WebCodecs and is optional; avoid crashing the render loop on encoder errors.

## Performance

- Avoid per-frame allocations inside render loops (arrays, textures, buffers).
- Prefer typed-array reuse (`Float32Array`) for uniforms and simulation state.
- Be cautious with high-res ping-pong sims (e.g. 512x512) and multi-steps per frame.

## Adding a New Shader Page (pattern)

1. Create `newpage/index.html` modeled after an existing page.
2. Add a new entry to `vite.config.js` under `rollupOptions.input`.
3. Create `src/newpage.js`:
   - import CSS and shaders
   - call `createShaderPage()` (preferred) unless you truly need a custom pipeline
4. Put shader sources in `src/shaders/<category>/` and import them.

## Repo-Specific Agent Notes

- Author guidance exists in `CLAUDE.md`; treat it as canonical for build/architecture details.
- No Cursor rules found in `.cursor/rules/` and no `.cursorrules`.
- No GitHub Copilot instructions found at `.github/copilot-instructions.md`.

## Before/After Changes

- Before: identify which page(s) you are touching and verify the entrypoint + uniforms.
- After: run `npm run lint`, run `npm run build`, then smoke-check in `npm run dev`.

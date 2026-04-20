import { defineConfig } from 'vite'
import glsl from 'vite-plugin-glsl'
import { resolve, dirname, relative, basename } from 'path'
import { readFileSync } from 'fs'

process.env.VITE_PROJECT_ROOT = process.cwd()

// Vite plugin: serves /__source-tree?entry=/src/tiles.js with the import tree
function sourceTreePlugin() {
  let root

  const SHADER_EXTS = new Set(['glsl', 'vert', 'frag'])
  const CODE_EXTS = new Set(['js', ...SHADER_EXTS])

  function getExt(p) {
    const i = p.lastIndexOf('.')
    return i > 0 ? p.slice(i + 1) : ''
  }

  function buildTree(filePath, visited) {
    if (visited.has(filePath)) return null
    visited.add(filePath)

    const relPath = relative(root, filePath)
    const ext = getExt(filePath)

    if (!CODE_EXTS.has(ext)) return null
    if (relPath === 'src/source-link.js') return null

    let content
    try { content = readFileSync(filePath, 'utf-8') }
    catch { return { path: relPath, name: basename(filePath), children: [] } }

    const children = []
    const dir = dirname(filePath)

    if (ext === 'js') {
      const re = /import\s[\s\S]*?from\s+['"]([^'"]+)['"]/g
      let m
      while ((m = re.exec(content))) {
        if (!m[1].startsWith('.')) continue
        const child = buildTree(resolve(dir, m[1]), visited)
        if (child) children.push(child)
      }
    } else if (SHADER_EXTS.has(ext)) {
      const re = /#(?:include|pragma\s+include)\s+["']([^"']+)["']/g
      let m
      while ((m = re.exec(content))) {
        if (m[1].includes('lygia')) continue
        const resolved = resolve(dir, m[1])
        if (!resolved.startsWith(resolve(root, 'src'))) continue
        const child = buildTree(resolved, visited)
        if (child) children.push(child)
      }
    }

    return { path: relPath, name: basename(filePath), children }
  }

  return {
    name: 'source-tree',
    configResolved(config) { root = config.root },
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url.startsWith('/__source-tree')) return next()
        const url = new URL(req.url, 'http://localhost')
        const entry = url.searchParams.get('entry')
        if (!entry) { res.statusCode = 400; res.end('{}'); return }

        const tree = buildTree(resolve(root, entry.replace(/^\//, '')), new Set())
        res.setHeader('Content-Type', 'application/json')
        res.end(JSON.stringify(tree))
      })
    }
  }
}

export default defineConfig({
  plugins: [glsl({ root: '/node_modules' }), sourceTreePlugin()],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        playground: resolve(__dirname, 'playground/index.html'),
        whitney: resolve(__dirname, 'whitney/index.html'),
        characters: resolve(__dirname, 'characters/index.html'),
        warps: resolve(__dirname, 'warps/index.html'),
        geometries: resolve(__dirname, 'geometries/index.html'),
        glyphs: resolve(__dirname, 'glyphs/index.html'),
        stipple: resolve(__dirname, 'stipple/index.html'),
        exercises: resolve(__dirname, 'exercises/index.html'),
        particles: resolve(__dirname, 'particles/index.html'),
        tiles: resolve(__dirname, 'tiles/index.html'),
        landscape: resolve(__dirname, 'landscape/index.html'),
        displace: resolve(__dirname, 'displace/index.html'),
        audio: resolve(__dirname, 'audio/index.html'),
        'reaction-diffusion': resolve(__dirname, 'reaction-diffusion/index.html'),
        scribble: resolve(__dirname, 'scribble/index.html'),
        fluid: resolve(__dirname, 'fluid/index.html'),
        lic: resolve(__dirname, 'lic/index.html'),
        threejs: resolve(__dirname, 'threejs/index.html'),
        fur: resolve(__dirname, 'fur/index.html'),
        spike: resolve(__dirname, 'spike/index.html'),
        zoom: resolve(__dirname, 'zoom/index.html'),
        palette: resolve(__dirname, 'palette/index.html'),
        kaleidoscope: resolve(__dirname, 'kaleidoscope/index.html'),
        'midi-visual': resolve(__dirname, 'midi-visual/index.html'),
        'learn-index': resolve(__dirname, 'learn/index.html'),
        'learn-pixel': resolve(__dirname, 'learn/pixel/index.html'),
        'learn-time': resolve(__dirname, 'learn/time/index.html'),
        'learn-randomness': resolve(__dirname, 'learn/randomness/index.html'),
        'learn-dimension': resolve(__dirname, 'learn/dimension/index.html'),
        crit: resolve(__dirname, 'crit/index.html'),
        workflow: resolve(__dirname, 'workflow/index.html'),
      },
    },
  },
})

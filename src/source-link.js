// Renders a file dependency tree panel in the bottom-left corner (dev only)

const root = import.meta.env.VITE_PROJECT_ROOT

if (import.meta.env.DEV) {
    const script = document.querySelector('script[type="module"][src^="/src/"]')
    if (script) {
        const srcPath = script.getAttribute('src').split('?')[0]
        fetch(`/__source-tree?entry=${srcPath}`)
            .then(r => r.json())
            .then(tree => { if (tree) renderTree(tree) })
            .catch(() => {})
    }
}

function vsLink(path) {
    return `vscode://file/${root}/${path}`
}

function renderNode(node, prefix, isLast, isRoot) {
    const ext = node.name.split('.').pop()
    const isShader = ['glsl', 'vert', 'frag'].includes(ext)
    const cls = isRoot ? 'root' : (isShader ? 'glsl' : '')
    const href = vsLink(node.path)
    const connector = isRoot ? '' : (isLast ? '└ ' : '├ ')

    let html = `<div class="${cls}"><span class="tc">${prefix}${connector}</span><a href="${href}" title="${node.path}">${node.name}</a></div>`

    const nextPrefix = isRoot ? '' : prefix + (isLast ? '  ' : '│ ')
    node.children.forEach((child, i) => {
        html += renderNode(child, nextPrefix, i === node.children.length - 1, false)
    })
    return html
}

function renderTree(tree) {
    const style = document.createElement('style')
    style.textContent = `
        #source-tree {
            position: fixed;
            bottom: 20px;
            left: 20px;
            padding: 10px 14px;
            background: rgba(0, 0, 0, 0.55);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            backdrop-filter: blur(12px);
            z-index: 100;
            font-family: 'SF Mono', 'Fira Code', 'Fira Mono', 'Menlo', monospace;
            font-size: 11px;
            line-height: 1.7;
            color: rgba(255, 255, 255, 0.4);
            max-height: 40vh;
            overflow-y: auto;
            pointer-events: auto;
        }
        #source-tree a {
            color: inherit;
            text-decoration: none;
            transition: color 0.15s;
        }
        #source-tree a:hover { color: white; }
        #source-tree .root > a {
            color: rgba(255, 255, 255, 0.75);
            font-weight: 500;
        }
        #source-tree .glsl > a { color: rgba(120, 160, 255, 0.55); }
        #source-tree .glsl > a:hover { color: rgba(140, 180, 255, 1); }
        #source-tree .tc {
            white-space: pre;
            user-select: none;
            color: rgba(255, 255, 255, 0.15);
        }
    `
    document.head.appendChild(style)

    const panel = document.createElement('div')
    panel.id = 'source-tree'
    panel.innerHTML = renderNode(tree, '', true, true)
    document.body.appendChild(panel)
}

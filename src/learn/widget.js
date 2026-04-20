import { createProgram, createFullscreenQuad } from '../webgl.js'
import vertexShader from '../shaders/vertex.glsl'

const visibilityObserver = new IntersectionObserver((entries) => {
    for (const entry of entries) {
        const widget = entry.target._widget
        if (widget) widget.visible = entry.isIntersecting
    }
}, { rootMargin: '80px' })

export function mount(selector, config) {
    const el = typeof selector === 'string' ? document.querySelector(selector) : selector
    if (!el) {
        console.warn('Widget target not found:', selector)
        return null
    }
    return new Widget(el, config)
}

class Widget {
    constructor(container, config) {
        this.container = container
        this.config = config
        this.visible = false
        this.values = {}
        this.build()
    }

    build() {
        this.container.classList.add('widget')

        const canvas = document.createElement('canvas')
        canvas.className = 'widget-canvas'
        this.canvas = canvas
        this.container.appendChild(canvas)

        const controls = this.config.controls || []
        if (controls.length) {
            const panel = document.createElement('div')
            panel.className = 'widget-controls'
            for (const c of controls) {
                this.values[c.uniform] = c.default ?? 0
                panel.appendChild(this.buildControl(c))
            }
            this.container.appendChild(panel)
        }

        if (this.config.caption) {
            const cap = document.createElement('figcaption')
            cap.className = 'widget-caption'
            cap.innerHTML = this.config.caption
            this.container.appendChild(cap)
        }

        const gl = canvas.getContext('webgl', { antialias: true, preserveDrawingBuffer: false })
        if (!gl) {
            canvas.replaceWith(Object.assign(document.createElement('div'), {
                className: 'widget-error',
                textContent: 'WebGL not supported in this browser.',
            }))
            return
        }
        this.gl = gl

        const program = createProgram(gl, vertexShader, this.config.shader)
        if (!program) {
            console.warn('Widget shader failed to compile')
            return
        }
        this.program = program
        gl.useProgram(program)
        createFullscreenQuad(gl, program)

        this.uniformLocs = {
            resolution: gl.getUniformLocation(program, 'u_resolution'),
            time: gl.getUniformLocation(program, 'u_time'),
        }
        for (const c of controls) {
            this.uniformLocs[c.uniform] = gl.getUniformLocation(program, c.uniform)
        }

        this.resize()
        this.container._widget = this
        visibilityObserver.observe(this.container)

        this.render(0)
        this.emitChange()

        const resizeObserver = new ResizeObserver(() => this.resize())
        resizeObserver.observe(canvas)

        const loop = (time) => {
            if (this.visible) this.render(time * 0.001)
            requestAnimationFrame(loop)
        }
        requestAnimationFrame(loop)
    }

    buildControl(c) {
        const row = document.createElement('label')
        row.className = 'widget-control'

        const name = document.createElement('span')
        name.className = 'widget-control-label'
        name.textContent = c.label || c.uniform

        const slider = document.createElement('input')
        slider.type = 'range'
        slider.min = c.min ?? 0
        slider.max = c.max ?? 1
        slider.step = c.step ?? 0.01
        slider.value = c.default ?? 0

        const value = document.createElement('span')
        value.className = 'widget-control-value'
        value.textContent = formatValue(slider.value, c)

        slider.addEventListener('input', () => {
            this.values[c.uniform] = parseFloat(slider.value)
            value.textContent = formatValue(slider.value, c)
            this.emitChange()
        })

        row.appendChild(name)
        row.appendChild(slider)
        row.appendChild(value)
        return row
    }

    resize() {
        const { canvas, gl } = this
        if (!gl) return
        const rect = canvas.getBoundingClientRect()
        const dpr = Math.min(window.devicePixelRatio || 1, 2)
        const w = Math.max(1, Math.floor(rect.width * dpr))
        const h = Math.max(1, Math.floor(rect.height * dpr))
        if (canvas.width !== w || canvas.height !== h) {
            canvas.width = w
            canvas.height = h
            gl.viewport(0, 0, w, h)
        }
    }

    emitChange() {
        this.container.dispatchEvent(new CustomEvent('widget:change', {
            detail: { values: { ...this.values } },
        }))
    }

    render(t) {
        const { gl, program, uniformLocs, canvas, config } = this
        if (!gl || !program) return
        gl.useProgram(program)
        if (uniformLocs.resolution) gl.uniform2f(uniformLocs.resolution, canvas.width, canvas.height)
        if (uniformLocs.time) gl.uniform1f(uniformLocs.time, t)
        for (const c of config.controls || []) {
            const loc = uniformLocs[c.uniform]
            if (!loc) continue
            gl.uniform1f(loc, this.values[c.uniform])
        }
        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }
}

function formatValue(v, c) {
    const n = Number(v)
    const step = c.step ?? 0.01
    const digits = step >= 1 ? 0 : step >= 0.1 ? 1 : 2
    return n.toFixed(digits)
}

// Find every <pre data-widget="..."> in the document, highlight GLSL uniforms,
// and attach a live values row that updates as the linked widget changes.
export function bindCode(root = document) {
    const VAR_RE = /\b(u_[A-Za-z_][A-Za-z0-9_]*)\b/g
    const blocks = root.querySelectorAll('pre[data-widget]')

    for (const pre of blocks) {
        const widgetId = pre.dataset.widget
        const container = document.getElementById(widgetId)
        if (!container) continue

        const codeEl = pre.querySelector('code') || pre
        const rawText = codeEl.textContent
        const found = Array.from(rawText.matchAll(VAR_RE), m => m[1])
        const vars = Array.from(new Set(found))

        codeEl.innerHTML = escapeHtml(rawText).replace(
            VAR_RE,
            '<span class="code-var" data-var="$1">$1</span>'
        )

        if (vars.length === 0) continue

        pre.classList.add('has-values')

        const valuesLine = document.createElement('div')
        valuesLine.className = 'code-values'
        pre.insertAdjacentElement('afterend', valuesLine)

        const update = (values) => {
            valuesLine.innerHTML = vars
                .filter(v => v in values)
                .map(v => (
                    `<span class="code-values-entry">` +
                    `<span class="code-var">${v}</span>` +
                    `<span class="code-values-sep">=</span>` +
                    `<span class="code-values-val">${Number(values[v]).toFixed(2)}</span>` +
                    `</span>`
                ))
                .join('')
        }

        container.addEventListener('widget:change', (e) => update(e.detail.values))

        const widget = container._widget
        if (widget && widget.values) update(widget.values)
    }
}

function escapeHtml(s) {
    return s.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]))
}

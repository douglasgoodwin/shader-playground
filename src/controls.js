import { CanvasRecorder } from './recorder.js'

// ===========================================
// SliderManager - Declarative parameter binding
// ===========================================
export class SliderManager {
    constructor(config) {
        // config: { name: { selector, default, uniform?, type? } }
        // type: 'range' (default) or 'checkbox'
        // uniform: optional - if omitted, uses 'u_' + name
        this._config = config
        this._values = {}
        this._elements = {}

        for (const [name, opts] of Object.entries(config)) {
            const el = document.querySelector(opts.selector)
            if (!el) {
                console.warn(`SliderManager: element not found for ${name} (${opts.selector})`)
                continue
            }

            this._elements[name] = el
            const type = opts.type || 'range'

            if (type === 'checkbox') {
                this._values[name] = opts.default ?? false
                el.checked = this._values[name]
                el.addEventListener('change', (e) => {
                    this._values[name] = e.target.checked
                })
            } else {
                this._values[name] = opts.default ?? parseFloat(el.value)
                el.value = this._values[name]
                el.addEventListener('input', (e) => {
                    this._values[name] = parseFloat(e.target.value)
                })
            }
        }
    }

    get params() {
        return { ...this._values }
    }

    get(name) {
        return this._values[name]
    }

    set(name, value) {
        if (!(name in this._values)) return
        this._values[name] = value
        const el = this._elements[name]
        if (el) {
            const type = this._config[name].type || 'range'
            if (type === 'checkbox') {
                el.checked = value
            } else {
                el.value = value
            }
        }
    }

    reset() {
        for (const [name, opts] of Object.entries(this._config)) {
            this.set(name, opts.default)
        }
    }

    applyUniforms(gl, locations) {
        for (const [name, opts] of Object.entries(this._config)) {
            const uniformKey = opts.uniform ?? `u_${name}`
            const loc = locations[uniformKey] ?? locations[name]
            if (!loc) continue

            const type = opts.type || 'range'
            const value = this._values[name]

            if (type === 'checkbox') {
                gl.uniform1f(loc, value ? 1.0 : 0.0)
            } else {
                gl.uniform1f(loc, value)
            }
        }
    }
}

// ===========================================
// setupRecording - One-liner recording setup
// ===========================================
export function setupRecording(canvas, options = {}) {
    const buttonSelector = options.buttonSelector ?? '#record-btn'
    const keyboardShortcut = options.keyboardShortcut ?? 'r'

    const recordBtn = document.querySelector(buttonSelector)
    const recorder = new CanvasRecorder(canvas, {
        onStateChange: (recording) => {
            if (recordBtn) {
                recordBtn.classList.toggle('recording', recording)
            }
        }
    })

    if (recordBtn) {
        recordBtn.addEventListener('click', () => recorder.toggle())
    }

    if (keyboardShortcut !== null) {
        document.addEventListener('keydown', (e) => {
            if (e.key === keyboardShortcut || e.key === keyboardShortcut.toUpperCase()) {
                recorder.toggle()
            }
        })
    }

    return recorder
}

// ===========================================
// MouseTracker - Reusable mouse tracking
// ===========================================
export class MouseTracker {
    constructor(canvas) {
        this._canvas = canvas
        this._x = 0
        this._y = 0

        canvas.addEventListener('mousemove', (e) => {
            this._x = e.clientX
            this._y = canvas.height - e.clientY
        })
    }

    get x() {
        return this._x
    }

    get y() {
        return this._y
    }

    applyUniform(gl, location) {
        if (location) {
            gl.uniform2f(location, this._x, this._y)
        }
    }
}

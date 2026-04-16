// Shared boilerplate for fullscreen shader pages
// Handles: GL setup, program creation, uniform caching, effect switching,
// resize, keyboard shortcuts, button handlers, render loop

import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'

const AUTO_KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'q', 'w']

export function createShaderPage({
    shaders,
    uniforms: uniformNames,
    defaultEffect,
    sliders: sliderConfig,
    keys,
    extensions,
    onRender,
    onSwitch,
}) {
    const canvas = document.querySelector('#canvas')
    const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

    if (!gl) {
        document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
        throw new Error('WebGL not supported')
    }

    if (extensions) extensions.forEach(ext => gl.getExtension(ext))

    // Create programs and uniform locations
    const programs = {}
    const uniforms = {}

    for (const [name, fragmentShader] of Object.entries(shaders)) {
        const program = createProgram(gl, vertexShader, fragmentShader)
        if (program) {
            programs[name] = program
            const u = {}
            for (const uName of uniformNames) {
                u[uName] = gl.getUniformLocation(program, `u_${uName}`)
            }
            uniforms[name] = u
        }
    }

    let current = defaultEffect
    gl.useProgram(programs[current])
    createFullscreenQuad(gl, programs[current])

    const mouse = new MouseTracker(canvas)
    const sliderMgr = sliderConfig ? new SliderManager(sliderConfig) : null
    const recorder = setupRecording(canvas, { keyboardShortcut: null })

    function switchEffect(name) {
        if (!programs[name]) return
        current = name
        gl.useProgram(programs[name])
        createFullscreenQuad(gl, programs[name])

        const u = uniforms[name]
        if (u && u.resolution) {
            gl.uniform2f(u.resolution, canvas.width, canvas.height)
        }

        document.querySelectorAll('#controls button').forEach(btn => {
            const btnName = btn.dataset.effect || btn.dataset.piece
            btn.classList.toggle('active', btnName === name)
        })

        if (onSwitch) onSwitch({ gl, u, name, canvas })
    }

    function resize() {
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        gl.viewport(0, 0, canvas.width, canvas.height)

        const u = uniforms[current]
        if (u && u.resolution) {
            gl.uniform2f(u.resolution, canvas.width, canvas.height)
        }
    }

    // Button click handlers
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation()
            switchEffect(btn.dataset.effect || btn.dataset.piece)
        })
    })

    // Keyboard shortcuts
    const shaderNames = Object.keys(shaders)
    const keyMap = keys || Object.fromEntries(
        shaderNames
            .map((name, i) => i < AUTO_KEYS.length ? [AUTO_KEYS[i], name] : null)
            .filter(Boolean)
    )

    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT') return
        if (keyMap[e.key]) switchEffect(keyMap[e.key])
        if (e.key === 'r' || e.key === 'R') recorder.toggle()
    })

    window.addEventListener('resize', resize)
    resize()

    // Render loop
    function render(time) {
        const t = time * 0.001
        const u = uniforms[current]

        if (u.resolution) gl.uniform2f(u.resolution, canvas.width, canvas.height)
        gl.uniform1f(u.time, t)
        mouse.applyUniform(gl, u.mouse)
        if (sliderMgr) sliderMgr.applyUniforms(gl, u)
        if (onRender) onRender({ gl, u, t, current, sliders: sliderMgr, mouse, canvas })

        gl.drawArrays(gl.TRIANGLES, 0, 6)
        requestAnimationFrame(render)
    }

    requestAnimationFrame(render)

    return {
        gl,
        canvas,
        programs,
        uniforms,
        mouse,
        sliders: sliderMgr,
        recorder,
        switchEffect,
        get current() { return current },
    }
}

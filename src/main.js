import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { FeedbackBuffer } from './feedback.js'
import vertexShader from './shaders/vertex.glsl'
import rippleShader from './shaders/ripple.glsl'
import plasmaShader from './shaders/plasma.glsl'
import warpShader from './shaders/warp.glsl'
import voronoiShader from './shaders/voronoi.glsl'
import truchetShader from './shaders/truchet.glsl'
import hexgridShader from './shaders/hexgrid.glsl'
import tilesShader from './shaders/tiles.glsl'
import cylinderShader from './shaders/cylinder.glsl'
import raymarchShader from './shaders/raymarch.glsl'
import mandelbulbShader from './shaders/mandelbulb.glsl'
import hyperbolicShader from './shaders/hyperbolic.glsl'
import viscousShader from './shaders/viscous.glsl'
import kaleidoscopeShader from './shaders/kaleidoscope.glsl'
import penroseShader from './shaders/penrose.glsl'
import reactionSimShader from './shaders/reaction-sim.glsl'
import reactionDisplayShader from './shaders/reaction-display.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Enable required extensions
gl.getExtension('OES_standard_derivatives')

// Create all shader programs
const shaders = {
    ripple: rippleShader,
    plasma: plasmaShader,
    warp: warpShader,
    voronoi: voronoiShader,
    truchet: truchetShader,
    hexgrid: hexgridShader,
    tiles: tilesShader,
    cylinder: cylinderShader,
    raymarch: raymarchShader,
    mandelbulb: mandelbulbShader,
    hyperbolic: hyperbolicShader,
    viscous: viscousShader,
    kaleidoscope: kaleidoscopeShader,
    penrose: penroseShader,
}

const programs = {}
const uniforms = {}

for (const [name, fragmentShader] of Object.entries(shaders)) {
    const program = createProgram(gl, vertexShader, fragmentShader)
    if (program) {
        programs[name] = program
        uniforms[name] = {
            resolution: gl.getUniformLocation(program, 'u_resolution'),
            time: gl.getUniformLocation(program, 'u_time'),
            mouse: gl.getUniformLocation(program, 'u_mouse'),
            ripples: gl.getUniformLocation(program, 'u_ripples'),
            rippleColors: gl.getUniformLocation(program, 'u_rippleColors'),
            speed: gl.getUniformLocation(program, 'u_speed'),
            intensity: gl.getUniformLocation(program, 'u_intensity'),
            scale: gl.getUniformLocation(program, 'u_scale'),
        }
    }
}

// Reaction-diffusion (feedback-based effect)
const reactionSimProgram = createProgram(gl, vertexShader, reactionSimShader)
const reactionDisplayProgram = createProgram(gl, vertexShader, reactionDisplayShader)

let feedbackBuffer = null
let feedbackEnabled = false

if (reactionSimProgram && reactionDisplayProgram) {
    feedbackBuffer = new FeedbackBuffer(gl)
    feedbackEnabled = feedbackBuffer.supported

    programs['reaction'] = reactionDisplayProgram
    uniforms['reaction'] = {
        resolution: gl.getUniformLocation(reactionDisplayProgram, 'u_resolution'),
        time: gl.getUniformLocation(reactionDisplayProgram, 'u_time'),
        mouse: gl.getUniformLocation(reactionDisplayProgram, 'u_mouse'),
        ripples: gl.getUniformLocation(reactionDisplayProgram, 'u_ripples'),
        rippleColors: gl.getUniformLocation(reactionDisplayProgram, 'u_rippleColors'),
        speed: gl.getUniformLocation(reactionDisplayProgram, 'u_speed'),
        intensity: gl.getUniformLocation(reactionDisplayProgram, 'u_intensity'),
        scale: gl.getUniformLocation(reactionDisplayProgram, 'u_scale'),
        buffer: gl.getUniformLocation(reactionDisplayProgram, 'u_buffer'),
    }

    console.log('Reaction-diffusion shaders compiled, feedback:', feedbackEnabled)
}

const reactionSimUniforms = reactionSimProgram ? {
    resolution: gl.getUniformLocation(reactionSimProgram, 'u_resolution'),
    time: gl.getUniformLocation(reactionSimProgram, 'u_time'),
    buffer: gl.getUniformLocation(reactionSimProgram, 'u_buffer'),
    frame: gl.getUniformLocation(reactionSimProgram, 'u_frame'),
    speed: gl.getUniformLocation(reactionSimProgram, 'u_speed'),
    intensity: gl.getUniformLocation(reactionSimProgram, 'u_intensity'),
    scale: gl.getUniformLocation(reactionSimProgram, 'u_scale'),
    mouse: gl.getUniformLocation(reactionSimProgram, 'u_mouse'),
} : null

let currentEffect = 'ripple'
let currentProgram = programs[currentEffect]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

// Shared state
let mouse = { x: 0, y: 0 }
const MAX_RIPPLES = 10
let ripples = new Float32Array(MAX_RIPPLES * 3)
let rippleColors = new Float32Array(MAX_RIPPLES * 3)
let rippleIndex = 0

// Slider parameters
const params = {
    speed: 1,
    intensity: 1,
    scale: 1,
}

const speedSlider = document.querySelector('#speed')
const intensitySlider = document.querySelector('#intensity')
const scaleSlider = document.querySelector('#scale')

speedSlider.addEventListener('input', (e) => params.speed = parseFloat(e.target.value))
intensitySlider.addEventListener('input', (e) => params.intensity = parseFloat(e.target.value))
scaleSlider.addEventListener('input', (e) => params.scale = parseFloat(e.target.value))

function switchEffect(name) {
    if (!programs[name]) return
    currentEffect = name
    currentProgram = programs[name]

    // Initialize feedback buffer for reaction effect
    if (name === 'reaction' && feedbackBuffer) {
        feedbackBuffer.init(canvas.width, canvas.height)
    }

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    // Update resolution uniform for new program
    const u = uniforms[currentEffect]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    // Update button states
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })
}

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    // Reinitialize feedback buffer on resize
    if (currentEffect === 'reaction' && feedbackBuffer) {
        feedbackBuffer.init(canvas.width, canvas.height)
    }

    const u = uniforms[currentEffect]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }
}

canvas.addEventListener('mousemove', (e) => {
    mouse.x = e.clientX
    mouse.y = canvas.height - e.clientY
})

canvas.addEventListener('click', (e) => {
    const x = e.clientX
    const y = canvas.height - e.clientY
    const idx = rippleIndex * 3
    ripples[idx] = x
    ripples[idx + 1] = y
    ripples[idx + 2] = performance.now() * 0.001
    rippleColors[idx] = 0.5 + Math.random() * 0.5
    rippleColors[idx + 1] = 0.5 + Math.random() * 0.5
    rippleColors[idx + 2] = 0.5 + Math.random() * 0.5
    rippleIndex = (rippleIndex + 1) % MAX_RIPPLES

    // Reset reaction simulation on click
    if (currentEffect === 'reaction' && feedbackBuffer) {
        feedbackBuffer.reset()
    }
})

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchEffect(btn.dataset.effect)
    })
})

const effectKeys = {
    '1': 'ripple', '2': 'plasma', '3': 'warp', '4': 'voronoi',
    '5': 'truchet', '6': 'hexgrid', '7': 'tiles', '8': 'cylinder',
    '9': 'raymarch', '0': 'mandelbulb', 'q': 'hyperbolic',
    'w': 'viscous', 'e': 'kaleidoscope', 'r': 'reaction',
    't': 'penrose'
}

document.addEventListener('keydown', (e) => {
    if (effectKeys[e.key]) {
        switchEffect(effectKeys[e.key])
    }
})

window.addEventListener('resize', resize)
resize()

function renderReaction(time) {
    const t = time * 0.001

    if (!feedbackBuffer || !feedbackBuffer.supported) {
        // Fallback - just show black
        gl.clearColor(0, 0, 0, 1)
        gl.clear(gl.COLOR_BUFFER_BIT)
        return
    }

    // Run multiple simulation steps per frame for faster evolution
    const stepsPerFrame = 8

    for (let step = 0; step < stepsPerFrame; step++) {
        // Render simulation to framebuffer
        gl.bindFramebuffer(gl.FRAMEBUFFER, feedbackBuffer.writeFramebuffer)
        gl.viewport(0, 0, feedbackBuffer.width, feedbackBuffer.height)

        gl.useProgram(reactionSimProgram)
        createFullscreenQuad(gl, reactionSimProgram)

        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, feedbackBuffer.readTexture)

        gl.uniform2f(reactionSimUniforms.resolution, feedbackBuffer.width, feedbackBuffer.height)
        gl.uniform1f(reactionSimUniforms.time, t)
        gl.uniform1i(reactionSimUniforms.buffer, 0)
        gl.uniform1i(reactionSimUniforms.frame, feedbackBuffer.frame)
        gl.uniform1f(reactionSimUniforms.speed, params.speed)
        gl.uniform1f(reactionSimUniforms.intensity, params.intensity)
        gl.uniform1f(reactionSimUniforms.scale, params.scale)
        gl.uniform2f(reactionSimUniforms.mouse, mouse.x, mouse.y)

        gl.drawArrays(gl.TRIANGLES, 0, 6)

        feedbackBuffer.swap()
    }

    // Render display to screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(reactionDisplayProgram)
    createFullscreenQuad(gl, reactionDisplayProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, feedbackBuffer.readTexture)

    const u = uniforms['reaction']
    gl.uniform2f(u.resolution, canvas.width, canvas.height)
    gl.uniform1f(u.time, t)
    gl.uniform1i(u.buffer, 0)
    gl.uniform2f(u.mouse, mouse.x, mouse.y)
    gl.uniform3fv(u.ripples, ripples)
    gl.uniform3fv(u.rippleColors, rippleColors)
    gl.uniform1f(u.speed, params.speed)
    gl.uniform1f(u.intensity, params.intensity)
    gl.uniform1f(u.scale, params.scale)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

function render(time) {
    if (currentEffect === 'reaction') {
        renderReaction(time)
    } else {
        const t = time * 0.001
        const u = uniforms[currentEffect]
        gl.uniform1f(u.time, t)
        gl.uniform2f(u.mouse, mouse.x, mouse.y)
        gl.uniform3fv(u.ripples, ripples)
        gl.uniform3fv(u.rippleColors, rippleColors)
        gl.uniform1f(u.speed, params.speed)
        gl.uniform1f(u.intensity, params.intensity)
        gl.uniform1f(u.scale, params.scale)
        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

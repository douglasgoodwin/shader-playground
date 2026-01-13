import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { CanvasRecorder } from './recorder.js'
import vertexShader from './shaders/vertex.glsl'
import rippleShader from './shaders/ripple.glsl'
import plasmaShader from './shaders/plasma.glsl'
import warpShader from './shaders/warp.glsl'
import voronoiShader from './shaders/voronoi.glsl'
import hexgridShader from './shaders/hexgrid.glsl'
import tilesShader from './shaders/tiles.glsl'
import kaleidoscopeShader from './shaders/kaleidoscope.glsl'
import noiseShader from './shaders/noise.glsl'
import driveShader from './shaders/drive.glsl'
import fireflyShader from './shaders/firefly.glsl'

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
    hexgrid: hexgridShader,
    tiles: tilesShader,
    kaleidoscope: kaleidoscopeShader,
    noise: noiseShader,
    drive: driveShader,
    firefly: fireflyShader,
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
    intensity: 0.7,
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

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = uniforms[currentEffect]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })
}

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

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
})

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchEffect(btn.dataset.effect)
    })
})

const effectKeys = {
    '1': 'ripple', '2': 'plasma', '3': 'warp', '4': 'voronoi',
    '5': 'hexgrid', '6': 'tiles', '7': 'kaleidoscope', '8': 'noise',
    '9': 'drive', '0': 'firefly'
}

document.addEventListener('keydown', (e) => {
    if (effectKeys[e.key]) {
        switchEffect(effectKeys[e.key])
    }
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
})

// Recording
const recordBtn = document.querySelector('#record-btn')
const recorder = new CanvasRecorder(canvas, {
    onStateChange: (recording) => {
        recordBtn.classList.toggle('recording', recording)
    }
})

recordBtn.addEventListener('click', () => recorder.toggle())

window.addEventListener('resize', resize)
resize()

function render(time) {
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
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

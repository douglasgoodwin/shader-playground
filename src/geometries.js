import './geometries.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import gyroidShader from './shaders/geometries/gyroid.glsl'
import penroseShader from './shaders/geometries/penrose.glsl'
import mandelbulbShader from './shaders/geometries/mandelbulb.glsl'
import cylinderShader from './shaders/geometries/cylinder.glsl'
import raymarchShader from './shaders/geometries/raymarch.glsl'
import oscillateShader from './shaders/geometries/oscillate.glsl'
import ropesShader from './shaders/geometries/ropes.glsl'
import trivoronoiShader from './shaders/geometries/trivoronoi.glsl'
import waterrippleShader from './shaders/geometries/waterripple.glsl'
import poolwaterShader from './shaders/geometries/poolwater.glsl'
import flowheartShader from './shaders/geometries/flowheart.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Create shader programs
const shaders = {
    gyroid: gyroidShader,
    penrose: penroseShader,
    mandelbulb: mandelbulbShader,
    cylinder: cylinderShader,
    raymarch: raymarchShader,
    oscillate: oscillateShader,
    ropes: ropesShader,
    trivoronoi: trivoronoiShader,
    waterripple: waterrippleShader,
    poolwater: poolwaterShader,
    flowheart: flowheartShader,
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
            speed: gl.getUniformLocation(program, 'u_speed'),
            // Support both naming conventions
            density: gl.getUniformLocation(program, 'u_density'),
            harmonics: gl.getUniformLocation(program, 'u_harmonics'),
            intensity: gl.getUniformLocation(program, 'u_intensity'),
            scale: gl.getUniformLocation(program, 'u_scale'),
        }
    }
}

let currentPiece = 'gyroid'
let currentProgram = programs[currentPiece]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

// Mouse tracking
const mouse = new MouseTracker(canvas)

// Slider parameters
const sliders = new SliderManager({
    speed:     { selector: '#speed',     default: 0.5 },
    density:   { selector: '#density',   default: 1 },
    harmonics: { selector: '#harmonics', default: 1 },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

function switchPiece(name) {
    if (!programs[name]) return
    currentPiece = name
    currentProgram = programs[name]

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = uniforms[currentPiece]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.piece === name)
    })
}

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    const u = uniforms[currentPiece]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchPiece(btn.dataset.piece)
    })
})

const pieceKeys = {
    '1': 'gyroid',
    '2': 'penrose',
    '3': 'mandelbulb',
    '4': 'cylinder',
    '5': 'raymarch',
    '6': 'oscillate',
    '7': 'ropes',
    '8': 'trivoronoi',
    '9': 'waterripple',
    '0': 'poolwater',
    '-': 'flowheart',
}

document.addEventListener('keydown', (e) => {
    if (pieceKeys[e.key]) {
        switchPiece(pieceKeys[e.key])
    }
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
})

window.addEventListener('resize', resize)
resize()

function render(time) {
    const t = time * 0.001
    const u = uniforms[currentPiece]

    gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)
    sliders.applyUniforms(gl, u)

    // Send both naming conventions - shaders use whichever they need
    const density = sliders.get('density')
    const harmonics = sliders.get('harmonics')
    if (u.intensity) gl.uniform1f(u.intensity, density)   // map density -> intensity
    if (u.scale) gl.uniform1f(u.scale, harmonics)         // map harmonics -> scale

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

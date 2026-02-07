import './whitney.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import lapisShader from './shaders/whitney/lapis.glsl'
import permutationsShader from './shaders/whitney/permutations.glsl'
import matrixShader from './shaders/whitney/matrix.glsl'
import arabesqueShader from './shaders/whitney/arabesque.glsl'
import columnaShader from './shaders/whitney/columna.glsl'
import spiralShader from './shaders/whitney/spiral.glsl'
import musicboxShader from './shaders/whitney/musicbox.glsl'
import trailsShader from './shaders/whitney/trails.glsl'
import fractalShader from './shaders/whitney/fractal.glsl'
import atomShader from './shaders/atom.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Create shader programs
const shaders = {
    lapis: lapisShader,
    permutations: permutationsShader,
    matrix: matrixShader,
    arabesque: arabesqueShader,
    columna: columnaShader,
    spiral: spiralShader,
    musicbox: musicboxShader,
    trails: trailsShader,
    fractal: fractalShader,
    atom: atomShader,
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
            density: gl.getUniformLocation(program, 'u_density'),
            harmonics: gl.getUniformLocation(program, 'u_harmonics'),
        }
    }
}

let currentPiece = 'lapis'
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

    // Update resolution uniform for new program
    const u = uniforms[currentPiece]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    // Update button states
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
    '1': 'lapis',
    '2': 'permutations',
    '3': 'matrix',
    '4': 'arabesque',
    '5': 'columna',
    '6': 'spiral',
    '7': 'musicbox',
    '8': 'trails',
    '9': 'fractal',
    '0': 'atom',
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

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

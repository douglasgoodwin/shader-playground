import './whitney.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import vertexShader from './shaders/vertex.glsl'
import lapisShader from './shaders/whitney/lapis.glsl'
import permutationsShader from './shaders/whitney/permutations.glsl'
import matrixShader from './shaders/whitney/matrix.glsl'
import arabesqueShader from './shaders/whitney/arabesque.glsl'
import columnaShader from './shaders/whitney/columna.glsl'
import spiralShader from './shaders/whitney/spiral.glsl'
import musicboxShader from './shaders/whitney/musicbox.glsl'
import trailsShader from './shaders/whitney/trails.glsl'

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

// State
let mouse = { x: 0, y: 0 }

// Slider parameters
const params = {
    speed: 0.5,
    density: 1,
    harmonics: 1,
}

const speedSlider = document.querySelector('#speed')
const densitySlider = document.querySelector('#density')
const harmonicsSlider = document.querySelector('#harmonics')

speedSlider.addEventListener('input', (e) => params.speed = parseFloat(e.target.value))
densitySlider.addEventListener('input', (e) => params.density = parseFloat(e.target.value))
harmonicsSlider.addEventListener('input', (e) => params.harmonics = parseFloat(e.target.value))

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

canvas.addEventListener('mousemove', (e) => {
    mouse.x = e.clientX
    mouse.y = canvas.height - e.clientY
})

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
}

document.addEventListener('keydown', (e) => {
    if (pieceKeys[e.key]) {
        switchPiece(pieceKeys[e.key])
    }
})

window.addEventListener('resize', resize)
resize()

function render(time) {
    const t = time * 0.001
    const u = uniforms[currentPiece]

    gl.uniform1f(u.time, t)
    gl.uniform2f(u.mouse, mouse.x, mouse.y)
    gl.uniform1f(u.speed, params.speed)
    gl.uniform1f(u.density, params.density)
    gl.uniform1f(u.harmonics, params.harmonics)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

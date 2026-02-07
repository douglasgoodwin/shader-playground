import './landscape.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import lightningShader from './shaders/landscape/lightning.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

const shaders = {
    lightning: lightningShader,
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
            intensity: gl.getUniformLocation(program, 'u_intensity'),
            scale: gl.getUniformLocation(program, 'u_scale'),
            camHeight: gl.getUniformLocation(program, 'u_camHeight'),
        }
    }
}

const speedSlider = document.querySelector('#speed')
const intensitySlider = document.querySelector('#intensity')
const scaleSlider = document.querySelector('#scale')
const camHeightSlider = document.querySelector('#camHeight')

let currentPiece = 'lightning'
let currentProgram = programs[currentPiece]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

const mouse = new MouseTracker(canvas)
const recorder = setupRecording(canvas)

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
    btn.addEventListener('click', () => switchPiece(btn.dataset.piece))
})

const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
const pieces = Object.keys(shaders)

document.addEventListener('keydown', (e) => {
    const idx = keys.indexOf(e.key)
    if (idx !== -1 && idx < pieces.length) {
        switchPiece(pieces[idx])
    }
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

window.addEventListener('resize', resize)
resize()

function render(time) {
    const t = time * 0.001
    const u = uniforms[currentPiece]

    gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)
    if (u.speed) gl.uniform1f(u.speed, parseFloat(speedSlider.value))
    if (u.intensity) gl.uniform1f(u.intensity, parseFloat(intensitySlider.value))
    if (u.scale) gl.uniform1f(u.scale, parseFloat(scaleSlider.value))
    if (u.camHeight) gl.uniform1f(u.camHeight, parseFloat(camHeightSlider.value))

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

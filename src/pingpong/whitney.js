import '../whitney.css'
import '../source-link.js'
import { createProgram } from '../webgl.js'
import { setupRecording, SliderManager, MouseTracker } from '../controls.js'

import vertShader from '../shaders/vertex.glsl'
import blendFrag from '../shaders/pingpong/blend.glsl'
import presentFrag from '../shaders/pingpong/present.glsl'

import lapisShader from '../shaders/whitney/lapis.glsl'
import permutationsShader from '../shaders/whitney/permutations.glsl'
import matrixShader from '../shaders/whitney/matrix.glsl'
import arabesqueShader from '../shaders/whitney/arabesque.glsl'
import columnaShader from '../shaders/whitney/columna.glsl'
import spiralShader from '../shaders/whitney/spiral.glsl'
import musicboxShader from '../shaders/whitney/musicbox.glsl'
import trailsShader from '../shaders/whitney/trails.glsl'
import fractalShader from '../shaders/whitney/fractal.glsl'
import atomShader from '../shaders/whitney/atom.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, alpha: false })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// ============== PIECE PROGRAMS ==============
// Each Whitney shader is a standalone fragment shader that writes gl_FragColor
// based on gl_FragCoord + uniforms. Reused unchanged.

const pieceShaders = {
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

const pieceUniformNames = ['resolution', 'time', 'mouse', 'speed', 'density', 'harmonics']

const programs = {}
const uniforms = {}
for (const [name, frag] of Object.entries(pieceShaders)) {
    const prog = createProgram(gl, vertShader, frag)
    programs[name] = prog
    const u = {}
    for (const un of pieceUniformNames) {
        u[un] = gl.getUniformLocation(prog, `u_${un}`)
    }
    uniforms[name] = u
}

// ============== BLEND + PRESENT PROGRAMS ==============

const vertUv = `
attribute vec2 a_position;
varying vec2 v_uv;
void main() {
    v_uv = a_position * 0.5 + 0.5;
    gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const blendProgram = createProgram(gl, vertUv, blendFrag)
const presentProgram = createProgram(gl, vertUv, presentFrag)

const blendU = {
    fresh: gl.getUniformLocation(blendProgram, 'u_fresh'),
    prev:  gl.getUniformLocation(blendProgram, 'u_prev'),
    decay: gl.getUniformLocation(blendProgram, 'u_decay'),
}
const presentU = {
    tex: gl.getUniformLocation(presentProgram, 'u_tex'),
}

// ============== FULLSCREEN QUAD ==============

const quad = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quad)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  1, -1,  -1,  1,
    -1,  1,  1, -1,   1,  1,
]), gl.STATIC_DRAW)

function bindQuad(program) {
    gl.bindBuffer(gl.ARRAY_BUFFER, quad)
    const loc = gl.getAttribLocation(program, 'a_position')
    gl.enableVertexAttribArray(loc)
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0)
}

// ============== FBOs ==============

function createFBO(w, h) {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    const fb = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)

    return { tex, fb, width: w, height: h }
}

let freshFBO = null
let pingPong = null
let read, write

function rebuildFBOs() {
    const w = canvas.width
    const h = canvas.height
    freshFBO = createFBO(w, h)
    pingPong = [createFBO(w, h), createFBO(w, h)]
    read  = pingPong[0]
    write = pingPong[1]
    clear()
}

function clear() {
    gl.bindFramebuffer(gl.FRAMEBUFFER, freshFBO.fb)
    gl.clearColor(0, 0, 0, 1)
    gl.clear(gl.COLOR_BUFFER_BIT)
    for (const p of pingPong) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, p.fb)
        gl.clear(gl.COLOR_BUFFER_BIT)
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
}

// ============== CONTROLS ==============

let current = 'lapis'

function switchEffect(name) {
    if (!programs[name]) return
    current = name
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.piece === name)
    })
    // Start the new piece on a clean canvas so trails don't bleed across effects
    clear()
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchEffect(btn.dataset.piece)
    })
})

const keyMap = {
    '1': 'lapis', '2': 'permutations', '3': 'matrix', '4': 'arabesque',
    '5': 'columna', '6': 'spiral', '7': 'musicbox', '8': 'trails',
    '9': 'fractal', '0': 'atom',
}

const mouse = new MouseTracker(canvas)
const sliders = new SliderManager({
    speed:     { selector: '#speed',     default: 0.5 },
    density:   { selector: '#density',   default: 1 },
    harmonics: { selector: '#harmonics', default: 1 },
    decay:     { selector: '#decay',     default: 0.92 },
})
const recorder = setupRecording(canvas, { keyboardShortcut: null })

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (keyMap[e.key]) switchEffect(keyMap[e.key])
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
    if (e.key === ' ') { e.preventDefault(); clear() }
})

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    rebuildFBOs()
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============

function render(time) {
    const t = time * 0.001
    const pieceProg = programs[current]
    const u = uniforms[current]

    // --- Pass 1: fresh ---  run the current Whitney piece into freshFBO
    gl.bindFramebuffer(gl.FRAMEBUFFER, freshFBO.fb)
    gl.viewport(0, 0, freshFBO.width, freshFBO.height)
    gl.useProgram(pieceProg)
    bindQuad(pieceProg)
    if (u.resolution) gl.uniform2f(u.resolution, freshFBO.width, freshFBO.height)
    if (u.time) gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)
    sliders.applyUniforms(gl, u)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // --- Pass 2: blend ---  write = mix(fresh, read, decay)
    gl.bindFramebuffer(gl.FRAMEBUFFER, write.fb)
    gl.viewport(0, 0, write.width, write.height)
    gl.useProgram(blendProgram)
    bindQuad(blendProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, freshFBO.tex)
    gl.uniform1i(blendU.fresh, 0)

    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, read.tex)
    gl.uniform1i(blendU.prev, 1)

    gl.uniform1f(blendU.decay, sliders.get('decay'))
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // --- Pass 3: present ---  write → screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(presentProgram)
    bindQuad(presentProgram)
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, write.tex)
    gl.uniform1i(presentU.tex, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // Swap for next frame
    const tmp = read
    read = write
    write = tmp

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

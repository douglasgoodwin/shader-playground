import './reaction-diffusion.css'
import { createProgram, perspective, lookAt, mat4Multiply } from './webgl.js'
import { setupRecording, SliderManager } from './controls.js'

import simFragShader from './shaders/reaction-diffusion/sim.glsl'
import torusVertShader from './shaders/reaction-diffusion/torus-vert.glsl'
import torusFragShader from './shaders/reaction-diffusion/torus-frag.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', {
    preserveDrawingBuffer: true,
    alpha: false
})

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

const floatTexExt = gl.getExtension('OES_texture_float')
const floatLinearExt = gl.getExtension('OES_texture_float_linear')

// ============== SIMULATION SETUP ==============

const SIM_RES = 256

// Simulation vertex shader (fullscreen quad)
const simVertSource = `
attribute vec2 a_position;
varying vec2 v_uv;
void main() {
    v_uv = a_position * 0.5 + 0.5;
    gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const simProgram = createProgram(gl, simVertSource, simFragShader)
const renderProgram = createProgram(gl, torusVertShader, torusFragShader)

const simUniforms = {
    state: gl.getUniformLocation(simProgram, 'u_state'),
    simRes: gl.getUniformLocation(simProgram, 'u_simRes'),
    feed: gl.getUniformLocation(simProgram, 'u_feed'),
    kill: gl.getUniformLocation(simProgram, 'u_kill'),
}

const renderUniforms = {
    mvp: gl.getUniformLocation(renderProgram, 'u_mvp'),
    state: gl.getUniformLocation(renderProgram, 'u_state'),
    twist: gl.getUniformLocation(renderProgram, 'u_twist'),
    time: gl.getUniformLocation(renderProgram, 'u_time'),
}

// ============== TEXTURES & FRAMEBUFFERS ==============

function initStateData() {
    const data = new Float32Array(SIM_RES * SIM_RES * 4)
    for (let y = 0; y < SIM_RES; y++) {
        for (let x = 0; x < SIM_RES; x++) {
            const i = (y * SIM_RES + x) * 4
            const nx = (x / SIM_RES) * 2.0 - 1.0
            const ny = (y / SIM_RES) * 2.0 - 1.0
            const d2 = nx * nx + ny * ny
            data[i] = 1.0  // Chemical A = 1 everywhere
            data[i + 1] = Math.exp(-400.0 * d2) * Math.random()  // Chemical B = gaussian seed
            data[i + 2] = 0.0
            data[i + 3] = 1.0
        }
    }
    return data
}

function createStateTexture(data) {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)

    if (floatTexExt) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, data)
    } else {
        const u8 = new Uint8Array(data.length)
        for (let i = 0; i < data.length; i++) {
            u8[i] = Math.floor(Math.max(0, Math.min(1, data[i])) * 255)
        }
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.UNSIGNED_BYTE, u8)
    }

    // LINEAR filtering needed for diagonal blur sampling
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

    return tex
}

function createFramebuffer(texture) {
    const fb = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0)
    return fb
}

let stateData = initStateData()
let stateTex0 = createStateTexture(stateData)
let stateTex1 = createStateTexture(stateData)
let stateFB0 = createFramebuffer(stateTex0)
let stateFB1 = createFramebuffer(stateTex1)

// ============== FULLSCREEN QUAD ==============

const quadBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1, 1, -1, -1, 1,
    -1, 1, 1, -1, 1, 1
]), gl.STATIC_DRAW)

// ============== TORUS MESH ==============

const TUBE_SEGS = 128
const RING_SEGS = 256

function createTorusMesh() {
    const rows = TUBE_SEGS + 1
    const cols = RING_SEGS + 1
    const uvs = new Float32Array(rows * cols * 2)

    for (let row = 0; row < rows; row++) {
        for (let col = 0; col < cols; col++) {
            const i = row * cols + col
            uvs[i * 2] = row / TUBE_SEGS       // u: around tube
            uvs[i * 2 + 1] = col / RING_SEGS   // v: around ring
        }
    }

    const indices = new Uint16Array(TUBE_SEGS * RING_SEGS * 6)
    let idx = 0
    for (let row = 0; row < TUBE_SEGS; row++) {
        for (let col = 0; col < RING_SEGS; col++) {
            const tl = row * cols + col
            const tr = tl + 1
            const bl = (row + 1) * cols + col
            const br = bl + 1
            indices[idx++] = tl
            indices[idx++] = bl
            indices[idx++] = tr
            indices[idx++] = tr
            indices[idx++] = bl
            indices[idx++] = br
        }
    }

    const uvBuf = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, uvBuf)
    gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW)

    const indexBuf = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuf)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW)

    return { uvBuf, indexBuf, indexCount: indices.length }
}

const torusMesh = createTorusMesh()

// ============== CONTROLS ==============

const sliders = new SliderManager({
    steps: { selector: '#steps', default: 3 },
    twist: { selector: '#twist', default: 2 },
    feed: { selector: '#feed', default: 0.02259 },
    kill: { selector: '#kill', default: 0.05444 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

// Reset on spacebar
document.addEventListener('keydown', (e) => {
    if (e.key === ' ') {
        e.preventDefault()
        resetSimulation()
    }
})

function resetSimulation() {
    const data = initStateData()
    gl.bindTexture(gl.TEXTURE_2D, stateTex0)
    if (floatTexExt) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, data)
    }
    gl.bindTexture(gl.TEXTURE_2D, stateTex1)
    if (floatTexExt) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, data)
    }
}

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============

let currentBuffer = 0

function render(time) {
    const t = time * 0.001
    const stepsPerFrame = Math.round(sliders.get('steps'))
    const twist = sliders.get('twist')
    const feed = sliders.get('feed')
    const kill = sliders.get('kill')

    const textures = [stateTex0, stateTex1]
    const framebuffers = [stateFB0, stateFB1]
    let readIdx = currentBuffer
    let writeIdx = 1 - currentBuffer

    // --- Simulation passes ---
    gl.viewport(0, 0, SIM_RES, SIM_RES)
    gl.useProgram(simProgram)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const simPosLoc = gl.getAttribLocation(simProgram, 'a_position')
    gl.enableVertexAttribArray(simPosLoc)
    gl.vertexAttribPointer(simPosLoc, 2, gl.FLOAT, false, 0, 0)

    gl.uniform1f(simUniforms.simRes, SIM_RES)
    gl.uniform1f(simUniforms.feed, feed)
    gl.uniform1f(simUniforms.kill, kill)

    for (let i = 0; i < stepsPerFrame; i++) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
        gl.uniform1i(simUniforms.state, 0)
        gl.drawArrays(gl.TRIANGLES, 0, 6)

        const tmp = readIdx
        readIdx = writeIdx
        writeIdx = tmp
    }

    // --- 3D Torus Render ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    const bg = [0.05, 0.1, 0.2]
    gl.clearColor(bg[0], bg[1], bg[2], 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.enable(gl.DEPTH_TEST)

    // Camera: orbit with aspect-correct perspective
    const aspect = canvas.width / canvas.height
    const camDist = 2.0
    const camAngle = t * 0.15
    const eye = [
        Math.sin(camAngle) * camDist,
        Math.sin(t * 0.1) * 0.5,
        Math.cos(camAngle) * camDist,
    ]

    const proj = perspective(Math.PI / 4, aspect, 0.1, 100)
    const view = lookAt(eye, [0, 0, 0], [0, 1, 0])
    const mvp = mat4Multiply(proj, view)

    gl.useProgram(renderProgram)
    gl.uniformMatrix4fv(renderUniforms.mvp, false, mvp)
    gl.uniform1f(renderUniforms.twist, twist)
    gl.uniform1f(renderUniforms.time, t)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
    gl.uniform1i(renderUniforms.state, 0)

    // Bind torus mesh
    gl.bindBuffer(gl.ARRAY_BUFFER, torusMesh.uvBuf)
    const uvLoc = gl.getAttribLocation(renderProgram, 'a_uv')
    gl.enableVertexAttribArray(uvLoc)
    gl.vertexAttribPointer(uvLoc, 2, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, torusMesh.indexBuf)
    gl.drawElements(gl.TRIANGLES, torusMesh.indexCount, gl.UNSIGNED_SHORT, 0)

    gl.disable(gl.DEPTH_TEST)

    currentBuffer = readIdx
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

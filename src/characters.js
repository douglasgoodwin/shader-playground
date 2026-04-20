import './characters.css'
import './source-link.js'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording, MouseTracker, SliderManager } from './controls.js'

import basicVertexShader from './shaders/vertex.glsl'
import simVertexShader from './shaders/characters/sim-vertex.glsl'

import frightenedShader from './shaders/characters/frightened.glsl'
import stickfolkShader from './shaders/characters/stickfolk.glsl'
import ragdollSimShader from './shaders/characters/ragdoll-sim.glsl'
import ragdollRenderShader from './shaders/characters/ragdoll-render.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', {
    preserveDrawingBuffer: true,
    alpha: false,
})

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

const floatTexExt = gl.getExtension('OES_texture_float')

// ============== Fullscreen-quad programs (frightened, stickfolk) ==============

const simpleUniformNames = ['resolution', 'time', 'mouse', 'blinkSpeed', 'sizeVariation', 'speed', 'intensity', 'scale']

const simplePrograms = {}
const simpleUniforms = {}

for (const [name, src] of Object.entries({
    frightened: frightenedShader,
    stickfolk: stickfolkShader,
})) {
    const program = createProgram(gl, basicVertexShader, src)
    if (!program) continue
    simplePrograms[name] = program
    const u = {}
    for (const uName of simpleUniformNames) {
        u[uName] = gl.getUniformLocation(program, `u_${uName}`)
    }
    simpleUniforms[name] = u
}

// ============== Ragdoll programs ==============

const RAGDOLL_SIM_RES = 64

const ragdollSimProgram = createProgram(gl, simVertexShader, ragdollSimShader)
const ragdollRenderProgram = createProgram(gl, basicVertexShader, ragdollRenderShader)

const ragdollSimUniforms = {
    positionTex: gl.getUniformLocation(ragdollSimProgram, 'u_positionTex'),
    resolution: gl.getUniformLocation(ragdollSimProgram, 'u_resolution'),
    simResolution: gl.getUniformLocation(ragdollSimProgram, 'u_simResolution'),
    deltaTime: gl.getUniformLocation(ragdollSimProgram, 'u_deltaTime'),
    mouse: gl.getUniformLocation(ragdollSimProgram, 'u_mouse'),
    gravity: gl.getUniformLocation(ragdollSimProgram, 'u_gravity'),
    damping: gl.getUniformLocation(ragdollSimProgram, 'u_damping'),
    pass: gl.getUniformLocation(ragdollSimProgram, 'u_pass'),
}

const ragdollRenderUniforms = {
    positionTex: gl.getUniformLocation(ragdollRenderProgram, 'u_positionTex'),
    resolution: gl.getUniformLocation(ragdollRenderProgram, 'u_resolution'),
    simResolution: gl.getUniformLocation(ragdollRenderProgram, 'u_simResolution'),
    time: gl.getUniformLocation(ragdollRenderProgram, 'u_time'),
}

// ============== Texture / framebuffer helpers ==============

function createDataTexture(data, size) {
    const texture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, texture)

    if (floatTexExt && data instanceof Float32Array) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, size, size, 0, gl.RGBA, gl.FLOAT, data)
    } else {
        const uint8Data = new Uint8Array(data.length)
        for (let i = 0; i < data.length; i++) {
            uint8Data[i] = Math.floor(Math.max(0, Math.min(1, data[i])) * 255)
        }
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, size, size, 0, gl.RGBA, gl.UNSIGNED_BYTE, uint8Data)
    }

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    return texture
}

function createFramebuffer(texture) {
    const fb = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0)
    return fb
}

function initRagdollParticles() {
    const data = new Float32Array(RAGDOLL_SIM_RES * RAGDOLL_SIM_RES * 4)

    for (let row = 0; row < RAGDOLL_SIM_RES; row++) {
        const baseX = (Math.random() - 0.5) * 1.5
        const baseY = 0.5 + Math.random() * 0.4

        const offsets = [
            [0, 0.25],
            [0, 0.17],
            [0, 0.07],
            [0, -0.05],
            [-0.08, 0.07],
            [-0.18, 0.07],
            [-0.27, 0.07],
            [0.08, 0.07],
            [0.18, 0.07],
            [0.27, 0.07],
            [-0.04, -0.05],
            [-0.04, -0.17],
            [-0.04, -0.28],
            [0.04, -0.05],
            [0.04, -0.17],
            [0.04, -0.28],
        ]

        for (let col = 0; col < RAGDOLL_SIM_RES; col++) {
            const idx = (row * RAGDOLL_SIM_RES + col) * 4
            if (col < 16) {
                const x = baseX + offsets[col][0] * 0.25
                const y = baseY + offsets[col][1] * 0.25
                data[idx + 0] = x * 0.5 + 0.5
                data[idx + 1] = y * 0.5 + 0.5
                data[idx + 2] = x * 0.5 + 0.5
                data[idx + 3] = y * 0.5 + 0.5
            } else {
                data[idx + 0] = 0.5
                data[idx + 1] = 0.5
                data[idx + 2] = 0.5
                data[idx + 3] = 0.5
            }
        }
    }

    return data
}

// ============== Buffers ==============

const ragdollData = initRagdollParticles()
let ragdollTex0 = createDataTexture(ragdollData, RAGDOLL_SIM_RES)
let ragdollTex1 = createDataTexture(ragdollData, RAGDOLL_SIM_RES)
let ragdollFB0 = createFramebuffer(ragdollTex0)
let ragdollFB1 = createFramebuffer(ragdollTex1)
let currentBuffer = 0

const quadBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1, 1, -1, -1, 1,
    -1, 1, 1, -1, 1, 1,
]), gl.STATIC_DRAW)

// ============== Controls ==============

const mouse = new MouseTracker(canvas)

const simpleSliders = new SliderManager({
    blinkSpeed: { selector: '#blinkSpeed', default: 1 },
    sizeVariation: { selector: '#sizeVariation', default: 0.3 },
})

const ragdollSliders = new SliderManager({
    gravity: { selector: '#gravity', default: 1.5 },
    damping: { selector: '#damping', default: 1.0 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

// ============== Mode switching ==============

let currentMode = 'frightened'

const simpleSliderPanel = document.getElementById('simple-sliders')
const ragdollSliderPanel = document.getElementById('ragdoll-sliders')

function switchMode(mode) {
    if (mode === currentMode) return
    if (!(mode in simplePrograms) && mode !== 'ragdoll') return
    currentMode = mode

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.piece === mode)
    })

    const isRagdoll = mode === 'ragdoll'
    if (simpleSliderPanel) simpleSliderPanel.style.display = isRagdoll ? 'none' : ''
    if (ragdollSliderPanel) ragdollSliderPanel.style.display = isRagdoll ? '' : 'none'

    if (isRagdoll) {
        const newData = initRagdollParticles()
        const upload = (tex) => {
            gl.bindTexture(gl.TEXTURE_2D, tex)
            if (floatTexExt) {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, RAGDOLL_SIM_RES, RAGDOLL_SIM_RES, 0, gl.RGBA, gl.FLOAT, newData)
            } else {
                const u8 = new Uint8Array(newData.length)
                for (let i = 0; i < newData.length; i++) {
                    u8[i] = Math.floor(Math.max(0, Math.min(1, newData[i])) * 255)
                }
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, RAGDOLL_SIM_RES, RAGDOLL_SIM_RES, 0, gl.RGBA, gl.UNSIGNED_BYTE, u8)
            }
        }
        upload(ragdollTex0)
        upload(ragdollTex1)
    }
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchMode(btn.dataset.piece)
    })
})

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === '1') switchMode('frightened')
    if (e.key === '2') switchMode('stickfolk')
    if (e.key === '3') switchMode('ragdoll')
})

// ============== Resize ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
}
window.addEventListener('resize', resize)
resize()

// ============== Render loop ==============

let lastTime = 0

function render(time) {
    const t = time * 0.001
    const deltaTime = Math.min((time - lastTime) * 0.001, 0.033)
    lastTime = time

    if (currentMode === 'ragdoll') {
        renderRagdoll(t, deltaTime)
    } else {
        renderSimple(t)
    }

    currentBuffer = 1 - currentBuffer
    requestAnimationFrame(render)
}

function renderSimple(t) {
    const program = simplePrograms[currentMode]
    if (!program) return
    const u = simpleUniforms[currentMode]

    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(program)

    createFullscreenQuad(gl, program)

    if (u.resolution) gl.uniform2f(u.resolution, canvas.width, canvas.height)
    if (u.time) gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)

    const blinkSpeed = simpleSliders.get('blinkSpeed')
    const sizeVariation = simpleSliders.get('sizeVariation')

    if (currentMode === 'stickfolk') {
        if (u.speed) gl.uniform1f(u.speed, blinkSpeed)
        if (u.intensity) gl.uniform1f(u.intensity, 0.7)
        if (u.scale) gl.uniform1f(u.scale, sizeVariation * 3.0 + 1.0)
    } else {
        if (u.blinkSpeed) gl.uniform1f(u.blinkSpeed, blinkSpeed)
        if (u.sizeVariation) gl.uniform1f(u.sizeVariation, sizeVariation)
    }

    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

function renderRagdoll(t, deltaTime) {
    const gravity = ragdollSliders.get('gravity') * 1.5
    const damping = 0.98 + ragdollSliders.get('damping') * 0.015

    const textures = [ragdollTex0, ragdollTex1]
    const framebuffers = [ragdollFB0, ragdollFB1]
    let readIdx = currentBuffer
    let writeIdx = 1 - currentBuffer

    const constraintPasses = 8

    gl.viewport(0, 0, RAGDOLL_SIM_RES, RAGDOLL_SIM_RES)
    gl.useProgram(ragdollSimProgram)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const simPosLoc = gl.getAttribLocation(ragdollSimProgram, 'a_position')
    gl.enableVertexAttribArray(simPosLoc)
    gl.vertexAttribPointer(simPosLoc, 2, gl.FLOAT, false, 0, 0)

    gl.uniform2f(ragdollSimUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(ragdollSimUniforms.simResolution, RAGDOLL_SIM_RES)
    gl.uniform1f(ragdollSimUniforms.deltaTime, deltaTime)
    mouse.applyUniform(gl, ragdollSimUniforms.mouse)
    gl.uniform1f(ragdollSimUniforms.gravity, gravity)
    gl.uniform1f(ragdollSimUniforms.damping, damping)

    // Verlet integration
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
    gl.uniform1i(ragdollSimUniforms.positionTex, 0)
    gl.uniform1i(ragdollSimUniforms.pass, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    let tmp = readIdx
    readIdx = writeIdx
    writeIdx = tmp

    // Constraint passes
    for (let i = 0; i < constraintPasses; i++) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
        gl.uniform1i(ragdollSimUniforms.pass, i + 1)
        gl.drawArrays(gl.TRIANGLES, 0, 6)

        tmp = readIdx
        readIdx = writeIdx
        writeIdx = tmp
    }

    // Display
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(ragdollRenderProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
    gl.uniform1i(ragdollRenderUniforms.positionTex, 0)
    gl.uniform2f(ragdollRenderUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(ragdollRenderUniforms.simResolution, RAGDOLL_SIM_RES)
    gl.uniform1f(ragdollRenderUniforms.time, t)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const renderPosLoc = gl.getAttribLocation(ragdollRenderProgram, 'a_position')
    gl.enableVertexAttribArray(renderPosLoc)
    gl.vertexAttribPointer(renderPosLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

requestAnimationFrame(render)

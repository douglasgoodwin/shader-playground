import './particles.css'
import { createProgram } from './webgl.js'
import { setupRecording, MouseTracker, SliderManager } from './controls.js'

// Shader imports - Murmuration
import simVertexShader from './shaders/particles/sim-vertex.glsl'
import simVelocityShader from './shaders/particles/sim-velocity.glsl'
import simPositionShader from './shaders/particles/sim-position.glsl'
import renderVertexShader from './shaders/particles/render-vertex.glsl'
import renderFragmentShader from './shaders/particles/render-fragment.glsl'
import backgroundShader from './shaders/particles/background.glsl'

// Shader imports - Ragdoll
import ragdollSimShader from './shaders/particles/ragdoll-sim.glsl'
import ragdollRenderShader from './shaders/particles/ragdoll-render.glsl'

// Shader imports - Lenia
import leniaSimShader from './shaders/particles/lenia-sim.glsl'
import leniaRenderVertexShader from './shaders/particles/lenia-render-vertex.glsl'
import leniaRenderShader from './shaders/particles/lenia-render.glsl'

import basicVertexShader from './shaders/vertex.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', {
    preserveDrawingBuffer: true,
    alpha: false
})

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Check for required extensions
const floatTexExt = gl.getExtension('OES_texture_float')
if (!floatTexExt) {
    console.warn('OES_texture_float not supported, using UNSIGNED_BYTE textures')
}

// ============== MURMURATION ==============
const SIM_RESOLUTION = 80
const PARTICLE_COUNT = SIM_RESOLUTION * SIM_RESOLUTION

const velocityProgram = createProgram(gl, simVertexShader, simVelocityShader)
const positionProgram = createProgram(gl, simVertexShader, simPositionShader)
const renderProgram = createProgram(gl, renderVertexShader, renderFragmentShader)
const backgroundProgram = createProgram(gl, basicVertexShader, backgroundShader)

const velocityUniforms = {
    positionTex: gl.getUniformLocation(velocityProgram, 'u_positionTex'),
    velocityTex: gl.getUniformLocation(velocityProgram, 'u_velocityTex'),
    resolution: gl.getUniformLocation(velocityProgram, 'u_resolution'),
    simResolution: gl.getUniformLocation(velocityProgram, 'u_simResolution'),
    deltaTime: gl.getUniformLocation(velocityProgram, 'u_deltaTime'),
    mouse: gl.getUniformLocation(velocityProgram, 'u_mouse'),
    mouseInfluence: gl.getUniformLocation(velocityProgram, 'u_mouseInfluence'),
    separation: gl.getUniformLocation(velocityProgram, 'u_separation'),
    alignment: gl.getUniformLocation(velocityProgram, 'u_alignment'),
    cohesion: gl.getUniformLocation(velocityProgram, 'u_cohesion'),
    maxSpeed: gl.getUniformLocation(velocityProgram, 'u_maxSpeed'),
    perceptionRadius: gl.getUniformLocation(velocityProgram, 'u_perceptionRadius'),
    time: gl.getUniformLocation(velocityProgram, 'u_time'),
}

const positionUniforms = {
    positionTex: gl.getUniformLocation(positionProgram, 'u_positionTex'),
    velocityTex: gl.getUniformLocation(positionProgram, 'u_velocityTex'),
    deltaTime: gl.getUniformLocation(positionProgram, 'u_deltaTime'),
}

const renderUniforms = {
    positionTex: gl.getUniformLocation(renderProgram, 'u_positionTex'),
    velocityTex: gl.getUniformLocation(renderProgram, 'u_velocityTex'),
    resolution: gl.getUniformLocation(renderProgram, 'u_resolution'),
    pointSize: gl.getUniformLocation(renderProgram, 'u_pointSize'),
}

const backgroundUniforms = {
    resolution: gl.getUniformLocation(backgroundProgram, 'u_resolution'),
    time: gl.getUniformLocation(backgroundProgram, 'u_time'),
}

// ============== RAGDOLL ==============
const RAGDOLL_SIM_RES = 64  // 64 rows = 64 ragdolls, 16 particles each
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

// ============== LENIA ==============
const LENIA_SIM_RES = 16
const LENIA_PARTICLE_COUNT = 200

// Compute normalization coefficient w_k from kernel params
function computeWk(mu_k, sigma_k) {
    const dr = 0.01
    let sum = 0
    for (let r = 0; r < 20; r += dr) {
        const t = (r - mu_k * sigma_k) / sigma_k
        sum += Math.exp(-0.5 * t * t) * r * dr
    }
    return 1.0 / (2.0 * Math.PI * sum)
}

const leniaSimProgram = createProgram(gl, simVertexShader, leniaSimShader)
const leniaRenderProgram = createProgram(gl, leniaRenderVertexShader, leniaRenderShader)

const leniaSimUniforms = {
    positionTex: gl.getUniformLocation(leniaSimProgram, 'u_positionTex'),
    dt: gl.getUniformLocation(leniaSimProgram, 'u_dt'),
    mu_k: gl.getUniformLocation(leniaSimProgram, 'u_mu_k'),
    sigma_k: gl.getUniformLocation(leniaSimProgram, 'u_sigma_k'),
    w_k: gl.getUniformLocation(leniaSimProgram, 'u_w_k'),
    mu_g: gl.getUniformLocation(leniaSimProgram, 'u_mu_g'),
    sigma_g: gl.getUniformLocation(leniaSimProgram, 'u_sigma_g'),
    c_rep: gl.getUniformLocation(leniaSimProgram, 'u_c_rep'),
    simResolution: gl.getUniformLocation(leniaSimProgram, 'u_simResolution'),
    particleCount: gl.getUniformLocation(leniaSimProgram, 'u_particleCount'),
}

const leniaRenderUniforms = {
    positionTex: gl.getUniformLocation(leniaRenderProgram, 'u_positionTex'),
    resolution: gl.getUniformLocation(leniaRenderProgram, 'u_resolution'),
    pointSize: gl.getUniformLocation(leniaRenderProgram, 'u_pointSize'),
    viewR: gl.getUniformLocation(leniaRenderProgram, 'u_viewR'),
}

// ============== TEXTURE HELPERS ==============
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

// ============== MURMURATION INIT ==============
function initMurmurationParticles() {
    const positions = new Float32Array(PARTICLE_COUNT * 4)
    const velocities = new Float32Array(PARTICLE_COUNT * 4)

    for (let i = 0; i < PARTICLE_COUNT; i++) {
        const theta = Math.random() * Math.PI * 2
        const phi = Math.acos(2 * Math.random() - 1)
        const r = Math.random() * 0.8

        const x = r * Math.sin(phi) * Math.cos(theta)
        const y = r * Math.sin(phi) * Math.sin(theta)
        const z = r * Math.cos(phi) * 0.3

        positions[i * 4 + 0] = x / 4 + 0.5
        positions[i * 4 + 1] = y / 4 + 0.5
        positions[i * 4 + 2] = z / 4 + 0.5
        positions[i * 4 + 3] = 1.0

        const vx = (Math.random() - 0.5) * 0.2
        const vy = (Math.random() - 0.5) * 0.2
        const vz = (Math.random() - 0.5) * 0.1

        velocities[i * 4 + 0] = vx / 2 + 0.5
        velocities[i * 4 + 1] = vy / 2 + 0.5
        velocities[i * 4 + 2] = vz / 2 + 0.5
        velocities[i * 4 + 3] = 1.0
    }

    return { positions, velocities }
}

// ============== RAGDOLL INIT ==============
function initRagdollParticles() {
    // Each ragdoll has 16 particles, arranged in rows
    // RGBA = x, y, prevX, prevY (2D Verlet)
    const data = new Float32Array(RAGDOLL_SIM_RES * RAGDOLL_SIM_RES * 4)

    for (let row = 0; row < RAGDOLL_SIM_RES; row++) {
        // Random starting position for this ragdoll
        const baseX = (Math.random() - 0.5) * 1.5
        const baseY = 0.5 + Math.random() * 0.4

        // Particle offsets for T-pose ragdoll
        const offsets = [
            [0, 0.25],      // 0: head
            [0, 0.17],      // 1: neck
            [0, 0.07],      // 2: chest
            [0, -0.05],     // 3: hips
            [-0.08, 0.07],  // 4: shoulderL
            [-0.18, 0.07],  // 5: elbowL
            [-0.27, 0.07],  // 6: handL
            [0.08, 0.07],   // 7: shoulderR
            [0.18, 0.07],   // 8: elbowR
            [0.27, 0.07],   // 9: handR
            [-0.04, -0.05], // 10: hipL
            [-0.04, -0.17], // 11: kneeL
            [-0.04, -0.28], // 12: footL
            [0.04, -0.05],  // 13: hipR
            [0.04, -0.17],  // 14: kneeR
            [0.04, -0.28],  // 15: footR
        ]

        for (let col = 0; col < RAGDOLL_SIM_RES; col++) {
            const idx = (row * RAGDOLL_SIM_RES + col) * 4
            if (col < 16) {
                const x = baseX + offsets[col][0] * 0.25
                const y = baseY + offsets[col][1] * 0.25
                // Store as normalized 0-1 range, will be decoded in shader
                // pos = (data - 0.5) * 2 for range -1 to 1
                data[idx + 0] = x * 0.5 + 0.5  // current x
                data[idx + 1] = y * 0.5 + 0.5  // current y
                data[idx + 2] = x * 0.5 + 0.5  // prev x (same = no velocity)
                data[idx + 3] = y * 0.5 + 0.5  // prev y
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

// ============== LENIA INIT ==============
function initLeniaParticles() {
    const data = new Float32Array(LENIA_SIM_RES * LENIA_SIM_RES * 4)
    for (let i = 0; i < LENIA_SIM_RES * LENIA_SIM_RES; i++) {
        if (i < LENIA_PARTICLE_COUNT) {
            const x = (Math.random() - 0.5) * 12.0 // [-6, 6]
            const y = (Math.random() - 0.5) * 12.0
            data[i * 4 + 0] = x / 14.0 + 0.5
            data[i * 4 + 1] = y / 14.0 + 0.5
            data[i * 4 + 2] = 0.5
            data[i * 4 + 3] = 0.5
        } else {
            data[i * 4 + 0] = 0.5
            data[i * 4 + 1] = 0.5
            data[i * 4 + 2] = 0.5
            data[i * 4 + 3] = 0.5
        }
    }
    return data
}

// ============== CREATE BUFFERS ==============
// Murmuration
const murmData = initMurmurationParticles()
let murmPosTex0 = createDataTexture(murmData.positions, SIM_RESOLUTION)
let murmPosTex1 = createDataTexture(murmData.positions, SIM_RESOLUTION)
let murmVelTex0 = createDataTexture(murmData.velocities, SIM_RESOLUTION)
let murmVelTex1 = createDataTexture(murmData.velocities, SIM_RESOLUTION)
let murmPosFB0 = createFramebuffer(murmPosTex0)
let murmPosFB1 = createFramebuffer(murmPosTex1)
let murmVelFB0 = createFramebuffer(murmVelTex0)
let murmVelFB1 = createFramebuffer(murmVelTex1)

// Ragdoll
const ragdollData = initRagdollParticles()
let ragdollTex0 = createDataTexture(ragdollData, RAGDOLL_SIM_RES)
let ragdollTex1 = createDataTexture(ragdollData, RAGDOLL_SIM_RES)
let ragdollFB0 = createFramebuffer(ragdollTex0)
let ragdollFB1 = createFramebuffer(ragdollTex1)

// Lenia
const leniaData = initLeniaParticles()
let leniaTex0 = createDataTexture(leniaData, LENIA_SIM_RES)
let leniaTex1 = createDataTexture(leniaData, LENIA_SIM_RES)
let leniaFB0 = createFramebuffer(leniaTex0)
let leniaFB1 = createFramebuffer(leniaTex1)

// Lenia particle tex coords (only first LENIA_PARTICLE_COUNT)
const leniaTexCoords = new Float32Array(LENIA_PARTICLE_COUNT * 2)
for (let i = 0; i < LENIA_PARTICLE_COUNT; i++) {
    const x = i % LENIA_SIM_RES
    const y = Math.floor(i / LENIA_SIM_RES)
    leniaTexCoords[i * 2] = (x + 0.5) / LENIA_SIM_RES
    leniaTexCoords[i * 2 + 1] = (y + 0.5) / LENIA_SIM_RES
}
const leniaParticleBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, leniaParticleBuffer)
gl.bufferData(gl.ARRAY_BUFFER, leniaTexCoords, gl.STATIC_DRAW)

let currentBuffer = 0

// Fullscreen quad
const quadBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1, 1, -1, -1, 1,
    -1, 1, 1, -1, 1, 1
]), gl.STATIC_DRAW)

// Particle texture coordinates for murmuration rendering
const particleTexCoords = new Float32Array(PARTICLE_COUNT * 2)
for (let i = 0; i < SIM_RESOLUTION; i++) {
    for (let j = 0; j < SIM_RESOLUTION; j++) {
        const idx = (i * SIM_RESOLUTION + j) * 2
        particleTexCoords[idx] = (j + 0.5) / SIM_RESOLUTION
        particleTexCoords[idx + 1] = (i + 0.5) / SIM_RESOLUTION
    }
}
const particleBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, particleBuffer)
gl.bufferData(gl.ARRAY_BUFFER, particleTexCoords, gl.STATIC_DRAW)

// ============== CONTROLS ==============
const mouse = new MouseTracker(canvas)

const sliders = new SliderManager({
    separation: { selector: '#separation', default: 1.5 },
    cohesion: { selector: '#cohesion', default: 1.0 },
    alignment: { selector: '#alignment', default: 1.0 },
})

const leniaSliders = new SliderManager({
    steps: { selector: '#lenia-steps', default: 5 },
    mu_k: { selector: '#lenia-mu-k', default: 4.0 },
    sigma_k: { selector: '#lenia-sigma-k', default: 1.0 },
    mu_g: { selector: '#lenia-mu-g', default: 0.6 },
    sigma_g: { selector: '#lenia-sigma-g', default: 0.15 },
    c_rep: { selector: '#lenia-c-rep', default: 1.0 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

// ============== MODE SWITCHING ==============
let currentMode = 'murmuration'

function switchMode(mode) {
    if (mode === currentMode) return
    currentMode = mode

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.piece === mode)
    })

    // Toggle slider panels
    document.getElementById('sliders').style.display = mode === 'lenia' ? 'none' : ''
    document.getElementById('lenia-sliders').style.display = mode === 'lenia' ? '' : 'none'

    // Update slider labels for murmuration/ragdoll
    if (mode !== 'lenia') {
        const labels = document.querySelectorAll('#sliders label span')
        if (mode === 'murmuration') {
            labels[0].textContent = 'Separation'
            labels[1].textContent = 'Cohesion'
            labels[2].textContent = 'Alignment'
        } else {
            labels[0].textContent = 'Gravity'
            labels[1].textContent = 'Damping'
            labels[2].textContent = 'Bounce'
        }
    }

    // Reset lenia when switching to that mode
    if (mode === 'lenia') {
        const newData = initLeniaParticles()
        gl.bindTexture(gl.TEXTURE_2D, leniaTex0)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, LENIA_SIM_RES, LENIA_SIM_RES, 0, gl.RGBA, gl.FLOAT, newData)
        gl.bindTexture(gl.TEXTURE_2D, leniaTex1)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, LENIA_SIM_RES, LENIA_SIM_RES, 0, gl.RGBA, gl.FLOAT, newData)
    }

    // Reset ragdolls when switching to that mode
    if (mode === 'ragdoll') {
        const newData = initRagdollParticles()
        gl.bindTexture(gl.TEXTURE_2D, ragdollTex0)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, RAGDOLL_SIM_RES, RAGDOLL_SIM_RES, 0, gl.RGBA, gl.FLOAT, newData)
        gl.bindTexture(gl.TEXTURE_2D, ragdollTex1)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, RAGDOLL_SIM_RES, RAGDOLL_SIM_RES, 0, gl.RGBA, gl.FLOAT, newData)
    }
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchMode(btn.dataset.piece)
    })
})

document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchMode('murmuration')
    if (e.key === '2') switchMode('ragdoll')
    if (e.key === '3') switchMode('lenia')
})

// ============== RESIZE ==============
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============
let lastTime = 0

function render(time) {
    const t = time * 0.001
    const deltaTime = Math.min((time - lastTime) * 0.001, 0.033)
    lastTime = time

    if (currentMode === 'murmuration') {
        renderMurmuration(t, deltaTime)
    } else if (currentMode === 'lenia') {
        renderLenia(t, deltaTime)
    } else {
        renderRagdoll(t, deltaTime)
    }

    currentBuffer = 1 - currentBuffer
    requestAnimationFrame(render)
}

function renderMurmuration(t, deltaTime) {
    const separation = sliders.get('separation')
    const cohesion = sliders.get('cohesion')
    const alignment = sliders.get('alignment')

    const readPosTex = currentBuffer === 0 ? murmPosTex0 : murmPosTex1
    const writePosFB = currentBuffer === 0 ? murmPosFB1 : murmPosFB0
    const writePosTex = currentBuffer === 0 ? murmPosTex1 : murmPosTex0
    const readVelTex = currentBuffer === 0 ? murmVelTex0 : murmVelTex1
    const writeVelFB = currentBuffer === 0 ? murmVelFB1 : murmVelFB0
    const writeVelTex = currentBuffer === 0 ? murmVelTex1 : murmVelTex0

    // Velocity update
    gl.bindFramebuffer(gl.FRAMEBUFFER, writeVelFB)
    gl.viewport(0, 0, SIM_RESOLUTION, SIM_RESOLUTION)
    gl.useProgram(velocityProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, readPosTex)
    gl.uniform1i(velocityUniforms.positionTex, 0)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, readVelTex)
    gl.uniform1i(velocityUniforms.velocityTex, 1)

    gl.uniform2f(velocityUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(velocityUniforms.simResolution, SIM_RESOLUTION)
    gl.uniform1f(velocityUniforms.deltaTime, deltaTime)
    mouse.applyUniform(gl, velocityUniforms.mouse)
    gl.uniform1f(velocityUniforms.mouseInfluence, 0.5)
    gl.uniform1f(velocityUniforms.separation, separation)
    gl.uniform1f(velocityUniforms.alignment, alignment)
    gl.uniform1f(velocityUniforms.cohesion, cohesion)
    gl.uniform1f(velocityUniforms.maxSpeed, 0.8)
    gl.uniform1f(velocityUniforms.perceptionRadius, 0.3)
    gl.uniform1f(velocityUniforms.time, t)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const velPosLoc = gl.getAttribLocation(velocityProgram, 'a_position')
    gl.enableVertexAttribArray(velPosLoc)
    gl.vertexAttribPointer(velPosLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // Position update
    gl.bindFramebuffer(gl.FRAMEBUFFER, writePosFB)
    gl.viewport(0, 0, SIM_RESOLUTION, SIM_RESOLUTION)
    gl.useProgram(positionProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, readPosTex)
    gl.uniform1i(positionUniforms.positionTex, 0)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, writeVelTex)
    gl.uniform1i(positionUniforms.velocityTex, 1)
    gl.uniform1f(positionUniforms.deltaTime, deltaTime)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const posPosLoc = gl.getAttribLocation(positionProgram, 'a_position')
    gl.enableVertexAttribArray(posPosLoc)
    gl.vertexAttribPointer(posPosLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // Render
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    // Background
    gl.useProgram(backgroundProgram)
    gl.uniform2f(backgroundUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(backgroundUniforms.time, t)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const bgPosLoc = gl.getAttribLocation(backgroundProgram, 'a_position')
    gl.enableVertexAttribArray(bgPosLoc)
    gl.vertexAttribPointer(bgPosLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // Particles
    gl.enable(gl.BLEND)
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.useProgram(renderProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, writePosTex)
    gl.uniform1i(renderUniforms.positionTex, 0)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, writeVelTex)
    gl.uniform1i(renderUniforms.velocityTex, 1)

    gl.uniform2f(renderUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(renderUniforms.pointSize, Math.min(canvas.width, canvas.height) * 0.0075)

    gl.bindBuffer(gl.ARRAY_BUFFER, particleBuffer)
    const texCoordLoc = gl.getAttribLocation(renderProgram, 'a_texCoord')
    gl.enableVertexAttribArray(texCoordLoc)
    gl.vertexAttribPointer(texCoordLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.POINTS, 0, PARTICLE_COUNT)

    gl.disable(gl.BLEND)
}

function renderRagdoll(t, deltaTime) {
    const gravity = sliders.get('separation') * 1.5  // Repurpose slider
    const damping = 0.98 + sliders.get('cohesion') * 0.015  // 0.98 - 0.995

    // Use local ping-pong state for ragdoll simulation
    // This keeps track of which texture has the current state
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

    // Set uniforms once
    gl.uniform2f(ragdollSimUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(ragdollSimUniforms.simResolution, RAGDOLL_SIM_RES)
    gl.uniform1f(ragdollSimUniforms.deltaTime, deltaTime)
    mouse.applyUniform(gl, ragdollSimUniforms.mouse)
    gl.uniform1f(ragdollSimUniforms.gravity, gravity)
    gl.uniform1f(ragdollSimUniforms.damping, damping)

    // Pass 0: Verlet integration
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
    gl.uniform1i(ragdollSimUniforms.positionTex, 0)
    gl.uniform1i(ragdollSimUniforms.pass, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // Swap for constraint passes
    let tmp = readIdx
    readIdx = writeIdx
    writeIdx = tmp

    // Constraint passes (ping-pong)
    for (let i = 0; i < constraintPasses; i++) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
        gl.uniform1i(ragdollSimUniforms.pass, i + 1)
        gl.drawArrays(gl.TRIANGLES, 0, 6)

        // Swap read/write
        tmp = readIdx
        readIdx = writeIdx
        writeIdx = tmp
    }

    // After all passes, readIdx points to the final result
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    // Render ragdolls
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

function renderLenia(t, deltaTime) {
    const mu_k = leniaSliders.get('mu_k')
    const sigma_k = leniaSliders.get('sigma_k')
    const mu_g = leniaSliders.get('mu_g')
    const sigma_g = leniaSliders.get('sigma_g')
    const c_rep = leniaSliders.get('c_rep')
    const stepsPerFrame = Math.round(leniaSliders.get('steps'))
    const w_k = computeWk(mu_k, sigma_k)
    const simDt = 0.1

    const textures = [leniaTex0, leniaTex1]
    const framebuffers = [leniaFB0, leniaFB1]
    let readIdx = currentBuffer
    let writeIdx = 1 - currentBuffer

    gl.viewport(0, 0, LENIA_SIM_RES, LENIA_SIM_RES)
    gl.useProgram(leniaSimProgram)

    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const simPosLoc = gl.getAttribLocation(leniaSimProgram, 'a_position')
    gl.enableVertexAttribArray(simPosLoc)
    gl.vertexAttribPointer(simPosLoc, 2, gl.FLOAT, false, 0, 0)

    // Set uniforms
    gl.uniform1f(leniaSimUniforms.dt, simDt)
    gl.uniform1f(leniaSimUniforms.mu_k, mu_k)
    gl.uniform1f(leniaSimUniforms.sigma_k, sigma_k)
    gl.uniform1f(leniaSimUniforms.w_k, w_k)
    gl.uniform1f(leniaSimUniforms.mu_g, mu_g)
    gl.uniform1f(leniaSimUniforms.sigma_g, sigma_g)
    gl.uniform1f(leniaSimUniforms.c_rep, c_rep)
    gl.uniform1f(leniaSimUniforms.simResolution, LENIA_SIM_RES)
    gl.uniform1f(leniaSimUniforms.particleCount, LENIA_PARTICLE_COUNT)

    for (let i = 0; i < stepsPerFrame; i++) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffers[writeIdx])
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
        gl.uniform1i(leniaSimUniforms.positionTex, 0)
        gl.drawArrays(gl.TRIANGLES, 0, 6)

        let tmp = readIdx
        readIdx = writeIdx
        writeIdx = tmp
    }

    // Render particles
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    // Dark background
    gl.clearColor(0.02, 0.02, 0.05, 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    // Additive blending for gaussian spots
    gl.enable(gl.BLEND)
    gl.blendFunc(gl.ONE, gl.ONE)

    gl.useProgram(leniaRenderProgram)
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, textures[readIdx])
    gl.uniform1i(leniaRenderUniforms.positionTex, 0)
    gl.uniform2f(leniaRenderUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(leniaRenderUniforms.pointSize, Math.min(canvas.width, canvas.height) * 0.04)
    gl.uniform1f(leniaRenderUniforms.viewR, 8.0)

    gl.bindBuffer(gl.ARRAY_BUFFER, leniaParticleBuffer)
    const texCoordLoc = gl.getAttribLocation(leniaRenderProgram, 'a_texCoord')
    gl.enableVertexAttribArray(texCoordLoc)
    gl.vertexAttribPointer(texCoordLoc, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.POINTS, 0, LENIA_PARTICLE_COUNT)

    gl.disable(gl.BLEND)
}

requestAnimationFrame(render)

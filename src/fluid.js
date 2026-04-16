import './fluid.css'
import './source-link.js'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import { createMediaLoader } from './media-loader.js'

import vertexShader from './shaders/vertex.glsl'
import simShader from './shaders/fluid/sim.glsl'
import transportShader from './shaders/fluid/transport.glsl'
import displayShader from './shaders/fluid/display.glsl'
import poolwaterShader from './shaders/fluid/poolwater.glsl'
import ferroSimShader from './shaders/fluid/ferrofluid-sim.glsl'
import ferroDisplayShader from './shaders/fluid/ferrofluid-display.glsl'

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
gl.getExtension('OES_texture_float_linear')

// ============== CURRENT EFFECT ==============

let currentEffect = 'navier-stokes'

// ============== NAVIER-STOKES SETUP ==============

const SIM_RES = 512

const simVertSource = `
attribute vec2 a_position;
void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const simProgram = createProgram(gl, simVertSource, simShader)
const transportProgram = createProgram(gl, simVertSource, transportShader)
const displayProgram = createProgram(gl, simVertSource, displayShader)

const simUniforms = {
    state: gl.getUniformLocation(simProgram, 'u_state'),
    resolution: gl.getUniformLocation(simProgram, 'u_resolution'),
    mouse: gl.getUniformLocation(simProgram, 'u_mouse'),
    mouseDown: gl.getUniformLocation(simProgram, 'u_mouseDown'),
    frame: gl.getUniformLocation(simProgram, 'u_frame'),
    viscosity: gl.getUniformLocation(simProgram, 'u_viscosity'),
    speed: gl.getUniformLocation(simProgram, 'u_speed'),
    obstacleSize: gl.getUniformLocation(simProgram, 'u_obstacleSize'),
}

const transportUniforms = {
    state: gl.getUniformLocation(transportProgram, 'u_state'),
    transport: gl.getUniformLocation(transportProgram, 'u_transport'),
    resolution: gl.getUniformLocation(transportProgram, 'u_resolution'),
    frame: gl.getUniformLocation(transportProgram, 'u_frame'),
}

const displayUniforms = {
    state: gl.getUniformLocation(displayProgram, 'u_state'),
    transport: gl.getUniformLocation(displayProgram, 'u_transport'),
    image: gl.getUniformLocation(displayProgram, 'u_image'),
    resolution: gl.getUniformLocation(displayProgram, 'u_resolution'),
    hasImage: gl.getUniformLocation(displayProgram, 'u_hasImage'),
}

// ============== FERROFLUID SETUP ==============

const ferroSimProgram = createProgram(gl, simVertSource, ferroSimShader)
const ferroDisplayProgram = createProgram(gl, simVertSource, ferroDisplayShader)

const ferroSimUniforms = {
    state: gl.getUniformLocation(ferroSimProgram, 'u_state'),
    resolution: gl.getUniformLocation(ferroSimProgram, 'u_resolution'),
    mouse: gl.getUniformLocation(ferroSimProgram, 'u_mouse'),
    mouseDown: gl.getUniformLocation(ferroSimProgram, 'u_mouseDown'),
    feed: gl.getUniformLocation(ferroSimProgram, 'u_feed'),
    kill: gl.getUniformLocation(ferroSimProgram, 'u_kill'),
}

const ferroDisplayUniforms = {
    state: gl.getUniformLocation(ferroDisplayProgram, 'u_state'),
    resolution: gl.getUniformLocation(ferroDisplayProgram, 'u_resolution'),
    time: gl.getUniformLocation(ferroDisplayProgram, 'u_time'),
    metallic: gl.getUniformLocation(ferroDisplayProgram, 'u_metallic'),
}

const FERRO_RES = 512

function initFerroData() {
    const data = new Float32Array(FERRO_RES * FERRO_RES * 4)
    for (let y = 0; y < FERRO_RES; y++) {
        for (let x = 0; x < FERRO_RES; x++) {
            const i = (y * FERRO_RES + x) * 4
            data[i] = 1.0  // Chemical A
            // Seed: random spots
            const nx = (x / FERRO_RES) * 2.0 - 1.0
            const ny = (y / FERRO_RES) * 2.0 - 1.0
            const d2 = nx * nx + ny * ny
            data[i + 1] = d2 < 0.04 ? Math.random() * 0.5 : 0.0  // Chemical B
            data[i + 2] = 0.0
            data[i + 3] = 1.0
        }
    }
    return data
}

let ferroData = initFerroData()
let ferroTex0 = createFloatTexture(ferroData, FERRO_RES)
let ferroTex1 = createFloatTexture(ferroData, FERRO_RES)
let ferroFB0 = createFramebuffer(ferroTex0)
let ferroFB1 = createFramebuffer(ferroTex1)
let ferroBuffer = 0

// ============== POOL WATER SETUP ==============

const poolProgram = createProgram(gl, vertexShader, poolwaterShader)
const poolUniforms = {
    resolution: gl.getUniformLocation(poolProgram, 'u_resolution'),
    time: gl.getUniformLocation(poolProgram, 'u_time'),
    mouse: gl.getUniformLocation(poolProgram, 'u_mouse'),
    speed: gl.getUniformLocation(poolProgram, 'u_speed'),
    density: gl.getUniformLocation(poolProgram, 'u_density'),
    harmonics: gl.getUniformLocation(poolProgram, 'u_harmonics'),
}

// ============== TEXTURES & FRAMEBUFFERS ==============

function createFloatTexture(data, res = SIM_RES) {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)

    if (floatTexExt) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, res, res, 0, gl.RGBA, gl.FLOAT, data)
    } else {
        const u8 = new Uint8Array(data.length)
        for (let i = 0; i < data.length; i++) {
            u8[i] = Math.floor(Math.max(0, Math.min(1, data[i])) * 255)
        }
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, res, res, 0, gl.RGBA, gl.UNSIGNED_BYTE, u8)
    }

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    return tex
}

function createFramebuffer(texture) {
    const fb = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0)
    return fb
}

function initSimData(imageData) {
    const data = new Float32Array(SIM_RES * SIM_RES * 4)
    for (let y = 0; y < SIM_RES; y++) {
        for (let x = 0; x < SIM_RES; x++) {
            const i = (y * SIM_RES + x) * 4
            if (imageData) {
                const r = imageData[i] / 255.0
                const g = imageData[i + 1] / 255.0
                data[i] = (r - 0.5) * 10.0
                data[i + 1] = (g - 0.5) * 10.0
            } else {
                const u = x / SIM_RES
                const v = y / SIM_RES
                data[i] = (u - 0.5) * 2.0
                data[i + 1] = (v - 0.5) * 2.0
            }
            data[i + 2] = 1.0
            data[i + 3] = 0.0
        }
    }
    return data
}

function initTransportData() {
    const data = new Float32Array(SIM_RES * SIM_RES * 4)
    for (let y = 0; y < SIM_RES; y++) {
        for (let x = 0; x < SIM_RES; x++) {
            const i = (y * SIM_RES + x) * 4
            data[i] = x / SIM_RES
            data[i + 1] = y / SIM_RES
            data[i + 2] = 0.0
            data[i + 3] = 0.0
        }
    }
    return data
}

let simData = initSimData()
let simTex0 = createFloatTexture(simData)
let simTex1 = createFloatTexture(simData)
let simFB0 = createFramebuffer(simTex0)
let simFB1 = createFramebuffer(simTex1)

let transData = initTransportData()
let transTex0 = createFloatTexture(transData)
let transTex1 = createFloatTexture(transData)
let transFB0 = createFramebuffer(transTex0)
let transFB1 = createFramebuffer(transTex1)

// ============== FULLSCREEN QUAD ==============

const quadBuffer = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1, 1, -1, -1, 1,
    -1, 1, 1, -1, 1, 1
]), gl.STATIC_DRAW)

function bindQuad(program) {
    gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
    const loc = gl.getAttribLocation(program, 'a_position')
    gl.enableVertexAttribArray(loc)
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0)
}

// ============== MEDIA UPLOAD ==============

const uploadPanel = document.querySelector('#upload-panel')

function seedSimFromSource(source) {
    const tempCanvas = document.createElement('canvas')
    tempCanvas.width = SIM_RES
    tempCanvas.height = SIM_RES
    const ctx = tempCanvas.getContext('2d')
    ctx.drawImage(source, 0, 0, SIM_RES, SIM_RES)
    const pixels = ctx.getImageData(0, 0, SIM_RES, SIM_RES).data
    resetSimulation(pixels)
}

const media = createMediaLoader(gl, {
    onLoad: (source) => seedSimFromSource(source),
})

// ============== CONTROLS ==============

const sliders = new SliderManager({
    viscosity: { selector: '#viscosity', default: 1.2 },
    force: { selector: '#force', default: 1.0 },
    obstacleSize: { selector: '#obstacle-size', default: 1.0 },
    speed: { selector: '#speed', default: 0.5 },
    density: { selector: '#density', default: 1 },
    harmonics: { selector: '#harmonics', default: 1 },
    feed: { selector: '#feed', default: 0.0367 },
    kill: { selector: '#kill', default: 0.0649 },
    metallic: { selector: '#metallic', default: 1.0 },
})

const mouse = new MouseTracker(canvas)
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// ============== EFFECT SWITCHING ==============

function switchEffect(name) {
    currentEffect = name

    // Update buttons
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })

    // Show/hide per-effect sliders
    document.querySelectorAll('#sliders label').forEach(label => {
        const isNS = label.classList.contains('slider-navier-stokes')
        const isPW = label.classList.contains('slider-poolwater')
        const isFF = label.classList.contains('slider-ferrofluid')
        if (name === 'navier-stokes') {
            label.classList.toggle('hidden', isPW || isFF)
        } else if (name === 'poolwater') {
            label.classList.toggle('hidden', isNS || isFF)
        } else {
            label.classList.toggle('hidden', isNS || isPW)
        }
    })

    // Show/hide upload panel (only for Navier-Stokes)
    uploadPanel.classList.toggle('hidden', name !== 'navier-stokes')

    // Set up pool water program if switching to it
    if (name === 'poolwater') {
        gl.useProgram(poolProgram)
        createFullscreenQuad(gl, poolProgram)
        gl.uniform2f(poolUniforms.resolution, canvas.width, canvas.height)
    }
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchEffect(btn.dataset.effect)
    })
})

// ============== RESET ==============

let frameCount = 0

function resetSimulation(imagePixels) {
    frameCount = 0
    const sd = initSimData(imagePixels)
    const td = initTransportData()

    gl.bindTexture(gl.TEXTURE_2D, simTex0)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, sd)
    gl.bindTexture(gl.TEXTURE_2D, simTex1)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, sd)

    gl.bindTexture(gl.TEXTURE_2D, transTex0)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, td)
    gl.bindTexture(gl.TEXTURE_2D, transTex1)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, SIM_RES, SIM_RES, 0, gl.RGBA, gl.FLOAT, td)
}

function resetFerro() {
    ferroData = initFerroData()
    ferroBuffer = 0
    gl.bindTexture(gl.TEXTURE_2D, ferroTex0)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, FERRO_RES, FERRO_RES, 0, gl.RGBA, gl.FLOAT, ferroData)
    gl.bindTexture(gl.TEXTURE_2D, ferroTex1)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, FERRO_RES, FERRO_RES, 0, gl.RGBA, gl.FLOAT, ferroData)
}

document.addEventListener('keydown', (e) => {
    if (e.key === ' ') {
        e.preventDefault()
        if (currentEffect === 'ferrofluid') resetFerro()
        else resetSimulation()
    }
    if (e.key === '1') switchEffect('navier-stokes')
    if (e.key === '2') switchEffect('poolwater')
    if (e.key === '3') switchEffect('ferrofluid')
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
}
window.addEventListener('resize', resize)
resize()

// Initialize slider visibility
switchEffect('navier-stokes')

// ============== RENDER LOOP ==============

let simBuffer = 0
let transBuffer = 0

function render(time) {
    const t = time * 0.001

    if (currentEffect === 'navier-stokes') {
        renderNavierStokes()
    } else if (currentEffect === 'ferrofluid') {
        renderFerrofluid(t)
    } else {
        renderPoolWater(t)
    }

    requestAnimationFrame(render)
}

function renderNavierStokes() {
    const simTextures = [simTex0, simTex1]
    const simFramebuffers = [simFB0, simFB1]
    const transTextures = [transTex0, transTex1]
    const transFramebuffers = [transFB0, transFB1]

    let simRead = simBuffer
    let simWrite = 1 - simBuffer
    let transRead = transBuffer
    let transWrite = 1 - transBuffer

    const mouseX = (mouse.x / canvas.width) * SIM_RES
    const mouseY = (mouse.y / canvas.height) * SIM_RES

    gl.viewport(0, 0, SIM_RES, SIM_RES)

    // Step 1: Fluid simulation
    gl.useProgram(simProgram)
    bindQuad(simProgram)

    gl.bindFramebuffer(gl.FRAMEBUFFER, simFramebuffers[simWrite])
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, simTextures[simRead])
    gl.uniform1i(simUniforms.state, 0)
    gl.uniform2f(simUniforms.resolution, SIM_RES, SIM_RES)
    gl.uniform2f(simUniforms.mouse, mouseX, mouseY)
    gl.uniform1f(simUniforms.mouseDown, mouse.isDown ? 1.0 : 0.0)
    gl.uniform1i(simUniforms.frame, frameCount)
    gl.uniform1f(simUniforms.viscosity, sliders.get('viscosity'))
    gl.uniform1f(simUniforms.speed, sliders.get('force'))
    gl.uniform1f(simUniforms.obstacleSize, sliders.get('obstacleSize'))
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    simRead = simWrite
    simWrite = 1 - simWrite

    // Step 2: Transport UV coordinates
    gl.useProgram(transportProgram)
    bindQuad(transportProgram)

    gl.bindFramebuffer(gl.FRAMEBUFFER, transFramebuffers[transWrite])
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, simTextures[simRead])
    gl.uniform1i(transportUniforms.state, 0)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, transTextures[transRead])
    gl.uniform1i(transportUniforms.transport, 1)
    gl.uniform2f(transportUniforms.resolution, SIM_RES, SIM_RES)
    gl.uniform1i(transportUniforms.frame, frameCount)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    transRead = transWrite
    transWrite = 1 - transWrite

    // Step 3: Display
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(displayProgram)
    bindQuad(displayProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, simTextures[simRead])
    gl.uniform1i(displayUniforms.state, 0)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, transTextures[transRead])
    gl.uniform1i(displayUniforms.transport, 1)
    gl.activeTexture(gl.TEXTURE2)
    if (media.texture) {
        media.updateVideoFrame()
        gl.bindTexture(gl.TEXTURE_2D, media.texture)
    }
    gl.uniform1i(displayUniforms.image, 2)
    gl.uniform2f(displayUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1i(displayUniforms.hasImage, media.hasMedia ? 1 : 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)

    simBuffer = simRead
    transBuffer = transRead
    frameCount++
}

function renderFerrofluid(t) {
    const ferroTextures = [ferroTex0, ferroTex1]
    const ferroFramebuffers = [ferroFB0, ferroFB1]

    let readIdx = ferroBuffer
    let writeIdx = 1 - ferroBuffer

    const mouseX = (mouse.x / canvas.width) * FERRO_RES
    const mouseY = (mouse.y / canvas.height) * FERRO_RES

    // Run multiple sim steps per frame for faster evolution
    gl.viewport(0, 0, FERRO_RES, FERRO_RES)
    gl.useProgram(ferroSimProgram)
    bindQuad(ferroSimProgram)

    gl.uniform2f(ferroSimUniforms.resolution, FERRO_RES, FERRO_RES)
    gl.uniform2f(ferroSimUniforms.mouse, mouseX, mouseY)
    gl.uniform1f(ferroSimUniforms.mouseDown, mouse.isDown ? 1.0 : 0.0)
    gl.uniform1f(ferroSimUniforms.feed, sliders.get('feed'))
    gl.uniform1f(ferroSimUniforms.kill, sliders.get('kill'))

    for (let i = 0; i < 8; i++) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, ferroFramebuffers[writeIdx])
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, ferroTextures[readIdx])
        gl.uniform1i(ferroSimUniforms.state, 0)
        gl.drawArrays(gl.TRIANGLES, 0, 6)

        const tmp = readIdx
        readIdx = writeIdx
        writeIdx = tmp
    }

    // Display pass
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(ferroDisplayProgram)
    bindQuad(ferroDisplayProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, ferroTextures[readIdx])
    gl.uniform1i(ferroDisplayUniforms.state, 0)
    gl.uniform2f(ferroDisplayUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(ferroDisplayUniforms.time, t)
    gl.uniform1f(ferroDisplayUniforms.metallic, sliders.get('metallic'))

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    ferroBuffer = readIdx
}

function renderPoolWater(t) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(poolProgram)
    createFullscreenQuad(gl, poolProgram)

    gl.uniform2f(poolUniforms.resolution, canvas.width, canvas.height)
    gl.uniform1f(poolUniforms.time, t)
    mouse.applyUniform(gl, poolUniforms.mouse)
    gl.uniform1f(poolUniforms.speed, sliders.get('speed'))
    gl.uniform1f(poolUniforms.density, sliders.get('density'))
    gl.uniform1f(poolUniforms.harmonics, sliders.get('harmonics'))

    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

requestAnimationFrame(render)

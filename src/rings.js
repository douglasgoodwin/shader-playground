import './rings.css'
import './source-link.js'
import { createProgram } from './webgl.js'
import { SliderManager } from './controls.js'
import { createMediaLoader } from './media-loader.js'
import { setupLoopRecording } from './loop-recording.js'

import ringsFrag from './shaders/rings/rings.glsl'

const MAX_RINGS = 8
const FRAME_FPS = 24
const RECORDING = { width: 1920, height: 1080 }

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, alpha: false })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

const vertSource = `
attribute vec2 a_position;
varying vec2 v_uv;
void main() {
    v_uv = a_position * 0.5 + 0.5;
    gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const program = createProgram(gl, vertSource, ringsFrag)
if (!program) throw new Error('Failed to create rings program')

const u = {
    texture:     gl.getUniformLocation(program, 'u_texture'),
    textureSize: gl.getUniformLocation(program, 'u_textureSize'),
    resolution:  gl.getUniformLocation(program, 'u_resolution'),
    hasTexture:  gl.getUniformLocation(program, 'u_hasTexture'),
    center:      gl.getUniformLocation(program, 'u_center'),
    phase:       gl.getUniformLocation(program, 'u_phase'),
    ringCount:   gl.getUniformLocation(program, 'u_ringCount'),
    turns:       gl.getUniformLocation(program, 'u_turns[0]'),
    inner:       gl.getUniformLocation(program, 'u_inner'),
    outer:       gl.getUniformLocation(program, 'u_outer'),
    spacing:     gl.getUniformLocation(program, 'u_spacing'),
    feather:     gl.getUniformLocation(program, 'u_feather'),
    spread:      gl.getUniformLocation(program, 'u_spread'),
    outsideMode: gl.getUniformLocation(program, 'u_outsideMode'),
    edgeMode:    gl.getUniformLocation(program, 'u_edgeMode'),
}

const quad = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quad)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  1, -1,  -1,  1,
    -1,  1,  1, -1,   1,  1,
]), gl.STATIC_DRAW)

gl.useProgram(program)
const posLoc = gl.getAttribLocation(program, 'a_position')
gl.enableVertexAttribArray(posLoc)
gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0)

// ============== SOURCE ==============

const loopReadout = document.querySelector('#loop-readout')
const loopLengthInput = document.querySelector('#loopLength')

let sourceDims = [1, 1]

const media = createMediaLoader(gl, {
    onLoad: (_element, size) => {
        sourceDims = [size.width || 1, size.height || 1]
        updateLoopReadout()
    },
})

// One pass of the source. A video defines its own loop; a still image (or
// nothing yet) falls back to the slider so the rings still turn.
function loopLength() {
    const v = media.videoSource
    if (v && v.duration && isFinite(v.duration) && v.duration > 0) return v.duration
    return parseFloat(loopLengthInput.value) || 4
}

function updateLoopReadout() {
    const v = media.videoSource
    const L = loopLength()
    loopLengthInput.disabled = !!v
    if (v) {
        loopReadout.textContent =
            `video loop ${L.toFixed(2)}s · ${Math.round(L * FRAME_FPS)} frames @ ${FRAME_FPS}fps`
    } else if (media.hasMedia) {
        loopReadout.textContent = `still image · loop set to ${L.toFixed(1)}s`
    } else {
        loopReadout.textContent = 'no source loaded'
    }
}

loopLengthInput.addEventListener('input', updateLoopReadout)

// ============== TURNS PER LOOP ==============

// Each ring turns a whole number of times per loop. Integers are what make
// the output loop: after one pass every ring is back at its start angle at
// the same instant the source video wraps.
const DEFAULT_TURNS = [-1, 2, 0, -3, 1, -2, 3, -1]
const turns = new Float32Array(MAX_RINGS)
DEFAULT_TURNS.forEach((t, i) => { turns[i] = t })

const turnsRows = document.querySelector('#turns-rows')
const turnInputs = []
const turnDirs = []

for (let i = 0; i < MAX_RINGS; i++) {
    const row = document.createElement('div')
    row.className = 'turn-row'

    const name = document.createElement('span')
    name.className = 'turn-name'
    name.textContent = `ring ${i + 1}`

    const input = document.createElement('input')
    input.type = 'number'
    input.step = '1'
    input.min = '-8'
    input.max = '8'
    input.value = String(turns[i])

    const dir = document.createElement('span')
    dir.className = 'turn-dir'

    input.addEventListener('input', () => {
        const n = Math.round(parseFloat(input.value))
        turns[i] = isFinite(n) ? n : 0
        updateTurnDir(i)
    })
    // Round on blur so a half-typed "-" or "1.5" settles to a whole turn.
    input.addEventListener('change', () => {
        input.value = String(turns[i])
        updateTurnDir(i)
    })

    row.append(name, input, dir)
    turnsRows.appendChild(row)
    turnInputs.push(input)
    turnDirs.push(dir)
}

function updateTurnDir(i) {
    const t = turns[i]
    turnDirs[i].textContent = t === 0 ? 'still' : (t > 0 ? '↻'.repeat(Math.min(Math.abs(t), 4)) : '↺'.repeat(Math.min(Math.abs(t), 4)))
}

function syncTurnRows() {
    const count = sliders.get('ringCount')
    turnsRows.childNodes.forEach((row, i) => {
        row.style.display = i < count ? 'flex' : 'none'
    })
}

function setTurns(values) {
    for (let i = 0; i < MAX_RINGS; i++) {
        turns[i] = values[i]
        turnInputs[i].value = String(values[i])
        updateTurnDir(i)
    }
}

document.querySelector('#shuffle-turns').addEventListener('click', () => {
    // Draw from a small signed set — big turn counts smear into motion blur
    // at 24fps, and 0 in the mix gives the eye somewhere to rest.
    const pool = [-3, -2, -1, 0, 1, 2, 3]
    setTurns(Array.from({ length: MAX_RINGS }, () => pool[Math.floor(Math.random() * pool.length)]))
})

document.querySelector('#zero-turns').addEventListener('click', () => {
    setTurns(new Array(MAX_RINGS).fill(0))
})

for (let i = 0; i < MAX_RINGS; i++) updateTurnDir(i)

// ============== CONTROLS ==============

const sliders = new SliderManager({
    ringCount: { selector: '#ringCount', default: 5 },
    inner:     { selector: '#inner',     default: 0 },
    outer:     { selector: '#outer',     default: 0.5 },
    spacing:   { selector: '#spacing',   default: 1 },
    feather:   { selector: '#feather',   default: 0 },
    spread:    { selector: '#spread',    default: 0 },
})

document.querySelector('#ringCount').addEventListener('input', syncTurnRows)
syncTurnRows()

const outsideSelect = document.querySelector('#outsideMode')
const edgeSelect = document.querySelector('#edgeMode')
const lockLoopCheckbox = document.querySelector('#lockLoop')

// ============== CENTER (drag on canvas) ==============

const center = { x: 0.5, y: 0.5 }
let dragging = false

function setCenterFromEvent(e) {
    const rect = canvas.getBoundingClientRect()
    center.x = (e.clientX - rect.left) / rect.width
    // v_uv has y up; pointer coords have y down.
    center.y = 1 - (e.clientY - rect.top) / rect.height
}

canvas.addEventListener('pointerdown', (e) => {
    dragging = true
    canvas.setPointerCapture(e.pointerId)
    setCenterFromEvent(e)
})
canvas.addEventListener('pointermove', (e) => {
    if (dragging) setCenterFromEvent(e)
})
canvas.addEventListener('pointerup', (e) => {
    dragging = false
    canvas.releasePointerCapture(e.pointerId)
})

// ============== RECORDING ==============

function turnsLabel() {
    const count = sliders.get('ringCount')
    const sig = Array.from(turns.slice(0, count))
        .map(t => (t < 0 ? `n${Math.abs(t)}` : `${t}`))
        .join('.')
    return `${count}r-${sig}`
}

const { frameRecorder } = setupLoopRecording(canvas, {
    ...RECORDING,
    fps: FRAME_FPS,
    getLoopLength: loopLength,
    isLoopLocked: () => lockLoopCheckbox.checked,
    getLabel: turnsLabel,
    renderFrame: () => renderFrame(),
    // Drive the video off virtual time instead of wall-clock playback, so the
    // exported sequence is frame-exact and reproducible.
    onBeforeFrame: (virtualTime) => media.seekVideoTo(virtualTime),
    onCaptureEnd: () => media.resumeVideo(),
})

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return
    if (e.key === 'c' || e.key === 'C') {
        center.x = 0.5
        center.y = 0.5
    }
})

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER ==============

const startTime = performance.now()

// 0..1 across one loop. During capture this comes from the recorder's
// virtual clock; live, from the video's own playhead so the rings stay
// locked to the footage even if playback stutters.
function phase() {
    const L = loopLength()
    if (frameRecorder.isCapturing()) return (frameRecorder.getTime() / L) % 1
    const v = media.videoSource
    if (v && v.duration && isFinite(v.duration) && v.duration > 0) {
        return (v.currentTime / L) % 1
    }
    return (((performance.now() - startTime) / 1000) / L) % 1
}

function renderFrame() {
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(program)

    if (media.hasMedia && media.texture) media.updateVideoFrame()

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, media.texture)
    gl.uniform1i(u.texture, 0)
    gl.uniform2f(u.textureSize, sourceDims[0], sourceDims[1])
    gl.uniform1i(u.hasTexture, media.hasMedia ? 1 : 0)

    gl.uniform2f(u.resolution, canvas.width, canvas.height)
    gl.uniform2f(u.center, center.x, center.y)
    gl.uniform1f(u.phase, phase())
    gl.uniform1i(u.ringCount, sliders.get('ringCount'))
    gl.uniform1fv(u.turns, turns)
    gl.uniform1f(u.inner, sliders.get('inner'))
    // Keep the stack non-degenerate if the two radius sliders cross.
    gl.uniform1f(u.outer, Math.max(sliders.get('outer'), sliders.get('inner') + 0.01))
    gl.uniform1f(u.spacing, sliders.get('spacing'))
    gl.uniform1f(u.feather, sliders.get('feather'))
    gl.uniform1f(u.spread, sliders.get('spread'))
    gl.uniform1i(u.outsideMode, parseInt(outsideSelect.value, 10))
    gl.uniform1i(u.edgeMode, parseInt(edgeSelect.value, 10))

    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

function loop() {
    if (!frameRecorder.isCapturing()) renderFrame()
    requestAnimationFrame(loop)
}

requestAnimationFrame(loop)
updateLoopReadout()

import './assembly.css'
import './source-link.js'
import { createProgram } from './webgl.js'
import { SliderManager } from './controls.js'
import { MediaLayer, wireDropZone } from './layer-loader.js'
import { setupLoopRecording } from './loop-recording.js'

import compositeFrag from './shaders/assembly/composite.glsl'

const SLOTS = 5
const FRAME_FPS = 24
const RECORDING = { width: 1920, height: 1080 }

// Starting keys: the primaries and secondaries that flat-color artwork
// tends to be built from. Every one is pickable from the map itself.
const DEFAULT_KEYS = [
    [1.0, 0.0, 0.0],
    [0.0, 0.4, 1.0],
    [1.0, 0.85, 0.0],
    [0.0, 0.75, 0.3],
    [0.9, 0.0, 0.9],
]

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

const program = createProgram(gl, vertSource, compositeFrag)
if (!program) throw new Error('Failed to create assembly program')

const u = {
    map:        gl.getUniformLocation(program, 'u_map'),
    mapSize:    gl.getUniformLocation(program, 'u_mapSize'),
    hasMap:     gl.getUniformLocation(program, 'u_hasMap'),
    sizes:      gl.getUniformLocation(program, 'u_sizes[0]'),
    has:        gl.getUniformLocation(program, 'u_has[0]'),
    keys:       gl.getUniformLocation(program, 'u_keys[0]'),
    matchKeys:  gl.getUniformLocation(program, 'u_matchKeys[0]'),
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    slotCount:  gl.getUniformLocation(program, 'u_slotCount'),
    tolerance:  gl.getUniformLocation(program, 'u_tolerance'),
    softness:   gl.getUniformLocation(program, 'u_softness'),
    chromaOnly: gl.getUniformLocation(program, 'u_chromaOnly'),
    unmatched:  gl.getUniformLocation(program, 'u_unmatched'),
    scale:      gl.getUniformLocation(program, 'u_scale'),
    preview:    gl.getUniformLocation(program, 'u_preview'),
    videos:     Array.from({ length: SLOTS }, (_, i) =>
        gl.getUniformLocation(program, `u_v${i}`)),
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

// ============== LAYERS ==============

const mapLayer = new MediaLayer(gl, 'map')
const slots = Array.from({ length: SLOTS }, (_, i) => new MediaLayer(gl, `slot-${i}`))
const allLayers = [mapLayer, ...slots]

// Name the zone after whatever landed in it, and re-derive the loop from the
// longest source now loaded.
function onLayerLoad(layer, file, zone) {
    zone.firstChild.textContent = file.name
    syncLoopSlider()
}

wireDropZone(
    mapLayer,
    document.querySelector('#map-zone'),
    document.querySelector('#map-input'),
    (layer, file) => onLayerLoad(layer, file, document.querySelector('#map-zone')),
)

// ============== SLOT ROWS ==============

const keys = new Float32Array(SLOTS * 3)
DEFAULT_KEYS.forEach((k, i) => keys.set(k, i * 3))

const pickHint = document.querySelector('#pick-hint')
const slotRows = document.querySelector('#slot-rows')
const colorInputs = []
const pickButtons = []
let armedSlot = -1

function toHex(i) {
    const c = [keys[i * 3], keys[i * 3 + 1], keys[i * 3 + 2]]
    return '#' + c.map(v => Math.round(Math.min(Math.max(v, 0), 1) * 255)
        .toString(16).padStart(2, '0')).join('')
}

for (let i = 0; i < SLOTS; i++) {
    const row = document.createElement('div')
    row.className = 'slot-row'

    const color = document.createElement('input')
    color.type = 'color'
    color.value = toHex(i)
    color.title = `Key color for source ${i + 1}`
    color.addEventListener('input', () => {
        const hex = color.value
        keys[i * 3]     = parseInt(hex.slice(1, 3), 16) / 255
        keys[i * 3 + 1] = parseInt(hex.slice(3, 5), 16) / 255
        keys[i * 3 + 2] = parseInt(hex.slice(5, 7), 16) / 255
    })

    const pick = document.createElement('button')
    pick.type = 'button'
    pick.className = 'eyedropper'
    pick.textContent = '⌖'
    pick.title = 'Pick this key color from the frame'
    pick.addEventListener('click', () => armPicker(i))

    const zone = document.createElement('div')
    zone.className = 'drop-zone slot-zone'
    zone.id = `slot-${i}-zone`
    zone.appendChild(document.createTextNode(`source ${i + 1}`))

    const input = document.createElement('input')
    input.type = 'file'
    input.accept = 'image/*,video/*'
    input.style.display = 'none'
    zone.appendChild(input)

    row.append(color, pick, zone)
    slotRows.appendChild(row)

    colorInputs.push(color)
    pickButtons.push(pick)
    wireDropZone(slots[i], zone, input, (layer, file) => onLayerLoad(layer, file, zone))
}

function armPicker(i) {
    armedSlot = armedSlot === i ? -1 : i
    pickButtons.forEach((b, j) => b.classList.toggle('picking', j === armedSlot))
    pickHint.classList.toggle('armed', armedSlot >= 0)
    pickHint.textContent = armedSlot >= 0
        ? `Click the color in the frame that should play source ${armedSlot + 1}.`
        : "Click a slot's eyedropper, then click that color in the frame."
}

// ============== EYEDROPPER ==============

// Read the map's own pixels rather than the composited canvas, so picking
// works even when that area is already filled by a video.
const readCanvas = document.createElement('canvas')
const readCtx = readCanvas.getContext('2d', { willReadFrequently: true })

// Mirror of the shader's coverUV, so a click maps to the same texel the
// shader would have sampled.
function coverUV(uv, texW, texH, screenW, screenH) {
    if (texW < 1.5 || texH < 1.5) return uv
    const screenAspect = screenW / screenH
    const texAspect = texW / texH
    let sx = 1, sy = 1
    if (texAspect > screenAspect) sx = screenAspect / texAspect
    else sy = texAspect / screenAspect
    return [(uv[0] - 0.5) * sx + 0.5, (uv[1] - 0.5) * sy + 0.5]
}

canvas.addEventListener('click', (e) => {
    if (armedSlot < 0) return
    if (!mapLayer.loaded || !mapLayer.element) {
        alert('Load the organizing media first.')
        return
    }

    const rect = canvas.getBoundingClientRect()
    const screenUV = [
        (e.clientX - rect.left) / rect.width,
        1 - (e.clientY - rect.top) / rect.height, // v_uv has y up
    ]
    const [tu, tv] = coverUV(screenUV, mapLayer.width, mapLayer.height, canvas.width, canvas.height)
    if (tu < 0 || tu > 1 || tv < 0 || tv > 1) return // outside the cover-fit map

    readCanvas.width = mapLayer.width
    readCanvas.height = mapLayer.height
    readCtx.drawImage(mapLayer.element, 0, 0, mapLayer.width, mapLayer.height)

    const px = Math.min(mapLayer.width - 1, Math.max(0, Math.floor(tu * mapLayer.width)))
    // The texture was uploaded flipped, so texture v maps to the bottom-up row.
    const py = Math.min(mapLayer.height - 1, Math.max(0, Math.floor((1 - tv) * mapLayer.height)))
    const d = readCtx.getImageData(px, py, 1, 1).data

    const i = armedSlot
    keys[i * 3]     = d[0] / 255
    keys[i * 3 + 1] = d[1] / 255
    keys[i * 3 + 2] = d[2] / 255
    colorInputs[i].value = toHex(i)
    armPicker(-1)
})

// ============== CONTROLS ==============

const sliders = new SliderManager({
    slotCount: { selector: '#slotCount', default: 5 },
    tolerance: { selector: '#tolerance', default: 0.25 },
    softness:  { selector: '#softness',  default: 0.02 },
    scale:     { selector: '#scale',     default: 1 },
})

const loopLengthInput = document.querySelector('#loopLength')
const unmatchedSelect = document.querySelector('#unmatched')
const chromaCheckbox = document.querySelector('#chromaOnly')
const previewCheckbox = document.querySelector('#preview')
const lockLoopCheckbox = document.querySelector('#lockLoop')

// The rings page emits equal-length loops, so the longest loaded source is
// the natural loop for the assembly. Still overridable by hand.
function syncLoopSlider() {
    let longest = 0
    for (const layer of allLayers) {
        const v = layer.videoSource
        if (v && isFinite(v.duration) && v.duration > longest) longest = v.duration
    }
    if (longest > 0) {
        loopLengthInput.value = Math.min(Math.max(longest, 1), 60).toFixed(1)
    }
}

function loopLength() {
    return parseFloat(loopLengthInput.value) || 4
}

// ============== RECORDING ==============

const { frameRecorder } = setupLoopRecording(canvas, {
    ...RECORDING,
    fps: FRAME_FPS,
    getLoopLength: loopLength,
    isLoopLocked: () => lockLoopCheckbox.checked,
    getLabel: () => `${sliders.get('slotCount')}up`,
    renderFrame: () => renderFrame(),
    // Every source has to land on the same virtual frame, so seek all six
    // together rather than letting them drift on their own playback clocks.
    onBeforeFrame: (virtualTime) =>
        Promise.all(allLayers.map(l => l.seekTo(virtualTime))),
    onCaptureEnd: () => allLayers.forEach(l => l.resume()),
})

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return
    if (e.key === 'v' || e.key === 'V') previewCheckbox.checked = !previewCheckbox.checked
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

const sizes = new Float32Array(SLOTS * 2)
const has = new Float32Array(SLOTS)
const matchKeys = new Float32Array(SLOTS * 3)

// The keys are constant across the frame, so normalize them here rather than
// per fragment. Kept separate from u_keys, which stays in display space for
// the flat swatch an unloaded slot draws.
function updateMatchKeys() {
    const chroma = chromaCheckbox.checked
    for (let i = 0; i < SLOTS; i++) {
        const r = keys[i * 3], g = keys[i * 3 + 1], b = keys[i * 3 + 2]
        const peak = chroma ? Math.max(r, g, b, 0.02) : 1
        matchKeys[i * 3]     = r / peak
        matchKeys[i * 3 + 1] = g / peak
        matchKeys[i * 3 + 2] = b / peak
    }
}

function renderFrame() {
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(program)

    mapLayer.bindTo(0, u.map)
    for (let i = 0; i < SLOTS; i++) {
        slots[i].bindTo(i + 1, u.videos[i])
        sizes[i * 2] = slots[i].width
        sizes[i * 2 + 1] = slots[i].height
        has[i] = slots[i].loaded ? 1 : 0
    }

    gl.uniform2f(u.mapSize, mapLayer.width, mapLayer.height)
    gl.uniform1i(u.hasMap, mapLayer.loaded ? 1 : 0)
    gl.uniform2fv(u.sizes, sizes)
    gl.uniform1fv(u.has, has)
    updateMatchKeys()
    gl.uniform3fv(u.keys, keys)
    gl.uniform3fv(u.matchKeys, matchKeys)
    gl.uniform2f(u.resolution, canvas.width, canvas.height)
    gl.uniform1i(u.slotCount, sliders.get('slotCount'))
    gl.uniform1f(u.tolerance, sliders.get('tolerance'))
    gl.uniform1f(u.softness, sliders.get('softness'))
    gl.uniform1f(u.scale, sliders.get('scale'))
    gl.uniform1i(u.chromaOnly, chromaCheckbox.checked ? 1 : 0)
    gl.uniform1i(u.unmatched, parseInt(unmatchedSelect.value, 10))
    gl.uniform1i(u.preview, previewCheckbox.checked ? 1 : 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
}

function loop() {
    if (!frameRecorder.isCapturing()) renderFrame()
    requestAnimationFrame(loop)
}

requestAnimationFrame(loop)

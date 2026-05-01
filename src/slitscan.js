import './kaleidoscope.css'
import './source-link.js'
import { createProgram } from './webgl.js'
import { setupRecording, SliderManager } from './controls.js'
import { createMediaLoader } from './media-loader.js'
import { FrameRecorder } from './frame-recorder.js'

import feedbackFrag from './shaders/slitscan/feedback.glsl'
import presentFrag from './shaders/pingpong/present.glsl'

const RECORDING = { width: 1920, height: 1080 }
const FRAME_FPS = 24

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

const feedbackProgram = createProgram(gl, vertSource, feedbackFrag)
const presentProgram  = createProgram(gl, vertSource, presentFrag)

const feedbackU = {
    prev:        gl.getUniformLocation(feedbackProgram, 'u_prev'),
    texture:     gl.getUniformLocation(feedbackProgram, 'u_texture'),
    textureSize: gl.getUniformLocation(feedbackProgram, 'u_textureSize'),
    hasTexture:  gl.getUniformLocation(feedbackProgram, 'u_hasTexture'),
    resolution:  gl.getUniformLocation(feedbackProgram, 'u_resolution'),
    time:        gl.getUniformLocation(feedbackProgram, 'u_time'),
    slitPos:     gl.getUniformLocation(feedbackProgram, 'u_slitPos'),
    speed:       gl.getUniformLocation(feedbackProgram, 'u_speed'),
    decay:       gl.getUniformLocation(feedbackProgram, 'u_decay'),
    direction:   gl.getUniformLocation(feedbackProgram, 'u_direction'),
    vertical:    gl.getUniformLocation(feedbackProgram, 'u_vertical'),
}

const presentU = {
    tex: gl.getUniformLocation(presentProgram, 'u_tex'),
}

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

let pingPong = null
let read, write

function rebuildFBOs() {
    if (pingPong) {
        for (const p of pingPong) {
            gl.deleteTexture(p.tex)
            gl.deleteFramebuffer(p.fb)
        }
    }
    pingPong = [createFBO(canvas.width, canvas.height), createFBO(canvas.width, canvas.height)]
    read = pingPong[0]
    write = pingPong[1]
    clear()
}

function clear() {
    for (const p of pingPong) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, p.fb)
        gl.clearColor(0, 0, 0, 1)
        gl.clear(gl.COLOR_BUFFER_BIT)
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
}

let textureSize = { width: 1, height: 1 }
const media = createMediaLoader(gl, {
    onLoad: (_source, size) => { textureSize = size },
})

const sliders = new SliderManager({
    slitPos:  { selector: '#slitPos',  default: 0.5 },
    speed:    { selector: '#speed',    default: 2 },
    decay:    { selector: '#decay',    default: 0 },
    period:   { selector: '#period',   default: 30 },
    vertical: { selector: '#vertical', default: false, type: 'checkbox' },
    reverse:  { selector: '#reverse',  default: false, type: 'checkbox' },
    sweep:    { selector: '#sweep',    default: false, type: 'checkbox' },
})

let sweepStart = 0
let sweepWasOn = false

const canvasRecorder = setupRecording(canvas, { keyboardShortcut: 'r', ...RECORDING })

const frameBtn = document.querySelector('#frame-btn')
const frameCounter = document.querySelector('#frame-counter')
const frameRecorder = new FrameRecorder(canvas, {
    ...RECORDING,
    fps: FRAME_FPS,
    renderFrame: () => renderFrame(),
    // Slit-scan needs the feedback FBO to fill before saved frames are
    // useful. Speed gets rescaled at capture time (recording-W / preview-W)
    // so a full fill takes the same *number of frames* it would at the
    // current preview size: previewDim / sliderSpeed. Add a small tail
    // so the leading edge has settled.
    getPrimeFrames: () => {
        const speed = Math.max(1, sliders.get('speed'))
        const vertical = sliders.get('vertical')
        const previewDim = vertical ? canvas.height : canvas.width
        return Math.ceil(previewDim / speed) + 24
    },
    onStateChange: (capturing) => {
        if (frameBtn) frameBtn.classList.toggle('recording', capturing)
        if (frameCounter) {
            frameCounter.classList.toggle('hidden', !capturing)
            frameCounter.textContent = capturing ? 'priming…' : ''
        }
    },
    onPrimeProgress: (n, total) => {
        if (frameCounter) {
            const pct = Math.floor((n / total) * 100)
            frameCounter.textContent = `priming ${n}/${total} (${pct}%)`
        }
    },
    onProgress: (n) => {
        if (frameCounter) {
            const seconds = (n / FRAME_FPS).toFixed(2)
            frameCounter.textContent = `frame ${n} · ${seconds}s`
        }
    },
})
if (frameBtn) frameBtn.addEventListener('click', () => frameRecorder.toggle())

const formatSelect = document.querySelector('#format')
if (formatSelect) {
    formatSelect.addEventListener('change', () => {
        const [w, h] = formatSelect.value.split('x').map(Number)
        canvasRecorder.recordingWidth = w
        canvasRecorder.recordingHeight = h
        frameRecorder.recordingWidth = w
        frameRecorder.recordingHeight = h
    })
}

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === ' ') {
        e.preventDefault()
        clear()
    }
    if (e.key === 'p' || e.key === 'P') frameRecorder.toggle()
})

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    rebuildFBOs()
}
window.addEventListener('resize', resize)
resize()

const startTime = performance.now()

function getTime() {
    if (frameRecorder.isCapturing()) return frameRecorder.getTime()
    return (performance.now() - startTime) / 1000
}

function renderFrame() {
    // The recorder kicks the canvas to RECORDING dims without firing a
    // window resize, so reconcile FBO size to canvas size each frame.
    if (!read || read.width !== canvas.width || read.height !== canvas.height) {
        rebuildFBOs()
    }

    const t = getTime()

    const sliderSpeed = sliders.get('speed')
    const decay     = sliders.get('decay')
    const period    = sliders.get('period')
    const vertical  = sliders.get('vertical')
    const reverse   = sliders.get('reverse')
    const sweep     = sliders.get('sweep')
    const direction = reverse ? -1 : 1

    // Speed is in absolute pixels/frame, but the canvas is much wider
    // during capture (3888 px) than in preview. Without rescaling, each
    // slit stamp would occupy a smaller fraction of the canvas during
    // capture and the recording would look denser/narrower than preview.
    // Scale by recording-width / preview-width so the visual character
    // of stamps matches what the user sees in preview.
    const speed = frameRecorder.isCapturing()
        ? sliderSpeed * (vertical
            ? canvas.height / frameRecorder.originalHeight
            : canvas.width  / frameRecorder.originalWidth)
        : sliderSpeed

    if (sweep && !sweepWasOn) sweepStart = t
    sweepWasOn = sweep
    // Triangle wave 0 → 1 → 0 over `period` seconds (full cycle = 2 * period)
    const sweepPhase = period > 0 ? ((t - sweepStart) / period) % 2 : 0
    const slitPos = sweep ? Math.abs(sweepPhase - 1) : sliders.get('slitPos')

    // --- Pass 1: feedback → write FBO ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, write.fb)
    gl.viewport(0, 0, write.width, write.height)

    gl.useProgram(feedbackProgram)
    bindQuad(feedbackProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, read.tex)
    gl.uniform1i(feedbackU.prev, 0)

    gl.activeTexture(gl.TEXTURE1)
    if (media.hasMedia && media.texture) {
        media.updateVideoFrame()
        gl.bindTexture(gl.TEXTURE_2D, media.texture)
    }
    gl.uniform1i(feedbackU.texture, 1)
    gl.uniform1i(feedbackU.hasTexture, media.hasMedia ? 1 : 0)
    gl.uniform2f(feedbackU.textureSize, textureSize.width, textureSize.height)

    gl.uniform2f(feedbackU.resolution, write.width, write.height)
    gl.uniform1f(feedbackU.time, t)
    gl.uniform1f(feedbackU.slitPos, slitPos)
    gl.uniform1f(feedbackU.speed, speed)
    gl.uniform1f(feedbackU.decay, decay)
    gl.uniform1f(feedbackU.direction, direction)
    gl.uniform1f(feedbackU.vertical, vertical ? 1 : 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // --- Pass 2: present → screen ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(presentProgram)
    bindQuad(presentProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, write.tex)
    gl.uniform1i(presentU.tex, 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    const tmp = read
    read = write
    write = tmp
}

function loop() {
    // During PNG capture, the FrameRecorder owns the render schedule
    // and drives renderFrame() with virtual time. Skip the live render
    // so the canvas isn't trampled between capture/save.
    if (!frameRecorder.isCapturing()) renderFrame()
    requestAnimationFrame(loop)
}

requestAnimationFrame(loop)

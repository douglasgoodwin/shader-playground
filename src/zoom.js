import './zoom.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording } from './controls.js'
import { createMediaLoader } from './media-loader.js'
import vertexShader from './shaders/vertex.glsl'
import videoShader from './shaders/zoom/video.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// ── Shader program ─────────────────────────────────────────────
const prog = createProgram(gl, vertexShader, videoShader)
const loc = prog ? {
    resolution: gl.getUniformLocation(prog, 'u_resolution'),
    videoSize:  gl.getUniformLocation(prog, 'u_videoSize'),
    texA:       gl.getUniformLocation(prog, 'u_texA'),
    texB:       gl.getUniformLocation(prog, 'u_texB'),
    progress:   gl.getUniformLocation(prog, 'u_progress'),
} : null

gl.useProgram(prog)
createFullscreenQuad(gl, prog)

// ── Textures (ping-pong) ───────────────────────────────────────
function createTex() {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE,
        new Uint8Array([0, 0, 0, 255]))
    return tex
}

const texA = createTex()
const texB = createTex()

// ── State ──────────────────────────────────────────────────────
let sourceVideo = null      // <video> element (webcam or file)
let webcamStream = null
let ready = false
let currentTexIsA = true    // which tex is "current" (displayed at 1x when idle)
let videoWidth = 1, videoHeight = 1

// Transition state
let transitioning = false
let transitionStart = 0
const TRANSITION_DURATION = 0.6  // seconds — fast like Google Maps

const recorder = setupRecording(canvas, { keyboardShortcut: null })
const hint = document.getElementById('hint')
const mediaPanel = document.getElementById('media-controls')

// ── Capture a frame from the video source into a texture ───────
function capture(tex) {
    if (!sourceVideo) return
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false)
    gl.bindTexture(gl.TEXTURE_2D, tex)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, sourceVideo)
}

// ── Get the "current" and "next" textures ──────────────────────
function currentTex() { return currentTexIsA ? texA : texB }
function nextTex()    { return currentTexIsA ? texB : texA }

// ── Click to zoom ──────────────────────────────────────────────
canvas.addEventListener('click', (e) => {
    if (!ready || transitioning) return
    // Ignore clicks on UI elements
    if (e.target !== canvas) return

    // Capture the next frame into the "next" texture
    capture(nextTex())

    // Start the transition
    transitioning = true
    transitionStart = performance.now() / 1000
})

// ── Webcam ─────────────────────────────────────────────────────
async function startWebcam() {
    stopWebcam()
    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: { width: { ideal: 1920 }, height: { ideal: 1080 }, facingMode: 'environment' }
        })
        webcamStream = stream
        const video = document.createElement('video')
        video.playsInline = true
        video.muted = true
        video.srcObject = stream
        await video.play()

        sourceVideo = video
        videoWidth = video.videoWidth
        videoHeight = video.videoHeight
        ready = true
        capture(currentTex())
        hint.classList.remove('hidden')
        mediaPanel.style.display = 'none'
    } catch (e) {
        console.error('Webcam access failed:', e)
    }
}

function stopWebcam() {
    if (webcamStream) {
        webcamStream.getTracks().forEach(t => t.stop())
        webcamStream = null
    }
}

// ── Video file loading ─────────────────────────────────────────
const media = createMediaLoader(gl, {
    onLoad(source) {
        if (!media.videoSource) return
        sourceVideo = media.videoSource
        videoWidth = sourceVideo.videoWidth
        videoHeight = sourceVideo.videoHeight
        ready = true
        currentTexIsA = true
        capture(currentTex())
        hint.classList.remove('hidden')
    },
})

// ── Source switching ────────────────────────────────────────────
function switchSource(name) {
    ready = false
    transitioning = false
    currentTexIsA = true
    hint.classList.add('hidden')

    if (name === 'webcam') {
        mediaPanel.style.display = 'none'
        startWebcam()
    } else {
        stopWebcam()
        sourceVideo = null
        mediaPanel.style.display = ''
        // If a video is already loaded, re-activate it
        if (media.videoSource) {
            sourceVideo = media.videoSource
            ready = true
            capture(currentTex())
            hint.classList.remove('hidden')
        }
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.source === name)
    })
}

// ── UI wiring ──────────────────────────────────────────────────
document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchSource(btn.dataset.source)
    })
})

const keyMap = { '1': 'video', '2': 'webcam' }
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (keyMap[e.key]) switchSource(keyMap[e.key])
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// ── Resize ─────────────────────────────────────────────────────
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
    if (loc.resolution) gl.uniform2f(loc.resolution, canvas.width, canvas.height)
}
window.addEventListener('resize', resize)
resize()

// ── Render loop ────────────────────────────────────────────────
function render(time) {
    const t = time * 0.001

    let progress = 0

    if (transitioning) {
        const elapsed = t - transitionStart
        progress = Math.min(elapsed / TRANSITION_DURATION, 1.0)

        if (progress >= 1.0) {
            // Transition complete — swap textures, back to idle
            currentTexIsA = !currentTexIsA
            transitioning = false
            progress = 0
        }
    }

    // Bind textures: slot 0 = current (being zoomed), slot 1 = next (sharp)
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, currentTex())
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, nextTex())

    gl.uniform1i(loc.texA, 0)
    gl.uniform1i(loc.texB, 1)
    gl.uniform1f(loc.progress, progress)
    gl.uniform2f(loc.resolution, canvas.width, canvas.height)
    gl.uniform2f(loc.videoSize, videoWidth, videoHeight)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

// Start with video mode (show drop zone, no webcam by default)
mediaPanel.style.display = ''
requestAnimationFrame(render)

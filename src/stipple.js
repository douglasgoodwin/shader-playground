import './style.css'
import './source-link.js'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording } from './controls.js'
import { createMediaLoader } from './media-loader.js'
import vertexShader from './shaders/vertex.glsl'
import stippleShader from './shaders/scribble/stipple.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Create shader program
const program = createProgram(gl, vertexShader, stippleShader)
if (!program) {
    throw new Error('Failed to create shader program')
}

gl.useProgram(program)
createFullscreenQuad(gl, program)

// Get uniform locations
const uniforms = {
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    time: gl.getUniformLocation(program, 'u_time'),
    video: gl.getUniformLocation(program, 'u_video'),
    videoSize: gl.getUniformLocation(program, 'u_videoSize'),
    dotDensity: gl.getUniformLocation(program, 'u_dotDensity'),
    dotScale: gl.getUniformLocation(program, 'u_dotScale'),
    contrast: gl.getUniformLocation(program, 'u_contrast'),
    showLines: gl.getUniformLocation(program, 'u_showLines'),
    invert: gl.getUniformLocation(program, 'u_invert'),
}

// Slider parameters (including checkboxes)
const sliders = new SliderManager({
    density:   { selector: '#density',   default: 1.0, uniform: 'dotDensity' },
    dotScale:  { selector: '#dotScale',  default: 1.0 },
    contrast:  { selector: '#contrast',  default: 1.5 },
    showLines: { selector: '#showLines', default: false, type: 'checkbox' },
    invert:    { selector: '#invert',    default: false, type: 'checkbox' },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// Webcam state (kept separate from media-loader)
let webcamTexture = null
let webcamElement = null
let webcamReady = false
let videoSize = { width: 640, height: 480 }

// Upload media via shared loader
let currentMode = 'webcam'
const media = createMediaLoader(gl, {
    onLoad: (source, size) => { videoSize = size },
})

// UI Elements
const modeSelector = document.querySelector('#mode-selector')
const uploadControls = document.querySelector('#upload-controls')
const webcamStatus = document.querySelector('#webcam-status')

function createWebcamTexture() {
    if (webcamTexture) gl.deleteTexture(webcamTexture)
    webcamTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, webcamTexture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
}

async function initWebcam() {
    webcamStatus.classList.remove('hidden')
    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: 'user' }
        })
        webcamElement = document.createElement('video')
        webcamElement.srcObject = stream
        webcamElement.playsInline = true
        webcamElement.muted = true
        await webcamElement.play()
        videoSize = { width: webcamElement.videoWidth, height: webcamElement.videoHeight }
        createWebcamTexture()
        webcamReady = true
        webcamStatus.classList.add('hidden')
    } catch (err) {
        console.error('Webcam error:', err)
        webcamStatus.innerHTML = '<p>Could not access webcam.</p>'
    }
}

function switchMode(mode) {
    currentMode = mode
    modeSelector.querySelectorAll('button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === mode)
    })
    uploadControls.style.display = 'none'
    webcamStatus.classList.add('hidden')

    if (mode === 'webcam') {
        if (!webcamReady) initWebcam()
    } else if (mode === 'upload') {
        uploadControls.style.display = 'flex'
        if (!media.hasMedia) uploadControls.classList.remove('loaded')
    }
}

// Event listeners
modeSelector.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => switchMode(btn.dataset.mode))
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchMode('webcam')
    if (e.key === '2') switchMode('upload')
    if (e.key === 'l' || e.key === 'L') {
        sliders.set('showLines', !sliders.get('showLines'))
    }
    if (e.key === 'i' || e.key === 'I') {
        sliders.set('invert', !sliders.get('invert'))
    }
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// Resize
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.uniform2f(uniforms.resolution, canvas.width, canvas.height)
}

window.addEventListener('resize', resize)
resize()

// Initialize
switchMode('webcam')

// Render loop
function render(time) {
    const t = time * 0.001

    // Update texture from live sources
    if (currentMode === 'webcam' && webcamReady && webcamElement && webcamElement.readyState >= 2) {
        gl.bindTexture(gl.TEXTURE_2D, webcamTexture)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, webcamElement)
    } else if (currentMode === 'upload') {
        media.updateVideoFrame()
    }

    // Only render if we have a source
    const hasSource = (currentMode === 'webcam' && webcamReady) || (currentMode === 'upload' && media.hasMedia)
    if (hasSource) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, currentMode === 'webcam' ? webcamTexture : media.texture)
        gl.uniform1i(uniforms.video, 0)

        gl.uniform1f(uniforms.time, t)
        gl.uniform2f(uniforms.videoSize, videoSize.width, videoSize.height)
        sliders.applyUniforms(gl, uniforms)

        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

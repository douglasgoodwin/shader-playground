import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import stippleShader from './shaders/stipple.glsl'

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

// Texture state
let videoTexture = null
let videoElement = null
let videoSize = { width: 640, height: 480 }
let currentMode = 'webcam'
let hasTexture = false
let webcamReady = false
let webcamElement = null

// UI Elements
const modeSelector = document.querySelector('#mode-selector')
const uploadControls = document.querySelector('#upload-controls')
const webcamStatus = document.querySelector('#webcam-status')
const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const loadingEl = document.querySelector('#loading')

// Create video texture
function createVideoTexture() {
    if (videoTexture) {
        gl.deleteTexture(videoTexture)
    }
    videoTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    return videoTexture
}

// Initialize webcam
async function initWebcam() {
    webcamStatus.classList.remove('hidden')

    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: {
                width: { ideal: 1280 },
                height: { ideal: 720 },
                facingMode: 'user'
            }
        })

        webcamElement = document.createElement('video')
        webcamElement.srcObject = stream
        webcamElement.playsInline = true
        webcamElement.muted = true

        await webcamElement.play()

        videoSize.width = webcamElement.videoWidth
        videoSize.height = webcamElement.videoHeight

        createVideoTexture()
        webcamReady = true
        webcamStatus.classList.add('hidden')
    } catch (err) {
        console.error('Webcam error:', err)
        webcamStatus.innerHTML = '<p>Could not access webcam.</p>'
    }
}

// Update texture from webcam
function updateWebcamTexture() {
    if (!webcamReady || !webcamElement || webcamElement.readyState < 2) return

    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, webcamElement)
}

// Load a video file and use it as the texture source
function loadVideoFile(file) {
    loadingEl.classList.remove('hidden')

    const url = URL.createObjectURL(file)
    const video = document.createElement('video')
    video.src = url
    video.loop = true
    video.muted = true
    video.playsInline = true

    video.addEventListener('loadeddata', () => {
        videoElement = video
        videoSize = { width: video.videoWidth, height: video.videoHeight }
        createVideoTexture()
        hasTexture = true
        loadingEl.classList.add('hidden')
        uploadControls.classList.add('loaded')
        video.play()
    })

    video.addEventListener('error', () => {
        alert('Failed to load video')
        loadingEl.classList.add('hidden')
        URL.revokeObjectURL(url)
    })
}

// Create texture from image (static)
function createTextureFromImage(image) {
    videoElement = null
    createVideoTexture()
    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)

    videoSize.width = image.width
    videoSize.height = image.height
    hasTexture = true
    uploadControls.classList.add('loaded')
}

// Load file (image or video)
function loadFile(file) {
    if (file.type.startsWith('video/')) {
        loadVideoFile(file)
        return
    }
    if (!file.type.startsWith('image/')) {
        alert('Please select an image or video file')
        return
    }

    loadingEl.classList.remove('hidden')
    const reader = new FileReader()

    reader.onload = (e) => {
        const img = new Image()
        img.onload = () => {
            createTextureFromImage(img)
            loadingEl.classList.add('hidden')
        }
        img.onerror = () => {
            alert('Failed to load image')
            loadingEl.classList.add('hidden')
        }
        img.src = e.target.result
    }

    reader.readAsDataURL(file)
}

// Load image from URL
function loadImageFromURL(url) {
    if (!url) return

    loadingEl.classList.remove('hidden')

    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
        createTextureFromImage(img)
        loadingEl.classList.add('hidden')
    }
    img.onerror = () => {
        alert('Failed to load image. The URL may not allow cross-origin requests.')
        loadingEl.classList.add('hidden')
    }
    img.src = url
}

// Mode switching
function switchMode(mode) {
    currentMode = mode

    modeSelector.querySelectorAll('button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === mode)
    })

    uploadControls.style.display = 'none'
    webcamStatus.classList.add('hidden')

    if (mode === 'webcam') {
        if (!webcamReady) {
            initWebcam()
        }
    } else if (mode === 'upload') {
        uploadControls.style.display = 'flex'
        if (!hasTexture) {
            uploadControls.classList.remove('loaded')
        }
    }
}

// Event listeners
modeSelector.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => switchMode(btn.dataset.mode))
})

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) loadFile(file)
})

dropZone.addEventListener('click', () => fileInput.click())

dropZone.addEventListener('dragover', (e) => {
    e.preventDefault()
    dropZone.classList.add('dragover')
})

dropZone.addEventListener('dragleave', () => {
    dropZone.classList.remove('dragover')
})

dropZone.addEventListener('drop', (e) => {
    e.preventDefault()
    dropZone.classList.remove('dragover')
    const file = e.dataTransfer.files[0]
    if (file) loadFile(file)
})

loadUrlBtn.addEventListener('click', () => loadImageFromURL(urlInput.value))

urlInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') loadImageFromURL(urlInput.value)
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchMode('webcam')
    if (e.key === '2') switchMode('upload')
    if (e.key === 'l' || e.key === 'L') {
        const newValue = !sliders.get('showLines')
        sliders.set('showLines', newValue)
    }
    if (e.key === 'i' || e.key === 'I') {
        const newValue = !sliders.get('invert')
        sliders.set('invert', newValue)
    }
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
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
    if (currentMode === 'webcam' && webcamReady) {
        updateWebcamTexture()
    } else if (currentMode === 'upload' && videoElement && videoElement.readyState >= 2) {
        gl.bindTexture(gl.TEXTURE_2D, videoTexture)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoElement)
    }

    // Only render if we have a source
    if ((currentMode === 'webcam' && webcamReady) || (currentMode === 'upload' && hasTexture)) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, videoTexture)
        gl.uniform1i(uniforms.video, 0)

        gl.uniform1f(uniforms.time, t)
        gl.uniform2f(uniforms.videoSize, videoSize.width, videoSize.height)
        sliders.applyUniforms(gl, uniforms)

        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

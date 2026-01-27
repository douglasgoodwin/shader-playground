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
    density:   { selector: '#density',   default: 1.0, uniform: 'u_dotDensity' },
    dotScale:  { selector: '#dotScale',  default: 1.0, uniform: 'u_dotScale' },
    contrast:  { selector: '#contrast',  default: 1.5, uniform: 'u_contrast' },
    showLines: { selector: '#showLines', default: false, type: 'checkbox', uniform: 'u_showLines' },
    invert:    { selector: '#invert',    default: false, type: 'checkbox', uniform: 'u_invert' },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// Video/image texture
let videoTexture = null
let videoElement = null
let videoSize = { width: 640, height: 480 }
let currentMode = 'webcam'
let webcamReady = false
let imageLoaded = false

// UI Elements
const modeSelector = document.querySelector('#mode-selector')
const imageControls = document.querySelector('#image-controls')
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

        videoElement = document.createElement('video')
        videoElement.srcObject = stream
        videoElement.playsInline = true
        videoElement.muted = true

        await videoElement.play()

        videoSize.width = videoElement.videoWidth
        videoSize.height = videoElement.videoHeight

        createVideoTexture()
        webcamReady = true
        webcamStatus.classList.add('hidden')

        console.log('Webcam initialized:', videoSize.width, 'x', videoSize.height)
    } catch (err) {
        console.error('Webcam error:', err)
        webcamStatus.innerHTML = '<p>Could not access webcam. Try image mode instead.</p>'
    }
}

// Update video texture from webcam
function updateVideoTexture() {
    if (!webcamReady || !videoElement || videoElement.readyState < 2) return

    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoElement)
}

// Load image from file
function loadImageFromFile(file) {
    if (!file.type.startsWith('image/')) {
        alert('Please select an image file')
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

// Create texture from image
function createTextureFromImage(image) {
    createVideoTexture()
    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)

    videoSize.width = image.width
    videoSize.height = image.height
    imageLoaded = true

    imageControls.classList.add('loaded')
}

// Mode switching
function switchMode(mode) {
    currentMode = mode

    modeSelector.querySelectorAll('button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === mode)
    })

    if (mode === 'webcam') {
        imageControls.style.display = 'none'
        webcamStatus.classList.remove('hidden')
        if (!webcamReady) {
            initWebcam()
        } else {
            webcamStatus.classList.add('hidden')
        }
    } else {
        imageControls.style.display = 'flex'
        webcamStatus.classList.add('hidden')
        if (!imageLoaded) {
            imageControls.classList.remove('loaded')
            // Load a default portrait image
            loadImageFromURL('https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Golde33443.jpg/800px-Golde33443.jpg')
        }
    }
}

// Event listeners
modeSelector.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => switchMode(btn.dataset.mode))
})

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) loadImageFromFile(file)
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
    if (file) loadImageFromFile(file)
})

loadUrlBtn.addEventListener('click', () => loadImageFromURL(urlInput.value))

urlInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') loadImageFromURL(urlInput.value)
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchMode('webcam')
    if (e.key === '2') switchMode('image')
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

    // Update video texture if in webcam mode
    if (currentMode === 'webcam' && webcamReady) {
        updateVideoTexture()
    }

    // Only render if we have a video source
    if ((currentMode === 'webcam' && webcamReady) || (currentMode === 'image' && imageLoaded)) {
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

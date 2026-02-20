import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import scribbleShader from './shaders/scribble.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

const program = createProgram(gl, vertexShader, scribbleShader)
if (!program) {
    throw new Error('Failed to create shader program')
}

gl.useProgram(program)
createFullscreenQuad(gl, program)

// Uniform locations
const uniforms = {
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    time: gl.getUniformLocation(program, 'u_time'),
    texture: gl.getUniformLocation(program, 'u_texture'),
    textureSize: gl.getUniformLocation(program, 'u_textureSize'),
    density: gl.getUniformLocation(program, 'u_density'),
    circleSize: gl.getUniformLocation(program, 'u_circleSize'),
    contrast: gl.getUniformLocation(program, 'u_contrast'),
    jitter: gl.getUniformLocation(program, 'u_jitter'),
    ellipse: gl.getUniformLocation(program, 'u_ellipse'),
    bgColor: gl.getUniformLocation(program, 'u_bgColor'),
}

// Sliders
const sliders = new SliderManager({
    density:    { selector: '#density',    default: 1.0 },
    circleSize: { selector: '#circleSize', default: 1.0 },
    contrast:   { selector: '#contrast',   default: 1.5 },
    jitter:     { selector: '#jitter',     default: 1.0 },
    ellipse:    { selector: '#ellipse',    default: 1.0 },
})

// Color schemes
const schemes = {
    red:  [0.9, 0.05, 0.05],
    cyan: [0.05, 0.9, 0.9],
}
let bgColor = schemes.red

function switchScheme(name) {
    bgColor = schemes[name]
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.scheme === name)
    })
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', () => switchScheme(btn.dataset.scheme))
})

// Recording
const recorder = setupRecording(canvas)

// Texture state
let imageTexture = null
let textureSize = { width: 1, height: 1 }
let hasTexture = false
let videoElement = null // non-null when source is a playing video

// UI elements
const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const loadingEl = document.querySelector('#loading')

// Ensure a GL texture object exists
function ensureTexture() {
    if (imageTexture) return imageTexture
    imageTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, imageTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    return imageTexture
}

// Create texture from image (static)
function createTextureFromImage(image) {
    videoElement = null
    ensureTexture()
    gl.bindTexture(gl.TEXTURE_2D, imageTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)

    textureSize = { width: image.width, height: image.height }
    hasTexture = true
    loadingEl.classList.add('hidden')
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
        textureSize = { width: video.videoWidth, height: video.videoHeight }
        ensureTexture()
        hasTexture = true
        loadingEl.classList.add('hidden')
        video.play()
    })

    video.addEventListener('error', () => {
        alert('Failed to load video')
        loadingEl.classList.add('hidden')
        URL.revokeObjectURL(url)
    })
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
        img.onload = () => createTextureFromImage(img)
        img.onerror = () => {
            alert('Failed to load image')
            loadingEl.classList.add('hidden')
        }
        img.src = e.target.result
    }

    reader.readAsDataURL(file)
}

// Load image from URL
function loadImageUrl(url) {
    if (!url) return

    loadingEl.classList.remove('hidden')
    const img = new Image()
    img.crossOrigin = 'anonymous'

    img.onload = () => createTextureFromImage(img)
    img.onerror = () => {
        alert('Failed to load image from URL')
        loadingEl.classList.add('hidden')
    }

    img.src = url
}

// Event listeners — image loading (same pattern as warps)
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

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) loadFile(file)
})

loadUrlBtn.addEventListener('click', () => loadImageUrl(urlInput.value))

urlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadImageUrl(urlInput.value)
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === '1') switchScheme('red')
    if (e.key === '2') switchScheme('cyan')
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

// Render loop
function render(time) {
    const t = time * 0.001

    gl.uniform1f(uniforms.time, t)
    gl.uniform3f(uniforms.bgColor, bgColor[0], bgColor[1], bgColor[2])
    sliders.applyUniforms(gl, uniforms)

    if (hasTexture && imageTexture) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, imageTexture)

        // Re-upload texture from video each frame
        if (videoElement && videoElement.readyState >= 2) {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoElement)
        }

        gl.uniform1i(uniforms.texture, 0)
        gl.uniform2f(uniforms.textureSize, textureSize.width, textureSize.height)
    }

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

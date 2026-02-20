import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import scribbleShader from './shaders/scribble.glsl'
import linesShader from './shaders/scribble-lines.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Shaders
const shaders = {
    circles: scribbleShader,
    lines: linesShader,
}

// Create programs and uniform locations for each shader
const programs = {}
const allUniforms = {}

const uniformNames = [
    'u_resolution', 'u_time', 'u_texture', 'u_textureSize',
    'u_density', 'u_circleSize', 'u_contrast', 'u_jitter',
    'u_ellipse', 'u_strokeWeight', 'u_bgColor',
]

for (const [name, fragmentShader] of Object.entries(shaders)) {
    const prog = createProgram(gl, vertexShader, fragmentShader)
    if (prog) {
        programs[name] = prog
        const locs = {}
        for (const u of uniformNames) {
            locs[u] = gl.getUniformLocation(prog, u)
        }
        allUniforms[name] = locs
    }
}

let currentEffect = 'circles'
let currentProgram = programs[currentEffect]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

function switchEffect(name) {
    if (!programs[name]) return
    currentEffect = name
    currentProgram = programs[name]
    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = allUniforms[currentEffect]
    if (u['u_resolution']) {
        gl.uniform2f(u['u_resolution'], canvas.width, canvas.height)
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })
}

document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', () => switchEffect(btn.dataset.effect))
})

// Sliders
const sliders = new SliderManager({
    density:      { selector: '#density',      default: 1.0 },
    circleSize:   { selector: '#circleSize',   default: 1.0 },
    contrast:     { selector: '#contrast',     default: 1.5 },
    jitter:       { selector: '#jitter',       default: 1.0 },
    ellipse:      { selector: '#ellipse',      default: 1.0 },
    strokeWeight: { selector: '#strokeWeight', default: 2.5 },
})

// Background color (red for both effects)
const bgColor = [0.9, 0.05, 0.05]

// Recording
const recorder = setupRecording(canvas)

// Texture state
let imageTexture = null
let textureSize = { width: 1, height: 1 }
let hasTexture = false
let videoElement = null

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

// Event listeners — image loading
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
    if (e.key === '1') switchEffect('circles')
    if (e.key === '2') switchEffect('lines')
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// Resize
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    const u = allUniforms[currentEffect]
    if (u['u_resolution']) {
        gl.uniform2f(u['u_resolution'], canvas.width, canvas.height)
    }
}

window.addEventListener('resize', resize)
resize()

// Render loop
function render(time) {
    const t = time * 0.001
    const u = allUniforms[currentEffect]

    gl.uniform1f(u['u_time'], t)
    gl.uniform3f(u['u_bgColor'], bgColor[0], bgColor[1], bgColor[2])

    // Apply sliders via uniform names
    const params = sliders.params
    if (u['u_density'])      gl.uniform1f(u['u_density'], params.density)
    if (u['u_circleSize'])   gl.uniform1f(u['u_circleSize'], params.circleSize)
    if (u['u_contrast'])     gl.uniform1f(u['u_contrast'], params.contrast)
    if (u['u_jitter'])       gl.uniform1f(u['u_jitter'], params.jitter)
    if (u['u_ellipse'])      gl.uniform1f(u['u_ellipse'], params.ellipse)
    if (u['u_strokeWeight']) gl.uniform1f(u['u_strokeWeight'], params.strokeWeight)

    if (hasTexture && imageTexture) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, imageTexture)

        if (videoElement && videoElement.readyState >= 2) {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoElement)
        }

        gl.uniform1i(u['u_texture'], 0)
        gl.uniform2f(u['u_textureSize'], textureSize.width, textureSize.height)
    }

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

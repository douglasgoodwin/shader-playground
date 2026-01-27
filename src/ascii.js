import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import asciiImageShader from './shaders/ascii-image.glsl'
import asciiPlatonicShader from './shaders/ascii.glsl'
import asciiCubeShader from './shaders/ascii-geometry.glsl'
import asciiFontShader from './shaders/ascii-font.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Font atlas configuration
// Characters chosen for good shape coverage (matching Alex Harri's approach)
const FONT_CHARS = ' .\'-|/\\_iczu1UBMW@#'
const FONT_SIZE = 32
const ATLAS_CHAR_SIZE = 40

// Create font texture atlas
function createFontAtlas() {
    const numChars = FONT_CHARS.length
    const atlasWidth = numChars * ATLAS_CHAR_SIZE
    const atlasHeight = ATLAS_CHAR_SIZE

    const atlasCanvas = document.createElement('canvas')
    atlasCanvas.width = atlasWidth
    atlasCanvas.height = atlasHeight
    const ctx = atlasCanvas.getContext('2d')

    // Clear to black
    ctx.fillStyle = 'black'
    ctx.fillRect(0, 0, atlasWidth, atlasHeight)

    // Draw characters in white
    ctx.fillStyle = 'white'
    ctx.font = `bold ${FONT_SIZE}px monospace`
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'

    for (let i = 0; i < numChars; i++) {
        const char = FONT_CHARS[i]
        const x = i * ATLAS_CHAR_SIZE + ATLAS_CHAR_SIZE / 2
        const y = ATLAS_CHAR_SIZE / 2
        ctx.fillText(char, x, y)
    }

    // Create WebGL texture
    const texture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, atlasCanvas)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    return { texture, numChars, atlasSize: ATLAS_CHAR_SIZE }
}

const fontAtlas = createFontAtlas()

// Create shader programs for each mode
const shaders = {
    waves: asciiFontShader,
    image: asciiImageShader,
    platonic: asciiPlatonicShader,
    cube: asciiCubeShader,
}

const programs = {}
const uniforms = {}

for (const [name, fragmentShader] of Object.entries(shaders)) {
    const program = createProgram(gl, vertexShader, fragmentShader)
    if (program) {
        programs[name] = program
        uniforms[name] = {
            resolution: gl.getUniformLocation(program, 'u_resolution'),
            time: gl.getUniformLocation(program, 'u_time'),
            mouse: gl.getUniformLocation(program, 'u_mouse'),
            speed: gl.getUniformLocation(program, 'u_speed'),
            intensity: gl.getUniformLocation(program, 'u_intensity'),
            scale: gl.getUniformLocation(program, 'u_scale'),
            // Image-specific
            imageSize: gl.getUniformLocation(program, 'u_imageSize'),
            image: gl.getUniformLocation(program, 'u_image'),
            contrast: gl.getUniformLocation(program, 'u_contrast'),
            charSize: gl.getUniformLocation(program, 'u_charSize'),
            // Font atlas uniforms
            fontAtlas: gl.getUniformLocation(program, 'u_fontAtlas'),
            numChars: gl.getUniformLocation(program, 'u_numChars'),
            atlasSize: gl.getUniformLocation(program, 'u_atlasSize'),
        }
    }
}

// Current mode
let currentMode = 'waves'
let currentProgram = programs[currentMode]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

// Mouse tracking
const mouse = new MouseTracker(canvas)

// Slider parameters
const sliders = new SliderManager({
    contrast: { selector: '#contrast', default: 2.5 },
    charSize: { selector: '#charSize', default: 12 },
    speed:    { selector: '#speed',    default: 1 },
    scale:    { selector: '#scale',    default: 1 },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// Image texture (for image mode)
let imageTexture = null
let imageSize = { width: 1, height: 1 }
let imageLoaded = false

// UI Elements
const modeSelector = document.querySelector('#mode-selector')
const imageControls = document.querySelector('#image-controls')
const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const speedLabel = document.querySelector('#speed-label')
const scaleLabel = document.querySelector('#scale-label')
const loadingEl = document.querySelector('#loading')

// Mode switching
function switchMode(mode) {
    if (!programs[mode]) return
    currentMode = mode
    currentProgram = programs[mode]

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    // Update resolution uniform
    const u = uniforms[currentMode]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    // Update UI
    modeSelector.querySelectorAll('button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === mode)
    })

    // Show/hide mode-specific controls
    const isImageMode = mode === 'image'
    const isWavesMode = mode === 'waves'
    const is3DMode = mode === 'platonic' || mode === 'cube'

    imageControls.style.display = isImageMode ? 'flex' : 'none'
    speedLabel.style.display = (isWavesMode || is3DMode) ? 'flex' : 'none'
    scaleLabel.style.display = is3DMode ? 'flex' : 'none'

    // For image mode, load default image if none loaded
    if (isImageMode && !imageLoaded) {
        imageControls.classList.remove('loaded')
        // Load default Saturn image
        loadImageFromURL('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Saturn_during_Equinox.jpg/1200px-Saturn_during_Equinox.jpg')
    }
}

// Mode button handlers
modeSelector.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => {
        switchMode(btn.dataset.mode)
    })
})

// Keyboard shortcuts for modes
document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchMode('waves')
    if (e.key === '2') switchMode('image')
    if (e.key === '3') switchMode('platonic')
    if (e.key === '4') switchMode('cube')
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
})

// Create texture from image
function createTextureFromImage(image) {
    if (imageTexture) {
        gl.deleteTexture(imageTexture)
    }

    imageTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, imageTexture)

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)

    imageSize.width = image.width
    imageSize.height = image.height
    imageLoaded = true

    imageControls.classList.add('loaded')
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

// File input handler
fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) {
        loadImageFromFile(file)
    }
})

// Drop zone handlers
dropZone.addEventListener('click', () => {
    fileInput.click()
})

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
    if (file) {
        loadImageFromFile(file)
    }
})

// URL input handler
loadUrlBtn.addEventListener('click', () => {
    loadImageFromURL(urlInput.value)
})

urlInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        loadImageFromURL(urlInput.value)
    }
})

// Resize handler
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    const u = uniforms[currentMode]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }
}

window.addEventListener('resize', resize)
resize()

// Initialize mode UI
switchMode('waves')

// Render loop
function render(time) {
    const t = time * 0.001
    const u = uniforms[currentMode]

    if (currentMode === 'image') {
        // Image mode with font atlas
        if (imageLoaded) {
            gl.activeTexture(gl.TEXTURE0)
            gl.bindTexture(gl.TEXTURE_2D, imageTexture)
            gl.uniform1i(u.image, 0)
            gl.activeTexture(gl.TEXTURE1)
            gl.bindTexture(gl.TEXTURE_2D, fontAtlas.texture)
            gl.uniform1i(u.fontAtlas, 1)
            gl.uniform1f(u.numChars, fontAtlas.numChars)
            gl.uniform2f(u.imageSize, imageSize.width, imageSize.height)
            gl.uniform1f(u.contrast, sliders.get('contrast'))
            gl.uniform1f(u.charSize, sliders.get('charSize'))
            gl.drawArrays(gl.TRIANGLES, 0, 6)
        }
    } else if (currentMode === 'waves') {
        // Waves mode with font atlas
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, fontAtlas.texture)
        gl.uniform1i(u.fontAtlas, 0)
        gl.uniform1f(u.numChars, fontAtlas.numChars)
        gl.uniform1f(u.atlasSize, ATLAS_CHAR_SIZE)
        gl.uniform1f(u.time, t)
        gl.uniform1f(u.speed, sliders.get('speed'))
        gl.uniform1f(u.contrast, sliders.get('contrast'))
        gl.uniform1f(u.charSize, sliders.get('charSize'))
        gl.drawArrays(gl.TRIANGLES, 0, 6)
    } else {
        // 3D modes (platonic, cube) with font atlas
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, fontAtlas.texture)
        gl.uniform1i(u.fontAtlas, 0)
        gl.uniform1f(u.numChars, fontAtlas.numChars)
        gl.uniform1f(u.time, t)
        mouse.applyUniform(gl, u.mouse)
        gl.uniform1f(u.speed, sliders.get('speed'))
        gl.uniform1f(u.intensity, sliders.get('contrast')) // Reuse contrast as intensity
        gl.uniform1f(u.scale, sliders.get('scale'))
        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

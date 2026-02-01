import './warps.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import drapeShader from './shaders/warps/drape.glsl'
import flowheartShader from './shaders/warps/flowheart.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Shaders
const shaders = {
    drape: drapeShader,
    flowheart: flowheartShader,
}

// Create programs and uniforms for each shader
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
            texture: gl.getUniformLocation(program, 'u_texture'),
            textureSize: gl.getUniformLocation(program, 'u_textureSize'),
            deform: gl.getUniformLocation(program, 'u_deform'),
            geometry: gl.getUniformLocation(program, 'u_geometry'),
            speed: gl.getUniformLocation(program, 'u_speed'),
            hasTexture: gl.getUniformLocation(program, 'u_hasTexture'),
        }
    }
}

let currentEffect = 'drape'
let currentProgram = programs[currentEffect]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

// UI elements
const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const loadingEl = document.querySelector('#loading')
const deformSlider = document.querySelector('#deform')
const geometrySlider = document.querySelector('#geometry')
const speedSlider = document.querySelector('#speed')

// Texture state
let imageTexture = null
let textureSize = { width: 1, height: 1 }
let hasTexture = false

const mouse = new MouseTracker(canvas)
const recorder = setupRecording(canvas)

// Switch effect
function switchEffect(name) {
    if (!programs[name]) return
    currentEffect = name
    currentProgram = programs[name]

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = uniforms[currentEffect]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })
}

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

    textureSize = { width: image.width, height: image.height }
    hasTexture = true
    loadingEl.classList.add('hidden')
}

// Load image from file
function loadImageFile(file) {
    if (!file.type.startsWith('image/')) {
        alert('Please select an image file')
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

// Event listeners for effect buttons
document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', () => switchEffect(btn.dataset.effect))
})

// Event listeners for image loading
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
    if (file) loadImageFile(file)
})

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) loadImageFile(file)
})

loadUrlBtn.addEventListener('click', () => loadImageUrl(urlInput.value))

urlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadImageUrl(urlInput.value)
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') switchEffect('drape')
    if (e.key === '2') switchEffect('flowheart')
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// Resize handler
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    const u = uniforms[currentEffect]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }
}

window.addEventListener('resize', resize)
resize()

// Render loop
function render(time) {
    const t = time * 0.001
    const u = uniforms[currentEffect]

    gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)

    gl.uniform1f(u.deform, parseFloat(deformSlider.value))
    gl.uniform1f(u.geometry, parseFloat(geometrySlider.value))
    gl.uniform1f(u.speed, parseFloat(speedSlider.value))
    gl.uniform1i(u.hasTexture, hasTexture ? 1 : 0)

    if (hasTexture && imageTexture) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, imageTexture)
        gl.uniform1i(u.texture, 0)
        gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
    }

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

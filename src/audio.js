import './audio.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import { AudioEngine } from './audio-engine.js'
import vertexShader from './shaders/vertex.glsl'
import landscapeShader from './shaders/audio/landscape.glsl'
import sphereShader from './shaders/audio/sphere.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Create shader programs
const shaders = {
    landscape: landscapeShader,
    sphere: sphereShader,
}

const audioUniforms = [
    'u_resolution', 'u_time', 'u_mouse', 'u_speed', 'u_intensity',
    'u_audioFreq', 'u_audioWave', 'u_audioEnergy', 'u_bassEnergy',
]

const programs = {}
const uniforms = {}

for (const [name, fragmentShader] of Object.entries(shaders)) {
    const program = createProgram(gl, vertexShader, fragmentShader)
    if (program) {
        programs[name] = program
        const u = {}
        for (const uName of audioUniforms) {
            u[uName] = gl.getUniformLocation(program, uName)
        }
        uniforms[name] = u
    }
}

let currentPiece = 'landscape'
let currentProgram = programs[currentPiece]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

// Mouse tracking
const mouse = new MouseTracker(canvas)

// Slider parameters
const sliders = new SliderManager({
    speed:     { selector: '#speed',     default: 1 },
    intensity: { selector: '#intensity', default: 1 },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// Audio engine
const audioEngine = new AudioEngine()

// Create 1D audio textures
function createAudioTexture(gl, width) {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)
    const data = new Uint8Array(width)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, 1, 0, gl.LUMINANCE, gl.UNSIGNED_BYTE, data)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    return tex
}

const freqTex = createAudioTexture(gl, 512)
const waveTex = createAudioTexture(gl, 1024)

function switchPiece(name) {
    if (!programs[name]) return
    currentPiece = name
    currentProgram = programs[name]

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = uniforms[currentPiece]
    if (u['u_resolution']) {
        gl.uniform2f(u['u_resolution'], canvas.width, canvas.height)
    }
    // Re-bind texture unit assignments for new program
    if (u['u_audioFreq']) gl.uniform1i(u['u_audioFreq'], 0)
    if (u['u_audioWave']) gl.uniform1i(u['u_audioWave'], 1)

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.piece === name)
    })
}

// Set initial texture unit assignments
const u0 = uniforms[currentPiece]
if (u0['u_audioFreq']) gl.uniform1i(u0['u_audioFreq'], 0)
if (u0['u_audioWave']) gl.uniform1i(u0['u_audioWave'], 1)

// Piece switching
document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchPiece(btn.dataset.piece)
    })
})

const pieceKeys = { '1': 'landscape', '2': 'sphere' }

// Audio controls
const startBtn = document.querySelector('#start-audio')
const micBtn = document.querySelector('#mic-toggle')
const tempoSlider = document.querySelector('#tempo')
const fmDepthSlider = document.querySelector('#fmDepth')
const fileUploadBtn = document.querySelector('#file-upload-btn')
const fileInput = document.querySelector('#file-input')
const filePauseBtn = document.querySelector('#file-pause-btn')
const fileNameSpan = document.querySelector('#file-name')
const tempoLabel = tempoSlider.closest('label')
const fmDepthLabel = fmDepthSlider.closest('label')

startBtn.addEventListener('click', () => {
    audioEngine.start()
    startBtn.classList.add('hidden')
})

micBtn.addEventListener('click', () => {
    if (audioEngine.isMicActive) {
        audioEngine.disableMic()
        micBtn.classList.remove('active')
    } else {
        if (!audioEngine.isPlaying) audioEngine.start()
        audioEngine.enableMic()
        micBtn.classList.add('active')
        updateFileUI()
    }
})

tempoSlider.addEventListener('input', (e) => {
    audioEngine.setTempo(parseFloat(e.target.value))
})

fmDepthSlider.addEventListener('input', (e) => {
    audioEngine.setModDepth(parseFloat(e.target.value))
})

function updateFileUI() {
    if (audioEngine.isFileActive) {
        filePauseBtn.classList.remove('hidden')
        filePauseBtn.textContent = audioEngine._fileIsPlaying ? 'Pause' : 'Resume'
        fileNameSpan.textContent = audioEngine._fileName
        tempoLabel.style.display = 'none'
        fmDepthLabel.style.display = 'none'
    } else {
        filePauseBtn.classList.add('hidden')
        fileNameSpan.textContent = ''
        tempoLabel.style.display = ''
        fmDepthLabel.style.display = ''
    }
}

fileUploadBtn.addEventListener('click', () => {
    if (!audioEngine.isPlaying) audioEngine.start()
    fileInput.click()
})

fileInput.addEventListener('change', async () => {
    const file = fileInput.files[0]
    if (!file) return
    if (!audioEngine.isPlaying) {
        audioEngine.start()
        startBtn.classList.add('hidden')
    }
    await audioEngine.loadFile(file)
    micBtn.classList.remove('active')
    updateFileUI()
    fileInput.value = ''
})

filePauseBtn.addEventListener('click', () => {
    if (audioEngine._fileIsPlaying) {
        audioEngine.pauseFile()
    } else {
        audioEngine.resumeFile()
    }
    updateFileUI()
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (pieceKeys[e.key]) {
        switchPiece(pieceKeys[e.key])
    }
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
    if (e.key === 'f' || e.key === 'F') {
        fileUploadBtn.click()
    }
    if (e.key === ' ' && audioEngine.isFileActive) {
        e.preventDefault()
        filePauseBtn.click()
    }
})

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
    const u = uniforms[currentPiece]
    if (u && u['u_resolution']) {
        gl.uniform2f(u['u_resolution'], canvas.width, canvas.height)
    }
}

window.addEventListener('resize', resize)
resize()

function render(time) {
    const t = time * 0.001
    const u = uniforms[currentPiece]

    // Update audio textures
    if (audioEngine.isPlaying) {
        audioEngine.updateTextures(gl, freqTex, waveTex)
    }

    // Bind audio textures
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, freqTex)
    gl.activeTexture(gl.TEXTURE1)
    gl.bindTexture(gl.TEXTURE_2D, waveTex)

    // Set uniforms
    gl.uniform1f(u['u_time'], t)
    mouse.applyUniform(gl, u['u_mouse'])
    sliders.applyUniforms(gl, u)
    gl.uniform1f(u['u_audioEnergy'], audioEngine.isPlaying ? audioEngine.getEnergy() : 0.0)
    gl.uniform1f(u['u_bassEnergy'], audioEngine.isPlaying ? audioEngine.getBassEnergy() : 0.0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

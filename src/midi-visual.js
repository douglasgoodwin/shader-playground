import './midi-visual.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import { createMidiEngine } from './midi-engine.js'
import kaleidoscopeShader from './shaders/kaleidoscope/kaleidoscope.glsl'
import tunnelShader from './shaders/kaleidoscope/tunnel.glsl'
import fractalShader from './shaders/kaleidoscope/fractal.glsl'

let textureSize = { width: 1, height: 1 }

// --- MIDI engine ---
const midi = createMidiEngine()

// --- UI elements ---
const playBtn = document.getElementById('play-btn')
const timeDisplay = document.getElementById('time-display')
const bpmDisplay = document.getElementById('bpm-display')
const midiStatus = document.getElementById('midi-status')
const midiDropZone = document.getElementById('midi-drop-zone')
const midiFileInput = document.getElementById('midi-file-input')
const midiUrlInput = document.getElementById('midi-url-input')
const midiLoadUrl = document.getElementById('midi-load-url')

// --- Shader page ---
const page = createShaderPage({
    shaders: {
        kaleidoscope: kaleidoscopeShader,
        tunnel: tunnelShader,
        fractal: fractalShader,
    },
    uniforms: [
        'resolution', 'time', 'mouse',
        'texture', 'textureSize', 'hasTexture',
        'segments', 'zoom', 'speed',
    ],
    defaultEffect: 'kaleidoscope',
    sliders: {
        segments:   { selector: '#segments',   default: 6 },
        zoom:       { selector: '#zoom',       default: 1 },
        speed:      { selector: '#speed',      default: 0.5 },
    },
    onRender({ gl, u, sliders }) {
        // Video texture
        gl.uniform1i(u.hasTexture, media.hasMedia ? 1 : 0)
        if (media.hasMedia && media.texture) {
            gl.activeTexture(gl.TEXTURE0)
            media.updateVideoFrame()
            gl.bindTexture(gl.TEXTURE_2D, media.texture)
            gl.uniform1i(u.texture, 0)
            gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
        }

        // MIDI → visual state
        const state = midi.updateVisualState()
        const reactivity = parseFloat(document.getElementById('reactivity').value)
        const rSegments = document.getElementById('react-segments').checked
        const rZoom = document.getElementById('react-zoom').checked
        const rSpeed = document.getElementById('react-speed').checked

        const baseSegments = sliders.get('segments')
        const baseZoom = sliders.get('zoom')
        const baseSpeed = sliders.get('speed')

        // Note pitch → segment count (low pitch = few, high pitch = many)
        const midiSegments = 2 + state.pitch * 20
        const segments = rSegments
            ? baseSegments + (midiSegments - baseSegments) * state.hit * reactivity
            : baseSegments

        // Note velocity → zoom pulse
        const zoomPulse = state.hit * state.velocity * reactivity * 0.8
        const zoom = rZoom ? baseZoom + zoomPulse : baseZoom

        // Note density → speed boost
        const speedBoost = state.density * reactivity * 2
        const speed = rSpeed ? baseSpeed + speedBoost : baseSpeed

        gl.uniform1f(u.segments, Math.max(2, Math.round(segments)))
        gl.uniform1f(u.zoom, zoom)
        gl.uniform1f(u.speed, speed)

        // Update time display
        if (midi.loaded) {
            const t = midi.currentTime
            const m = Math.floor(t / 60)
            const s = Math.floor(t % 60)
            const ms = Math.floor((t % 1) * 10)
            timeDisplay.textContent = `${m}:${String(s).padStart(2, '0')}.${ms}`
        }
    },
})

// --- Video loader ---
const media = createMediaLoader(page.gl, {
    onLoad: (source, size) => { textureSize = size },
    selectors: {
        loading: '#video-loading',
        dropZone: '#video-drop-zone',
        fileInput: '#video-file-input',
        urlInput: '#video-url-input',
        loadUrl: '#video-load-url',
    },
})

// --- MIDI file loading ---
function loadMidiFile(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
        const info = midi.loadMidi(e.target.result)
        bpmDisplay.textContent = `${info.bpm} BPM`
        midiStatus.textContent = `${info.noteCount} notes`
        playBtn.disabled = false
    }
    reader.readAsArrayBuffer(file)
}

function loadMidiUrl(url) {
    if (!url) return
    fetch(url)
        .then(r => r.arrayBuffer())
        .then(buf => {
            const info = midi.loadMidi(buf)
            bpmDisplay.textContent = `${info.bpm} BPM`
            midiStatus.textContent = `${info.noteCount} notes`
            playBtn.disabled = false
        })
        .catch(() => alert('Failed to load MIDI from URL'))
}

// MIDI drop zone events
midiDropZone.addEventListener('click', () => midiFileInput.click())
midiDropZone.addEventListener('dragover', (e) => {
    e.preventDefault()
    midiDropZone.classList.add('dragover')
})
midiDropZone.addEventListener('dragleave', () => midiDropZone.classList.remove('dragover'))
midiDropZone.addEventListener('drop', (e) => {
    e.preventDefault()
    midiDropZone.classList.remove('dragover')
    const file = e.dataTransfer.files[0]
    if (file) loadMidiFile(file)
})
midiFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0]
    if (file) loadMidiFile(file)
})
midiLoadUrl.addEventListener('click', () => loadMidiUrl(midiUrlInput.value))
midiUrlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadMidiUrl(midiUrlInput.value)
})

// --- Transport controls ---
playBtn.addEventListener('click', () => {
    if (midi.isPlaying) {
        midi.pause()
        playBtn.textContent = '\u25B6'
        playBtn.classList.remove('playing')
    } else {
        midi.play()
        playBtn.textContent = '\u23F8'
        playBtn.classList.add('playing')
    }
})

// Keyboard: space = play/pause
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === ' ') {
        e.preventDefault()
        if (midi.loaded) playBtn.click()
    }
})

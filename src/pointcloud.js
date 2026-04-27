import './pointcloud.css'
import './source-link.js'
import * as THREE from 'three'
import { setupRecording, SliderManager } from './controls.js'
import { createAudioAnalyzer } from './audio-analyzer.js'
import pointsVert from './shaders/pointcloud/points.vert'
import pointsFrag from './shaders/pointcloud/points.frag'

const canvas = document.getElementById('canvas')
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true, alpha: false })
renderer.setPixelRatio(window.devicePixelRatio)
renderer.setSize(window.innerWidth, window.innerHeight)

const scene = new THREE.Scene()
scene.background = new THREE.Color(0x050608)

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.01, 100)
camera.position.set(0, 0, 3.2)

// ---------- Grid geometry ----------
// Each point at (u, v, 0) in [0,1]. The vertex shader re-centers and aspect-corrects.

const GRID = 400
const pointCount = GRID * GRID
const positions = new Float32Array(pointCount * 3)
for (let y = 0; y < GRID; y++) {
    for (let x = 0; x < GRID; x++) {
        const i = (y * GRID + x) * 3
        positions[i]     = x / (GRID - 1)
        positions[i + 1] = y / (GRID - 1)
        positions[i + 2] = 0
    }
}
const geometry = new THREE.BufferGeometry()
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))

// ---------- Material ----------

const uniforms = {
    u_image:       { value: null },
    u_imageSize:   { value: new THREE.Vector2(1, 1) },
    u_depth:       { value: 1.0 },
    u_pointSize:   { value: 2.0 },
    u_invert:      { value: 0.0 },
    u_pixelRatio:  { value: window.devicePixelRatio },
    u_blurRadius:  { value: 3.0 },
    u_colorBoost:  { value: 0.3 },
    u_depthShade:  { value: 1.0 },
    u_time:        { value: 0.0 },
    u_level:       { value: 0.0 },
    u_bass:        { value: 0.0 },
    u_treble:      { value: 0.0 },
}

const material = new THREE.ShaderMaterial({
    vertexShader: pointsVert,
    fragmentShader: pointsFrag,
    uniforms,
    transparent: true,
    depthWrite: false,
    blending: THREE.NormalBlending,
})

const points = new THREE.Points(geometry, material)
scene.add(points)

// ---------- Texture management ----------

let currentTexture = null
let currentVideo = null   // <video> element, if any
let webcamStream = null

function disposeCurrent() {
    if (currentTexture) {
        currentTexture.dispose()
        currentTexture = null
    }
    if (currentVideo) {
        currentVideo.pause()
        if (currentVideo.srcObject) {
            // webcam stream
            const tracks = currentVideo.srcObject.getTracks?.() || []
            tracks.forEach(t => t.stop())
            currentVideo.srcObject = null
        } else if (currentVideo.src?.startsWith('blob:')) {
            URL.revokeObjectURL(currentVideo.src)
        }
        currentVideo = null
    }
    if (webcamStream) {
        webcamStream.getTracks().forEach(t => t.stop())
        webcamStream = null
    }
}

function setImageTexture(image, width, height) {
    disposeCurrent()
    const tex = new THREE.Texture(image)
    tex.colorSpace = THREE.SRGBColorSpace
    tex.minFilter = THREE.LinearFilter
    tex.magFilter = THREE.LinearFilter
    tex.wrapS = THREE.ClampToEdgeWrapping
    tex.wrapT = THREE.ClampToEdgeWrapping
    tex.flipY = true
    tex.needsUpdate = true
    currentTexture = tex
    uniforms.u_image.value = tex
    uniforms.u_imageSize.value.set(width, height)
}

function setVideoTexture(videoEl) {
    disposeCurrent()
    currentVideo = videoEl
    const tex = new THREE.VideoTexture(videoEl)
    tex.colorSpace = THREE.SRGBColorSpace
    tex.minFilter = THREE.LinearFilter
    tex.magFilter = THREE.LinearFilter
    tex.wrapS = THREE.ClampToEdgeWrapping
    tex.wrapT = THREE.ClampToEdgeWrapping
    currentTexture = tex
    uniforms.u_image.value = tex
    uniforms.u_imageSize.value.set(videoEl.videoWidth || 1, videoEl.videoHeight || 1)
}

// ---------- Loaders ----------

const loadingEl = document.querySelector('#loading')
const dropZone  = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput  = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const webcamBtn = document.querySelector('#webcam-btn')

function showLoading(on) {
    loadingEl.classList.toggle('hidden', !on)
}

function loadImageElement(src) {
    showLoading(true)
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
        setImageTexture(img, img.naturalWidth, img.naturalHeight)
        showLoading(false)
    }
    img.onerror = () => {
        showLoading(false)
        console.warn('Failed to load image:', src)
    }
    img.src = src
}

function loadVideoSrc(src) {
    showLoading(true)
    const video = document.createElement('video')
    video.muted = true
    video.loop = true
    video.playsInline = true
    video.crossOrigin = 'anonymous'
    video.src = src
    video.addEventListener('loadeddata', () => {
        video.play()
        setVideoTexture(video)
        showLoading(false)
    })
    video.addEventListener('error', () => {
        showLoading(false)
        console.warn('Failed to load video:', src)
    })
}

function loadFile(file) {
    if (file.type.startsWith('video/')) {
        loadVideoSrc(URL.createObjectURL(file))
        return
    }
    if (!file.type.startsWith('image/')) {
        alert('Please drop an image or video')
        return
    }
    const reader = new FileReader()
    reader.onload = (e) => loadImageElement(e.target.result)
    reader.readAsDataURL(file)
}

function loadUrl(url) {
    if (!url) return
    if (/\.(mp4|webm|ogv|mov)(\?|$)/i.test(url)) loadVideoSrc(url)
    else loadImageElement(url)
}

async function startWebcam() {
    try {
        showLoading(true)
        const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 960, height: 720 }, audio: false })
        webcamStream = stream
        const video = document.createElement('video')
        video.muted = true
        video.playsInline = true
        video.srcObject = stream
        await video.play()
        // wait a tick so videoWidth/Height are populated
        await new Promise(r => {
            if (video.videoWidth) r()
            else video.addEventListener('loadedmetadata', () => r(), { once: true })
        })
        setVideoTexture(video)
        showLoading(false)
    } catch (err) {
        showLoading(false)
        alert('Webcam access denied: ' + err.message)
    }
}

// Drop zone
dropZone.addEventListener('click', () => fileInput.click())
dropZone.addEventListener('dragover', (e) => {
    e.preventDefault()
    dropZone.classList.add('dragover')
})
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'))
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
loadUrlBtn.addEventListener('click', () => loadUrl(urlInput.value))
urlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadUrl(urlInput.value)
})
webcamBtn.addEventListener('click', startWebcam)

// ---------- Audio (mic or file) ----------

const audioBtn       = document.querySelector('#audio-btn')
const audioFileBtn   = document.querySelector('#audio-file-btn')
const audioFileInput = document.querySelector('#audio-file-input')
const audioMeter     = document.querySelector('#audio-meter')
const audioMeterFill = document.querySelector('#audio-meter-fill')

const audio = createAudioAnalyzer()
let currentAudioFile = null

function resetAudioUI() {
    audioBtn.textContent = 'Use Mic'
    audioBtn.classList.remove('on')
    audioFileBtn.textContent = 'Load Audio'
    audioFileBtn.classList.remove('on')
    audioMeter.classList.remove('visible')
    audioMeterFill.style.width = '0%'
}

function stopAudio() {
    if (audio.running) audio.stop()
    if (currentAudioFile) {
        currentAudioFile.pause()
        if (currentAudioFile.src?.startsWith('blob:')) URL.revokeObjectURL(currentAudioFile.src)
        if (currentAudioFile.parentNode) currentAudioFile.parentNode.removeChild(currentAudioFile)
        currentAudioFile = null
    }
    resetAudioUI()
}

audioBtn.addEventListener('click', async () => {
    const wasOn = audioBtn.classList.contains('on')
    stopAudio()
    if (wasOn) return
    try {
        audioBtn.textContent = 'Mic: …'
        await audio.start()
        audioBtn.textContent = 'Mic: On'
        audioBtn.classList.add('on')
        audioMeter.classList.add('visible')
    } catch (err) {
        resetAudioUI()
        alert('Mic access denied: ' + err.message)
    }
})

audioFileBtn.addEventListener('click', () => audioFileInput.click())

audioFileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0]
    if (!file) return
    stopAudio()

    // Attach to DOM (hidden) — some browsers won't route detached audio
    // elements through createMediaElementSource.
    const audioEl = document.createElement('audio')
    audioEl.src = URL.createObjectURL(file)
    audioEl.loop = true
    audioEl.style.display = 'none'
    document.body.appendChild(audioEl)
    currentAudioFile = audioEl

    // Kick off play() synchronously so it's inside the file-input user gesture.
    const playPromise = audioEl.play()

    try {
        await audio.startFromElement(audioEl)
        await playPromise
        const short = file.name.length > 18 ? file.name.slice(0, 18) + '…' : file.name
        audioFileBtn.textContent = '♪ ' + short
        audioFileBtn.classList.add('on')
        audioMeter.classList.add('visible')
    } catch (err) {
        console.error('Audio file load failed:', err)
        stopAudio()
        alert('Failed to play audio: ' + err.message)
    }

    // Reset input so choosing the same file again still fires `change`.
    audioFileInput.value = ''
})

// ---------- Sliders ----------

const sliders = new SliderManager({
    depth:       { selector: '#depth',       default: 1.0 },
    pointSize:   { selector: '#pointSize',   default: 2.0 },
    blurRadius:  { selector: '#blurRadius',  default: 3.0 },
    colorBoost:  { selector: '#colorBoost',  default: 0.3 },
    invert:      { selector: '#invert',      default: false, type: 'checkbox' },
    depthShade:  { selector: '#depthShade',  default: true,  type: 'checkbox' },
})

// ---------- Recording ----------

const recorder = setupRecording(canvas, {
    onStateChange(recording) {
        if (recording) {
            renderer.setPixelRatio(1)
            renderer.setSize(canvas.width, canvas.height, false)
            camera.aspect = canvas.width / canvas.height
            camera.updateProjectionMatrix()
            uniforms.u_pixelRatio.value = 1
        }
    },
})

document.addEventListener('keydown', (e) => {
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// ---------- Orbit camera (mouse drag, wheel zoom) ----------

let isDragging = false
let prevMouse = { x: 0, y: 0 }
let rotY = 0
let rotX = 0

canvas.addEventListener('mousedown', (e) => {
    isDragging = true
    prevMouse = { x: e.clientX, y: e.clientY }
})
window.addEventListener('mouseup', () => { isDragging = false })
window.addEventListener('mousemove', (e) => {
    if (!isDragging) return
    rotY += (e.clientX - prevMouse.x) * 0.005
    rotX += (e.clientY - prevMouse.y) * 0.005
    rotX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, rotX))
    prevMouse = { x: e.clientX, y: e.clientY }
})
canvas.addEventListener('wheel', (e) => {
    e.preventDefault()
    camera.position.z = Math.max(0.8, Math.min(20, camera.position.z + e.deltaY * 0.003))
}, { passive: false })

// ---------- Resize ----------

window.addEventListener('resize', () => {
    if (recorder.isRecording?.()) return
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.setSize(window.innerWidth, window.innerHeight)
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    uniforms.u_pixelRatio.value = window.devicePixelRatio
})

// ---------- Default image ----------

loadImageElement('/images/artists/engel-portrait.jpg')

// ---------- Render loop ----------

const startTime = performance.now()

function animate() {
    uniforms.u_time.value       = (performance.now() - startTime) / 1000
    uniforms.u_depth.value      = sliders.get('depth')
    uniforms.u_pointSize.value  = sliders.get('pointSize')
    uniforms.u_blurRadius.value = sliders.get('blurRadius')
    uniforms.u_colorBoost.value = sliders.get('colorBoost')
    uniforms.u_invert.value     = sliders.get('invert') ? 1.0 : 0.0
    uniforms.u_depthShade.value = sliders.get('depthShade') ? 1.0 : 0.0

    if (audio.running) {
        const v = audio.values
        uniforms.u_level.value  = v.energy
        uniforms.u_bass.value   = v.bass
        uniforms.u_treble.value = v.treble
        audioMeterFill.style.width = Math.min(100, v.energy * 400) + '%'
    } else {
        uniforms.u_level.value = 0
        uniforms.u_bass.value = 0
        uniforms.u_treble.value = 0
    }

    points.rotation.y = rotY
    points.rotation.x = rotX

    renderer.render(scene, camera)
    requestAnimationFrame(animate)
}
requestAnimationFrame(animate)

// Voronoi stippling via Lloyd's relaxation, after Mike Bostock's
// "Voronoi Stippling" notebook (https://observablehq.com/@mbostock/voronoi-stippling).
//
// Algorithm per iteration:
//   1. For every pixel in the source, find the nearest stipple point and
//      accumulate (weight*x, weight*y, weight) where weight = darkness.
//   2. Move each point toward its weighted-centroid with overshoot 1.8.
//   3. Re-triangulate.
// The display canvas just renders dots; the heavy lifting happens in a
// lower-resolution offscreen "compute" canvas to keep find() loops fast.
import './style.css'
import './source-link.js'
import { Delaunay } from 'd3-delaunay'
import { SliderManager, setupRecording } from './controls.js'

const canvas = document.querySelector('#canvas')
const ctx = canvas.getContext('2d')

// Source pixels are read from this hidden canvas. Capping its longest side
// keeps the per-iteration find() loop bounded — the visible canvas can be
// any size; points are scaled up at render time.
const COMPUTE_MAX = 720
const computeCanvas = document.createElement('canvas')
const computeCtx = computeCanvas.getContext('2d', { willReadFrequently: true })
let computeW = 0, computeH = 0

let density = null     // Float32Array length W*H, weighted darkness
let points = null      // Float64Array length 2N, point coords in compute space
let pointCount = 0
let delaunay = null
// Reused per-Lloyd-step accumulators so we don't re-allocate each iteration.
let centroidAcc = null
let weightAcc = null

const sliders = new SliderManager({
    points:   { selector: '#points',   default: 4000 },
    dotSize:  { selector: '#dotSize',  default: 1.4 },
    contrast: { selector: '#contrast', default: 1.4 },
    iters:    { selector: '#iters',    default: 2 },
    respawn:  { selector: '#respawn',  default: 0.05 },
    invert:   { selector: '#invert',   default: false, type: 'checkbox' },
})

// Source state
let currentMode = 'webcam'
let webcamEl = null
let webcamReady = false
let imageEl = null
let videoEl = null
// Set whenever the source image/video changes; consumed by the frame loop
// so we re-seed points and rebuild density before the next iteration.
let needsReseed = false

const modeSelector = document.querySelector('#mode-selector')
const uploadControls = document.querySelector('#upload-controls')
const webcamStatus = document.querySelector('#webcam-status')
const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const loadingEl = document.querySelector('#loading')
const restartBtn = document.querySelector('#restart-btn')

const recorder = setupRecording(canvas, { keyboardShortcut: null })

// ---------- Sizing ----------

function setComputeSize() {
    const aspect = canvas.width / canvas.height
    let w, h
    if (aspect >= 1) {
        w = COMPUTE_MAX
        h = Math.max(2, Math.round(COMPUTE_MAX / aspect))
    } else {
        h = COMPUTE_MAX
        w = Math.max(2, Math.round(COMPUTE_MAX * aspect))
    }
    if (w === computeW && h === computeH) return false
    computeW = w
    computeH = h
    computeCanvas.width = w
    computeCanvas.height = h
    return true
}

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    if (setComputeSize()) needsReseed = true
}

// ---------- Source drawing ----------

function activeSource() {
    if (currentMode === 'webcam' && webcamReady && webcamEl && webcamEl.readyState >= 2) {
        return { el: webcamEl, w: webcamEl.videoWidth, h: webcamEl.videoHeight, dynamic: true }
    }
    if (videoEl && videoEl.readyState >= 2) {
        return { el: videoEl, w: videoEl.videoWidth, h: videoEl.videoHeight, dynamic: true }
    }
    if (imageEl && imageEl.complete && imageEl.naturalWidth > 0) {
        return { el: imageEl, w: imageEl.naturalWidth, h: imageEl.naturalHeight, dynamic: false }
    }
    return null
}

// Cover-fit the source into the compute canvas so the dot field always
// fills the screen, mirroring the default behavior of the old shader.
function drawSourceCover(src) {
    const aspect = computeW / computeH
    const srcAspect = src.w / src.h
    let sx, sy, sw, sh
    if (srcAspect > aspect) {
        sh = src.h
        sw = src.h * aspect
        sx = (src.w - sw) / 2
        sy = 0
    } else {
        sw = src.w
        sh = src.w / aspect
        sx = 0
        sy = (src.h - sh) / 2
    }
    computeCtx.drawImage(src.el, sx, sy, sw, sh, 0, 0, computeW, computeH)
}

function readDensity() {
    const data = computeCtx.getImageData(0, 0, computeW, computeH).data
    const len = computeW * computeH
    if (!density || density.length !== len) density = new Float32Array(len)
    const contrast = sliders.get('contrast')
    // Invert flips which luma end of the source attracts dots: off → dots
    // pile onto the dark areas (a dark drawing on white paper); on → dots
    // pile onto the bright areas (a chalk drawing on a blackboard).
    const invert = sliders.get('invert')
    for (let i = 0, j = 0; i < len; i++, j += 4) {
        const luma = (0.299 * data[j] + 0.587 * data[j + 1] + 0.114 * data[j + 2]) / 255
        const w = invert ? luma : 1 - luma
        density[i] = Math.pow(Math.max(0, w), contrast)
    }
}

// ---------- Points ----------

function reseedPoints() {
    if (!density) return
    const n = sliders.get('points') | 0
    pointCount = n
    points = new Float64Array(n * 2)
    centroidAcc = new Float64Array(n * 2)
    weightAcc = new Float64Array(n)

    // Rejection sampling weighted by density. Bostock's notebook does the
    // same — it gives a much better starting point than uniform random,
    // which matters when we only run a couple of Lloyd iterations per
    // frame (video/webcam can't ever fully converge).
    let placed = 0
    let safety = n * 200  // bail-out if the source is nearly all-bright
    while (placed < n && safety-- > 0) {
        const x = Math.random() * computeW
        const y = Math.random() * computeH
        const i = ((y | 0) * computeW + (x | 0))
        if (Math.random() < density[i]) {
            points[placed * 2] = x
            points[placed * 2 + 1] = y
            placed++
        }
    }
    // If safety exhausted (very pale source), fill the rest uniformly.
    while (placed < n) {
        points[placed * 2] = Math.random() * computeW
        points[placed * 2 + 1] = Math.random() * computeH
        placed++
    }
    delaunay = new Delaunay(points)
}

function lloydStep() {
    if (!delaunay || !density) return
    const n = pointCount
    centroidAcc.fill(0)
    weightAcc.fill(0)

    // Walk every pixel, find which point owns it. The `prev` hint makes
    // delaunay.find() near-constant-time for adjacent pixels because
    // they almost always belong to the same or a neighboring cell.
    let prev = 0
    let totalWeight = 0
    for (let y = 0, i = 0; y < computeH; y++) {
        for (let x = 0; x < computeW; x++, i++) {
            const w = density[i]
            if (w < 0.001) continue
            const j = delaunay.find(x, y, prev)
            prev = j
            weightAcc[j] += w
            centroidAcc[j * 2] += w * x
            centroidAcc[j * 2 + 1] += w * y
            totalWeight += w
        }
    }

    // Points whose cell contains almost no density are "stuck" — the
    // centroid is effectively undefined and Lloyd's leaves them where
    // they are. On a static image with 80+ iterations they slowly drift
    // out, but at 2 iterations/frame on video they never escape, which
    // shows up as scattered specks on the dark background. Respawn them
    // via rejection sampling so they rejoin the high-density region.
    // Threshold scales with average cell weight; slider == 0 disables
    // respawning entirely (pure Lloyd's).
    const respawnFraction = sliders.get('respawn')
    const stuckThreshold = respawnFraction > 0
        ? Math.max(1.0, (totalWeight / n) * respawnFraction)
        : -1

    // Successive over-relaxation: ω=1.8 overshoots the centroid, which
    // makes Lloyd's converge faster (Bostock uses the same value).
    const omega = 1.8
    for (let i = 0; i < n; i++) {
        const w = weightAcc[i]
        if (w < stuckThreshold) {
            for (let attempt = 0; attempt < 50; attempt++) {
                const rx = Math.random() * computeW
                const ry = Math.random() * computeH
                const idx = (ry | 0) * computeW + (rx | 0)
                if (Math.random() < density[idx]) {
                    points[i * 2] = rx
                    points[i * 2 + 1] = ry
                    break
                }
            }
        } else {
            const cx = centroidAcc[i * 2] / w
            const cy = centroidAcc[i * 2 + 1] / w
            points[i * 2] += (cx - points[i * 2]) * omega
            points[i * 2 + 1] += (cy - points[i * 2 + 1]) * omega
        }
    }
    delaunay.update()
}

// ---------- Render ----------

function render() {
    const invert = sliders.get('invert')
    ctx.fillStyle = invert ? '#000' : '#fff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    if (!points) return

    const sx = canvas.width / computeW
    const sy = canvas.height / computeH
    const r = sliders.get('dotSize') * Math.min(sx, sy) * 0.6
    ctx.fillStyle = invert ? '#fff' : '#000'
    ctx.beginPath()
    for (let i = 0; i < pointCount; i++) {
        const x = points[i * 2] * sx
        const y = points[i * 2 + 1] * sy
        ctx.moveTo(x + r, y)
        ctx.arc(x, y, r, 0, Math.PI * 2)
    }
    ctx.fill()
}

// ---------- Source loaders ----------

function clearStaticSources() {
    if (videoEl) {
        videoEl.pause()
        if (videoEl.src) URL.revokeObjectURL(videoEl.src)
        videoEl = null
    }
    imageEl = null
    // Drop the point cloud too — otherwise the next render keeps drawing
    // dots from the old source while the new one is still loading.
    points = null
    pointCount = 0
}

function loadImage(url, revoke) {
    clearStaticSources()
    loadingEl?.classList.remove('hidden')
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
        imageEl = img
        if (revoke) URL.revokeObjectURL(url)
        loadingEl?.classList.add('hidden')
        needsReseed = true
    }
    img.onerror = () => {
        loadingEl?.classList.add('hidden')
        alert('Could not load image')
    }
    img.src = url
}

function loadVideo(url, revoke) {
    clearStaticSources()
    loadingEl?.classList.remove('hidden')
    const v = document.createElement('video')
    v.crossOrigin = 'anonymous'
    v.muted = true
    v.loop = true
    v.playsInline = true
    v.addEventListener('loadeddata', () => {
        v.play()
        videoEl = v
        loadingEl?.classList.add('hidden')
        needsReseed = true
    })
    v.addEventListener('error', () => {
        loadingEl?.classList.add('hidden')
        if (revoke) URL.revokeObjectURL(url)
        alert('Could not load video')
    })
    v.src = url
}

function loadFile(file) {
    if (!file) return
    const url = URL.createObjectURL(file)
    if (file.type.startsWith('video/')) loadVideo(url, true)
    else if (file.type.startsWith('image/')) loadImage(url, true)
    else alert('Please drop an image or video')
}

function loadUrl(url) {
    if (!url) return
    if (/\.(mp4|webm|ogv|mov)(\?|$)/i.test(url)) loadVideo(url, false)
    else loadImage(url, false)
}

// ---------- Webcam ----------

async function initWebcam() {
    webcamStatus.classList.remove('hidden')
    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: 'user' },
        })
        webcamEl = document.createElement('video')
        webcamEl.srcObject = stream
        webcamEl.playsInline = true
        webcamEl.muted = true
        await webcamEl.play()
        webcamReady = true
        webcamStatus.classList.add('hidden')
        needsReseed = true
    } catch (err) {
        console.error('Webcam error:', err)
        webcamStatus.innerHTML = '<p>Could not access webcam.</p>'
    }
}

// ---------- Mode UI ----------

function switchMode(mode) {
    currentMode = mode
    modeSelector.querySelectorAll('button').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.mode === mode)
    })
    uploadControls.style.display = 'none'
    webcamStatus.classList.add('hidden')

    if (mode === 'webcam') {
        clearStaticSources()
        if (!webcamReady) initWebcam()
        else needsReseed = true
    } else if (mode === 'upload') {
        // No source yet until a file is dropped — clear points so the
        // canvas isn't showing stale webcam dots in the meantime.
        points = null
        pointCount = 0
        uploadControls.style.display = 'flex'
        needsReseed = true
    }
}

modeSelector.querySelectorAll('button').forEach((btn) => {
    btn.addEventListener('click', () => switchMode(btn.dataset.mode))
})

if (dropZone) {
    dropZone.addEventListener('click', () => fileInput?.click())
    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault()
        dropZone.classList.add('dragover')
    })
    dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'))
    dropZone.addEventListener('drop', (e) => {
        e.preventDefault()
        dropZone.classList.remove('dragover')
        loadFile(e.dataTransfer.files[0])
    })
}
fileInput?.addEventListener('change', (e) => loadFile(e.target.files[0]))
loadUrlBtn?.addEventListener('click', () => loadUrl(urlInput.value))
urlInput?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadUrl(urlInput.value)
})

restartBtn?.addEventListener('click', () => { needsReseed = true })

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === '1') switchMode('webcam')
    if (e.key === '2') switchMode('upload')
    if (e.key === 'i' || e.key === 'I') {
        // sliders.set() doesn't dispatch a change event, so trigger the
        // reseed manually to keep the keyboard shortcut in sync with the
        // checkbox click behavior.
        sliders.set('invert', !sliders.get('invert'))
        needsReseed = true
    }
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
    if (e.key === ' ') {
        e.preventDefault()
        needsReseed = true
    }
})

// Re-seed when the user changes how many points to use, or when invert
// flips which luma end attracts dots (the high-weight pixels move to the
// other side of the histogram, so the existing point cloud is now in the
// wrong places — a fresh seed is the simplest way to redistribute).
document.querySelector('#points').addEventListener('change', () => { needsReseed = true })
document.querySelector('#invert').addEventListener('change', () => { needsReseed = true })

window.addEventListener('resize', resize)
resize()
switchMode('webcam')

// ---------- Frame loop ----------

function frame() {
    const src = activeSource()
    if (src) {
        // For dynamic sources, refresh density every frame so the point
        // field follows motion. For static images we only resample on
        // reseed (skip the cost of redrawing every frame).
        if (src.dynamic || needsReseed) {
            drawSourceCover(src)
            readDensity()
        }
        if (needsReseed) {
            reseedPoints()
            needsReseed = false
        }
        const iters = sliders.get('iters') | 0
        for (let i = 0; i < iters; i++) lloydStep()
    }
    render()
    requestAnimationFrame(frame)
}

requestAnimationFrame(frame)

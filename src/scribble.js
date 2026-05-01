import './style.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import { CanvasRecorder } from './recorder.js'
import { extractLuminance, runSimulation, runCurlSimulation, runPointsSimulation } from './scribble-flowfield.js'
import scribbleShader from './shaders/scribble/scribble.glsl'
import linesShader from './shaders/scribble/scribble-lines.glsl'
import flowfieldShader from './shaders/scribble/flowfield.glsl'

let textureSize = { width: 1, height: 1 }
const bgColor = [0.9, 0.05, 0.05]

// ---- 2D simulation state ----
let imageSource = null
let lumData = null
let active2dMode = null // null, 'flowfield', or 'curl'
let animFrame = null
let debounceTimer = null

function is2dMode(name) { return name === 'flowfield' || name === 'curl' || name === 'points' }

// Create 2D canvas overlay (hidden by default)
const canvas2d = document.createElement('canvas')
canvas2d.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;display:none;'
document.body.insertBefore(canvas2d, document.body.firstChild)

function isVideo() {
    return imageSource && imageSource.tagName === 'VIDEO'
}

function getFlowfieldParams() {
    return {
        lineCount: 30 * (page.sliders?.get('density') || 1),
        loopStrength: (page.sliders?.get('circleSize') || 1),
        noiseFreq: 0.006 * (page.sliders?.get('ellipse') || 1),
        strokeWeight: (page.sliders?.get('strokeWeight') || 2.5) * 0.35,
        contrast: page.sliders?.get('contrast') || 1.5,
        neighborRank: Math.round(page.sliders?.get('neighbor') || 1),
    }
}

function jitterSpeed() {
    return page.sliders?.get('jitter') || 0
}

// Run one frame of the simulation (dispatches to the right mode)
function render2dFrame(time) {
    canvas2d.width = window.innerWidth
    canvas2d.height = window.innerHeight

    const params = getFlowfieldParams()

    if (isVideo() && !imageSource.paused) {
        lumData = extractLuminance(imageSource, params.contrast)
    }

    params.time = time * 0.001 * jitterSpeed()

    if (active2dMode === 'curl') {
        runCurlSimulation(canvas2d, lumData, params)
    } else if (active2dMode === 'points') {
        runPointsSimulation(canvas2d, lumData, params)
    } else {
        runSimulation(canvas2d, lumData, params)
    }
}

// Animation loop — runs when jitter > 0 or video is playing
function start2dLoop() {
    stop2dLoop()
    if (!active2dMode) return

    function tick(time) {
        if (!active2dMode) return
        render2dFrame(time)

        if (jitterSpeed() > 0 || isVideo()) {
            animFrame = requestAnimationFrame(tick)
        }
    }

    if (jitterSpeed() > 0 || isVideo()) {
        animFrame = requestAnimationFrame(tick)
    } else {
        render2dFrame(0)
    }
}

function stop2dLoop() {
    if (animFrame) {
        cancelAnimationFrame(animFrame)
        animFrame = null
    }
}

function debouncedStaticRender() {
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
        if (active2dMode && jitterSpeed() === 0 && !isVideo()) {
            render2dFrame(0)
        }
    }, 250)
}

// ---- Contextual slider labels ----
const sliderLabels = {
    circles:   { circleSize: 'Circle Size', ellipse: 'Ellipse',   jitter: 'Jitter' },
    lines:     { circleSize: 'Line Scale',  ellipse: 'Ellipse',   jitter: 'Jitter' },
    flowfield: { circleSize: 'Loop Size',   ellipse: 'Loop Freq', jitter: 'Animate' },
    curl:      { circleSize: 'Loop Size',   ellipse: 'Loop Freq', jitter: 'Animate' },
    points:    { circleSize: 'Threshold',   ellipse: 'Smoothing', jitter: 'Animate' },
}

// Show/hide the neighbor slider based on mode
function updateNeighborVisibility(mode) {
    const el = document.querySelector('#neighbor')
    if (el) el.closest('label').style.display = mode === 'points' ? '' : 'none'
}

function updateSliderLabels(mode) {
    const labels = sliderLabels[mode]
    if (!labels) return
    for (const [id, text] of Object.entries(labels)) {
        const el = document.querySelector(`#${id}`)
        const span = el?.closest('label')?.querySelector('span')
        if (span) span.textContent = text
    }
}

// ---- Shader page ----
// flowfield.glsl is a dummy shader (hidden behind canvas2d when active)
const page = createShaderPage({
    shaders: {
        circles: scribbleShader,
        lines: linesShader,
        flowfield: flowfieldShader,
        curl: flowfieldShader, // reuse dummy shader
        points: flowfieldShader,
    },
    uniforms: [
        'resolution', 'time', 'texture', 'textureSize',
        'density', 'circleSize', 'contrast', 'jitter',
        'ellipse', 'strokeWeight', 'bgColor', 'neighbor',
    ],
    defaultEffect: 'circles',
    sliders: {
        density:      { selector: '#density',      default: 1.0 },
        circleSize:   { selector: '#circleSize',   default: 1.0 },
        contrast:     { selector: '#contrast',     default: 1.5 },
        jitter:       { selector: '#jitter',       default: 1.0 },
        ellipse:      { selector: '#ellipse',      default: 1.0 },
        strokeWeight: { selector: '#strokeWeight', default: 2.5 },
        neighbor:     { selector: '#neighbor',     default: 1 },
    },
    onSwitch({ name }) {
        updateSliderLabels(name)
        updateNeighborVisibility(name)
        active2dMode = is2dMode(name) ? name : null
        canvas2d.style.display = active2dMode ? '' : 'none'
        page.canvas.style.display = active2dMode ? 'none' : ''
        if (active2dMode) {
            if (imageSource && !lumData) {
                const params = getFlowfieldParams()
                lumData = extractLuminance(imageSource, params.contrast)
            }
            start2dLoop()
        } else {
            stop2dLoop()
        }
    },
    onRender({ gl, u, current }) {
        if (is2dMode(current)) return
        gl.uniform3f(u.bgColor, bgColor[0], bgColor[1], bgColor[2])
        if (media.hasMedia && media.texture) {
            gl.activeTexture(gl.TEXTURE0)
            media.updateVideoFrame()
            gl.bindTexture(gl.TEXTURE_2D, media.texture)
            gl.uniform1i(u.texture, 0)
            gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
        }
    },
})

// ---- Recording: swap recorder based on active mode ----
const recordBtn = document.querySelector('#record-btn')
const recorder2d = new CanvasRecorder(canvas2d, {
    fps: 14,
    onStateChange: (recording) => {
        if (recordBtn) recordBtn.classList.toggle('recording', recording)
    },
})

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    if (e.key === 'r' || e.key === 'R') {
        if (active2dMode) {
            e.stopImmediatePropagation()
            recorder2d.toggle()
        }
    }
}, true)

if (recordBtn) {
    recordBtn.addEventListener('click', (e) => {
        if (active2dMode) {
            e.stopImmediatePropagation()
            recorder2d.toggle()
        }
    }, true)
}

// Hide neighbor slider on initial load (only visible in points mode)
updateNeighborVisibility('circles')

const media = createMediaLoader(page.gl, {
    onLoad: (source, size) => {
        textureSize = size
        imageSource = source
        const params = getFlowfieldParams()
        lumData = extractLuminance(source, params.contrast)
        if (active2dMode) start2dLoop()
    },
})
page.attachMedia(media)

// Re-run on slider changes
document.querySelectorAll('#sliders input').forEach(input => {
    input.addEventListener('input', () => {
        if (!active2dMode) return
        if (input.id === 'jitter') {
            start2dLoop()
        } else {
            if (input.id === 'contrast' && imageSource) {
                const params = getFlowfieldParams()
                lumData = extractLuminance(imageSource, params.contrast)
            }
            if (jitterSpeed() === 0 && !isVideo()) {
                debouncedStaticRender()
            }
        }
    })
})

window.addEventListener('resize', () => {
    if (active2dMode && jitterSpeed() === 0 && !isVideo()) {
        debouncedStaticRender()
    }
})

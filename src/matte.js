import './matte.css'
import './source-link.js'
import { createProgram } from './webgl.js'
import { setupRecording, SliderManager } from './controls.js'

import vertSource from './shaders/matte/vert.glsl'
import fragSource from './shaders/matte/composite.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// ============== PROGRAM ==============

const program = createProgram(gl, vertSource, fragSource)
if (!program) throw new Error('Failed to create matte program')

const u = {
    back:         gl.getUniformLocation(program, 'u_back'),
    front:        gl.getUniformLocation(program, 'u_front'),
    matte:        gl.getUniformLocation(program, 'u_matte'),
    backSize:     gl.getUniformLocation(program, 'u_backSize'),
    frontSize:    gl.getUniformLocation(program, 'u_frontSize'),
    matteSize:    gl.getUniformLocation(program, 'u_matteSize'),
    hasBack:      gl.getUniformLocation(program, 'u_hasBack'),
    hasFront:     gl.getUniformLocation(program, 'u_hasFront'),
    hasMatte:     gl.getUniformLocation(program, 'u_hasMatte'),
    resolution:   gl.getUniformLocation(program, 'u_resolution'),
    time:         gl.getUniformLocation(program, 'u_time'),
    drift:        gl.getUniformLocation(program, 'u_drift'),
    breath:       gl.getUniformLocation(program, 'u_breath'),
    jitter:       gl.getUniformLocation(program, 'u_jitter'),
    speed:        gl.getUniformLocation(program, 'u_speed'),
    softness:     gl.getUniformLocation(program, 'u_softness'),
    useLuminance: gl.getUniformLocation(program, 'u_useLuminance'),
}

// ============== FULLSCREEN QUAD ==============

const quad = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quad)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  1, -1,  -1,  1,
    -1,  1,  1, -1,   1,  1,
]), gl.STATIC_DRAW)

gl.useProgram(program)
const posLoc = gl.getAttribLocation(program, 'a_position')
gl.enableVertexAttribArray(posLoc)
gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0)

// ============== LAYERS (back / front / matte) ==============

function createLayer(name) {
    const layer = {
        name,
        texture: gl.createTexture(),
        size: { width: 1, height: 1 },
        loaded: false,
        videoSource: null,
    }

    gl.bindTexture(gl.TEXTURE_2D, layer.texture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    return layer
}

const layers = {
    back:  createLayer('back'),
    front: createLayer('front'),
    matte: createLayer('matte'),
}

function uploadImage(layer, image) {
    layer.videoSource = null
    gl.bindTexture(gl.TEXTURE_2D, layer.texture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
    layer.size = { width: image.width || image.videoWidth, height: image.height || image.videoHeight }
    layer.loaded = true
    document.querySelector(`#${layer.name}-zone`).classList.add('loaded')
}

function uploadVideo(layer, video) {
    layer.videoSource = video
    gl.bindTexture(gl.TEXTURE_2D, layer.texture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, video)
    layer.size = { width: video.videoWidth, height: video.videoHeight }
    layer.loaded = true
    document.querySelector(`#${layer.name}-zone`).classList.add('loaded')
}

function loadFile(layer, file) {
    if (file.type.startsWith('video/')) {
        const video = document.createElement('video')
        video.muted = true
        video.loop = true
        video.playsInline = true
        video.src = URL.createObjectURL(file)
        video.addEventListener('loadeddata', () => {
            video.play()
            uploadVideo(layer, video)
        })
        return
    }
    if (!file.type.startsWith('image/')) {
        alert('Please drop an image or video')
        return
    }
    const reader = new FileReader()
    reader.onload = (e) => {
        const img = new Image()
        img.onload = () => uploadImage(layer, img)
        img.src = e.target.result
    }
    reader.readAsDataURL(file)
}

function wireZone(layer) {
    const zone = document.querySelector(`#${layer.name}-zone`)
    const input = document.querySelector(`#${layer.name}-input`)

    zone.addEventListener('click', () => input.click())
    zone.addEventListener('dragover', (e) => {
        e.preventDefault()
        zone.classList.add('dragover')
    })
    zone.addEventListener('dragleave', () => zone.classList.remove('dragover'))
    zone.addEventListener('drop', (e) => {
        e.preventDefault()
        zone.classList.remove('dragover')
        const file = e.dataTransfer.files[0]
        if (file) loadFile(layer, file)
    })
    input.addEventListener('change', (e) => {
        const file = e.target.files[0]
        if (file) loadFile(layer, file)
    })
}

wireZone(layers.back)
wireZone(layers.front)
wireZone(layers.matte)

// ============== CONTROLS ==============

const sliders = new SliderManager({
    drift:    { selector: '#drift',    default: 0.06 },
    breath:   { selector: '#breath',   default: 0.06 },
    jitter:   { selector: '#jitter',   default: 0.04 },
    softness: { selector: '#softness', default: 0.08 },
    speed:    { selector: '#speed',    default: 1.0 },
})

const luminanceCheckbox = document.querySelector('#use-luminance')

setupRecording(canvas, { keyboardShortcut: 'r' })

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============

function bindLayer(layer, unit, sampler, sizeU, hasU) {
    gl.activeTexture(gl.TEXTURE0 + unit)
    if (layer.videoSource && !layer.videoSource.paused) {
        gl.bindTexture(gl.TEXTURE_2D, layer.texture)
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, layer.videoSource)
    } else {
        gl.bindTexture(gl.TEXTURE_2D, layer.texture)
    }
    gl.uniform1i(sampler, unit)
    gl.uniform2f(sizeU, layer.size.width, layer.size.height)
    gl.uniform1i(hasU, layer.loaded ? 1 : 0)
}

function render(time) {
    const t = time * 0.001

    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.useProgram(program)

    bindLayer(layers.back,  0, u.back,  u.backSize,  u.hasBack)
    bindLayer(layers.front, 1, u.front, u.frontSize, u.hasFront)
    bindLayer(layers.matte, 2, u.matte, u.matteSize, u.hasMatte)

    gl.uniform2f(u.resolution, canvas.width, canvas.height)
    gl.uniform1f(u.time, t)
    gl.uniform1f(u.drift,    sliders.get('drift'))
    gl.uniform1f(u.breath,   sliders.get('breath'))
    gl.uniform1f(u.jitter,   sliders.get('jitter'))
    gl.uniform1f(u.softness, sliders.get('softness'))
    gl.uniform1f(u.speed,    sliders.get('speed'))
    gl.uniform1i(u.useLuminance, luminanceCheckbox.checked ? 1 : 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

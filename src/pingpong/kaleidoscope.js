import '../kaleidoscope.css'
import '../source-link.js'
import { createProgram } from '../webgl.js'
import { setupRecording, SliderManager } from '../controls.js'
import { createMediaLoader } from '../media-loader.js'

import feedbackFrag from '../shaders/pingpong/kaleidoscope.glsl'
import presentFrag from '../shaders/pingpong/present.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, alpha: false })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// ============== PROGRAMS ==============

const vertSource = `
attribute vec2 a_position;
varying vec2 v_uv;
void main() {
    v_uv = a_position * 0.5 + 0.5;
    gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const feedbackProgram = createProgram(gl, vertSource, feedbackFrag)
const presentProgram  = createProgram(gl, vertSource, presentFrag)

const feedbackU = {
    prev:        gl.getUniformLocation(feedbackProgram, 'u_prev'),
    texture:     gl.getUniformLocation(feedbackProgram, 'u_texture'),
    textureSize: gl.getUniformLocation(feedbackProgram, 'u_textureSize'),
    hasTexture:  gl.getUniformLocation(feedbackProgram, 'u_hasTexture'),
    resolution:  gl.getUniformLocation(feedbackProgram, 'u_resolution'),
    time:        gl.getUniformLocation(feedbackProgram, 'u_time'),
    segments:    gl.getUniformLocation(feedbackProgram, 'u_segments'),
    zoom:        gl.getUniformLocation(feedbackProgram, 'u_zoom'),
    speed:       gl.getUniformLocation(feedbackProgram, 'u_speed'),
    decay:       gl.getUniformLocation(feedbackProgram, 'u_decay'),
}

const presentU = {
    tex: gl.getUniformLocation(presentProgram, 'u_tex'),
}

// ============== FULLSCREEN QUAD ==============

const quad = gl.createBuffer()
gl.bindBuffer(gl.ARRAY_BUFFER, quad)
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  1, -1,  -1,  1,
    -1,  1,  1, -1,   1,  1,
]), gl.STATIC_DRAW)

function bindQuad(program) {
    gl.bindBuffer(gl.ARRAY_BUFFER, quad)
    const loc = gl.getAttribLocation(program, 'a_position')
    gl.enableVertexAttribArray(loc)
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0)
}

// ============== PING-PONG BUFFERS ==============

function createFBO(w, h) {
    const tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    const fb = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)

    return { tex, fb, width: w, height: h }
}

let pingPong = null
let read, write

function rebuildFBOs() {
    const w = canvas.width
    const h = canvas.height
    pingPong = [createFBO(w, h), createFBO(w, h)]
    read = pingPong[0]
    write = pingPong[1]
    clear()
}

function clear() {
    for (const p of pingPong) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, p.fb)
        gl.clearColor(0, 0, 0, 1)
        gl.clear(gl.COLOR_BUFFER_BIT)
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
}

// ============== MEDIA ==============

let textureSize = { width: 1, height: 1 }
const media = createMediaLoader(gl, {
    onLoad: (_source, size) => { textureSize = size },
})

// ============== CONTROLS ==============

const sliders = new SliderManager({
    segments: { selector: '#segments', default: 6 },
    zoom:     { selector: '#zoom',     default: 1 },
    speed:    { selector: '#speed',    default: 0.5 },
    decay:    { selector: '#decay',    default: 0.85 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

document.addEventListener('keydown', (e) => {
    if (e.key === ' ') {
        e.preventDefault()
        clear()
    }
})

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    rebuildFBOs()
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============

const startTime = performance.now()

function render() {
    const t = (performance.now() - startTime) / 1000

    const segments = sliders.get('segments')
    const zoom     = sliders.get('zoom')
    const speed    = sliders.get('speed')
    const decay    = sliders.get('decay')

    // --- Pass 1: feedback (kaleidoscope + smear) → write FBO ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, write.fb)
    gl.viewport(0, 0, write.width, write.height)

    gl.useProgram(feedbackProgram)
    bindQuad(feedbackProgram)

    // unit 0: previous frame
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, read.tex)
    gl.uniform1i(feedbackU.prev, 0)

    // unit 1: media (image/video)
    gl.activeTexture(gl.TEXTURE1)
    if (media.hasMedia && media.texture) {
        media.updateVideoFrame()
        gl.bindTexture(gl.TEXTURE_2D, media.texture)
    }
    gl.uniform1i(feedbackU.texture, 1)
    gl.uniform1i(feedbackU.hasTexture, media.hasMedia ? 1 : 0)
    gl.uniform2f(feedbackU.textureSize, textureSize.width, textureSize.height)

    gl.uniform2f(feedbackU.resolution, write.width, write.height)
    gl.uniform1f(feedbackU.time, t)
    gl.uniform1f(feedbackU.segments, segments)
    gl.uniform1f(feedbackU.zoom, zoom)
    gl.uniform1f(feedbackU.speed, speed)
    gl.uniform1f(feedbackU.decay, decay)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // --- Pass 2: present → screen ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(presentProgram)
    bindQuad(presentProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, write.tex)
    gl.uniform1i(presentU.tex, 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // swap
    const tmp = read
    read = write
    write = tmp

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

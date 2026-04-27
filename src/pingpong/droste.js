import '../kaleidoscope.css'
import '../source-link.js'
import { createProgram } from '../webgl.js'
import { setupRecording, SliderManager } from '../controls.js'
import { createMediaLoader } from '../media-loader.js'

import feedbackFrag from '../shaders/pingpong/droste.glsl'
import presentFrag from '../shaders/pingpong/present.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, alpha: false })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

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
    prev:       gl.getUniformLocation(feedbackProgram, 'u_prev'),
    video:      gl.getUniformLocation(feedbackProgram, 'u_video'),
    hasVideo:   gl.getUniformLocation(feedbackProgram, 'u_hasVideo'),
    videoSize:  gl.getUniformLocation(feedbackProgram, 'u_videoSize'),
    resolution: gl.getUniformLocation(feedbackProgram, 'u_resolution'),
    time:       gl.getUniformLocation(feedbackProgram, 'u_time'),
    zoomR:      gl.getUniformLocation(feedbackProgram, 'u_zoomR'),
    rotation:   gl.getUniformLocation(feedbackProgram, 'u_rotation'),
    decay:      gl.getUniformLocation(feedbackProgram, 'u_decay'),
    videoGain:  gl.getUniformLocation(feedbackProgram, 'u_videoGain'),
    innerHole:  gl.getUniformLocation(feedbackProgram, 'u_innerHole'),
    twist:      gl.getUniformLocation(feedbackProgram, 'u_twist'),
}

const presentU = {
    tex: gl.getUniformLocation(presentProgram, 'u_tex'),
}

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

let videoSize = { width: 1, height: 1 }
const media = createMediaLoader(gl, {
    onLoad: (_source, size) => { videoSize = size },
})

const sliders = new SliderManager({
    zoomR:     { selector: '#zoomR',     default: 16 },
    rotation:  { selector: '#rotation',  default: 0 },
    decay:     { selector: '#decay',     default: 0.90 },
    videoGain: { selector: '#videoGain', default: 0.5 },
    innerHole: { selector: '#innerHole', default: 0.18 },
    twist:     { selector: '#twist',     default: 1.0 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

document.addEventListener('keydown', (e) => {
    if (e.key === ' ') {
        e.preventDefault()
        clear()
    }
})

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    rebuildFBOs()
}
window.addEventListener('resize', resize)
resize()

const startTime = performance.now()

function render() {
    const t = (performance.now() - startTime) / 1000

    const zoomR     = sliders.get('zoomR')
    const rotation  = sliders.get('rotation')
    const decay     = sliders.get('decay')
    const videoGain = sliders.get('videoGain')
    const innerHole = sliders.get('innerHole')
    const twist     = sliders.get('twist')

    // --- Pass 1: Droste feedback → write FBO ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, write.fb)
    gl.viewport(0, 0, write.width, write.height)

    gl.useProgram(feedbackProgram)
    bindQuad(feedbackProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, read.tex)
    gl.uniform1i(feedbackU.prev, 0)

    gl.activeTexture(gl.TEXTURE1)
    if (media.hasMedia && media.texture) {
        media.updateVideoFrame()
        gl.bindTexture(gl.TEXTURE_2D, media.texture)
    }
    gl.uniform1i(feedbackU.video, 1)
    gl.uniform1i(feedbackU.hasVideo, media.hasMedia ? 1 : 0)
    gl.uniform2f(feedbackU.videoSize, videoSize.width, videoSize.height)

    gl.uniform2f(feedbackU.resolution, write.width, write.height)
    gl.uniform1f(feedbackU.time, t)
    gl.uniform1f(feedbackU.zoomR, zoomR)
    gl.uniform1f(feedbackU.rotation, rotation)
    gl.uniform1f(feedbackU.decay, decay)
    gl.uniform1f(feedbackU.videoGain, videoGain)
    gl.uniform1f(feedbackU.innerHole, innerHole)
    gl.uniform1f(feedbackU.twist, twist)

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

    const tmp = read
    read = write
    write = tmp

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

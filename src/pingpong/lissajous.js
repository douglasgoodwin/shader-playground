import '../pingpong.css'
import '../source-link.js'
import { createProgram } from '../webgl.js'
import { setupRecording, SliderManager } from '../controls.js'

import feedbackFrag from '../shaders/pingpong/feedback.glsl'
import presentFrag from '../shaders/pingpong/present.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, alpha: false })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// ============== SHARED VERTEX SHADER ==============
// Fullscreen quad that also forwards uv into the frag shader.

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
    time:       gl.getUniformLocation(feedbackProgram, 'u_time'),
    decay:      gl.getUniformLocation(feedbackProgram, 'u_decay'),
    radius:     gl.getUniformLocation(feedbackProgram, 'u_radius'),
    hue:        gl.getUniformLocation(feedbackProgram, 'u_hue'),
    resolution: gl.getUniformLocation(feedbackProgram, 'u_resolution'),
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
// Byte-backed RGBA textures are widely supported and plenty for a smear.
// Linear filtering lets us sample the previous frame smoothly at any uv.

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

// ============== CONTROLS ==============

const sliders = new SliderManager({
    decay:  { selector: '#decay',  default: 0.96 },
    speed:  { selector: '#speed',  default: 0.8 },
    radius: { selector: '#radius', default: 0.025 },
    hue:    { selector: '#hue',    default: 0.58 },
})

setupRecording(canvas, { keyboardShortcut: 'r' })

// Spacebar clears the trail buffer
document.addEventListener('keydown', (e) => {
    if (e.key === ' ') {
        e.preventDefault()
        clear()
    }
})

function clear() {
    for (const p of pingPong) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, p.fb)
        gl.clearColor(0, 0, 0, 1)
        gl.clear(gl.COLOR_BUFFER_BIT)
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
}

// ============== RESIZE ==============

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    rebuildFBOs()
}
window.addEventListener('resize', resize)
resize()

// ============== RENDER LOOP ==============

let simTime = 0
let lastRaf = 0

function render(now) {
    const dt = lastRaf === 0 ? 0 : Math.min((now - lastRaf) / 1000, 0.05)
    lastRaf = now

    const decay  = sliders.get('decay')
    const speed  = sliders.get('speed')
    const radius = sliders.get('radius')
    const hue    = sliders.get('hue')

    simTime += dt * speed

    // --- Pass 1: feedback --- write = decay(read) + newShape
    gl.bindFramebuffer(gl.FRAMEBUFFER, write.fb)
    gl.viewport(0, 0, write.width, write.height)

    gl.useProgram(feedbackProgram)
    bindQuad(feedbackProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, read.tex)
    gl.uniform1i(feedbackU.prev, 0)
    gl.uniform1f(feedbackU.time, simTime)
    gl.uniform1f(feedbackU.decay, decay)
    gl.uniform1f(feedbackU.radius, radius)
    gl.uniform1f(feedbackU.hue, hue)
    gl.uniform2f(feedbackU.resolution, write.width, write.height)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // --- Pass 2: present --- copy write to screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.useProgram(presentProgram)
    bindQuad(presentProgram)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, write.tex)
    gl.uniform1i(presentU.tex, 0)

    gl.drawArrays(gl.TRIANGLES, 0, 6)

    // swap read/write for next frame
    const tmp = read
    read = write
    write = tmp

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

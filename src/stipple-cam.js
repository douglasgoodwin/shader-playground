import './style.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import stippleShader from './shaders/stipple.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// Create shader program
const program = createProgram(gl, vertexShader, stippleShader)
if (!program) {
    throw new Error('Failed to create shader program')
}

gl.useProgram(program)
createFullscreenQuad(gl, program)

// Get uniform locations
const uniforms = {
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    time: gl.getUniformLocation(program, 'u_time'),
    video: gl.getUniformLocation(program, 'u_video'),
    videoSize: gl.getUniformLocation(program, 'u_videoSize'),
    dotDensity: gl.getUniformLocation(program, 'u_dotDensity'),
    dotScale: gl.getUniformLocation(program, 'u_dotScale'),
    contrast: gl.getUniformLocation(program, 'u_contrast'),
    showLines: gl.getUniformLocation(program, 'u_showLines'),
    invert: gl.getUniformLocation(program, 'u_invert'),
}

// Slider parameters (including checkboxes)
const sliders = new SliderManager({
    density:   { selector: '#density',   default: 1.0, uniform: 'dotDensity' },
    dotScale:  { selector: '#dotScale',  default: 1.0 },
    contrast:  { selector: '#contrast',  default: 1.5 },
    showLines: { selector: '#showLines', default: false, type: 'checkbox' },
    invert:    { selector: '#invert',    default: false, type: 'checkbox' },
})

// Recording
const recorder = setupRecording(canvas, { keyboardShortcut: null })

// Webcam state
let videoTexture = null
let videoElement = null
let videoSize = { width: 640, height: 480 }
let webcamReady = false

const webcamStatus = document.querySelector('#webcam-status')

// Create video texture
function createVideoTexture() {
    if (videoTexture) {
        gl.deleteTexture(videoTexture)
    }
    videoTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    return videoTexture
}

// Initialize webcam
async function initWebcam() {
    webcamStatus.classList.remove('hidden')

    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: {
                width: { ideal: 1280 },
                height: { ideal: 720 },
                facingMode: 'user'
            }
        })

        videoElement = document.createElement('video')
        videoElement.srcObject = stream
        videoElement.playsInline = true
        videoElement.muted = true

        await videoElement.play()

        videoSize.width = videoElement.videoWidth
        videoSize.height = videoElement.videoHeight

        createVideoTexture()
        webcamReady = true
        webcamStatus.classList.add('hidden')

        console.log('Webcam initialized:', videoSize.width, 'x', videoSize.height)
    } catch (err) {
        console.error('Webcam error:', err)
        webcamStatus.innerHTML = '<p>Could not access webcam.</p>'
    }
}

// Update video texture from webcam
function updateVideoTexture() {
    if (!webcamReady || !videoElement || videoElement.readyState < 2) return

    gl.bindTexture(gl.TEXTURE_2D, videoTexture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoElement)
}

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === 'l' || e.key === 'L') {
        const newValue = !sliders.get('showLines')
        sliders.set('showLines', newValue)
    }
    if (e.key === 'i' || e.key === 'I') {
        const newValue = !sliders.get('invert')
        sliders.set('invert', newValue)
    }
    if (e.key === 'r' || e.key === 'R') {
        recorder.toggle()
    }
})

// Resize
function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.uniform2f(uniforms.resolution, canvas.width, canvas.height)
}

window.addEventListener('resize', resize)
resize()

// Initialize webcam
initWebcam()

// Render loop
function render(time) {
    const t = time * 0.001

    if (webcamReady) {
        updateVideoTexture()

        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, videoTexture)
        gl.uniform1i(uniforms.video, 0)

        gl.uniform1f(uniforms.time, t)
        gl.uniform2f(uniforms.videoSize, videoSize.width, videoSize.height)
        sliders.applyUniforms(gl, uniforms)

        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    requestAnimationFrame(render)
}

requestAnimationFrame(render)

import './home.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording } from './controls.js'
import vertexShader from './shaders/vertex.glsl'
import colorfieldShader from './shaders/colorfield.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.style.background = '#0a0c14'
} else {
    const program = createProgram(gl, vertexShader, colorfieldShader)

    if (program) {
        gl.useProgram(program)
        createFullscreenQuad(gl, program)

        const resolutionLoc = gl.getUniformLocation(program, 'u_resolution')
        const timeLoc = gl.getUniformLocation(program, 'u_time')

        setupRecording(canvas)

        function resize() {
            canvas.width = window.innerWidth
            canvas.height = window.innerHeight
            gl.viewport(0, 0, canvas.width, canvas.height)
            gl.uniform2f(resolutionLoc, canvas.width, canvas.height)
        }

        window.addEventListener('resize', resize)
        resize()

        function render(time) {
            gl.uniform1f(timeLoc, time * 0.001)
            gl.drawArrays(gl.TRIANGLES, 0, 6)
            requestAnimationFrame(render)
        }

        requestAnimationFrame(render)
    }
}

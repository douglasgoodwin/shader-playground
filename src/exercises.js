import './exercises.css'
import { createProgram, createFullscreenQuad } from './webgl.js'
import { setupRecording, MouseTracker } from './controls.js'
import vertexShader from './shaders/vertex.glsl'

// Basics
import ex1_1 from './shaders/exercises/ex1-1-color-mixing.glsl'
import ex1_2 from './shaders/exercises/ex1-2-gradient-position.glsl'
// Variables
import ex2_1 from './shaders/exercises/ex2-1-store-and-reuse.glsl'
import ex2_2 from './shaders/exercises/ex2-2-order-matters.glsl'
// Math
import ex3_1 from './shaders/exercises/ex3-1-sin-wave.glsl'
import ex3_2 from './shaders/exercises/ex3-2-mix-blend.glsl'
import ex3_3 from './shaders/exercises/ex3-3-step-cutoff.glsl'
// Shapes
import ex4_1 from './shaders/exercises/ex4-1-circle.glsl'
import ex4_2 from './shaders/exercises/ex4-2-multiple-circles.glsl'
import ex4_3 from './shaders/exercises/ex4-3-rectangle.glsl'
// Animation
import ex5_1 from './shaders/exercises/ex5-1-pulsing-circle.glsl'
import ex5_2 from './shaders/exercises/ex5-2-moving-circle.glsl'
import ex5_3 from './shaders/exercises/ex5-3-color-cycle.glsl'
// Symmetry
import ex6_1 from './shaders/exercises/ex6-1-two-halves.glsl'
import ex6_2 from './shaders/exercises/ex6-2-four-quadrants.glsl'
// Grids
import ex7_1 from './shaders/exercises/ex7-1-row-of-circles.glsl'
import ex7_2 from './shaders/exercises/ex7-2-grid-of-circles.glsl'
// Functions
import ex8_1 from './shaders/exercises/ex8-1-circle-function.glsl'
import ex8_2 from './shaders/exercises/ex8-2-ring-function.glsl'
// Challenges
import challengeA from './shaders/exercises/challenge-a-traffic-light.glsl'
import challengeB from './shaders/exercises/challenge-b-loading-spinner.glsl'
import challengeC from './shaders/exercises/challenge-c-gradient-sunset.glsl'
import challengeD from './shaders/exercises/challenge-d-spotlight.glsl'
// Intermediate - Hash Functions (from Desert Passage II analysis)
import ex9_1 from './shaders/exercises/ex9-1-hash-basics.glsl'
import ex9_2 from './shaders/exercises/ex9-2-hash-hoskins.glsl'
import ex9_3 from './shaders/exercises/ex9-3-hash-applications.glsl'
// Intermediate - Noise
import ex10_1 from './shaders/exercises/ex10-1-value-noise.glsl'
import ex10_2 from './shaders/exercises/ex10-2-gradient-noise.glsl'
import ex10_3 from './shaders/exercises/ex10-3-fbm.glsl'
// Intermediate - Raymarching
import ex11_1 from './shaders/exercises/ex11-1-raymarching-basics.glsl'
import ex11_2 from './shaders/exercises/ex11-2-sdf-shapes.glsl'
import ex11_3 from './shaders/exercises/ex11-3-smooth-blend.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

gl.getExtension('OES_standard_derivatives')

const shaders = {
    'ex1-1': ex1_1,
    'ex1-2': ex1_2,
    'ex2-1': ex2_1,
    'ex2-2': ex2_2,
    'ex3-1': ex3_1,
    'ex3-2': ex3_2,
    'ex3-3': ex3_3,
    'ex4-1': ex4_1,
    'ex4-2': ex4_2,
    'ex4-3': ex4_3,
    'ex5-1': ex5_1,
    'ex5-2': ex5_2,
    'ex5-3': ex5_3,
    'ex6-1': ex6_1,
    'ex6-2': ex6_2,
    'ex7-1': ex7_1,
    'ex7-2': ex7_2,
    'ex8-1': ex8_1,
    'ex8-2': ex8_2,
    'challenge-a': challengeA,
    'challenge-b': challengeB,
    'challenge-c': challengeC,
    'challenge-d': challengeD,
    // Intermediate - Hash
    'ex9-1': ex9_1,
    'ex9-2': ex9_2,
    'ex9-3': ex9_3,
    // Intermediate - Noise
    'ex10-1': ex10_1,
    'ex10-2': ex10_2,
    'ex10-3': ex10_3,
    // Intermediate - Raymarching
    'ex11-1': ex11_1,
    'ex11-2': ex11_2,
    'ex11-3': ex11_3,
}

const exerciseNames = {
    'ex1-1': 'Ex 1.1 - Color Mixing',
    'ex1-2': 'Ex 1.2 - Gradient Position',
    'ex2-1': 'Ex 2.1 - Store & Reuse',
    'ex2-2': 'Ex 2.2 - Order Matters',
    'ex3-1': 'Ex 3.1 - Sin Wave',
    'ex3-2': 'Ex 3.2 - Mix Blend',
    'ex3-3': 'Ex 3.3 - Step Cutoff',
    'ex4-1': 'Ex 4.1 - Circle',
    'ex4-2': 'Ex 4.2 - Multiple Circles',
    'ex4-3': 'Ex 4.3 - Rectangle',
    'ex5-1': 'Ex 5.1 - Pulsing Circle',
    'ex5-2': 'Ex 5.2 - Moving Circle',
    'ex5-3': 'Ex 5.3 - Color Cycle',
    'ex6-1': 'Ex 6.1 - Two Halves',
    'ex6-2': 'Ex 6.2 - Four Quadrants',
    'ex7-1': 'Ex 7.1 - Row of Circles',
    'ex7-2': 'Ex 7.2 - Grid of Circles',
    'ex8-1': 'Ex 8.1 - Circle Function',
    'ex8-2': 'Ex 8.2 - Ring Function',
    'challenge-a': 'Challenge A - Traffic Light',
    'challenge-b': 'Challenge B - Loading Spinner',
    'challenge-c': 'Challenge C - Gradient Sunset',
    'challenge-d': 'Challenge D - Spotlight',
    // Intermediate - Hash
    'ex9-1': 'Ex 9.1 - Hash Basics',
    'ex9-2': 'Ex 9.2 - Hash (Hoskins)',
    'ex9-3': 'Ex 9.3 - Hash Applications',
    // Intermediate - Noise
    'ex10-1': 'Ex 10.1 - Value Noise',
    'ex10-2': 'Ex 10.2 - Gradient Noise',
    'ex10-3': 'Ex 10.3 - FBM',
    // Intermediate - Raymarching
    'ex11-1': 'Ex 11.1 - Raymarching Basics',
    'ex11-2': 'Ex 11.2 - SDF Shapes',
    'ex11-3': 'Ex 11.3 - Smooth Blend',
}

const exerciseOrder = Object.keys(shaders)

const programs = {}
const uniforms = {}

for (const [name, fragmentShader] of Object.entries(shaders)) {
    const program = createProgram(gl, vertexShader, fragmentShader)
    if (program) {
        programs[name] = program
        uniforms[name] = {
            resolution: gl.getUniformLocation(program, 'u_resolution'),
            time: gl.getUniformLocation(program, 'u_time'),
            mouse: gl.getUniformLocation(program, 'u_mouse'),
        }
    }
}

let currentExercise = 'ex1-1'
let currentProgram = programs[currentExercise]
gl.useProgram(currentProgram)
createFullscreenQuad(gl, currentProgram)

const mouse = new MouseTracker(canvas)
const recorder = setupRecording(canvas, { keyboardShortcut: null })
const exerciseNameEl = document.querySelector('#exercise-name')

function switchExercise(name) {
    if (!programs[name]) return
    currentExercise = name
    currentProgram = programs[name]

    gl.useProgram(currentProgram)
    createFullscreenQuad(gl, currentProgram)

    const u = uniforms[currentExercise]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.exercise === name)
    })

    exerciseNameEl.textContent = exerciseNames[name] || name
}

function navigateExercise(direction) {
    const idx = exerciseOrder.indexOf(currentExercise)
    const next = idx + direction
    if (next >= 0 && next < exerciseOrder.length) {
        switchExercise(exerciseOrder[next])
    }
}

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)

    const u = uniforms[currentExercise]
    if (u && u.resolution) {
        gl.uniform2f(u.resolution, canvas.width, canvas.height)
    }
}

// Button clicks
document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.stopPropagation()
        switchExercise(btn.dataset.exercise)
    })
})

// Prev/next buttons
document.querySelector('#prev-btn').addEventListener('click', (e) => {
    e.stopPropagation()
    navigateExercise(-1)
})
document.querySelector('#next-btn').addEventListener('click', (e) => {
    e.stopPropagation()
    navigateExercise(1)
})

// Keyboard navigation
document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowLeft') navigateExercise(-1)
    if (e.key === 'ArrowRight') navigateExercise(1)
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

window.addEventListener('resize', resize)
resize()

// Set initial name
exerciseNameEl.textContent = exerciseNames[currentExercise]

function render(time) {
    const t = time * 0.001
    const u = uniforms[currentExercise]

    gl.uniform1f(u.time, t)
    mouse.applyUniform(gl, u.mouse)

    gl.drawArrays(gl.TRIANGLES, 0, 6)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

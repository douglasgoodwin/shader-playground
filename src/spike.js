import './spike.css'
import * as THREE from 'three'
import { setupRecording } from './controls.js'
import { createModelLoader } from './model-loader.js'

import breatheVert from './shaders/spike/breathe.vert'
import breatheFrag from './shaders/spike/breathe.frag'
import meltVert from './shaders/spike/melt.vert'
import meltFrag from './shaders/spike/melt.frag'
import glitchVert from './shaders/spike/glitch.vert'
import glitchFrag from './shaders/spike/glitch.frag'
import rippleVert from './shaders/spike/ripple.vert'
import rippleFrag from './shaders/spike/ripple.frag'
import erodeVert from './shaders/spike/erode.vert'
import erodeFrag from './shaders/spike/erode.frag'

// --- Setup ---
const canvas = document.getElementById('canvas')
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true })
renderer.setPixelRatio(window.devicePixelRatio)
renderer.setSize(window.innerWidth, window.innerHeight)

const scene = new THREE.Scene()
scene.background = new THREE.Color(0x111111)

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000)
camera.position.z = 5

const recorder = setupRecording(canvas)

// --- Shared uniforms ---
const uniforms = {
    u_time: { value: 0 },
    u_resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
    u_intensity: { value: 1.0 },
}

// --- Materials (each has a deforming vertex shader) ---
function makeMat(vert, frag, opts) {
    return new THREE.ShaderMaterial({
        vertexShader: vert,
        fragmentShader: frag,
        uniforms,
        ...opts,
    })
}

const materials = {
    breathe: makeMat(breatheVert, breatheFrag),
    melt:    makeMat(meltVert, meltFrag),
    glitch:  makeMat(glitchVert, glitchFrag, { transparent: true, side: THREE.DoubleSide }),
    ripple:  makeMat(rippleVert, rippleFrag),
    erode:   makeMat(erodeVert, erodeFrag, { transparent: true, side: THREE.DoubleSide }),
}

let activeEffect = 'breathe'
let mesh = null
let isDragging = false
let prevMouse = { x: 0, y: 0 }
let rotationY = 0
let rotationX = 0

// --- Model loading ---
function setGeometry(geometry) {
    if (mesh) scene.remove(mesh)
    mesh = new THREE.Mesh(geometry, materials[activeEffect])
    mesh.rotation.y = rotationY
    mesh.rotation.x = rotationX
    scene.add(mesh)
}

const modelLoader = createModelLoader({
    onLoad: (geometry, name) => setGeometry(geometry),
})

// Load default model
modelLoader.loadUrl('/threejs/printreadyspike.obj')

// --- Effect switching ---
function switchEffect(name) {
    if (!materials[name]) return
    activeEffect = name
    if (mesh) mesh.material = materials[name]

    document.querySelectorAll('#controls button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.effect === name)
    })
}

// Button clicks
document.querySelectorAll('#controls button').forEach(btn => {
    btn.addEventListener('click', () => switchEffect(btn.dataset.effect))
})

// Keyboard shortcuts
const effectNames = Object.keys(materials)
const keys = ['1', '2', '3', '4', '5']
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return
    const idx = keys.indexOf(e.key)
    if (idx >= 0 && idx < effectNames.length) switchEffect(effectNames[idx])
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// --- Intensity slider ---
const intensitySlider = document.getElementById('intensity')
intensitySlider.addEventListener('input', () => {
    uniforms.u_intensity.value = parseFloat(intensitySlider.value)
})

// --- Mouse orbit (no auto-spin) ---
canvas.addEventListener('mousedown', (e) => {
    isDragging = true
    prevMouse = { x: e.clientX, y: e.clientY }
})
window.addEventListener('mouseup', () => { isDragging = false })
window.addEventListener('mousemove', (e) => {
    if (!isDragging) return
    rotationY += (e.clientX - prevMouse.x) * 0.005
    rotationX += (e.clientY - prevMouse.y) * 0.005
    rotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, rotationX))
    prevMouse = { x: e.clientX, y: e.clientY }
})

canvas.addEventListener('wheel', (e) => {
    camera.position.z += e.deltaY * 0.005
    camera.position.z = Math.max(1, Math.min(50, camera.position.z))
})

// --- Resize ---
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize(window.innerWidth, window.innerHeight)
    uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight)
})

// --- Render loop (no auto-rotation) ---
function animate(time) {
    uniforms.u_time.value = time * 0.001

    if (mesh) {
        mesh.rotation.y = rotationY
        mesh.rotation.x = rotationX
    }

    renderer.render(scene, camera)
    requestAnimationFrame(animate)
}
requestAnimationFrame(animate)

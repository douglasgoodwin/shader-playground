import './threejs.css'
import * as THREE from 'three'
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js'
import blobVert from './shaders/threejs/blob.vert'
import blobFrag from './shaders/threejs/blob.frag'
import sculptureVert from './shaders/threejs/sculpture.vert'
import sculptureFrag from './shaders/threejs/sculpture.frag'
import bronzeFrag from './shaders/threejs/bronze.frag'
import hologramFrag from './shaders/threejs/hologram.frag'
import contourFrag from './shaders/threejs/contour.frag'
import halftoneFrag from './shaders/threejs/halftone.frag'
import xrayFrag from './shaders/threejs/xray.frag'

const canvas = document.getElementById('canvas')
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true })
renderer.setPixelRatio(window.devicePixelRatio)
renderer.setSize(window.innerWidth, window.innerHeight)

const scene = new THREE.Scene()
scene.background = new THREE.Color(0x111111)

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100)
camera.position.z = 4

const uniforms = {
    u_time: { value: 0 },
    u_resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
}

// --- Materials ---
function makeMat(vert, frag, opts) {
    return new THREE.ShaderMaterial({ vertexShader: vert, fragmentShader: frag, uniforms, ...opts })
}

const textureMaterials = {
    marble:   makeMat(sculptureVert, sculptureFrag),
    bronze:   makeMat(sculptureVert, bronzeFrag),
    hologram: makeMat(sculptureVert, hologramFrag, { transparent: true, side: THREE.DoubleSide }),
    contour:  makeMat(sculptureVert, contourFrag),
    halftone: makeMat(sculptureVert, halftoneFrag),
    xray:     makeMat(sculptureVert, xrayFrag, { transparent: true, side: THREE.DoubleSide }),
}

let activeTexture = 'marble'

// --- Pieces ---
const pieces = {}
let activePiece = null
let sculptureObj = null

// Blob
const blobMaterial = makeMat(blobVert, blobFrag)
pieces.blob = new THREE.Mesh(new THREE.IcosahedronGeometry(1.2, 64), blobMaterial)

// Sculpture — loaded async
const loader = new OBJLoader()
loader.load('/objs/atelier-louvre-head-of-woman.obj', (obj) => {
    obj.traverse((child) => {
        if (child.isMesh) {
            child.material = textureMaterials[activeTexture]
            if (!child.geometry.attributes.normal) {
                child.geometry.computeVertexNormals()
            }
        }
    })

    const box = new THREE.Box3().setFromObject(obj)
    const center = box.getCenter(new THREE.Vector3())
    const size = box.getSize(new THREE.Vector3())
    const scale = 3.0 / Math.max(size.x, size.y, size.z)
    obj.scale.setScalar(scale)
    obj.position.sub(center.multiplyScalar(scale))

    sculptureObj = obj
    pieces.sculpture = obj

    if (activePiece === 'sculpture') showPiece('sculpture')
})

function applySculptureMaterial() {
    if (!sculptureObj) return
    const mat = textureMaterials[activeTexture]
    sculptureObj.traverse((child) => {
        if (child.isMesh) child.material = mat
    })
}

// --- Piece switching ---
const textureSelect = document.getElementById('texture-select')
const textureDropdown = document.getElementById('texture')

function showPiece(name) {
    activePiece = name
    Object.values(pieces).forEach((p) => scene.remove(p))
    if (pieces[name]) scene.add(pieces[name])
    textureSelect.style.display = name === 'sculpture' ? '' : 'none'
}

showPiece('blob')

// Controls — piece buttons
const buttons = document.querySelectorAll('#controls button')
buttons.forEach((btn) => {
    btn.addEventListener('click', () => {
        buttons.forEach((b) => b.classList.remove('active'))
        btn.classList.add('active')
        showPiece(btn.dataset.piece)
    })
})

// Texture dropdown
textureDropdown.addEventListener('change', () => {
    activeTexture = textureDropdown.value
    applySculptureMaterial()
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') buttons[0]?.click()
    if (e.key === '2') buttons[1]?.click()
})

// --- Mouse orbit + zoom ---
let isDragging = false
let prevMouse = { x: 0, y: 0 }
let rotationY = 0
let rotationX = 0

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
    camera.position.z = Math.max(1, Math.min(10, camera.position.z))
})

window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize(window.innerWidth, window.innerHeight)
    uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight)
})

function animate(time) {
    uniforms.u_time.value = time * 0.001
    if (!isDragging) rotationY += 0.003

    const current = pieces[activePiece]
    if (current) {
        current.rotation.y = rotationY
        current.rotation.x = rotationX
    }

    renderer.render(scene, camera)
    requestAnimationFrame(animate)
}
requestAnimationFrame(animate)

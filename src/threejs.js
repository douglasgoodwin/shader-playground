import './threejs.css'
import './source-link.js'
import { setupRecording } from './controls.js'
import { createModelLoader } from './model-loader.js'
import * as THREE from 'three'
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js'
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'
import blobVert from './shaders/threejs/blob.vert'
import blobFrag from './shaders/threejs/blob.frag'
import sculptureVert from './shaders/threejs/sculpture.vert'
import sculptureFrag from './shaders/threejs/sculpture.frag'
import bronzeFrag from './shaders/threejs/bronze.frag'
import hologramFrag from './shaders/threejs/hologram.frag'
import contourFrag from './shaders/threejs/contour.frag'
import halftoneFrag from './shaders/threejs/halftone.frag'
import xrayFrag from './shaders/threejs/xray.frag'
import iridescentFrag from './shaders/threejs/iridescent.frag'
import wireframeFrag from './shaders/threejs/wireframe.frag'
import lavaFrag from './shaders/threejs/lava.frag'
import ceramicFrag from './shaders/threejs/ceramic.frag'

const canvas = document.getElementById('canvas')
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true })
renderer.setPixelRatio(window.devicePixelRatio)
renderer.setSize(window.innerWidth, window.innerHeight)

const scene = new THREE.Scene()
scene.background = new THREE.Color(0x111111)

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000)
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
    xray:       makeMat(sculptureVert, xrayFrag, { transparent: true, side: THREE.DoubleSide }),
    iridescent: makeMat(sculptureVert, iridescentFrag),
    wireframe:  makeMat(sculptureVert, wireframeFrag),
    lava:       makeMat(sculptureVert, lavaFrag),
    ceramic:    makeMat(sculptureVert, ceramicFrag),
}

let activeTexture = 'marble'
let instanceCount = 1

// --- Pieces ---
const pieces = {}
let activePiece = null
const objPieces = new Set(['sculpture', 'venus'])

// Store normalized geometries for instancing
const objGeometries = {}
// Currently displayed instanced group
let activeInstanceGroup = null

// Blob
const blobMaterial = makeMat(blobVert, blobFrag)
pieces.blob = new THREE.Mesh(new THREE.IcosahedronGeometry(1.2, 64), blobMaterial)

// Torus
pieces.torus = new THREE.Mesh(new THREE.TorusGeometry(1.0, 0.4, 64, 128), blobMaterial)

// Helper: load an OBJ, normalize its geometry, register as a piece
const loader = new OBJLoader()
function loadOBJ(url, pieceName) {
    loader.load(url, (obj) => {
        // Collect and merge all mesh geometries
        const geometries = []
        obj.traverse((child) => {
            if (child.isMesh) {
                const geo = child.geometry.clone()
                if (!geo.attributes.normal) geo.computeVertexNormals()
                geometries.push(geo)
            }
        })

        const merged = geometries.length > 1 ? mergeGeometries(geometries) : geometries[0]

        // Center and normalize to fit in a ~3-unit box
        merged.computeBoundingBox()
        const box = merged.boundingBox
        const center = box.getCenter(new THREE.Vector3())
        const size = box.getSize(new THREE.Vector3())
        const scale = 3.0 / Math.max(size.x, size.y, size.z)
        merged.translate(-center.x, -center.y, -center.z)
        merged.scale(scale, scale, scale)

        objGeometries[pieceName] = merged

        if (activePiece === pieceName) showPiece(pieceName)
    })
}

loadOBJ('/objs/atelier-louvre-head-of-woman.obj', 'sculpture')
loadOBJ('/lowpoly_venusdemilo.obj', 'venus')

// --- User OBJ upload ---
const modelLoader = createModelLoader({
    onLoad: (geometry) => {
        objGeometries.custom = geometry
        objPieces.add('custom')
        showPiece('custom')
        // Highlight the custom button if it exists, dim the built-in ones
        document.querySelectorAll('#controls button').forEach(b => b.classList.remove('active'))
    },
})

// Build an InstancedMesh (or plain Mesh for count=1) with random placements
function buildInstances(pieceName, count) {
    const geo = objGeometries[pieceName]
    if (!geo) return null

    const mat = textureMaterials[activeTexture]

    if (count === 1) {
        return new THREE.Mesh(geo, mat)
    }

    const instanced = new THREE.InstancedMesh(geo, mat, count)
    const dummy = new THREE.Object3D()

    // Spread radius scales with count so they don't all pile up
    const spread = 2 + Math.pow(count, 0.45) * 1.8
    const modelScale = Math.max(0.3, 1.0 - count * 0.0005)

    for (let i = 0; i < count; i++) {
        dummy.position.set(
            (Math.random() - 0.5) * spread * 2,
            (Math.random() - 0.5) * spread * 2,
            (Math.random() - 0.5) * spread * 2,
        )
        dummy.rotation.set(
            Math.random() * Math.PI * 2,
            Math.random() * Math.PI * 2,
            Math.random() * Math.PI * 2,
        )
        const s = modelScale * (0.5 + Math.random() * 0.5)
        dummy.scale.setScalar(s)
        dummy.updateMatrix()
        instanced.setMatrixAt(i, dummy.matrix)
    }

    instanced.instanceMatrix.needsUpdate = true
    return instanced
}

// --- Piece switching ---
const textureSelect = document.getElementById('texture-select')
const textureDropdown = document.getElementById('texture')
const copiesDropdown = document.getElementById('copies')

function clearActiveGroup() {
    if (activeInstanceGroup) {
        scene.remove(activeInstanceGroup)
        activeInstanceGroup = null
    }
    // Remove all non-OBJ pieces
    for (const p of Object.values(pieces)) scene.remove(p)
}

function showPiece(name) {
    activePiece = name
    clearActiveGroup()

    if (objPieces.has(name)) {
        textureSelect.style.display = ''
        const group = buildInstances(name, instanceCount)
        if (group) {
            activeInstanceGroup = group
            scene.add(group)
        }
    } else {
        textureSelect.style.display = 'none'
        if (pieces[name]) scene.add(pieces[name])
    }
}

function rebuildCurrentPiece() {
    if (objPieces.has(activePiece)) showPiece(activePiece)
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
    rebuildCurrentPiece()
})

// Copies dropdown
copiesDropdown.addEventListener('change', () => {
    instanceCount = parseInt(copiesDropdown.value, 10)
    // Pull camera back for larger counts
    if (instanceCount > 1) {
        camera.position.z = Math.max(camera.position.z, 4 + Math.pow(instanceCount, 0.45) * 2)
    }
    rebuildCurrentPiece()
})

// Recording
const recorder = setupRecording(canvas, {
    onStateChange(recording) {
        if (recording) {
            renderer.setPixelRatio(1)
            renderer.setSize(canvas.width, canvas.height, false)
            camera.aspect = canvas.width / canvas.height
            camera.updateProjectionMatrix()
            uniforms.u_resolution.value.set(canvas.width, canvas.height)
        }
    },
})

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === '1') buttons[0]?.click()
    if (e.key === '2') buttons[1]?.click()
    if (e.key === '3') buttons[2]?.click()
    if (e.key === '4') buttons[3]?.click()
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
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
    camera.position.z = Math.max(1, Math.min(200, camera.position.z))
})

window.addEventListener('resize', () => {
    if (recorder.isRecording()) return
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.setSize(window.innerWidth, window.innerHeight)
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight)
})

function animate(time) {
    uniforms.u_time.value = time * 0.001
    if (!isDragging) rotationY += 0.003

    // Rotate the whole group or single piece
    const target = activeInstanceGroup || pieces[activePiece]
    if (target) {
        target.rotation.y = rotationY
        target.rotation.x = rotationX
    }

    renderer.render(scene, camera)
    requestAnimationFrame(animate)
}
requestAnimationFrame(animate)

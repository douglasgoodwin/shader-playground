import './displace.css'
import { createProgram } from './webgl.js'
import { setupRecording } from './controls.js'
import terrainVert from './shaders/displace/terrain-vert.glsl'
import terrainFrag from './shaders/displace/terrain-frag.glsl'

const canvas = document.querySelector('#canvas')
const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

if (!gl) {
    document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
    throw new Error('WebGL not supported')
}

// --- Matrix math (minimal) ---

function perspective(fov, aspect, near, far) {
    const f = 1.0 / Math.tan(fov / 2)
    const nf = 1 / (near - far)
    return new Float32Array([
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) * nf, -1,
        0, 0, 2 * far * near * nf, 0,
    ])
}

function lookAt(eye, center, up) {
    const zx = eye[0] - center[0], zy = eye[1] - center[1], zz = eye[2] - center[2]
    let len = 1 / Math.sqrt(zx * zx + zy * zy + zz * zz)
    const z0 = zx * len, z1 = zy * len, z2 = zz * len

    const xx = up[1] * z2 - up[2] * z1
    const xy = up[2] * z0 - up[0] * z2
    const xz = up[0] * z1 - up[1] * z0
    len = 1 / Math.sqrt(xx * xx + xy * xy + xz * xz)
    const x0 = xx * len, x1 = xy * len, x2 = xz * len

    const y0 = z1 * x2 - z2 * x1
    const y1 = z2 * x0 - z0 * x2
    const y2 = z0 * x1 - z1 * x0

    return new Float32Array([
        x0, y0, z0, 0,
        x1, y1, z1, 0,
        x2, y2, z2, 0,
        -(x0 * eye[0] + x1 * eye[1] + x2 * eye[2]),
        -(y0 * eye[0] + y1 * eye[1] + y2 * eye[2]),
        -(z0 * eye[0] + z1 * eye[1] + z2 * eye[2]),
        1,
    ])
}

function mat4Multiply(a, b) {
    const out = new Float32Array(16)
    for (let i = 0; i < 4; i++) {
        for (let j = 0; j < 4; j++) {
            out[j * 4 + i] =
                a[i] * b[j * 4] +
                a[4 + i] * b[j * 4 + 1] +
                a[8 + i] * b[j * 4 + 2] +
                a[12 + i] * b[j * 4 + 3]
        }
    }
    return out
}

// --- Subdivided plane geometry ---

const GRID = 128

function createSubdividedPlane(gl, program) {
    const verts = (GRID + 1) * (GRID + 1)
    const positions = new Float32Array(verts * 3)
    const uvs = new Float32Array(verts * 2)

    for (let row = 0; row <= GRID; row++) {
        for (let col = 0; col <= GRID; col++) {
            const i = row * (GRID + 1) + col
            const u = col / GRID
            const v = row / GRID
            positions[i * 3] = (u - 0.5) * 2      // x: -1 to 1
            positions[i * 3 + 1] = 0               // y: 0 (displaced in shader)
            positions[i * 3 + 2] = (v - 0.5) * 2   // z: -1 to 1
            uvs[i * 2] = u
            uvs[i * 2 + 1] = v
        }
    }

    // Index buffer: two triangles per quad
    const indices = new Uint16Array(GRID * GRID * 6)
    let idx = 0
    for (let row = 0; row < GRID; row++) {
        for (let col = 0; col < GRID; col++) {
            const tl = row * (GRID + 1) + col
            const tr = tl + 1
            const bl = (row + 1) * (GRID + 1) + col
            const br = bl + 1
            indices[idx++] = tl
            indices[idx++] = bl
            indices[idx++] = tr
            indices[idx++] = tr
            indices[idx++] = bl
            indices[idx++] = br
        }
    }

    // Position buffer
    const posBuf = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, posBuf)
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW)
    const posLoc = gl.getAttribLocation(program, 'a_position')
    gl.enableVertexAttribArray(posLoc)
    gl.vertexAttribPointer(posLoc, 3, gl.FLOAT, false, 0, 0)

    // UV buffer
    const uvBuf = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, uvBuf)
    gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW)
    const uvLoc = gl.getAttribLocation(program, 'a_uv')
    gl.enableVertexAttribArray(uvLoc)
    gl.vertexAttribPointer(uvLoc, 2, gl.FLOAT, false, 0, 0)

    // Index buffer
    const indexBuf = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuf)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW)

    return { indexCount: indices.length, posBuf, uvBuf, indexBuf }
}

// --- Program setup ---

const program = createProgram(gl, terrainVert, terrainFrag)
if (!program) throw new Error('Failed to create shader program')

gl.useProgram(program)

const mesh = createSubdividedPlane(gl, program)

const u = {
    mvp: gl.getUniformLocation(program, 'u_mvp'),
    time: gl.getUniformLocation(program, 'u_time'),
    displacement: gl.getUniformLocation(program, 'u_displacement'),
    noiseScale: gl.getUniformLocation(program, 'u_noiseScale'),
    speed: gl.getUniformLocation(program, 'u_speed'),
    texture: gl.getUniformLocation(program, 'u_texture'),
    hasTexture: gl.getUniformLocation(program, 'u_hasTexture'),
}

// --- Texture / image upload ---

const dropZone = document.querySelector('#drop-zone')
const fileInput = document.querySelector('#file-input')
const urlInput = document.querySelector('#url-input')
const loadUrlBtn = document.querySelector('#load-url')
const loadingEl = document.querySelector('#loading')
const displacementSlider = document.querySelector('#displacement')
const noiseScaleSlider = document.querySelector('#noiseScale')
const speedSlider = document.querySelector('#speed')

let imageTexture = null
let hasTexture = false

const recorder = setupRecording(canvas)

function createTextureFromImage(image) {
    if (imageTexture) gl.deleteTexture(imageTexture)
    imageTexture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, imageTexture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
    hasTexture = true
    loadingEl.classList.add('hidden')
}

function loadImageFile(file) {
    if (!file.type.startsWith('image/')) { alert('Please select an image file'); return }
    loadingEl.classList.remove('hidden')
    const reader = new FileReader()
    reader.onload = (e) => {
        const img = new Image()
        img.onload = () => createTextureFromImage(img)
        img.onerror = () => { alert('Failed to load image'); loadingEl.classList.add('hidden') }
        img.src = e.target.result
    }
    reader.readAsDataURL(file)
}

function loadImageUrl(url) {
    if (!url) return
    loadingEl.classList.remove('hidden')
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => createTextureFromImage(img)
    img.onerror = () => { alert('Failed to load image from URL'); loadingEl.classList.add('hidden') }
    img.src = url
}

// Event listeners
dropZone.addEventListener('click', () => fileInput.click())
dropZone.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.classList.add('dragover') })
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'))
dropZone.addEventListener('drop', (e) => {
    e.preventDefault(); dropZone.classList.remove('dragover')
    const file = e.dataTransfer.files[0]
    if (file) loadImageFile(file)
})
fileInput.addEventListener('change', (e) => { const file = e.target.files[0]; if (file) loadImageFile(file) })
loadUrlBtn.addEventListener('click', () => loadImageUrl(urlInput.value))
urlInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadImageUrl(urlInput.value) })

document.addEventListener('keydown', (e) => {
    if (e.key === 'r' || e.key === 'R') recorder.toggle()
})

// --- Resize ---

function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    gl.viewport(0, 0, canvas.width, canvas.height)
}

window.addEventListener('resize', resize)
resize()

// --- Render ---

gl.enable(gl.DEPTH_TEST)

function render(time) {
    const t = time * 0.001

    gl.clearColor(0.05, 0.05, 0.1, 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    // Camera: orbit slowly
    const camDist = 2.2
    const camAngle = t * 0.1
    const eye = [
        Math.sin(camAngle) * camDist,
        1.2,
        Math.cos(camAngle) * camDist,
    ]
    const center = [0, 0, 0]
    const up = [0, 1, 0]

    const proj = perspective(Math.PI / 4, canvas.width / canvas.height, 0.1, 100)
    const view = lookAt(eye, center, up)
    const mvp = mat4Multiply(proj, view)

    gl.uniformMatrix4fv(u.mvp, false, mvp)
    gl.uniform1f(u.time, t)
    gl.uniform1f(u.displacement, parseFloat(displacementSlider.value))
    gl.uniform1f(u.noiseScale, parseFloat(noiseScaleSlider.value))
    gl.uniform1f(u.speed, parseFloat(speedSlider.value))
    gl.uniform1i(u.hasTexture, hasTexture ? 1 : 0)

    if (hasTexture && imageTexture) {
        gl.activeTexture(gl.TEXTURE0)
        gl.bindTexture(gl.TEXTURE_2D, imageTexture)
        gl.uniform1i(u.texture, 0)
    }

    gl.drawElements(gl.TRIANGLES, mesh.indexCount, gl.UNSIGNED_SHORT, 0)
    requestAnimationFrame(render)
}

requestAnimationFrame(render)

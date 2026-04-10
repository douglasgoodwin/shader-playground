// Shared model loader for OBJ drag-and-drop / file pick / URL loading
// Mirrors media-loader.js but for 3D models
// Returns normalized, centered geometry via onLoad callback

import { OBJLoader } from 'three/addons/loaders/OBJLoader.js'
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'
import * as THREE from 'three'

const objLoader = new OBJLoader()

function parseOBJ(obj) {
    const geometries = []
    obj.traverse((child) => {
        if (child.isMesh) {
            const geo = child.geometry.clone()
            if (!geo.attributes.normal) geo.computeVertexNormals()
            geometries.push(geo)
        }
    })

    if (geometries.length === 0) return null

    const merged = geometries.length > 1 ? mergeGeometries(geometries) : geometries[0]

    // Center and normalize to fit in a ~3-unit box
    merged.computeBoundingBox()
    const box = merged.boundingBox
    const center = box.getCenter(new THREE.Vector3())
    const size = box.getSize(new THREE.Vector3())
    const scale = 3.0 / Math.max(size.x, size.y, size.z)
    merged.translate(-center.x, -center.y, -center.z)
    merged.scale(scale, scale, scale)

    return merged
}

export function createModelLoader({ onLoad, selectors } = {}) {
    const sel = selectors || {}
    const dropZone = document.querySelector(sel.dropZone || '#model-drop-zone')
    const fileInput = document.querySelector(sel.fileInput || '#model-file-input')
    const urlInput = document.querySelector(sel.urlInput || '#model-url-input')
    const loadUrlBtn = document.querySelector(sel.loadUrl || '#model-load-url')
    const loadingEl = document.querySelector(sel.loading || '#model-loading')

    function showLoading() { if (loadingEl) loadingEl.classList.remove('hidden') }
    function hideLoading() { if (loadingEl) loadingEl.classList.add('hidden') }

    function loadFromText(text, name) {
        try {
            const obj = objLoader.parse(text)
            const geometry = parseOBJ(obj)
            if (geometry) {
                hideLoading()
                if (onLoad) onLoad(geometry, name)
            } else {
                alert('No mesh data found in OBJ file')
                hideLoading()
            }
        } catch (e) {
            alert('Failed to parse OBJ: ' + e.message)
            hideLoading()
        }
    }

    function loadFile(file) {
        if (!file.name.match(/\.obj$/i)) {
            alert('Please select an OBJ file')
            return
        }
        showLoading()
        const reader = new FileReader()
        reader.onload = (e) => loadFromText(e.target.result, file.name)
        reader.onerror = () => {
            alert('Failed to read file')
            hideLoading()
        }
        reader.readAsText(file)
    }

    function loadUrl(url) {
        if (!url) return
        showLoading()
        objLoader.load(
            url,
            (obj) => {
                const geometry = parseOBJ(obj)
                if (geometry) {
                    hideLoading()
                    if (onLoad) onLoad(geometry, url.split('/').pop())
                } else {
                    alert('No mesh data found in OBJ')
                    hideLoading()
                }
            },
            undefined,
            () => {
                alert('Failed to load OBJ from URL')
                hideLoading()
            },
        )
    }

    // Bind drop zone events
    if (dropZone) {
        dropZone.addEventListener('click', () => fileInput && fileInput.click())
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault()
            dropZone.classList.add('dragover')
        })
        dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'))
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault()
            dropZone.classList.remove('dragover')
            const file = e.dataTransfer.files[0]
            if (file) loadFile(file)
        })
    }
    if (fileInput) {
        fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0]
            if (file) loadFile(file)
        })
    }
    if (loadUrlBtn && urlInput) {
        loadUrlBtn.addEventListener('click', () => loadUrl(urlInput.value))
        urlInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') loadUrl(urlInput.value)
        })
    }

    return { loadFile, loadUrl }
}

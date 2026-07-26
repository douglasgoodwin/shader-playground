// Multi-layer media loading.
//
// media-loader.js handles the one-source case: a page with a single drop
// zone. Pages that composite several sources at once — /matte/ with its
// back/front/matte, /assembly/ with a map and five videos — need one
// texture per zone, each independently loaded, uploaded, and seekable.
// This is that: a texture plus the element it came from, and the drop-zone
// wiring to fill it.

export class MediaLayer {
    constructor(gl, name) {
        this.gl = gl
        this.name = name
        this.texture = gl.createTexture()
        this.width = 1
        this.height = 1
        this.loaded = false
        this.element = null      // the <img> or <video> behind the texture
        this.videoSource = null  // set only for video, drives per-frame upload

        gl.bindTexture(gl.TEXTURE_2D, this.texture)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    }

    upload(element, isVideo) {
        const gl = this.gl
        this.element = element
        this.videoSource = isVideo ? element : null
        this.width = (isVideo ? element.videoWidth : element.width) || 1
        this.height = (isVideo ? element.videoHeight : element.height) || 1
        gl.bindTexture(gl.TEXTURE_2D, this.texture)
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, element)
        this.loaded = true
    }

    // Bind to a texture unit, refreshing from the video first. readyState >= 2
    // means there is a current frame to read; checking that rather than
    // `!paused` keeps a seeked-but-paused video uploading, which is what the
    // frame-sequence recorder needs.
    bindTo(unit, sampler) {
        const gl = this.gl
        gl.activeTexture(gl.TEXTURE0 + unit)
        gl.bindTexture(gl.TEXTURE_2D, this.texture)
        if (this.videoSource && this.videoSource.readyState >= 2) {
            gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, this.videoSource)
        }
        gl.uniform1i(sampler, unit)
    }

    // Pause and seek, resolving once the frame is actually available. Mirrors
    // media-loader's seekVideoTo so both recording paths behave the same.
    seekTo(time) {
        const v = this.videoSource
        if (!v) return Promise.resolve()
        if (!v.paused) v.pause()
        const duration = v.duration || 0
        const target = duration > 0 ? time % duration : time
        if (Math.abs(v.currentTime - target) < 1e-3) return Promise.resolve()
        return new Promise((resolve) => {
            const onSeeked = () => {
                v.removeEventListener('seeked', onSeeked)
                resolve()
            }
            v.addEventListener('seeked', onSeeked)
            v.currentTime = target
        })
    }

    resume() {
        if (this.videoSource && this.videoSource.paused) this.videoSource.play()
    }
}

// Load a dropped/picked file into a layer. onLoad fires once the texture is
// filled, so callers can update their own UI (labels, loop length, uniforms).
export function loadFileIntoLayer(layer, file, onLoad) {
    if (file.type.startsWith('video/')) {
        const video = document.createElement('video')
        video.muted = true
        video.loop = true
        video.playsInline = true
        video.src = URL.createObjectURL(file)
        video.addEventListener('loadeddata', () => {
            video.play()
            layer.upload(video, true)
            if (onLoad) onLoad(layer, file)
        })
        return
    }
    if (!file.type.startsWith('image/')) {
        alert('Please drop an image or video')
        return
    }
    const reader = new FileReader()
    reader.onload = (e) => {
        const img = new Image()
        img.onload = () => {
            layer.upload(img, false)
            if (onLoad) onLoad(layer, file)
        }
        img.src = e.target.result
    }
    reader.readAsDataURL(file)
}

// Wire a drop zone + hidden file input to a layer. Adds `.loaded` to the zone
// once media arrives, which is the class both pages style against.
export function wireDropZone(layer, zone, input, onLoad) {
    const handle = (file) => {
        if (!file) return
        loadFileIntoLayer(layer, file, (...args) => {
            zone.classList.add('loaded')
            if (onLoad) onLoad(...args)
        })
    }

    zone.addEventListener('click', () => input.click())
    zone.addEventListener('dragover', (e) => {
        e.preventDefault()
        zone.classList.add('dragover')
    })
    zone.addEventListener('dragleave', () => zone.classList.remove('dragover'))
    zone.addEventListener('drop', (e) => {
        e.preventDefault()
        zone.classList.remove('dragover')
        handle(e.dataTransfer.files[0])
    })
    input.addEventListener('change', (e) => handle(e.target.files[0]))
}

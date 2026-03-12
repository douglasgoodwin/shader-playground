// Shared media loader for image/video texture upload
// Used by warps, displace, and fluid pages

export function createMediaLoader(gl, { onLoad } = {}) {
    let texture = null
    let videoSource = null
    let hasMedia = false

    const loadingEl = document.querySelector('#loading')
    const dropZone = document.querySelector('#drop-zone')
    const fileInput = document.querySelector('#file-input')
    const urlInput = document.querySelector('#url-input')
    const loadUrlBtn = document.querySelector('#load-url')

    function initTexture() {
        if (texture) gl.deleteTexture(texture)
        videoSource = null

        texture = gl.createTexture()
        gl.bindTexture(gl.TEXTURE_2D, texture)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    }

    function loadFromImage(image) {
        initTexture()
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
        hasMedia = true
        if (loadingEl) loadingEl.classList.add('hidden')
        if (onLoad) onLoad(image, { width: image.width, height: image.height })
    }

    function loadFromVideo(video) {
        initTexture()
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, video)
        hasMedia = true
        videoSource = video
        if (loadingEl) loadingEl.classList.add('hidden')
        if (onLoad) onLoad(video, { width: video.videoWidth, height: video.videoHeight })
    }

    function loadFile(file) {
        if (file.type.startsWith('video/')) {
            if (loadingEl) loadingEl.classList.remove('hidden')
            const video = document.createElement('video')
            video.muted = true
            video.loop = true
            video.playsInline = true
            video.src = URL.createObjectURL(file)
            video.addEventListener('loadeddata', () => {
                video.play()
                loadFromVideo(video)
            })
            video.addEventListener('error', () => {
                alert('Failed to load video')
                if (loadingEl) loadingEl.classList.add('hidden')
            })
            return
        }

        if (!file.type.startsWith('image/')) {
            alert('Please select an image or video file')
            return
        }

        if (loadingEl) loadingEl.classList.remove('hidden')
        const reader = new FileReader()
        reader.onload = (e) => {
            const img = new Image()
            img.onload = () => loadFromImage(img)
            img.onerror = () => {
                alert('Failed to load image')
                if (loadingEl) loadingEl.classList.add('hidden')
            }
            img.src = e.target.result
        }
        reader.readAsDataURL(file)
    }

    function loadUrl(url) {
        if (!url) return

        const videoExts = /\.(mp4|webm|ogv|mov)(\?|$)/i
        if (videoExts.test(url)) {
            if (loadingEl) loadingEl.classList.remove('hidden')
            const video = document.createElement('video')
            video.muted = true
            video.loop = true
            video.playsInline = true
            video.crossOrigin = 'anonymous'
            video.src = url
            video.addEventListener('loadeddata', () => {
                video.play()
                loadFromVideo(video)
            })
            video.addEventListener('error', () => {
                alert('Failed to load video from URL')
                if (loadingEl) loadingEl.classList.add('hidden')
            })
            return
        }

        if (loadingEl) loadingEl.classList.remove('hidden')
        const img = new Image()
        img.crossOrigin = 'anonymous'
        img.onload = () => loadFromImage(img)
        img.onerror = () => {
            alert('Failed to load image from URL')
            if (loadingEl) loadingEl.classList.add('hidden')
        }
        img.src = url
    }

    // Bind drop zone and file input events
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

    return {
        get texture() { return texture },
        get videoSource() { return videoSource },
        get hasMedia() { return hasMedia },
        // Update video texture each frame (call in render loop)
        updateVideoFrame() {
            if (videoSource && !videoSource.paused && texture) {
                gl.bindTexture(gl.TEXTURE_2D, texture)
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoSource)
            }
        },
        loadFile,
        loadUrl,
    }
}

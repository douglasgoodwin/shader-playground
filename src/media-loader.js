// Shared media loader for image/video texture upload
// Used by warps, displace, and fluid pages

export function createMediaLoader(gl, { onLoad, selectors } = {}) {
    let texture = null
    let videoSource = null
    let hasMedia = false

    const sel = selectors || {}
    const loadingEl = document.querySelector(sel.loading || '#loading')
    const dropZone = document.querySelector(sel.dropZone || '#drop-zone')
    const fileInput = document.querySelector(sel.fileInput || '#file-input')
    const urlInput = document.querySelector(sel.urlInput || '#url-input')
    const loadUrlBtn = document.querySelector(sel.loadUrl || '#load-url')

    function initTexture() {
        if (texture) gl.deleteTexture(texture)
        videoSource = null

        texture = gl.createTexture()
        gl.bindTexture(gl.TEXTURE_2D, texture)
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
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
            if (videoSource && texture) {
                gl.bindTexture(gl.TEXTURE_2D, texture)
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, videoSource)
            }
        },
        // Pause the video and seek it to a specific time (in seconds).
        // Resolves once the seek completes so the frame at that time is
        // available for texture upload. No-op if there is no video source.
        async seekVideoTo(time) {
            if (!videoSource) return
            if (!videoSource.paused) videoSource.pause()
            const duration = videoSource.duration || 0
            const target = duration > 0 ? time % duration : time
            if (Math.abs(videoSource.currentTime - target) < 1e-3) return
            await new Promise((resolve) => {
                const onSeeked = () => {
                    videoSource.removeEventListener('seeked', onSeeked)
                    resolve()
                }
                videoSource.addEventListener('seeked', onSeeked)
                videoSource.currentTime = target
            })
        },
        resumeVideo() {
            if (videoSource && videoSource.paused) videoSource.play()
        },
        loadFile,
        loadUrl,
    }
}

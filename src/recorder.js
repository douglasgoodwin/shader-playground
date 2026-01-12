// Canvas video recorder using MediaRecorder API
// Records WebM video (VP9 codec for better quality, VP8 fallback)

export class CanvasRecorder {
    constructor(canvas, options = {}) {
        this.canvas = canvas
        this.mediaRecorder = null
        this.chunks = []
        this.recording = false
        this.options = {
            mimeType: this.getSupportedMimeType(),
            videoBitsPerSecond: options.bitrate || 8000000, // 8 Mbps default
        }
        this.onStateChange = options.onStateChange || (() => {})
    }

    getSupportedMimeType() {
        const types = [
            'video/webm;codecs=vp9',
            'video/webm;codecs=vp8',
            'video/webm',
            'video/mp4',
        ]
        for (const type of types) {
            if (MediaRecorder.isTypeSupported(type)) {
                return type
            }
        }
        return 'video/webm'
    }

    start() {
        if (this.recording) return

        this.chunks = []
        const stream = this.canvas.captureStream(60) // 60 fps

        try {
            this.mediaRecorder = new MediaRecorder(stream, this.options)
        } catch (e) {
            // Fallback without codec specification
            this.mediaRecorder = new MediaRecorder(stream)
        }

        this.mediaRecorder.ondataavailable = (e) => {
            if (e.data.size > 0) {
                this.chunks.push(e.data)
            }
        }

        this.mediaRecorder.onstop = () => {
            this.saveRecording()
        }

        this.mediaRecorder.start(100) // Collect data every 100ms
        this.recording = true
        this.onStateChange(true)
    }

    stop() {
        if (!this.recording || !this.mediaRecorder) return

        this.mediaRecorder.stop()
        this.recording = false
        this.onStateChange(false)
    }

    toggle() {
        if (this.recording) {
            this.stop()
        } else {
            this.start()
        }
    }

    saveRecording() {
        const blob = new Blob(this.chunks, { type: this.options.mimeType })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')
        const ext = this.options.mimeType.includes('mp4') ? 'mp4' : 'webm'
        a.download = `shader-${timestamp}.${ext}`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
    }

    isRecording() {
        return this.recording
    }
}

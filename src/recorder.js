// Canvas video recorder using WebCodecs API + mp4-muxer
// Records H.264 MP4 video with hardware acceleration

import { Muxer, ArrayBufferTarget } from 'mp4-muxer'

export class CanvasRecorder {
    constructor(canvas, options = {}) {
        this.canvas = canvas
        this.recording = false
        this.muxer = null
        this.videoEncoder = null
        this.frameInterval = null
        this.startTime = 0
        this.frameCount = 0
        this.fps = options.fps || 60
        this.bitrate = options.bitrate || 30_000_000 // 30 Mbps — high for fine detail
        this.onStateChange = options.onStateChange || (() => {})

        // Check WebCodecs support
        this.supported = typeof VideoEncoder !== 'undefined'
        if (!this.supported) {
            console.warn('WebCodecs API not supported - recording disabled')
        }
    }

    async start() {
        if (this.recording || !this.supported) return

        // Save original canvas dimensions so we can restore after recording
        this.originalWidth = this.canvas.width
        this.originalHeight = this.canvas.height

        // Always record at 1920x1080
        const encodedWidth = 1920
        const encodedHeight = 1080

        // Resize the canvas drawing buffer so shaders render at recording resolution
        this.canvas.width = encodedWidth
        this.canvas.height = encodedHeight
        const gl = this.canvas.getContext('webgl')
        if (gl) gl.viewport(0, 0, encodedWidth, encodedHeight)

        // Create muxer with ArrayBuffer target
        this.target = new ArrayBufferTarget()
        this.muxer = new Muxer({
            target: this.target,
            video: {
                codec: 'avc',
                width: encodedWidth,
                height: encodedHeight,
            },
            fastStart: 'in-memory',
        })

        // Create video encoder — capture muxer ref so late frames
        // from a previous session can't write to a new muxer
        const muxer = this.muxer
        this.videoEncoder = new VideoEncoder({
            output: (chunk, meta) => {
                if (this.muxer !== muxer) return // stale session
                muxer.addVideoChunk(chunk, meta)
            },
            error: (e) => {
                console.error('VideoEncoder error:', e)
                this.stop()
            },
        })

        // Configure encoder - try hardware acceleration first
        const config = {
            codec: 'avc1.640033', // H.264 High Profile Level 5.1 (supports wider resolutions)
            width: encodedWidth,
            height: encodedHeight,
            bitrate: this.bitrate,
            bitrateMode: 'constant', // avoid starving complex frames
            framerate: this.fps,
            latencyMode: 'quality', // prioritize quality over encode speed
            hardwareAcceleration: 'prefer-hardware',
        }

        try {
            const support = await VideoEncoder.isConfigSupported(config)
            if (!support.supported) {
                // Fall back to software encoding
                config.hardwareAcceleration = 'prefer-software'
            }
            this.videoEncoder.configure(config)
        } catch (e) {
            console.error('Failed to configure encoder:', e)
            return
        }

        this.recording = true
        this.startTime = performance.now()
        this.frameCount = 0
        this.encodedWidth = encodedWidth
        this.encodedHeight = encodedHeight
        this.onStateChange(true)

        // Capture frames at specified FPS
        const frameTime = 1000 / this.fps
        this.frameInterval = setInterval(() => this.captureFrame(), frameTime)
    }

    captureFrame() {
        if (!this.recording || !this.videoEncoder) return

        createImageBitmap(this.canvas).then((bitmap) => {
            // Encoder may have closed while the bitmap was being created
            if (!this.recording) { bitmap.close(); return }

            const timestamp = (this.frameCount * 1_000_000) / this.fps
            const frame = new VideoFrame(bitmap, {
                timestamp,
                duration: 1_000_000 / this.fps,
            })
            bitmap.close()

            try {
                const keyFrame = this.frameCount % this.fps === 0
                this.videoEncoder.encode(frame, { keyFrame })
                this.frameCount++
            } finally {
                frame.close()
            }
        }).catch(() => {})
    }

    async stop() {
        if (!this.recording || this._stopping) return
        this._stopping = true

        this.recording = false
        this.onStateChange(false)

        if (this.frameInterval) {
            clearInterval(this.frameInterval)
            this.frameInterval = null
        }

        if (this.videoEncoder) {
            try {
                await this.videoEncoder.flush()
                this.videoEncoder.close()
            } catch (e) {
                console.error('Encoder flush error:', e)
            }
        }

        // Restore original canvas dimensions and trigger resize so pages
        // update their viewport and uniforms
        if (this.originalWidth && this.originalHeight) {
            this.canvas.width = this.originalWidth
            this.canvas.height = this.originalHeight
        }
        window.dispatchEvent(new Event('resize'))

        if (this.muxer) {
            this.muxer.finalize()
            this.saveRecording()
        }

        this._stopping = false
    }

    toggle() {
        if (this.recording) {
            this.stop()
        } else {
            this.start()
        }
    }

    saveRecording() {
        const buffer = this.target.buffer
        const blob = new Blob([buffer], { type: 'video/mp4' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')
        a.download = `shader-${timestamp}.mp4`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
    }

    isRecording() {
        return this.recording
    }

    isSupported() {
        return this.supported
    }
}

// PNG frame-sequence recorder for festival/ProRes-bound captures.
// Uses File System Access API + canvas.toBlob('image/png') to write
// a numbered PNG per frame. Drives the page's render via a callback
// with deterministic virtual time so the output is reproducible and
// independent of realtime performance.

export class FrameRecorder {
    constructor(canvas, options = {}) {
        this.canvas = canvas
        this.fps = options.fps || 24
        this.recordingWidth = options.width || 1920
        this.recordingHeight = options.height || 1080
        this.renderFrame = options.renderFrame || (() => {})
        this.onStateChange = options.onStateChange || (() => {})
        this.onProgress = options.onProgress || (() => {})
        this.onPrimeProgress = options.onPrimeProgress || (() => {})
        // Prime: number of warm-up frames to render *without saving* so
        // feedback / accumulator buffers can fill before the first saved
        // frame. Pass a function to compute lazily from current state.
        this.getPrimeFrames =
            typeof options.getPrimeFrames === 'function'
                ? options.getPrimeFrames
                : () => options.primeFrames || 0

        this.capturing = false
        this.cancelRequested = false
        this.frameIndex = 0   // total frames rendered (prime + saved)
        this.savedCount = 0   // frames written to disk
        this.virtualTime = 0
        this.priming = false

        this.supported =
            typeof window !== 'undefined' &&
            typeof window.showDirectoryPicker === 'function'
    }

    isCapturing() { return this.capturing }
    isPriming() { return this.priming }
    isSupported() { return this.supported }
    getTime() { return this.virtualTime }
    getFrameCount() { return this.savedCount }

    async start() {
        if (this.capturing) return
        if (!this.supported) {
            alert(
                'PNG sequence export needs the File System Access API ' +
                '(Chrome or Edge on desktop). Safari and Firefox do not support it.'
            )
            return
        }

        let dirHandle
        try {
            dirHandle = await window.showDirectoryPicker({ mode: 'readwrite' })
        } catch {
            return // user cancelled the picker
        }

        const primeTotal = Math.max(0, this.getPrimeFrames() | 0)

        this.originalWidth = this.canvas.width
        this.originalHeight = this.canvas.height
        this.canvas.width = this.recordingWidth
        this.canvas.height = this.recordingHeight
        const gl =
            this.canvas.getContext('webgl2') ||
            this.canvas.getContext('webgl')
        if (gl) gl.viewport(0, 0, this.recordingWidth, this.recordingHeight)

        this.capturing = true
        this.cancelRequested = false
        this.frameIndex = 0
        this.savedCount = 0
        this.virtualTime = 0
        this.priming = primeTotal > 0
        this.onStateChange(true)
        if (this.priming) this.onPrimeProgress(0, primeTotal)

        try {
            // Prime phase: render through warm-up frames without saving.
            // Skip gl.finish() and PNG encoding so this rips through fast.
            while (
                this.priming &&
                this.capturing &&
                !this.cancelRequested &&
                this.frameIndex < primeTotal
            ) {
                this.renderFrame()
                this.frameIndex++
                this.virtualTime = this.frameIndex / this.fps

                // Yield every ~30 frames so UI/keypresses still process
                // and the GPU command queue doesn't get unbounded.
                if (this.frameIndex % 30 === 0) {
                    if (gl) gl.finish()
                    this.onPrimeProgress(this.frameIndex, primeTotal)
                    await new Promise(r => setTimeout(r, 0))
                }
            }
            this.priming = false
            if (primeTotal > 0) this.onPrimeProgress(primeTotal, primeTotal)

            // Capture phase: render → finish → toBlob → write file.
            while (this.capturing && !this.cancelRequested) {
                this.renderFrame()
                if (gl) gl.finish()

                const blob = await new Promise(resolve =>
                    this.canvas.toBlob(resolve, 'image/png')
                )
                if (!blob) break

                const name = `frame_${String(this.savedCount).padStart(6, '0')}.png`
                const fileHandle = await dirHandle.getFileHandle(name, { create: true })
                const writable = await fileHandle.createWritable()
                await writable.write(blob)
                await writable.close()

                this.savedCount++
                this.frameIndex++
                this.virtualTime = this.frameIndex / this.fps
                this.onProgress(this.savedCount)

                // Yield so the UI thread can paint the progress badge
                // and process the stop button / keypress.
                await new Promise(r => setTimeout(r, 0))
            }
        } catch (e) {
            console.error('Frame capture error:', e)
        } finally {
            this.canvas.width = this.originalWidth
            this.canvas.height = this.originalHeight
            window.dispatchEvent(new Event('resize'))
            this.capturing = false
            this.cancelRequested = false
            this.priming = false
            this.onStateChange(false)
        }
    }

    stop() {
        if (this.capturing) this.cancelRequested = true
    }

    toggle() {
        if (this.capturing) this.stop()
        else this.start()
    }
}

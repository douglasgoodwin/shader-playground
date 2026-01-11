// Feedback buffer system for simulation shaders

export class FeedbackBuffer {
    constructor(gl) {
        this.gl = gl
        this.width = 0
        this.height = 0
        this.textures = [null, null]
        this.framebuffers = [null, null]
        this.index = 0
        this.frame = 0
        this.supported = false

        // Check for float texture support
        this.floatExt = gl.getExtension('OES_texture_float')
        this.floatLinearExt = gl.getExtension('OES_texture_float_linear')

        if (!this.floatExt) {
            console.warn('OES_texture_float not supported, using UNSIGNED_BYTE fallback')
        }

        this.supported = true
    }

    init(width, height) {
        const gl = this.gl
        this.width = width
        this.height = height

        // Clean up old buffers
        this.cleanup()

        for (let i = 0; i < 2; i++) {
            // Create texture
            const texture = gl.createTexture()
            gl.bindTexture(gl.TEXTURE_2D, texture)

            // Use float if available, otherwise unsigned byte
            if (this.floatExt) {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.FLOAT, null)
            } else {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
            }

            // Use NEAREST if float linear not supported
            const filter = this.floatLinearExt ? gl.LINEAR : gl.NEAREST
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filter)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

            // Create framebuffer
            const fb = gl.createFramebuffer()
            gl.bindFramebuffer(gl.FRAMEBUFFER, fb)
            gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0)

            // Check framebuffer status
            const status = gl.checkFramebufferStatus(gl.FRAMEBUFFER)
            if (status !== gl.FRAMEBUFFER_COMPLETE) {
                console.error('Framebuffer not complete:', status)
                this.supported = false
            }

            this.textures[i] = texture
            this.framebuffers[i] = fb
        }

        gl.bindFramebuffer(gl.FRAMEBUFFER, null)
        gl.bindTexture(gl.TEXTURE_2D, null)

        this.frame = 0
        this.index = 0

        console.log('FeedbackBuffer initialized:', width, 'x', height, 'float:', !!this.floatExt)
    }

    cleanup() {
        const gl = this.gl
        for (let i = 0; i < 2; i++) {
            if (this.textures[i]) gl.deleteTexture(this.textures[i])
            if (this.framebuffers[i]) gl.deleteFramebuffer(this.framebuffers[i])
            this.textures[i] = null
            this.framebuffers[i] = null
        }
    }

    get readTexture() {
        return this.textures[this.index]
    }

    get writeFramebuffer() {
        return this.framebuffers[1 - this.index]
    }

    get writeTexture() {
        return this.textures[1 - this.index]
    }

    swap() {
        this.index = 1 - this.index
        this.frame++
    }

    reset() {
        this.frame = 0
    }
}

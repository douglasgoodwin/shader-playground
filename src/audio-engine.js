// C minor pentatonic scale frequencies (C2 region up through several octaves)
const C_MINOR_PENTA = [
    65.41, 77.78, 87.31, 98.0, 116.54,   // C2 Eb2 F2 G2 Bb2
    130.81, 155.56, 174.61, 196.0, 233.08, // C3 Eb3 F3 G3 Bb3
    261.63, 311.13, 349.23, 392.0, 466.16, // C4 Eb4 F4 G4 Bb4
    523.25, 622.25, 698.46,                 // C5 Eb5 F5
]

export class AudioEngine {
    constructor() {
        this.ctx = null
        this.analyser = null
        this.masterGain = null
        this.isPlaying = false
        this.isMicActive = false

        // Synth nodes
        this._droneCarrier = null
        this._droneModulator = null
        this._droneModGain = null
        this._droneLFO = null
        this._droneLFOGain = null
        this._droneGain = null
        this._arpInterval = null
        this._arpGain = null

        // Analysis buffers
        this._freqData = null
        this._waveData = null

        // Parameters
        this._tempo = 120
        this._modDepth = 0.5
        this._arpIndex = 0

        // Mic
        this._micStream = null
        this._micSource = null

        // File playback
        this.isFileActive = false
        this._fileBuffer = null
        this._fileSource = null
        this._fileGain = null
        this._fileStartTime = 0
        this._filePauseOffset = 0
        this._fileIsPlaying = false
        this._fileName = ''
    }

    start() {
        if (this.isPlaying) return

        this.ctx = new AudioContext()
        this.analyser = this.ctx.createAnalyser()
        this.analyser.fftSize = 1024
        this.analyser.smoothingTimeConstant = 0.8

        this._freqData = new Uint8Array(this.analyser.frequencyBinCount) // 512
        this._waveData = new Uint8Array(this.analyser.fftSize) // 1024

        this.masterGain = this.ctx.createGain()
        this.masterGain.gain.value = 0.4
        this.masterGain.connect(this.analyser)
        this.analyser.connect(this.ctx.destination)

        this._startDrone()
        this._startArp()

        this.isPlaying = true
    }

    stop() {
        if (!this.isPlaying) return
        this._stopSynth()
        this.stopFile()
        this.disableMic()
        if (this.ctx) {
            this.ctx.close()
            this.ctx = null
        }
        this.isPlaying = false
    }

    _stopSynth() {
        this._stopDrone()
        this._stopArp()
    }

    _startDrone() {
        const ctx = this.ctx

        // Carrier: sine at C2 (~65Hz)
        this._droneCarrier = ctx.createOscillator()
        this._droneCarrier.type = 'sine'
        this._droneCarrier.frequency.value = 65.41

        // Modulator: sine
        this._droneModulator = ctx.createOscillator()
        this._droneModulator.type = 'sine'
        this._droneModulator.frequency.value = 65.41 * 1.5 // fifth ratio

        // Mod depth gain
        this._droneModGain = ctx.createGain()
        this._droneModGain.gain.value = 50 * this._modDepth

        // LFO sweeps mod depth slowly
        this._droneLFO = ctx.createOscillator()
        this._droneLFO.type = 'sine'
        this._droneLFO.frequency.value = 0.1

        this._droneLFOGain = ctx.createGain()
        this._droneLFOGain.gain.value = 40 * this._modDepth

        // Drone output gain
        this._droneGain = ctx.createGain()
        this._droneGain.gain.value = 0.3

        // Connections: modulator → modGain → carrier.frequency
        this._droneModulator.connect(this._droneModGain)
        this._droneModGain.connect(this._droneCarrier.frequency)

        // LFO → LFOGain → modGain.gain (sweeps FM depth)
        this._droneLFO.connect(this._droneLFOGain)
        this._droneLFOGain.connect(this._droneModGain.gain)

        // Carrier → droneGain → master
        this._droneCarrier.connect(this._droneGain)
        this._droneGain.connect(this.masterGain)

        this._droneCarrier.start()
        this._droneModulator.start()
        this._droneLFO.start()
    }

    _stopDrone() {
        if (this._droneCarrier) { this._droneCarrier.stop(); this._droneCarrier = null }
        if (this._droneModulator) { this._droneModulator.stop(); this._droneModulator = null }
        if (this._droneLFO) { this._droneLFO.stop(); this._droneLFO = null }
        if (this._droneGain) { this._droneGain.disconnect(); this._droneGain = null }
    }

    _startArp() {
        const ctx = this.ctx

        this._arpGain = ctx.createGain()
        this._arpGain.gain.value = 0.25
        this._arpGain.connect(this.masterGain)

        this._arpIndex = 0
        this._scheduleArp()
    }

    _scheduleArp() {
        const intervalMs = (60 / this._tempo) * 1000 / 2 // eighth notes
        this._arpInterval = setInterval(() => {
            // 30% beat skip for rhythm
            if (Math.random() < 0.3) return
            this._playArpNote()
        }, intervalMs)
    }

    _playArpNote() {
        if (!this.ctx || !this._arpGain) return
        const ctx = this.ctx
        const now = ctx.currentTime

        const freq = C_MINOR_PENTA[this._arpIndex % C_MINOR_PENTA.length]
        this._arpIndex++

        // FM bell: carrier + modulator at ratio 2.0
        const carrier = ctx.createOscillator()
        carrier.type = 'sine'
        carrier.frequency.value = freq

        const modulator = ctx.createOscillator()
        modulator.type = 'sine'
        modulator.frequency.value = freq * 2.0 // bell ratio

        const modGain = ctx.createGain()
        modGain.gain.value = freq * this._modDepth * 2.0

        const noteGain = ctx.createGain()
        // Attack 10ms, decay 200ms
        noteGain.gain.setValueAtTime(0, now)
        noteGain.gain.linearRampToValueAtTime(0.6, now + 0.01)
        noteGain.gain.exponentialRampToValueAtTime(0.001, now + 0.21)

        modulator.connect(modGain)
        modGain.connect(carrier.frequency)
        carrier.connect(noteGain)
        noteGain.connect(this._arpGain)

        carrier.start(now)
        modulator.start(now)
        carrier.stop(now + 0.25)
        modulator.stop(now + 0.25)
    }

    _stopArp() {
        if (this._arpInterval) {
            clearInterval(this._arpInterval)
            this._arpInterval = null
        }
        if (this._arpGain) {
            this._arpGain.disconnect()
            this._arpGain = null
        }
    }

    async enableMic() {
        if (this.isMicActive || !this.ctx) return
        try {
            this._stopSynth()
            this.stopFile()

            this._micStream = await navigator.mediaDevices.getUserMedia({ audio: true })
            this._micSource = this.ctx.createMediaStreamSource(this._micStream)
            this._micSource.connect(this.analyser)
            this.isMicActive = true
        } catch (e) {
            console.error('Mic access denied:', e)
        }
    }

    disableMic() {
        if (!this.isMicActive) return
        if (this._micSource) {
            this._micSource.disconnect()
            this._micSource = null
        }
        if (this._micStream) {
            this._micStream.getTracks().forEach(t => t.stop())
            this._micStream = null
        }
        this.isMicActive = false

        // Restart synth if still playing (but not if file is active)
        if (!this.isFileActive && this.ctx && this.ctx.state !== 'closed') {
            this._startDrone()
            this._startArp()
        }
    }

    setTempo(bpm) {
        this._tempo = bpm
        // Restart arp with new tempo
        if (this._arpInterval) {
            this._stopArp()
            this._arpGain = this.ctx.createGain()
            this._arpGain.gain.value = 0.25
            this._arpGain.connect(this.masterGain)
            this._scheduleArp()
        }
    }

    setModDepth(value) {
        this._modDepth = value
        // Update drone FM depth
        if (this._droneModGain) {
            this._droneModGain.gain.value = 50 * value
        }
        if (this._droneLFOGain) {
            this._droneLFOGain.gain.value = 40 * value
        }
    }

    async loadFile(file) {
        if (!this.ctx) return
        // Decode first so a bad file doesn't leave silence
        let buffer
        try {
            const arrayBuffer = await file.arrayBuffer()
            buffer = await this.ctx.decodeAudioData(arrayBuffer)
        } catch (e) {
            console.error('Failed to decode audio file:', e)
            return
        }

        // Stop other sources
        this._stopSynth()
        this.disableMic()
        // Stop previous file if any
        this._teardownFile()

        this._fileBuffer = buffer
        this._fileName = file.name
        this._filePauseOffset = 0
        this.isFileActive = true

        this._fileGain = this.ctx.createGain()
        this._fileGain.gain.value = 1.0
        this._fileGain.connect(this.masterGain)

        this._playFileFromOffset(0)
    }

    _playFileFromOffset(offset) {
        if (!this._fileBuffer || !this.ctx) return
        this._fileSource = this.ctx.createBufferSource()
        this._fileSource.buffer = this._fileBuffer
        this._fileSource.loop = true
        this._fileSource.connect(this._fileGain)
        this._fileSource.start(0, offset)
        this._fileStartTime = this.ctx.currentTime - offset
        this._fileIsPlaying = true
    }

    pauseFile() {
        if (!this._fileIsPlaying || !this._fileSource) return
        this._filePauseOffset = (this.ctx.currentTime - this._fileStartTime) % this._fileBuffer.duration
        this._fileSource.stop()
        this._fileSource = null
        this._fileIsPlaying = false
    }

    resumeFile() {
        if (this._fileIsPlaying || !this._fileBuffer) return
        this._playFileFromOffset(this._filePauseOffset)
    }

    _teardownFile() {
        if (this._fileSource) {
            this._fileSource.stop()
            this._fileSource = null
        }
        if (this._fileGain) {
            this._fileGain.disconnect()
            this._fileGain = null
        }
        this._fileIsPlaying = false
    }

    stopFile() {
        if (!this.isFileActive) return
        this._teardownFile()
        this._fileBuffer = null
        this._fileName = ''
        this._filePauseOffset = 0
        this.isFileActive = false

        // Restart synth if engine is still running
        if (this.ctx && this.ctx.state !== 'closed') {
            this._startDrone()
            this._startArp()
        }
    }

    getEnergy() {
        if (!this._freqData) return 0
        this.analyser.getByteFrequencyData(this._freqData)
        let sum = 0
        for (let i = 0; i < this._freqData.length; i++) {
            sum += this._freqData[i]
        }
        return sum / (this._freqData.length * 255)
    }

    getBassEnergy() {
        if (!this._freqData) return 0
        this.analyser.getByteFrequencyData(this._freqData)
        let sum = 0
        // First 32 bins ≈ bass frequencies
        const bassCount = 32
        for (let i = 0; i < bassCount; i++) {
            sum += this._freqData[i]
        }
        return sum / (bassCount * 255)
    }

    updateTextures(gl, freqTex, waveTex) {
        if (!this.analyser || !this._freqData) return

        this.analyser.getByteFrequencyData(this._freqData)
        this.analyser.getByteTimeDomainData(this._waveData)

        // Upload frequency data as 512x1 LUMINANCE texture
        gl.bindTexture(gl.TEXTURE_2D, freqTex)
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.LUMINANCE,
            this._freqData.length, 1, 0,
            gl.LUMINANCE, gl.UNSIGNED_BYTE, this._freqData
        )

        // Upload waveform data as 1024x1 LUMINANCE texture
        gl.bindTexture(gl.TEXTURE_2D, waveTex)
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.LUMINANCE,
            this._waveData.length, 1, 0,
            gl.LUMINANCE, gl.UNSIGNED_BYTE, this._waveData
        )
    }
}

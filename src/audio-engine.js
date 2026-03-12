import * as Tone from 'tone'

// Notes extracted from recorded session — D-centered modal set across octaves 2-4
// Most frequent: D, C, G, Eb, A, E (loosely D Dorian)
const NOTES = [
    'C2', 'D2', 'Eb2', 'F2', 'G2', 'A2',
    'C3', 'D3', 'Eb3', 'E3', 'F3', 'G3', 'A3',
    'C4', 'Ab4', 'G4',
]

export class AudioEngine {
    constructor() {
        this.ctx = null
        this.analyser = null
        this.masterGain = null
        this.isPlaying = false
        this.isMicActive = false

        // Tone.js synth
        this._synth = null
        this._reverb = null
        this._synthGain = null
        this._noteLoop = null

        // Analysis buffers
        this._freqData = null
        this._waveData = null

        // Parameters
        this._tempo = 108
        this._modDepth = 0.5
        this._noteIndex = 0

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

    async start() {
        if (this.isPlaying) return

        await Tone.start()
        this.ctx = Tone.getContext().rawContext
        this.analyser = this.ctx.createAnalyser()
        this.analyser.fftSize = 1024
        this.analyser.smoothingTimeConstant = 0.8

        this._freqData = new Uint8Array(this.analyser.frequencyBinCount)
        this._waveData = new Uint8Array(this.analyser.fftSize)

        this.masterGain = this.ctx.createGain()
        this.masterGain.gain.value = 0.4
        this.masterGain.connect(this.analyser)
        this.analyser.connect(this.ctx.destination)

        this._startSynth()
        this.isPlaying = true
    }

    stop() {
        if (!this.isPlaying) return
        this._stopSynth()
        this.stopFile()
        this.disableMic()
        Tone.getTransport().stop()
        Tone.getTransport().cancel()
        this.isPlaying = false
    }

    _startSynth() {
        // FM synth tuned to match recorded session — short soft notes, D modal
        this._synth = new Tone.PolySynth(Tone.FMSynth, {
            maxPolyphony: 4,
            voice: Tone.FMSynth,
            options: {
                harmonicity: 2,
                modulationIndex: this._modDepth * 3,
                oscillator: { type: 'sine' },
                modulation: { type: 'triangle' },
                envelope: {
                    attack: 0.05,
                    decay: 0.25,
                    sustain: 0.3,
                    release: 0.8,
                },
                modulationEnvelope: {
                    attack: 0.1,
                    decay: 0.2,
                    sustain: 0.2,
                    release: 0.8,
                },
            },
        })

        this._reverb = new Tone.Reverb({ decay: 4, wet: 0.4 })

        // Route Tone.js output through raw Web Audio masterGain → analyser
        this._synthGain = Tone.getContext().createGain()
        this._synthGain.gain.value = 0.3

        this._synth.connect(this._reverb)
        Tone.connect(this._reverb, this._synthGain)
        this._synthGain.connect(this.masterGain)

        // Disconnect Tone.js from its default destination so we don't double-output
        Tone.getDestination().volume.value = -Infinity

        this._noteIndex = 0

        // ~0.43s between onsets matching the recording
        this._noteLoop = new Tone.Loop((time) => {
            // Walk sequentially with frequent random jumps (matching free/modal feel)
            if (Math.random() < 0.35) {
                this._noteIndex = Math.floor(Math.random() * NOTES.length)
            } else {
                // Step by 1-3 notes, sometimes backwards
                const step = Math.random() < 0.2 ? -1 : (Math.random() < 0.5 ? 1 : 2)
                this._noteIndex = ((this._noteIndex + step) % NOTES.length + NOTES.length) % NOTES.length
            }
            const note = NOTES[this._noteIndex]
            // ~0.3-0.5s duration matching recording's avg note sustain
            this._synth.triggerAttackRelease(note, 0.3 + Math.random() * 0.2, time, 0.25 + Math.random() * 0.15)
        }, 0.43)

        Tone.getTransport().bpm.value = this._tempo
        Tone.getTransport().start()
        this._noteLoop.start(0)
    }

    _stopSynth() {
        if (this._noteLoop) {
            this._noteLoop.stop()
            this._noteLoop.dispose()
            this._noteLoop = null
        }
        if (this._synth) {
            this._synth.releaseAll()
            this._synth.dispose()
            this._synth = null
        }
        if (this._reverb) {
            this._reverb.dispose()
            this._reverb = null
        }
        if (this._synthGain) {
            this._synthGain.disconnect()
            this._synthGain = null
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

        if (!this.isFileActive && this.ctx && this.ctx.state !== 'closed') {
            this._startSynth()
        }
    }

    setTempo(bpm) {
        this._tempo = bpm
        Tone.getTransport().bpm.value = bpm
        // Scale interval: baseline 0.43s at 108 BPM
        if (this._noteLoop) {
            this._noteLoop.interval = 0.43 * (108 / bpm)
        }
    }

    setModDepth(value) {
        this._modDepth = value
        if (this._synth) {
            this._synth.set({
                modulationIndex: value * 3,
            })
        }
    }

    async loadFile(file) {
        if (!this.ctx) return
        let buffer
        try {
            const arrayBuffer = await file.arrayBuffer()
            buffer = await this.ctx.decodeAudioData(arrayBuffer)
        } catch (e) {
            console.error('Failed to decode audio file:', e)
            return
        }

        this._stopSynth()
        this.disableMic()
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

        if (this.ctx && this.ctx.state !== 'closed') {
            this._startSynth()
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
        const bassCount = 32
        for (let i = 0; i < bassCount; i++) {
            sum += this._freqData[i]
        }
        return sum / (bassCount * 255)
    }

    getMidEnergy() {
        if (!this._freqData) return 0
        this.analyser.getByteFrequencyData(this._freqData)
        let sum = 0
        for (let i = 32; i < 128; i++) {
            sum += this._freqData[i]
        }
        return sum / (96 * 255)
    }

    getTrebleEnergy() {
        if (!this._freqData) return 0
        this.analyser.getByteFrequencyData(this._freqData)
        let sum = 0
        for (let i = 128; i < this._freqData.length; i++) {
            sum += this._freqData[i]
        }
        return sum / (384 * 255)
    }

    updateTextures(gl, freqTex, waveTex) {
        if (!this.analyser || !this._freqData) return

        this.analyser.getByteFrequencyData(this._freqData)
        this.analyser.getByteTimeDomainData(this._waveData)

        gl.bindTexture(gl.TEXTURE_2D, freqTex)
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.LUMINANCE,
            this._freqData.length, 1, 0,
            gl.LUMINANCE, gl.UNSIGNED_BYTE, this._freqData
        )

        gl.bindTexture(gl.TEXTURE_2D, waveTex)
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.LUMINANCE,
            this._waveData.length, 1, 0,
            gl.LUMINANCE, gl.UNSIGNED_BYTE, this._waveData
        )
    }
}

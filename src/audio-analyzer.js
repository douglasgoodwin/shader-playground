// Lightweight mic → FFT → frequency band energies
// No Tone.js dependency — uses raw Web Audio API
// Outputs 5 smoothed bands: bass, lowMid, mid, highMid, treble

export function createAudioAnalyzer({ onUpdate, onReady, fftSize = 1024, smoothing = 0.3 } = {}) {
    let ctx = null
    let analyser = null
    let micStream = null
    let micSource = null
    let elementSource = null
    let freqData = null
    let running = false
    let animId = null

    function ensureContext() {
        if (ctx) return
        ctx = new AudioContext()
        analyser = ctx.createAnalyser()
        analyser.fftSize = fftSize
        analyser.smoothingTimeConstant = 0.8
        freqData = new Uint8Array(analyser.frequencyBinCount)
    }

    // Band boundaries (bin indices for 1024 FFT at 44.1kHz ≈ 43Hz per bin)
    // bass: 0-170 Hz (bins 0-3)
    // lowMid: 170-700 Hz (bins 4-15)
    // mid: 700-2800 Hz (bins 16-63)
    // highMid: 2800-6000 Hz (bins 64-139)
    // treble: 6000+ Hz (bins 140-511)
    const BANDS = [
        { name: 'bass',    lo: 0,   hi: 4   },
        { name: 'lowMid',  lo: 4,   hi: 16  },
        { name: 'mid',     lo: 16,  hi: 64  },
        { name: 'highMid', lo: 64,  hi: 140 },
        { name: 'treble',  lo: 140, hi: 512 },
    ]

    const values = {
        bass: 0,
        lowMid: 0,
        mid: 0,
        highMid: 0,
        treble: 0,
        energy: 0,  // overall RMS energy
    }

    const smoothFactor = smoothing

    function lerp(a, b, t) { return a + (b - a) * t }

    function bandEnergy(lo, hi) {
        let sum = 0
        for (let i = lo; i < hi && i < freqData.length; i++) {
            sum += freqData[i]
        }
        return sum / ((hi - lo) * 255)
    }

    function analyze() {
        if (!running || !analyser) {
            if (running) animId = requestAnimationFrame(analyze)
            return
        }

        analyser.getByteFrequencyData(freqData)

        // Per-band energy
        for (const band of BANDS) {
            const raw = bandEnergy(band.lo, band.hi)
            values[band.name] = lerp(values[band.name], raw, smoothFactor)
        }

        // Overall energy
        let total = 0
        for (let i = 0; i < freqData.length; i++) total += freqData[i]
        const rawEnergy = total / (freqData.length * 255)
        values.energy = lerp(values.energy, rawEnergy, smoothFactor)

        if (onUpdate) onUpdate(values)

        animId = requestAnimationFrame(analyze)
    }

    async function start() {
        if (running) return
        ensureContext()

        micStream = await navigator.mediaDevices.getUserMedia({ audio: true })
        micSource = ctx.createMediaStreamSource(micStream)
        micSource.connect(analyser)
        // Don't connect to destination — we only analyze, don't play back mic

        running = true
        if (onReady) onReady()
        analyze()
    }

    // Analyze audio coming from an HTMLAudioElement (WAV/MP3/etc).
    // Unlike mic mode, this routes analyser → destination so the user hears it.
    // createMediaElementSource can only be called once per element — callers
    // should create a fresh <audio> element per load.
    async function startFromElement(audioEl) {
        if (running) stop()
        ensureContext()
        if (ctx.state === 'suspended') await ctx.resume()

        elementSource = ctx.createMediaElementSource(audioEl)
        elementSource.connect(analyser)
        analyser.connect(ctx.destination)

        running = true
        if (onReady) onReady()
        analyze()
    }

    function stop() {
        running = false
        if (animId) {
            cancelAnimationFrame(animId)
            animId = null
        }
        if (micSource)      { micSource.disconnect(); micSource = null }
        if (elementSource)  { elementSource.disconnect(); elementSource = null }
        if (micStream) {
            micStream.getTracks().forEach(t => t.stop())
            micStream = null
        }
        if (analyser) {
            try { analyser.disconnect() } catch (_) { /* noop */ }
        }
        if (ctx) {
            ctx.close()
            ctx = null
        }
        analyser = null
        freqData = null
        for (const key of Object.keys(values)) values[key] = 0
    }

    return {
        start,
        startFromElement,
        stop,
        get running() { return running },
        get values() { return values },
    }
}

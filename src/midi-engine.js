// MIDI file parser + Tone.js synth playback + visual state extraction
// Loads a MIDI file, schedules notes on Tone.Transport, and provides
// per-frame visual state derived from note events.

import { Midi } from '@tonejs/midi'
import * as Tone from 'tone'

export function createMidiEngine() {
    let notes = []       // flat sorted array: [{time, duration, midi, velocity, name}, ...]
    let bpm = 120
    let loaded = false
    let synth = null
    let reverb = null
    let lastScanTime = -1

    // Visual accumulators — updated per frame
    const state = {
        hit: 0,          // 0→1 on note, fast decay
        pitch: 0.5,      // 0→1 normalized MIDI pitch
        density: 0,      // rolling note density
        velocity: 0,     // latest note velocity
    }

    function initAudio() {
        if (synth) return
        reverb = new Tone.Reverb({ decay: 2, wet: 0.3 })
        reverb.toDestination()
        synth = new Tone.PolySynth(Tone.FMSynth, {
            maxPolyphony: 16,
            voice: Tone.FMSynth,
            options: {
                envelope: { attack: 0.02, decay: 0.3, sustain: 0.2, release: 0.5 },
                volume: -12,
            },
        })
        synth.connect(reverb)
    }

    function loadMidi(arrayBuffer) {
        const midi = new Midi(arrayBuffer)

        // Extract tempo
        if (midi.header.tempos.length > 0) {
            bpm = Math.round(midi.header.tempos[0].bpm)
        }
        Tone.getTransport().bpm.value = bpm

        // Flatten all tracks' notes into a single sorted array
        notes = []
        midi.tracks.forEach(track => {
            track.notes.forEach(n => {
                notes.push({
                    time: n.time,
                    duration: Math.min(n.duration, 2), // cap long notes
                    midi: n.midi,
                    velocity: n.velocity,
                    name: n.name,
                })
            })
        })
        notes.sort((a, b) => a.time - b.time)

        // Clear previous schedule
        Tone.getTransport().cancel()
        Tone.getTransport().stop()
        Tone.getTransport().seconds = 0

        // Schedule all notes on Transport
        initAudio()
        notes.forEach(n => {
            Tone.getTransport().schedule(time => {
                synth.triggerAttackRelease(n.name, n.duration, time, n.velocity)
            }, n.time)
        })

        loaded = true
        lastScanTime = -1
        state.hit = 0
        state.pitch = 0.5
        state.density = 0
        state.velocity = 0

        return { bpm, noteCount: notes.length, duration: notes.length > 0 ? notes[notes.length - 1].time + 1 : 0 }
    }

    async function play() {
        if (!loaded) return
        await Tone.start() // resume AudioContext on user gesture
        Tone.getTransport().start()
    }

    function pause() {
        Tone.getTransport().pause()
    }

    function stop() {
        Tone.getTransport().stop()
        Tone.getTransport().seconds = 0
        lastScanTime = -1
        state.hit = 0
        state.pitch = 0.5
        state.density = 0
        state.velocity = 0
    }

    // Lerp targets — state eases toward these
    const target = { pitch: 0.5, velocity: 0, density: 0 }

    function lerp(current, goal, rate) {
        return current + (goal - current) * rate
    }

    // Call each frame to update visual state from current transport position
    function updateVisualState() {
        if (!loaded || notes.length === 0) return state

        const now = Tone.getTransport().seconds
        const dt = lastScanTime >= 0 ? now - lastScanTime : 0

        // Hit decays fast (punchy pulse — no lerp, direct decay)
        state.hit *= 0.92

        // Find notes that started since last scan
        if (dt > 0 && Tone.getTransport().state === 'started') {
            for (let i = 0; i < notes.length; i++) {
                const n = notes[i]
                if (n.time > lastScanTime && n.time <= now) {
                    // New note — hit snaps, others set targets
                    state.hit = Math.max(state.hit, n.velocity)
                    target.pitch = n.midi / 127
                    target.velocity = n.velocity
                }
                if (n.time > now) break
            }
        }

        // Note density: count notes within ±0.3s window
        const window = 0.3
        let count = 0
        for (let i = 0; i < notes.length; i++) {
            if (notes[i].time > now + window) break
            if (notes[i].time >= now - window) count++
        }
        target.density = Math.min(count / 10, 1)

        // Ease toward targets
        state.pitch = lerp(state.pitch, target.pitch, 0.08)
        state.velocity = lerp(state.velocity, target.velocity, 0.1)
        state.density = lerp(state.density, target.density, 0.06)

        lastScanTime = now
        return state
    }

    return {
        loadMidi,
        play,
        pause,
        stop,
        updateVisualState,
        get isPlaying() { return Tone.getTransport().state === 'started' },
        get currentTime() { return Tone.getTransport().seconds },
        get bpm() { return bpm },
        get loaded() { return loaded },
        get noteCount() { return notes.length },
        get duration() { return notes.length > 0 ? notes[notes.length - 1].time + 1 : 0 },
    }
}

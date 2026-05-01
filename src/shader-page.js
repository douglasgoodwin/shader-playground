// Shared boilerplate for fullscreen shader pages
// Handles: GL setup, program creation, uniform caching, effect switching,
// resize, keyboard shortcuts, button handlers, render loop

import { createProgram, createFullscreenQuad } from './webgl.js'
import { SliderManager, setupRecording, MouseTracker } from './controls.js'
import { FrameRecorder } from './frame-recorder.js'
import vertexShader from './shaders/vertex.glsl'

const AUTO_KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'q', 'w']

export function createShaderPage({
    shaders,
    uniforms: uniformNames,
    defaultEffect,
    sliders: sliderConfig,
    keys,
    extensions,
    recording,
    onRender,
    onSwitch,
}) {
    const canvas = document.querySelector('#canvas')
    const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true })

    if (!gl) {
        document.body.innerHTML = '<p style="color:white;padding:20px;">WebGL not supported</p>'
        throw new Error('WebGL not supported')
    }

    if (extensions) extensions.forEach(ext => gl.getExtension(ext))

    // Create programs and uniform locations
    const programs = {}
    const uniforms = {}

    for (const [name, fragmentShader] of Object.entries(shaders)) {
        const program = createProgram(gl, vertexShader, fragmentShader)
        if (program) {
            programs[name] = program
            const u = {}
            for (const uName of uniformNames) {
                u[uName] = gl.getUniformLocation(program, `u_${uName}`)
            }
            uniforms[name] = u
        }
    }

    let current = defaultEffect
    gl.useProgram(programs[current])
    createFullscreenQuad(gl, programs[current])

    const mouse = new MouseTracker(canvas)
    const sliderMgr = sliderConfig ? new SliderManager(sliderConfig) : null
    const recorder = setupRecording(canvas, { keyboardShortcut: null, ...recording })

    // PNG-sequence recorder for festival/ProRes-bound captures. Activated
    // by 'P' keyboard or #frame-btn click. Pages that want the visual
    // button + progress badge include #frame-btn and #frame-counter in
    // their HTML; pages that don't, still get the keyboard shortcut.
    //
    // Video sync: pages with a video source must call `page.attachMedia(m)`
    // after constructing their media loader, or PNG capture will sample
    // the video at wall-clock playback rate while the recorder runs on
    // virtual time, smearing many seconds of source content into the
    // buffer width. With a media attached, the recorder pauses the video
    // at capture start and seeks it to videoStartTime + virtualTime each
    // frame.
    const FRAME_FPS = (recording && recording.frameFps) || 24
    const frameBtn = document.querySelector('#frame-btn')
    const frameCounter = document.querySelector('#frame-counter')
    // Each entry: { media, startTime }. Pages with multiple media loaders
    // (e.g. warps' foreground + background) call attachMedia for each;
    // capture syncs every video source independently from where it was
    // paused so multi-source comps stay in step.
    const attachedMedias = []
    const frameRecorder = new FrameRecorder(canvas, {
        width: recording && recording.width,
        height: recording && recording.height,
        fps: FRAME_FPS,
        primeFrames: (recording && recording.primeFrames) || 0,
        renderFrame: () => renderFrame(frameRecorder.getTime()),
        onBeforeFrame: async (virtualTime) => {
            for (const entry of attachedMedias) {
                if (entry.media.videoSource) {
                    await entry.media.seekVideoTo(entry.startTime + virtualTime)
                }
            }
        },
        onStateChange: (capturing) => {
            if (frameBtn) frameBtn.classList.toggle('recording', capturing)
            if (frameCounter) {
                frameCounter.classList.toggle('hidden', !capturing)
                frameCounter.textContent = capturing ? 'priming…' : ''
            }
            if (capturing) {
                for (const entry of attachedMedias) {
                    if (entry.media.videoSource) {
                        entry.startTime = entry.media.videoSource.currentTime
                    }
                }
            } else {
                for (const entry of attachedMedias) {
                    entry.media.resumeVideo()
                }
            }
        },
        onPrimeProgress: (n, total) => {
            if (frameCounter && total > 0) {
                const pct = Math.floor((n / total) * 100)
                frameCounter.textContent = `priming ${n}/${total} (${pct}%)`
            }
        },
        onProgress: (n) => {
            if (frameCounter) {
                const seconds = (n / FRAME_FPS).toFixed(2)
                frameCounter.textContent = `frame ${n} · ${seconds}s`
            }
        },
    })
    if (frameBtn) frameBtn.addEventListener('click', () => frameRecorder.toggle())

    function attachMedia(media) {
        attachedMedias.push({ media, startTime: 0 })
    }

    function switchEffect(name) {
        if (!programs[name]) return
        current = name
        gl.useProgram(programs[name])
        createFullscreenQuad(gl, programs[name])

        const u = uniforms[name]
        if (u && u.resolution) {
            gl.uniform2f(u.resolution, canvas.width, canvas.height)
        }

        document.querySelectorAll('#controls button').forEach(btn => {
            const btnName = btn.dataset.effect || btn.dataset.piece
            btn.classList.toggle('active', btnName === name)
        })

        if (onSwitch) onSwitch({ gl, u, name, canvas })
    }

    function resize() {
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        gl.viewport(0, 0, canvas.width, canvas.height)

        const u = uniforms[current]
        if (u && u.resolution) {
            gl.uniform2f(u.resolution, canvas.width, canvas.height)
        }
    }

    // Button click handlers
    document.querySelectorAll('#controls button').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation()
            switchEffect(btn.dataset.effect || btn.dataset.piece)
        })
    })

    // Keyboard shortcuts
    const shaderNames = Object.keys(shaders)
    const keyMap = keys || Object.fromEntries(
        shaderNames
            .map((name, i) => i < AUTO_KEYS.length ? [AUTO_KEYS[i], name] : null)
            .filter(Boolean)
    )

    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT') return
        if (keyMap[e.key]) switchEffect(keyMap[e.key])
        if (e.key === 'r' || e.key === 'R') recorder.toggle()
        if (e.key === 'p' || e.key === 'P') frameRecorder.toggle()
    })

    window.addEventListener('resize', resize)
    resize()

    function renderFrame(t) {
        const u = uniforms[current]

        // Keep viewport synced to canvas — the recorder resizes the canvas
        // without going through the window-resize path, so syncing here lets
        // rendering self-correct the following frame.
        gl.viewport(0, 0, canvas.width, canvas.height)
        if (u.resolution) gl.uniform2f(u.resolution, canvas.width, canvas.height)
        gl.uniform1f(u.time, t)
        mouse.applyUniform(gl, u.mouse)
        if (sliderMgr) sliderMgr.applyUniforms(gl, u)
        if (onRender) onRender({ gl, u, t, current, sliders: sliderMgr, mouse, canvas })

        gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    // Track preview frame rate via EMA so consumers (and frame-rate-
    // dependent uniforms) can rescale during capture. Most monitors
    // settle at 60; 120Hz panels and throttled tabs will read different
    // values. Sampled only during preview to avoid contamination from
    // the recorder's wall-clock cadence.
    let previewFps = 60
    let lastPreviewTimestamp = 0

    // rAF loop drives the live preview; the FrameRecorder owns rendering
    // during PNG capture, so skip the live render to avoid clobbering the
    // canvas between capture/save.
    function loop(time) {
        if (frameRecorder.isCapturing()) {
            lastPreviewTimestamp = 0
        } else {
            if (lastPreviewTimestamp > 0) {
                const dt = (time - lastPreviewTimestamp) / 1000
                if (dt > 0 && dt < 0.1) {
                    previewFps = previewFps * 0.95 + (1 / dt) * 0.05
                }
            }
            lastPreviewTimestamp = time
            renderFrame(time * 0.001)
        }
        requestAnimationFrame(loop)
    }

    requestAnimationFrame(loop)

    return {
        gl,
        canvas,
        programs,
        uniforms,
        mouse,
        sliders: sliderMgr,
        recorder,
        frameRecorder,
        attachMedia,
        frameFps: FRAME_FPS,
        get previewFps() { return previewFps },
        switchEffect,
        get current() { return current },
    }
}

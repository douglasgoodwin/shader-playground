// Recording a single clean loop, two ways.
//
// Pages whose output is periodic (/rings/, /assembly/) want to capture
// exactly one pass and no more. Both export paths need that bound:
//
//   MP4 (R)  — realtime. Because these pages derive their animation from the
//              source's own playhead, ANY contiguous one-loop window is a
//              clean loop, so this just stops the recorder after one pass.
//   PNG (P)  — deterministic. Renders off FrameRecorder's virtual clock and
//              stops at exactly round(loopLength * fps) frames. The frame at
//              t = loopLength would duplicate frame 0, so it is left out.
//
// Assumes the page's markup follows the repo convention: #record-btn,
// #frame-btn, #frame-counter, #format.

import { setupRecording } from './controls.js'
import { FrameRecorder } from './frame-recorder.js'

export function setupLoopRecording(canvas, {
    fps = 24,
    width = 1920,
    height = 1080,
    getLoopLength,      // () => seconds in one pass
    isLoopLocked = () => true,
    getLabel,           // () => filename fragment
    renderFrame,
    onBeforeFrame,      // async (virtualTime) => sync your sources
    onCaptureEnd,       // () => resume playback
} = {}) {
    const frameBtn = document.querySelector('#frame-btn')
    const frameCounter = document.querySelector('#frame-counter')
    const formatSelect = document.querySelector('#format')

    let loopStopTimer = null

    const canvasRecorder = setupRecording(canvas, {
        width, height, fps,
        keyboardShortcut: 'r',
        getLabel,
        onStateChange: (recording) => {
            clearTimeout(loopStopTimer)
            if (recording && isLoopLocked()) {
                loopStopTimer = setTimeout(() => canvasRecorder.stop(), getLoopLength() * 1000)
            }
        },
    })

    const loopFrames = () => Math.max(1, Math.round(getLoopLength() * fps))

    const frameRecorder = new FrameRecorder(canvas, {
        width, height, fps,
        renderFrame,
        onBeforeFrame,
        onStateChange: (capturing) => {
            if (frameBtn) frameBtn.classList.toggle('recording', capturing)
            if (frameCounter) {
                frameCounter.classList.toggle('hidden', !capturing)
                frameCounter.textContent = capturing ? 'capturing…' : ''
            }
            if (!capturing && onCaptureEnd) onCaptureEnd()
        },
        onProgress: (n) => {
            const total = loopFrames()
            if (frameCounter) frameCounter.textContent = `frame ${n}/${total}`
            if (n >= total) frameRecorder.stop()
        },
    })

    if (frameBtn) frameBtn.addEventListener('click', () => frameRecorder.toggle())

    if (formatSelect) {
        formatSelect.addEventListener('change', () => {
            const [w, h] = formatSelect.value.split('x').map(Number)
            canvasRecorder.recordingWidth = w
            canvasRecorder.recordingHeight = h
            frameRecorder.recordingWidth = w
            frameRecorder.recordingHeight = h
        })
    }

    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return
        if (e.key === 'p' || e.key === 'P') frameRecorder.toggle()
    })

    return { canvasRecorder, frameRecorder }
}

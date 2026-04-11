// Face tracker using MediaPipe FaceLandmarker
// Outputs blend shape values for driving shader uniforms
// Uses webcam video → FaceLandmarker → blend shapes each frame

import { FaceLandmarker, FilesetResolver } from '@mediapipe/tasks-vision'

const BLEND_SHAPE_NAMES = [
    'jawOpen',
    'mouthSmileLeft',
    'mouthSmileRight',
    'browInnerUp',
    'browOuterUpLeft',
    'browOuterUpRight',
    'eyeBlinkLeft',
    'eyeBlinkRight',
    'mouthPucker',
    'mouthFunnel',
    'cheekPuff',
    'jawLeft',
    'jawRight',
]

export function createFaceTracker({ onReady, onUpdate, previewEl } = {}) {
    let faceLandmarker = null
    let video = null
    let running = false
    let animId = null

    // Smoothed output values
    const values = {
        mouthOpen: 0,
        smile: 0,
        browRaise: 0,
        eyeBlink: 0,
        pucker: 0,
        cheekPuff: 0,
        jawX: 0,
    }

    const smoothing = 0.35 // lower = smoother, higher = more responsive

    function lerp(current, target, t) {
        return current + (target - current) * t
    }

    async function init() {
        // Load MediaPipe WASM + model
        const vision = await FilesetResolver.forVisionTasks(
            'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm'
        )

        faceLandmarker = await FaceLandmarker.createFromOptions(vision, {
            baseOptions: {
                modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task',
                delegate: 'GPU',
            },
            runningMode: 'VIDEO',
            numFaces: 1,
            outputFaceBlendshapes: true,
            outputFacialTransformationMatrixes: false,
        })

        // Set up webcam
        video = document.createElement('video')
        video.setAttribute('playsinline', '')
        video.setAttribute('autoplay', '')
        video.muted = true

        const stream = await navigator.mediaDevices.getUserMedia({
            video: { width: 320, height: 240, facingMode: 'user' },
            audio: false,
        })

        video.srcObject = stream
        await video.play()

        // Show preview if element provided
        if (previewEl) {
            previewEl.srcObject = stream
            previewEl.play()
        }

        if (onReady) onReady()
    }

    function extractBlendShapes(result) {
        if (!result.faceBlendshapes || result.faceBlendshapes.length === 0) return

        const shapes = result.faceBlendshapes[0].categories
        const map = {}
        for (const s of shapes) {
            map[s.categoryName] = s.score
        }

        // Map raw blend shapes to our simplified values
        const jaw = map['jawOpen'] || 0
        const smileL = map['mouthSmileLeft'] || 0
        const smileR = map['mouthSmileRight'] || 0
        const browIn = map['browInnerUp'] || 0
        const browOutL = map['browOuterUpLeft'] || 0
        const browOutR = map['browOuterUpRight'] || 0
        const blinkL = map['eyeBlinkLeft'] || 0
        const blinkR = map['eyeBlinkRight'] || 0
        const pucker = map['mouthPucker'] || 0
        const funnel = map['mouthFunnel'] || 0
        const puff = map['cheekPuff'] || 0
        const jawL = map['jawLeft'] || 0
        const jawR = map['jawRight'] || 0

        // Smooth all values
        values.mouthOpen = lerp(values.mouthOpen, jaw, smoothing)
        values.smile = lerp(values.smile, (smileL + smileR) * 0.5, smoothing)
        values.browRaise = lerp(values.browRaise, (browIn + browOutL + browOutR) / 3, smoothing)
        values.eyeBlink = lerp(values.eyeBlink, (blinkL + blinkR) * 0.5, smoothing)
        values.pucker = lerp(values.pucker, Math.max(pucker, funnel), smoothing)
        values.cheekPuff = lerp(values.cheekPuff, puff, smoothing)
        values.jawX = lerp(values.jawX, jawR - jawL, smoothing)
    }

    function detect() {
        if (!running || !faceLandmarker || !video || video.readyState < 2) {
            if (running) animId = requestAnimationFrame(detect)
            return
        }

        const result = faceLandmarker.detectForVideo(video, performance.now())
        extractBlendShapes(result)

        if (onUpdate) onUpdate(values)

        animId = requestAnimationFrame(detect)
    }

    async function start() {
        if (running) return
        if (!faceLandmarker) await init()
        running = true
        detect()
    }

    function stop() {
        running = false
        if (animId) {
            cancelAnimationFrame(animId)
            animId = null
        }
        // Stop webcam
        if (video && video.srcObject) {
            video.srcObject.getTracks().forEach(t => t.stop())
            video.srcObject = null
        }
        if (previewEl && previewEl.srcObject) {
            previewEl.srcObject = null
        }
        // Reset values
        for (const key of Object.keys(values)) values[key] = 0
    }

    return {
        start,
        stop,
        get running() { return running },
        get values() { return values },
    }
}

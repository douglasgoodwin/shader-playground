import './style.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import rippleShader from './shaders/effects/ripple.glsl'
import plasmaShader from './shaders/effects/plasma.glsl'
import warpShader from './shaders/effects/warp.glsl'
import kaleidoscopeShader from './shaders/effects/kaleidoscope.glsl'
import noiseShader from './shaders/effects/noise.glsl'
import driveShader from './shaders/effects/drive.glsl'
import fireflyShader from './shaders/effects/firefly.glsl'
import exerciseShader from './shaders/exercises/ex3-1-sin-wave.glsl'
import phyllotaxisShader from './shaders/effects/phyllotaxis.glsl'

const MAX_RIPPLES = 10
let ripples = new Float32Array(MAX_RIPPLES * 3)
let rippleColors = new Float32Array(MAX_RIPPLES * 3)
let rippleIndex = 0

const page = createShaderPage({
    shaders: {
        ripple: rippleShader,
        plasma: plasmaShader,
        warp: warpShader,
        kaleidoscope: kaleidoscopeShader,
        noise: noiseShader,
        drive: driveShader,
        firefly: fireflyShader,
        phyllotaxis: phyllotaxisShader,
        exercise: exerciseShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'ripples', 'rippleColors', 'speed', 'intensity', 'scale'],
    defaultEffect: 'ripple',
    extensions: ['OES_standard_derivatives'],
    keys: {
        '1': 'ripple', '2': 'plasma', '3': 'warp', '4': 'kaleidoscope',
        '5': 'noise', '6': 'drive', '7': 'firefly', '8': 'phyllotaxis',
        'e': 'exercise',
    },
    sliders: {
        speed:     { selector: '#speed',     default: 1 },
        intensity: { selector: '#intensity', default: 0.7 },
        scale:     { selector: '#scale',     default: 1 },
    },
    onRender({ gl, u }) {
        gl.uniform3fv(u.ripples, ripples)
        gl.uniform3fv(u.rippleColors, rippleColors)
    },
})

page.canvas.addEventListener('click', (e) => {
    const x = e.clientX
    const y = page.canvas.height - e.clientY
    const idx = rippleIndex * 3
    ripples[idx] = x
    ripples[idx + 1] = y
    ripples[idx + 2] = performance.now() * 0.001
    rippleColors[idx] = 0.5 + Math.random() * 0.5
    rippleColors[idx + 1] = 0.5 + Math.random() * 0.5
    rippleColors[idx + 2] = 0.5 + Math.random() * 0.5
    rippleIndex = (rippleIndex + 1) % MAX_RIPPLES
})

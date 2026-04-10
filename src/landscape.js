import './landscape.css'
import { createShaderPage } from './shader-page.js'
import lightningShader from './shaders/landscape/lightning.glsl'
import sandShader from './shaders/landscape/sand.glsl'
import noiseShader from './shaders/effects/noise.glsl'
import driveShader from './shaders/effects/drive.glsl'
import fireflyShader from './shaders/effects/firefly.glsl'

createShaderPage({
    shaders: {
        lightning: lightningShader,
        sand: sandShader,
        noise: noiseShader,
        drive: driveShader,
        firefly: fireflyShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'speed', 'intensity', 'scale', 'camHeight'],
    defaultEffect: 'lightning',
    sliders: {
        speed:     { selector: '#speed',     default: 1 },
        intensity: { selector: '#intensity', default: 1 },
        scale:     { selector: '#scale',     default: 1 },
        camHeight: { selector: '#camHeight', default: 1 },
    },
})

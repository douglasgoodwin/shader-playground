import './characters.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import frightenedShader from './shaders/characters/frightened.glsl'
import stickfolkShader from './shaders/characters/stickfolk.glsl'

const blinkSpeedSlider = document.querySelector('#blinkSpeed')
const sizeVariationSlider = document.querySelector('#sizeVariation')

createShaderPage({
    shaders: {
        frightened: frightenedShader,
        stickfolk: stickfolkShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'blinkSpeed', 'sizeVariation', 'speed', 'intensity', 'scale'],
    defaultEffect: 'frightened',
    onRender({ gl, u, current }) {
        const blinkSpeed = parseFloat(blinkSpeedSlider.value)
        const sizeVariation = parseFloat(sizeVariationSlider.value)

        if (current === 'stickfolk') {
            if (u.speed) gl.uniform1f(u.speed, blinkSpeed)
            if (u.intensity) gl.uniform1f(u.intensity, 0.7)
            if (u.scale) gl.uniform1f(u.scale, sizeVariation * 3.0 + 1.0)
        } else {
            if (u.blinkSpeed) gl.uniform1f(u.blinkSpeed, blinkSpeed)
            if (u.sizeVariation) gl.uniform1f(u.sizeVariation, sizeVariation)
        }
    },
})

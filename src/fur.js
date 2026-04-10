import './fur.css'
import { createShaderPage } from './shader-page.js'
import shellsShader from './shaders/fur/shells.glsl'
import prairieShader from './shaders/fur/prairie.glsl'
import creatureShader from './shaders/fur/creature.glsl'

createShaderPage({
    shaders: {
        shells: shellsShader,
        prairie: prairieShader,
        creature: creatureShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'wind', 'gravity', 'density', 'furLength'],
    defaultEffect: 'shells',
    sliders: {
        wind:      { selector: '#wind',      default: 0.8 },
        gravity:   { selector: '#gravity',   default: 0.4 },
        density:   { selector: '#density',   default: 1 },
        furLength: { selector: '#furLength',  default: 1 },
    },
})

import './whitney.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import lapisShader from './shaders/whitney/lapis.glsl'
import permutationsShader from './shaders/whitney/permutations.glsl'
import matrixShader from './shaders/whitney/matrix.glsl'
import arabesqueShader from './shaders/whitney/arabesque.glsl'
import columnaShader from './shaders/whitney/columna.glsl'
import spiralShader from './shaders/whitney/spiral.glsl'
import musicboxShader from './shaders/whitney/musicbox.glsl'
import trailsShader from './shaders/whitney/trails.glsl'
import fractalShader from './shaders/whitney/fractal.glsl'
import atomShader from './shaders/whitney/atom.glsl'

createShaderPage({
    shaders: {
        lapis: lapisShader,
        permutations: permutationsShader,
        matrix: matrixShader,
        arabesque: arabesqueShader,
        columna: columnaShader,
        spiral: spiralShader,
        musicbox: musicboxShader,
        trails: trailsShader,
        fractal: fractalShader,
        atom: atomShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'speed', 'density', 'harmonics'],
    defaultEffect: 'lapis',
    sliders: {
        speed:     { selector: '#speed',     default: 0.5 },
        density:   { selector: '#density',   default: 1 },
        harmonics: { selector: '#harmonics', default: 1 },
    },
})

import './geometries.css'
import { createShaderPage } from './shader-page.js'
import gyroidShader from './shaders/geometries/gyroid.glsl'
import penroseShader from './shaders/geometries/penrose.glsl'
import mandelbulbShader from './shaders/geometries/mandelbulb.glsl'
import raymarchShader from './shaders/geometries/raymarch.glsl'
import oscillateShader from './shaders/geometries/oscillate.glsl'
import ropesShader from './shaders/geometries/ropes.glsl'
import trivoronoiShader from './shaders/geometries/trivoronoi.glsl'
import waterrippleShader from './shaders/geometries/waterripple.glsl'
import phyllotaxisShader from './shaders/geometries/phyllotaxis.glsl'
import stilllifeShader from './shaders/geometries/stilllife.glsl'
import stilllife2Shader from './shaders/geometries/stilllife2.glsl'
import bustShader from './shaders/geometries/bust.glsl'

createShaderPage({
    shaders: {
        gyroid: gyroidShader,
        penrose: penroseShader,
        mandelbulb: mandelbulbShader,
        raymarch: raymarchShader,
        oscillate: oscillateShader,
        ropes: ropesShader,
        trivoronoi: trivoronoiShader,
        waterripple: waterrippleShader,
        phyllotaxis: phyllotaxisShader,
        stilllife: stilllifeShader,
        stilllife2: stilllife2Shader,
        bust: bustShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'speed', 'density', 'harmonics', 'intensity', 'scale'],
    defaultEffect: 'gyroid',
    sliders: {
        speed:     { selector: '#speed',     default: 0.5 },
        density:   { selector: '#density',   default: 1 },
        harmonics: { selector: '#harmonics', default: 1 },
    },
    onRender({ gl, u, sliders }) {
        // Map density/harmonics to intensity/scale for shaders using those names
        const density = sliders.get('density')
        const harmonics = sliders.get('harmonics')
        if (u.intensity) gl.uniform1f(u.intensity, density)
        if (u.scale) gl.uniform1f(u.scale, harmonics)
    },
})

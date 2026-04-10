import './tiles.css'
import { createShaderPage } from './shader-page.js'
import voronoiShader from './shaders/tiles/voronoi.glsl'
import hexgridShader from './shaders/tiles/hexgrid.glsl'
import tilesShader from './shaders/tiles/tiles.glsl'
import varitilesShader from './shaders/tiles/varitiles.glsl'
import plasmaShader from './shaders/effects/plasma.glsl'
import kaleidoscopeShader from './shaders/effects/kaleidoscope.glsl'
import phyllotaxisShader from './shaders/effects/phyllotaxis.glsl'

createShaderPage({
    shaders: {
        voronoi: voronoiShader,
        hexgrid: hexgridShader,
        tiles: tilesShader,
        varitiles: varitilesShader,
        plasma: plasmaShader,
        kaleidoscope: kaleidoscopeShader,
        phyllotaxis: phyllotaxisShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'speed', 'intensity', 'scale'],
    defaultEffect: 'voronoi',
    sliders: {
        speed:     { selector: '#speed',     default: 1 },
        intensity: { selector: '#intensity', default: 0.7 },
        scale:     { selector: '#scale',     default: 1 },
    },
})

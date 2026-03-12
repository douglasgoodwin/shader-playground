import './tiles.css'
import { createShaderPage } from './shader-page.js'
import voronoiShader from './shaders/tiles/voronoi.glsl'
import hexgridShader from './shaders/tiles/hexgrid.glsl'
import tilesShader from './shaders/tiles/tiles.glsl'
import varitilesShader from './shaders/tiles/varitiles.glsl'

createShaderPage({
    shaders: {
        voronoi: voronoiShader,
        hexgrid: hexgridShader,
        tiles: tilesShader,
        varitiles: varitilesShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'speed', 'intensity', 'scale'],
    defaultEffect: 'voronoi',
    sliders: {
        speed:     { selector: '#speed',     default: 1 },
        intensity: { selector: '#intensity', default: 0.7 },
        scale:     { selector: '#scale',     default: 1 },
    },
})

import './kaleidoscope.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import kaleidoscopeShader from './shaders/kaleidoscope/kaleidoscope.glsl'
import tunnelShader from './shaders/kaleidoscope/tunnel.glsl'
import fractalShader from './shaders/kaleidoscope/fractal.glsl'

let textureSize = { width: 1, height: 1 }

const page = createShaderPage({
    shaders: {
        kaleidoscope: kaleidoscopeShader,
        tunnel: tunnelShader,
        fractal: fractalShader,
    },
    uniforms: [
        'resolution', 'time', 'mouse',
        'texture', 'textureSize', 'hasTexture',
        'segments', 'zoom', 'speed', 'invert',
    ],
    defaultEffect: 'kaleidoscope',
    recording: { width: 3888, height: 1080 },
    sliders: {
        segments: { selector: '#segments', default: 6 },
        zoom:     { selector: '#zoom',     default: 1 },
        speed:    { selector: '#speed',    default: 0.5 },
        invert:   { selector: '#invert',   default: false, type: 'checkbox' },
    },
    onRender({ gl, u }) {
        gl.uniform1i(u.hasTexture, media.hasMedia ? 1 : 0)
        if (media.hasMedia && media.texture) {
            gl.activeTexture(gl.TEXTURE0)
            media.updateVideoFrame()
            gl.bindTexture(gl.TEXTURE_2D, media.texture)
            gl.uniform1i(u.texture, 0)
            gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
        }
    },
})

const media = createMediaLoader(page.gl, {
    onLoad: (source, size) => { textureSize = size },
})
page.attachMedia(media)

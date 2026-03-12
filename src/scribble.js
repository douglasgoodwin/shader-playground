import './style.css'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import scribbleShader from './shaders/scribble/scribble.glsl'
import linesShader from './shaders/scribble/scribble-lines.glsl'

let textureSize = { width: 1, height: 1 }
const bgColor = [0.9, 0.05, 0.05]

const page = createShaderPage({
    shaders: {
        circles: scribbleShader,
        lines: linesShader,
    },
    uniforms: [
        'resolution', 'time', 'texture', 'textureSize',
        'density', 'circleSize', 'contrast', 'jitter',
        'ellipse', 'strokeWeight', 'bgColor',
    ],
    defaultEffect: 'circles',
    sliders: {
        density:      { selector: '#density',      default: 1.0 },
        circleSize:   { selector: '#circleSize',   default: 1.0 },
        contrast:     { selector: '#contrast',     default: 1.5 },
        jitter:       { selector: '#jitter',       default: 1.0 },
        ellipse:      { selector: '#ellipse',      default: 1.0 },
        strokeWeight: { selector: '#strokeWeight', default: 2.5 },
    },
    onRender({ gl, u }) {
        gl.uniform3f(u.bgColor, bgColor[0], bgColor[1], bgColor[2])
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

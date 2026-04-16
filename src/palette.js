import './palette.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import risoShader from './shaders/palette/riso.glsl'
import pastelShader from './shaders/palette/pastel.glsl'
import thermalShader from './shaders/palette/thermal.glsl'
import duotoneShader from './shaders/palette/duotone.glsl'
import posterizeShader from './shaders/palette/posterize.glsl'

let textureSize = { width: 1, height: 1 }

// Parse hex color to [r, g, b] floats
function hexToRGB(hex) {
    const n = parseInt(hex.slice(1), 16)
    return [(n >> 16 & 255) / 255, (n >> 8 & 255) / 255, (n & 255) / 255]
}

const colorAInput = document.getElementById('color-a')
const colorBInput = document.getElementById('color-b')
const duotoneColors = document.getElementById('duotone-colors')

const page = createShaderPage({
    shaders: {
        riso: risoShader,
        pastel: pastelShader,
        thermal: thermalShader,
        duotone: duotoneShader,
        posterize: posterizeShader,
    },
    uniforms: [
        'resolution', 'time', 'mouse',
        'texture', 'textureSize', 'hasTexture',
        'intensity', 'scale',
        'colorA', 'colorB',
    ],
    defaultEffect: 'riso',
    sliders: {
        intensity: { selector: '#intensity', default: 0.7 },
        scale:     { selector: '#scale',     default: 1 },
    },
    onRender({ gl, u, current }) {
        gl.uniform1i(u.hasTexture, media.hasMedia ? 1 : 0)
        if (media.hasMedia && media.texture) {
            gl.activeTexture(gl.TEXTURE0)
            media.updateVideoFrame()
            gl.bindTexture(gl.TEXTURE_2D, media.texture)
            gl.uniform1i(u.texture, 0)
            gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
        }

        // Pass duotone colors
        if (current === 'duotone') {
            const a = hexToRGB(colorAInput.value)
            const b = hexToRGB(colorBInput.value)
            gl.uniform3f(u.colorA, a[0], a[1], a[2])
            gl.uniform3f(u.colorB, b[0], b[1], b[2])
        }
    },
    onSwitch({ name }) {
        duotoneColors.style.display = name === 'duotone' ? '' : 'none'
    },
})

const media = createMediaLoader(page.gl, {
    onLoad: (source, size) => { textureSize = size },
})

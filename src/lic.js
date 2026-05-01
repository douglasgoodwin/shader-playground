import './style.css'
import './source-link.js'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import licShader from './shaders/lic/lic.glsl'
import flowShader from './shaders/lic/flow.glsl'

let textureSize = { width: 1, height: 1 }

const page = createShaderPage({
    shaders: {
        paint: licShader,
        flow: flowShader,
    },
    uniforms: [
        'resolution', 'time', 'texture', 'textureSize',
        'length', 'strength', 'contrast', 'curvature',
    ],
    defaultEffect: 'paint',
    sliders: {
        length:    { selector: '#length',    default: 20 },
        strength:  { selector: '#strength',  default: 0.8 },
        contrast:  { selector: '#contrast',  default: 1.5 },
        curvature: { selector: '#curvature', default: 0.6 },
    },
    onRender({ gl, u }) {
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

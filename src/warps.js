import './warps.css'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import drapeShader from './shaders/warps/drape.glsl'
import flowheartShader from './shaders/warps/flowheart.glsl'
import mercuryShader from './shaders/warps/mercury.glsl'
import vcrShader from './shaders/warps/vcr.glsl'

let textureSize = { width: 1, height: 1 }

const page = createShaderPage({
    shaders: {
        drape: drapeShader,
        flowheart: flowheartShader,
        mercury: mercuryShader,
        vcr: vcrShader,
    },
    uniforms: ['resolution', 'time', 'mouse', 'texture', 'textureSize', 'deform', 'geometry', 'speed', 'hasTexture'],
    defaultEffect: 'drape',
    sliders: {
        deform:   { selector: '#deform',   default: 0.5 },
        geometry: { selector: '#geometry', default: 1 },
        speed:    { selector: '#speed',    default: 0.5 },
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

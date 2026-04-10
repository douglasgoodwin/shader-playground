import './warps.css'
import { createShaderPage } from './shader-page.js'
import { createMediaLoader } from './media-loader.js'
import drapeShader from './shaders/warps/drape.glsl'
import flowheartShader from './shaders/warps/flowheart.glsl'
import mercuryShader from './shaders/warps/mercury.glsl'
import vcrShader from './shaders/warps/vcr.glsl'
import refractShader from './shaders/warps/refract.glsl'
import rippleShader from './shaders/effects/ripple.glsl'
import warpShader from './shaders/effects/warp.glsl'

let textureSize = { width: 1, height: 1 }

const bgControls = document.getElementById('bg-controls')
const imageControls = document.getElementById('image-controls')

const page = createShaderPage({
    shaders: {
        drape: drapeShader,
        flowheart: flowheartShader,
        mercury: mercuryShader,
        vcr: vcrShader,
        refract: refractShader,
        ripple: rippleShader,
        warp: warpShader,
    },
    uniforms: [
        'resolution', 'time', 'mouse',
        'texture', 'textureSize', 'hasTexture',
        'bgTexture', 'hasBgTexture',
        'deform', 'geometry', 'speed', 'intensity', 'scale',
    ],
    defaultEffect: 'drape',
    sliders: {
        deform:   { selector: '#deform',   default: 0.5 },
        geometry: { selector: '#geometry', default: 1 },
        speed:    { selector: '#speed',    default: 0.5 },
        intensity: { selector: '#intensity', default: 0.7 },
        scale:     { selector: '#scale',     default: 1 },
    },
    onRender({ gl, u, current }) {
        // Inner texture (TEXTURE0)
        gl.uniform1i(u.hasTexture, media.hasMedia ? 1 : 0)
        if (media.hasMedia && media.texture) {
            gl.activeTexture(gl.TEXTURE0)
            media.updateVideoFrame()
            gl.bindTexture(gl.TEXTURE_2D, media.texture)
            gl.uniform1i(u.texture, 0)
            gl.uniform2f(u.textureSize, textureSize.width, textureSize.height)
        }

        // Background texture (TEXTURE1) — only used by refract
        if (current === 'refract') {
            gl.uniform1i(u.hasBgTexture, bgMedia.hasMedia ? 1 : 0)
            if (bgMedia.hasMedia && bgMedia.texture) {
                gl.activeTexture(gl.TEXTURE1)
                bgMedia.updateVideoFrame()
                gl.bindTexture(gl.TEXTURE_2D, bgMedia.texture)
                gl.uniform1i(u.bgTexture, 1)
            }
        }
    },
    onSwitch({ name }) {
        // Show/hide background loader for refract mode
        const isRefract = name === 'refract'
        bgControls.style.display = isRefract ? '' : 'none'
        // Relabel the main loader when in refract mode
        const mainLabel = imageControls.querySelector('#drop-zone p')
        if (mainLabel) {
            mainLabel.innerHTML = isRefract
                ? 'Drop <b>inner</b> video here<br><span style="font-size:11px; opacity:0.6;">seen through the glass</span>'
                : 'Drop image/video here<br><span style="font-size:11px; opacity:0.6;">or click to browse</span>'
        }
    },
})

const media = createMediaLoader(page.gl, {
    onLoad: (source, size) => { textureSize = size },
})

const bgMedia = createMediaLoader(page.gl, {
    onLoad: () => {},
    selectors: {
        loading: '#bg-loading',
        dropZone: '#bg-drop-zone',
        fileInput: '#bg-file-input',
        urlInput: '#bg-url-input',
        loadUrl: '#bg-load-url',
    },
})

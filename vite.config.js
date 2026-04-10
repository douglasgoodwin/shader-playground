import { defineConfig } from 'vite'
import glsl from 'vite-plugin-glsl'
import { resolve } from 'path'

export default defineConfig({
  plugins: [glsl({ root: '/node_modules' })],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        whitney: resolve(__dirname, 'whitney/index.html'),
        geometries: resolve(__dirname, 'geometries/index.html'),
        glyphs: resolve(__dirname, 'glyphs/index.html'),
        stipple: resolve(__dirname, 'stipple/index.html'),
        exercises: resolve(__dirname, 'exercises/index.html'),
        particles: resolve(__dirname, 'particles/index.html'),
        opart: resolve(__dirname, 'opart/index.html'),
        tiles: resolve(__dirname, 'tiles/index.html'),
        landscape: resolve(__dirname, 'landscape/index.html'),
        displace: resolve(__dirname, 'displace/index.html'),
        audio: resolve(__dirname, 'audio/index.html'),
        'reaction-diffusion': resolve(__dirname, 'reaction-diffusion/index.html'),
        scribble: resolve(__dirname, 'scribble/index.html'),
        fluid: resolve(__dirname, 'fluid/index.html'),
        lic: resolve(__dirname, 'lic/index.html'),
        threejs: resolve(__dirname, 'threejs/index.html'),
        fur: resolve(__dirname, 'fur/index.html'),
        spike: resolve(__dirname, 'spike/index.html'),
      },
    },
  },
})

import { defineConfig } from 'vite'
import glsl from 'vite-plugin-glsl'
import { resolve } from 'path'

export default defineConfig({
  plugins: [glsl()],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        playground: resolve(__dirname, 'playground/index.html'),
        whitney: resolve(__dirname, 'whitney/index.html'),
        geometries: resolve(__dirname, 'geometries/index.html'),
        ascii: resolve(__dirname, 'ascii/index.html'),
      },
    },
  },
})

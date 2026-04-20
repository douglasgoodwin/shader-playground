import './learn.css'
import { mount, bindCode } from './widget.js'

import ray from '../shaders/learn/dimension/ray.glsl'
import sphere from '../shaders/learn/dimension/sphere.glsl'
import lit from '../shaders/learn/dimension/lit.glsl'
import unionShader from '../shaders/learn/dimension/union.glsl'
import blend from '../shaders/learn/dimension/blend.glsl'
import scene from '../shaders/learn/dimension/scene.glsl'
import terrain from '../shaders/learn/dimension/terrain.glsl'

mount('#w-ray', {
    shader: ray,
    controls: [
        { uniform: 'u_fov', label: 'u_fov', min: 0.3, max: 3.0, step: 0.05, default: 1.0 },
    ],
})

mount('#w-sphere', {
    shader: sphere,
    controls: [
        { uniform: 'u_radius',   label: 'u_radius',   min: 0.2, max: 1.0, step: 0.01, default: 0.6 },
        { uniform: 'u_distance', label: 'u_distance', min: 1.5, max: 6.0, step: 0.05, default: 3.0 },
    ],
})

mount('#w-lit', {
    shader: lit,
    controls: [
        { uniform: 'u_radius',      label: 'u_radius',      min: 0.3, max: 1.0, step: 0.01, default: 0.7 },
        { uniform: 'u_light_angle', label: 'u_light_angle', min: 0, max: 6.28, step: 0.05, default: 1.0 },
    ],
})

mount('#w-union', {
    shader: unionShader,
    controls: [
        { uniform: 'u_radius',     label: 'u_radius',     min: 0.2, max: 0.6, step: 0.01, default: 0.4 },
        { uniform: 'u_separation', label: 'u_separation', min: 0.0, max: 1.0, step: 0.01, default: 0.6 },
    ],
})

mount('#w-blend', {
    shader: blend,
    controls: [
        { uniform: 'u_radius',     label: 'u_radius',     min: 0.2, max: 0.6, step: 0.01, default: 0.4 },
        { uniform: 'u_separation', label: 'u_separation', min: 0.0, max: 1.0, step: 0.01, default: 0.55 },
        { uniform: 'u_k',          label: 'u_k',          min: 0.0, max: 0.6, step: 0.01, default: 0.25 },
    ],
})

mount('#w-scene', {
    shader: scene,
    controls: [
        { uniform: 'u_speed', label: 'u_speed', min: 0.0, max: 1.5, step: 0.05, default: 0.3 },
        { uniform: 'u_blend', label: 'u_blend', min: 0.0, max: 0.4, step: 0.01, default: 0.2 },
    ],
})

mount('#w-terrain', {
    shader: terrain,
    controls: [
        { uniform: 'u_scale',     label: 'u_scale',     min: 0.2, max: 1.5, step: 0.05, default: 0.6 },
        { uniform: 'u_amplitude', label: 'u_amplitude', min: 0.5, max: 2.0, step: 0.05, default: 1.0 },
        { uniform: 'u_speed',     label: 'u_speed',     min: 0.0, max: 1.0, step: 0.05, default: 0.3 },
    ],
})

bindCode()

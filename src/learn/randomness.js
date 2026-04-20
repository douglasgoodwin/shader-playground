import './learn.css'
import { mount, bindCode } from './widget.js'

import hash from '../shaders/learn/randomness/hash.glsl'
import smoothing from '../shaders/learn/randomness/smoothing.glsl'
import gradient from '../shaders/learn/randomness/gradient.glsl'
import fbm from '../shaders/learn/randomness/fbm.glsl'
import flow from '../shaders/learn/randomness/flow.glsl'
import warp from '../shaders/learn/randomness/warp.glsl'
import domain from '../shaders/learn/randomness/domain.glsl'

mount('#w-hash', {
    shader: hash,
    controls: [
        { uniform: 'u_cells', label: 'u_cells', min: 2, max: 120, step: 1, default: 14 },
        { uniform: 'u_seed',  label: 'u_seed',  min: 0, max: 20, step: 0.1, default: 0 },
    ],
})

mount('#w-smoothing', {
    shader: smoothing,
    controls: [
        { uniform: 'u_scale',  label: 'u_scale',  min: 2, max: 16, step: 0.5, default: 6 },
        { uniform: 'u_smooth', label: 'u_smooth', min: 0, max: 1, step: 0.01, default: 1 },
    ],
})

mount('#w-gradient', {
    shader: gradient,
    controls: [
        { uniform: 'u_scale', label: 'u_scale', min: 2, max: 18, step: 0.5, default: 6 },
        { uniform: 'u_mode',  label: 'u_mode',  min: 0, max: 1, step: 1, default: 0 },
    ],
})

mount('#w-fbm', {
    shader: fbm,
    controls: [
        { uniform: 'u_scale',       label: 'u_scale',       min: 1, max: 10, step: 0.5, default: 3 },
        { uniform: 'u_octaves',     label: 'u_octaves',     min: 1, max: 6, step: 1, default: 4 },
        { uniform: 'u_persistence', label: 'u_persistence', min: 0.2, max: 0.8, step: 0.01, default: 0.5 },
    ],
})

mount('#w-flow', {
    shader: flow,
    controls: [
        { uniform: 'u_scale', label: 'u_scale', min: 1, max: 10, step: 0.5, default: 4 },
        { uniform: 'u_speed', label: 'u_speed', min: 0, max: 2.0, step: 0.01, default: 0.35 },
    ],
})

mount('#w-warp', {
    shader: warp,
    controls: [
        { uniform: 'u_scale',    label: 'u_scale',    min: 1, max: 12, step: 0.5, default: 5 },
        { uniform: 'u_strength', label: 'u_strength', min: 0, max: 1.5, step: 0.01, default: 0.35 },
        { uniform: 'u_radius',   label: 'u_radius',   min: 0.1, max: 0.45, step: 0.01, default: 0.28 },
    ],
})

mount('#w-domain', {
    shader: domain,
    controls: [
        { uniform: 'u_scale',    label: 'u_scale',    min: 1, max: 6, step: 0.5, default: 3 },
        { uniform: 'u_strength', label: 'u_strength', min: 0, max: 4, step: 0.05, default: 2.0 },
        { uniform: 'u_speed',    label: 'u_speed',    min: 0, max: 0.5, step: 0.005, default: 0.08 },
    ],
})

bindCode()

import './learn.css'
import { mount, bindCode } from './widget.js'

import oscillation from '../shaders/learn/time/oscillation.glsl'
import pulsingCircle from '../shaders/learn/time/pulsing-circle.glsl'
import orbitingCircle from '../shaders/learn/time/orbiting-circle.glsl'
import colorCycle from '../shaders/learn/time/color-cycle.glsl'
import mirror from '../shaders/learn/time/mirror.glsl'
import grid from '../shaders/learn/time/grid.glsl'
import breathingGrid from '../shaders/learn/time/breathing-grid.glsl'

mount('#w-oscillation', {
    shader: oscillation,
    controls: [],
})

mount('#w-pulse', {
    shader: pulsingCircle,
    controls: [
        { uniform: 'u_base_radius', label: 'u_base_radius', min: 0.05, max: 0.5, step: 0.01, default: 0.25 },
        { uniform: 'u_amplitude',   label: 'u_amplitude',   min: 0.0, max: 0.2, step: 0.005, default: 0.08 },
        { uniform: 'u_speed',       label: 'u_speed',       min: 0.0, max: 6.0, step: 0.05, default: 2.0 },
    ],
})

mount('#w-orbit', {
    shader: orbitingCircle,
    controls: [
        { uniform: 'u_radius', label: 'u_radius', min: 0.05, max: 0.3, step: 0.01, default: 0.12 },
        { uniform: 'u_orbit',  label: 'u_orbit',  min: 0.0, max: 0.45, step: 0.01, default: 0.28 },
        { uniform: 'u_speed',  label: 'u_speed',  min: 0.0, max: 4.0, step: 0.05, default: 1.2 },
    ],
})

mount('#w-color', {
    shader: colorCycle,
    controls: [
        { uniform: 'u_speed',      label: 'u_speed',      min: 0.0, max: 2.0, step: 0.01, default: 0.25 },
        { uniform: 'u_saturation', label: 'u_saturation', min: 0.0, max: 1.0, step: 0.01, default: 1.0 },
    ],
})

mount('#w-mirror', {
    shader: mirror,
    controls: [
        { uniform: 'u_cx',     label: 'u_cx',     min: 0.0, max: 0.5, step: 0.01, default: 0.22 },
        { uniform: 'u_radius', label: 'u_radius', min: 0.04, max: 0.22, step: 0.01, default: 0.12 },
    ],
})

mount('#w-grid', {
    shader: grid,
    controls: [
        { uniform: 'u_count',  label: 'u_count',  min: 2.0, max: 14.0, step: 1.0, default: 6.0 },
        { uniform: 'u_radius', label: 'u_radius', min: 0.1, max: 0.5, step: 0.01, default: 0.28 },
    ],
})

mount('#w-breathing', {
    shader: breathingGrid,
    controls: [
        { uniform: 'u_count',  label: 'u_count',  min: 2.0, max: 12.0, step: 1.0, default: 5.0 },
        { uniform: 'u_radius', label: 'u_radius', min: 0.1, max: 0.4, step: 0.01, default: 0.22 },
        { uniform: 'u_speed',  label: 'u_speed',  min: 0.0, max: 4.0, step: 0.05, default: 1.6 },
    ],
})

bindCode()

import './learn.css'
import { mount, bindCode } from './widget.js'

import solidColor from '../shaders/learn/pixel/solid-color.glsl'
import positionColor from '../shaders/learn/pixel/position-color.glsl'
import distance from '../shaders/learn/pixel/distance.glsl'
import stepCircle from '../shaders/learn/pixel/step-circle.glsl'
import smoothCircle from '../shaders/learn/pixel/smooth-circle.glsl'
import movableCircle from '../shaders/learn/pixel/movable-circle.glsl'
import coloredCircle from '../shaders/learn/pixel/colored-circle.glsl'

mount('#w-solid', {
    shader: solidColor,
    controls: [
        { uniform: 'u_red',   label: 'u_red',   min: 0, max: 1, step: 0.01, default: 0.85 },
        { uniform: 'u_green', label: 'u_green', min: 0, max: 1, step: 0.01, default: 0.34 },
        { uniform: 'u_blue',  label: 'u_blue',  min: 0, max: 1, step: 0.01, default: 0.28 },
    ],
})

mount('#w-position', {
    shader: positionColor,
    controls: [],
})

mount('#w-distance', {
    shader: distance,
    controls: [
        { uniform: 'u_scale', label: 'u_scale', min: 0.2, max: 3.0, step: 0.01, default: 1.4 },
    ],
})

mount('#w-step', {
    shader: stepCircle,
    controls: [
        { uniform: 'u_radius', label: 'u_radius', min: 0.05, max: 0.6, step: 0.01, default: 0.32 },
    ],
})

mount('#w-smooth', {
    shader: smoothCircle,
    controls: [
        { uniform: 'u_radius',   label: 'u_radius',   min: 0.05, max: 0.6, step: 0.01, default: 0.32 },
        { uniform: 'u_softness', label: 'u_softness', min: 0.0,  max: 0.3, step: 0.01, default: 0.02 },
    ],
})

mount('#w-movable', {
    shader: movableCircle,
    controls: [
        { uniform: 'u_cx',     label: 'u_cx',     min: -0.6, max: 0.6, step: 0.01, default: 0.15 },
        { uniform: 'u_cy',     label: 'u_cy',     min: -0.4, max: 0.4, step: 0.01, default: -0.1 },
        { uniform: 'u_radius', label: 'u_radius', min: 0.05, max: 0.45, step: 0.01, default: 0.22 },
    ],
})

mount('#w-colored', {
    shader: coloredCircle,
    controls: [
        { uniform: 'u_radius',   label: 'u_radius',   min: 0.05, max: 0.55, step: 0.01, default: 0.32 },
        { uniform: 'u_softness', label: 'u_softness', min: 0.0, max: 0.2, step: 0.01, default: 0.02 },
        { uniform: 'u_hue_in',   label: 'u_hue_in',   min: 0, max: 1, step: 0.005, default: 0.07 },
        { uniform: 'u_hue_out',  label: 'u_hue_out',  min: 0, max: 1, step: 0.005, default: 0.58 },
    ],
})

bindCode()

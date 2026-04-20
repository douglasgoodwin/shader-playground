import './learn.css'
import './about.css'
import { mount } from './widget.js'

import solidColor from '../shaders/learn/pixel/solid-color.glsl'
import stepCircle from '../shaders/learn/pixel/step-circle.glsl'
import pulsingCircle from '../shaders/learn/time/pulsing-circle.glsl'

mount('#q-solid', {
    shader: solidColor,
    controls: [
        { uniform: 'u_red',   label: 'u_red',   min: 0, max: 1, step: 0.01, default: 0.85 },
        { uniform: 'u_green', label: 'u_green', min: 0, max: 1, step: 0.01, default: 0.34 },
        { uniform: 'u_blue',  label: 'u_blue',  min: 0, max: 1, step: 0.01, default: 0.28 },
    ],
})

mount('#q-circle', {
    shader: stepCircle,
    controls: [
        { uniform: 'u_radius', label: 'u_radius', min: 0.05, max: 0.45, step: 0.01, default: 0.28 },
    ],
})

mount('#q-pulse', {
    shader: pulsingCircle,
    controls: [
        { uniform: 'u_base_radius', label: 'u_base_radius', min: 0.1, max: 0.4, step: 0.01, default: 0.22 },
        { uniform: 'u_amplitude',   label: 'u_amplitude',   min: 0.0, max: 0.15, step: 0.005, default: 0.08 },
        { uniform: 'u_speed',       label: 'u_speed',       min: 0.0, max: 4.0, step: 0.05, default: 1.8 },
    ],
})

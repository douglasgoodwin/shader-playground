// Firefly shader - gentle blinking particles with spark bursts
// Converted from Shadertoy

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "lygia/math/const.glsl"
#include "lygia/generative/random.glsl"

// Smooth "spark/firefly" intensity blob with halo
float blob(vec2 p, vec2 c, float rCore, float rHalo) {
    float d = length(p - c);
    float core = smoothstep(rCore, 0.0, d);
    float halo = smoothstep(rHalo, rCore, d) * 0.025;
    return core + halo;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;

    // Background (dark with slight gradient)
    vec3 col = vec3(0.0);
    col += vec3(0.01, 0.012, 0.02) * (0.5 + 0.5 * uv.y);

    // Parameters
    float N = 70.0 * u_scale;  // number of particles scales with u_scale
    float t = u_time * u_speed;

    // Accumulate fireflies
    for (float i = 0.0; i < 150.0; i += 1.0) {
        if (i >= N) break;
        float id = i + 1.0;

        // Per-particle randoms
        vec2 seed = random2(id * 13.7);
        float phase = random(id * 9.1) * TAU;
        float blinkRate = mix(0.8, 2.2, random(id * 5.3)); // Hz-ish
        float size = mix(0.004, 0.010, random(id * 2.7));  // core radius in uv units
        float halo = size * 6.0;

        // Base position in a box around center
        vec2 base = (seed - 0.5) * vec2(1.6, 0.9);

        // Drift (gentle, insect-like) using sin/cos with per-id frequencies
        float f1 = mix(0.2, 0.7, random(id * 1.1));
        float f2 = mix(0.15, 0.55, random(id * 1.9));
        vec2 drift = 0.12 * vec2(
            sin(t * TAU * f1 + phase),
            cos(t * TAU * f2 + phase * 1.7)
        );

        // Occasional impulse (spark-ish) as a short-lived velocity burst
        float eventRate = mix(0.15, 0.45, random(id * 7.7));
        float eventT = t * eventRate + random(id * 11.3) * 10.0;
        float k = fract(eventT);
        float burst = exp(-k * 18.0);

        // Random burst direction
        vec2 dir = normalize(random2(id * 23.9) - 0.5);
        vec2 impulse = dir * burst * 0.22;

        // Slight gravity downward for sparks
        vec2 gravity = vec2(0.0, -0.03) * burst;

        vec2 pos = base + drift + impulse + gravity;

        // Blink: mostly soft pulsing + occasional sharper flare
        float blink = 0.5 + 0.5 * sin(t * TAU * blinkRate + phase);
        blink = smoothstep(0.3, 1.0, blink);

        // Add a rare bright flare
        float flare = pow(0.5 + 0.5 * sin(t * TAU * (blinkRate * 0.5) + phase * 2.0), 18.0);
        float intensity = (0.25 + 0.9 * blink) + 0.6 * flare;
        intensity *= u_intensity;

        // Color: firefly green-yellow with slight variation
        float hueVar = random(id * 3.3);
        vec3 firefly = mix(vec3(0.6, 1.2, 0.3), vec3(1.3, 1.0, 0.2), hueVar);
        firefly *= 1.2;

        float b = blob(uv, pos, size, halo);
        col += firefly * b * intensity;
    }

    // Mouse glow interaction
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / u_resolution.y;
    float mouseDist = length(uv - mouse);
    col += vec3(0.4, 0.8, 0.3) * 0.015 / (mouseDist + 0.1);

    // Click ripples
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.4 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.03, 0.0, ring) * exp(-age * 2.5 / u_intensity);
            col += ripple * u_rippleColors[i] * 0.5;
        }
    }

    // Gentle tonemap
    col = col / (1.0 + col);

    gl_FragColor = vec4(col, 1.0);
}

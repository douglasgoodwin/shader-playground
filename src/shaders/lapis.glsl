// Inspired by James Whitney's "Lapis" (1966)
// Dot patterns with harmonic orbital motion

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "/lygia/math/const.glsl"

// Soft dot function
float dot_pattern(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.3, d);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv *= 2.0 / u_scale;

    float t = u_time * u_speed * 0.5;

    vec3 color = vec3(0.0);

    // Number of concentric rings
    const int NUM_RINGS = 12;
    // Dots per ring
    const int DOTS_PER_RING = 24;

    float dotSize = 0.015 * u_intensity;

    for (int ring = 1; ring <= NUM_RINGS; ring++) {
        float ringRadius = float(ring) * 0.08;

        // Harmonic frequency - each ring rotates at different speed
        // Using harmonic ratios inspired by Whitney's work
        float freq = 1.0 / float(ring);
        float ringRotation = t * freq * 2.0;

        // Secondary oscillation for more complex motion
        float wobble = sin(t * 0.5 + float(ring) * 0.5) * 0.02;

        for (int i = 0; i < DOTS_PER_RING; i++) {
            // Base angle for this dot
            float baseAngle = float(i) * TAU / float(DOTS_PER_RING);

            // Add rotation and per-dot phase offset
            float angle = baseAngle + ringRotation;

            // Radial breathing
            float r = ringRadius + wobble + sin(baseAngle * 3.0 + t) * 0.01;

            // Dot position
            vec2 dotPos = vec2(cos(angle), sin(angle)) * r;

            // Calculate dot contribution
            float dot = dot_pattern(uv, dotPos, dotSize);

            // Color based on ring and angle - deep blues and golds like Lapis lazuli
            float hue = float(ring) / float(NUM_RINGS);
            vec3 dotColor = mix(
                vec3(0.1, 0.2, 0.6),  // Deep blue
                vec3(0.9, 0.8, 0.4),  // Gold
                sin(angle + t * 0.2) * 0.5 + 0.5
            );

            // Add subtle variation
            dotColor *= 0.7 + 0.3 * sin(float(ring) + t);

            color += dot * dotColor * u_intensity;
        }
    }

    // Central mandala - smaller, faster rotating dots
    const int CENTER_RINGS = 4;
    const int CENTER_DOTS = 12;

    for (int ring = 1; ring <= CENTER_RINGS; ring++) {
        float ringRadius = float(ring) * 0.025;
        float freq = float(CENTER_RINGS - ring + 1) * 0.5;
        float ringRotation = t * freq * 3.0;

        for (int i = 0; i < CENTER_DOTS; i++) {
            float baseAngle = float(i) * TAU / float(CENTER_DOTS);
            float angle = baseAngle + ringRotation;

            vec2 dotPos = vec2(cos(angle), sin(angle)) * ringRadius;
            float dot = dot_pattern(uv, dotPos, dotSize * 0.6);

            vec3 dotColor = vec3(1.0, 0.95, 0.8); // Bright center
            color += dot * dotColor * u_intensity * 0.8;
        }
    }

    // Outer slow-moving ring
    const int OUTER_DOTS = 36;
    float outerRadius = 1.1;
    float outerRotation = t * 0.1;

    for (int i = 0; i < OUTER_DOTS; i++) {
        float baseAngle = float(i) * TAU / float(OUTER_DOTS);
        float angle = baseAngle + outerRotation;

        // Elliptical orbit
        vec2 dotPos = vec2(cos(angle) * outerRadius, sin(angle) * outerRadius * 0.9);
        float dot = dot_pattern(uv, dotPos, dotSize * 1.2);

        vec3 dotColor = vec3(0.3, 0.4, 0.8) * (0.5 + 0.5 * sin(baseAngle * 2.0 + t));
        color += dot * dotColor * u_intensity * 0.5;
    }

    // Mouse influence - attracts nearby dots visually
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    mouse *= 2.0 / u_scale;
    float mouseDist = length(uv - mouse);
    color += 0.02 / (mouseDist + 0.1) * vec3(0.5, 0.6, 1.0);

    // Subtle vignette
    float vignette = 1.0 - length(uv) * 0.3;
    color *= vignette;

    // Background - deep space blue
    vec3 bg = vec3(0.02, 0.03, 0.08);
    color = max(color, bg);

    // Ripple effects
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

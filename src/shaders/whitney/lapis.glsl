// Inspired by James Whitney's "Lapis" (1966)
// Dot patterns with harmonic orbital motion

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "../lygia/math/const.glsl"

// Soft dot function
float dot_pattern(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.3, d);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv *= 1.8;

    float t = u_time * u_speed * 0.5;

    vec3 color = vec3(0.0);

    // Number of concentric rings - affected by density
    int numRings = int(12.0 * u_density);
    int dotsPerRing = int(24.0 * u_density);

    float dotSize = 0.018;

    for (int ring = 1; ring <= 24; ring++) {
        if (ring > numRings) break;

        float ringRadius = float(ring) * 0.07;

        // Harmonic frequency - each ring rotates at different speed
        // Harmonics parameter affects the frequency relationship
        float freq = 1.0 / pow(float(ring), u_harmonics * 0.5);
        float ringRotation = t * freq * 2.0;

        // Secondary oscillation for more complex motion
        float wobble = sin(t * 0.5 + float(ring) * 0.5) * 0.02;

        for (int i = 0; i < 48; i++) {
            if (i >= dotsPerRing) break;

            // Base angle for this dot
            float baseAngle = float(i) * TAU / float(dotsPerRing);

            // Add rotation and per-dot phase offset
            float angle = baseAngle + ringRotation;

            // Radial breathing
            float r = ringRadius + wobble + sin(baseAngle * 3.0 + t) * 0.01;

            // Dot position
            vec2 dotPos = vec2(cos(angle), sin(angle)) * r;

            // Calculate dot contribution
            float dot = dot_pattern(uv, dotPos, dotSize);

            // Color based on ring and angle - deep blues and golds like Lapis lazuli
            vec3 dotColor = mix(
                vec3(0.1, 0.2, 0.6),  // Deep blue
                vec3(0.9, 0.8, 0.4),  // Gold
                sin(angle + t * 0.2) * 0.5 + 0.5
            );

            // Add subtle variation
            dotColor *= 0.7 + 0.3 * sin(float(ring) + t);

            color += dot * dotColor;
        }
    }

    // Central mandala - smaller, faster rotating dots
    int centerRings = int(4.0 * u_density);
    int centerDots = int(12.0 * u_density);

    for (int ring = 1; ring <= 8; ring++) {
        if (ring > centerRings) break;

        float ringRadius = float(ring) * 0.022;
        float freq = float(centerRings - ring + 1) * 0.5 * u_harmonics;
        float ringRotation = t * freq * 3.0;

        for (int i = 0; i < 24; i++) {
            if (i >= centerDots) break;

            float baseAngle = float(i) * TAU / float(centerDots);
            float angle = baseAngle + ringRotation;

            vec2 dotPos = vec2(cos(angle), sin(angle)) * ringRadius;
            float dot = dot_pattern(uv, dotPos, dotSize * 0.6);

            vec3 dotColor = vec3(1.0, 0.95, 0.8); // Bright center
            color += dot * dotColor * 0.8;
        }
    }

    // Outer slow-moving ring
    int outerDots = int(36.0 * u_density);
    float outerRadius = 1.0;
    float outerRotation = t * 0.1 * u_harmonics;

    for (int i = 0; i < 72; i++) {
        if (i >= outerDots) break;

        float baseAngle = float(i) * TAU / float(outerDots);
        float angle = baseAngle + outerRotation;

        // Elliptical orbit
        vec2 dotPos = vec2(cos(angle) * outerRadius, sin(angle) * outerRadius * 0.9);
        float dot = dot_pattern(uv, dotPos, dotSize * 1.2);

        vec3 dotColor = vec3(0.3, 0.4, 0.8) * (0.5 + 0.5 * sin(baseAngle * 2.0 + t));
        color += dot * dotColor * 0.5;
    }

    // Mouse influence
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    mouse *= 1.8;
    float mouseDist = length(uv - mouse);
    color += 0.015 / (mouseDist + 0.1) * vec3(0.5, 0.6, 1.0);

    // Subtle vignette
    float vignette = 1.0 - length(uv) * 0.25;
    color *= vignette;

    // Background - deep space blue
    vec3 bg = vec3(0.02, 0.03, 0.08);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "lygia/math/const.glsl"
#include "lygia/color/space/hsv2rgb.glsl"

// Soft circle/seed shape
float seed(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.3, d);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed * 0.5;

    // Background gradient
    float bgGrad = length(uv) * 0.5;
    vec3 bgColor = mix(
        vec3(0.02, 0.03, 0.08),
        vec3(0.08, 0.05, 0.12),
        bgGrad
    );
    vec3 color = bgColor;

    // Number of seeds to render
    int maxSeeds = 500;

    // Animate the growth - seeds emerge over time
    float growthPhase = mod(t * 0.3, 4.0);
    float activeSeeds = growthPhase * 125.0;

    // Mouse influence on rotation
    float mouseAngle = atan(mouse.y, mouse.x);
    float mouseDist = length(mouse);

    for (int i = 0; i < 500; i++) {
        if (i >= maxSeeds) break;

        float fi = float(i);

        // Fade in seeds progressively
        float seedAlpha = smoothstep(fi - 10.0, fi, activeSeeds);
        if (seedAlpha < 0.01) continue;

        // Phyllotaxis formula: angle = i * golden_angle, radius = c * sqrt(i)
        float angle = fi * GOLDEN_ANGLE;

        // Add subtle rotation animation
        angle += t * 0.2;

        // Radius grows with sqrt(index) for even distribution
        float baseRadius = 0.025 * sqrt(fi) * u_scale;

        // Breathing animation - seeds pulse outward
        float breathe = 1.0 + 0.05 * sin(t * 2.0 - fi * 0.1);
        float r = baseRadius * breathe;

        // Calculate seed position
        vec2 seedPos = vec2(cos(angle), sin(angle)) * r;

        // Mouse repulsion effect
        vec2 toMouse = seedPos - mouse;
        float mouseInfluence = u_intensity * 0.1 / (length(toMouse) + 0.2);
        seedPos += normalize(toMouse) * mouseInfluence * 0.05;

        // Seed size varies by position (smaller toward center, larger outside)
        float seedSize = 0.008 + 0.006 * (baseRadius / 0.4);
        seedSize *= (0.8 + 0.2 * sin(fi * 0.5 + t));

        // Draw the seed
        float s = seed(uv, seedPos, seedSize);

        // Color based on spiral arm (using golden angle creates natural spiral arms)
        // The modulo creates distinct spiral patterns
        float spiralArm = mod(fi, 13.0) / 13.0; // 13 is a Fibonacci number
        float hue = spiralArm + t * 0.1;

        // Secondary pattern based on another Fibonacci number
        float spiralArm2 = mod(fi, 21.0) / 21.0;
        float saturation = 0.6 + 0.3 * spiralArm2;

        // Brightness varies by distance from center
        float brightness = 0.7 + 0.3 * (1.0 - baseRadius / 0.5);

        vec3 seedColor = hsv2rgb(vec3(hue, saturation, brightness));

        // Add glow effect
        float glow = seed(uv, seedPos, seedSize * 2.5) * 0.3;

        // Composite
        color = mix(color, seedColor * 0.3, glow * seedAlpha);
        color = mix(color, seedColor, s * seedAlpha);
    }

    // Add subtle vignette
    float vignette = 1.0 - length(uv) * 0.5;
    color *= vignette;

    // Central glow
    float centerGlow = exp(-length(uv) * 4.0) * 0.2 * u_intensity;
    color += vec3(0.9, 0.8, 0.5) * centerGlow;

    gl_FragColor = vec4(color, 1.0);
}

// Inspired by John Whitney's "Permutations" (1968)
// Colorful dots in Lissajous-like paths with rainbow cycling

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "/lygia/math/const.glsl"
#include "/lygia/color/space/hsv2rgb.glsl"

// Soft dot
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.2, d);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv *= 1.5;

    float t = u_time * u_speed * 0.3;

    vec3 color = vec3(0.0);

    // Number of dots
    int numDots = int(64.0 * u_density);

    for (int i = 0; i < 128; i++) {
        if (i >= numDots) break;

        float fi = float(i);
        float n = float(numDots);

        // Each dot has unique frequency ratios - Whitney's differential dynamics
        float freqX = 1.0 + fi * 0.05 * u_harmonics;
        float freqY = 1.0 + fi * 0.07 * u_harmonics;
        float phase = fi * TAU / n;

        // Lissajous-like motion
        float x = sin(t * freqX + phase) * (0.8 - fi * 0.003);
        float y = cos(t * freqY + phase * 1.5) * (0.8 - fi * 0.003);

        vec2 dotPos = vec2(x, y);

        // Dot size varies slightly
        float size = 0.02 + 0.01 * sin(fi * 0.5);

        float dot = dot_shape(uv, dotPos, size);

        // Rainbow color cycling - each dot slightly offset in hue
        float hue = fract(fi / n + t * 0.1);
        vec3 dotColor = hsv2rgb(vec3(hue, 0.8, 1.0));

        color += dot * dotColor * 0.7;
    }

    // Mouse glow
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    mouse *= 1.5;
    float mouseDist = length(uv - mouse);
    color += 0.015 / (mouseDist + 0.1) * vec3(0.8, 0.9, 1.0);

    // Subtle vignette
    float vignette = 1.0 - length(uv) * 0.2;
    color *= vignette;

    // Deep background
    vec3 bg = vec3(0.01, 0.01, 0.02);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

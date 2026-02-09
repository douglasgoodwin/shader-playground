// "Arabesque" from John Whitney's "Digital Harmony"
// Original algorithm by Paul Rother, ported from Processing

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "../lygia/math/const.glsl"

// Soft dot
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.2, d);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    float t = u_time * u_speed * 0.1;

    vec3 color = vec3(0.0);

    // Whitney's parameters
    float radius = 0.8;
    int npoints = int(360.0 * u_density);
    float stepVal = t * (1.0 / 60.0) * u_harmonics;

    for (int i = 0; i < 720; i++) {
        if (i >= npoints) break;

        float fi = float(i);
        float ratio = fi / float(npoints);

        // Angle in radians (starting at -90 degrees)
        float a = (-0.25 + ratio) * 2.0 * PI;

        // Whitney's arabesque formula
        float r = 3.0 * radius;
        float x = cos(a) * ratio + fi * stepVal * r;

        // Modular wrapping - the key to the arabesque effect
        x = mod(x + r * 0.5, r) - r * 0.5;

        float y = sin(a) * radius;

        vec2 dotPos = vec2(x, y);

        float dotSize = 0.012;
        float dot = dot_shape(uv, dotPos, dotSize);

        // Color based on position in sequence
        vec3 dotColor = vec3(
            0.8 + 0.2 * sin(ratio * PI * 2.0 + t),
            0.7 + 0.3 * sin(ratio * PI * 4.0 + t * 0.7),
            0.9
        );

        color += dot * dotColor * 0.8;
    }

    // Mouse glow
    vec2 mouse = u_mouse / u_resolution;
    mouse = mouse * 2.0 - 1.0;
    mouse.x *= u_resolution.x / u_resolution.y;
    float mouseDist = length(uv - mouse);
    color += 0.01 / (mouseDist + 0.1) * vec3(0.7, 0.8, 1.0);

    // Background
    vec3 bg = vec3(0.01, 0.01, 0.02);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

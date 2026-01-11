// Whitney Music Box - Jim Bumgardner's interpretation
// Based on John Whitney's "Digital Harmony"

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359
#define TAU 6.28318530718

// Soft dot with glow
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.1, d);
}

// HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    float t = u_time * u_speed * 0.3;

    vec3 color = vec3(0.0);

    // Number of dots
    int npoints = int(48.0 * u_density);
    float maxRadius = 0.9;

    for (int i = 1; i <= 96; i++) {
        if (i > npoints) break;

        float fi = float(i);
        float np = float(npoints);

        // Each dot's radius from center (outer dots are index 1, inner are higher)
        float r = (1.0 - fi / np) * maxRadius;

        // Key insight: each dot rotates at speed proportional to its index
        // This creates harmonic relationships
        float angularSpeed = fi * u_harmonics;
        float a = t * angularSpeed;

        // Position on circle
        float x = cos(a) * r;
        float y = sin(a) * r;

        vec2 dotPos = vec2(x, y);

        // Dot size - slightly larger for outer dots
        float dotSize = 0.015 + 0.01 * (1.0 - fi / np);
        float dot = dot_shape(uv, dotPos, dotSize);

        // Color - hue based on position, shifts over time
        float hue = fract(fi / np + t * 0.01);
        vec3 dotColor = hsv2rgb(vec3(hue, 0.6, 1.0));

        // Brightness based on radius
        dotColor *= 0.7 + 0.3 * (1.0 - fi / np);

        color += dot * dotColor;
    }

    // Mouse glow
    vec2 mouse = u_mouse / u_resolution;
    mouse = mouse * 2.0 - 1.0;
    mouse.x *= u_resolution.x / u_resolution.y;
    float mouseDist = length(uv - mouse);
    color += 0.01 / (mouseDist + 0.1) * vec3(0.7, 0.8, 1.0);

    // Subtle center glow
    float centerDist = length(uv);
    color += 0.02 / (centerDist + 0.2) * vec3(0.3, 0.4, 0.6);

    // Background
    vec3 bg = vec3(0.01, 0.01, 0.02);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

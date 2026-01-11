// Inspired by John Whitney's "Matrix III" (1972)
// Grid of dots with wave-like transformations

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359
#define TAU 6.28318530718

// Soft dot
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.1, d);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed * 0.4;

    vec3 color = vec3(0.0);

    // Grid parameters
    int gridSize = int(12.0 * u_density);
    float spacing = 2.0 / float(gridSize);

    for (int ix = 0; ix < 24; ix++) {
        if (ix >= gridSize) break;
        for (int iy = 0; iy < 24; iy++) {
            if (iy >= gridSize) break;

            float fx = float(ix);
            float fy = float(iy);
            float n = float(gridSize);

            // Base grid position (centered)
            vec2 basePos = vec2(
                (fx - n * 0.5 + 0.5) * spacing,
                (fy - n * 0.5 + 0.5) * spacing
            );

            // Distance from center for wave effects
            float dist = length(basePos);
            float angle = atan(basePos.y, basePos.x);

            // Whitney-style transformations
            // Radial wave
            float radialWave = sin(dist * 8.0 * u_harmonics - t * 2.0) * 0.05;

            // Spiral twist
            float twist = sin(dist * 4.0 - t) * 0.3 * u_harmonics;
            float newAngle = angle + twist;

            // Apply transformation
            float newDist = dist + radialWave;
            vec2 dotPos = vec2(cos(newAngle), sin(newAngle)) * newDist;

            // Pulsing dot size based on position
            float pulse = 0.5 + 0.5 * sin(dist * 6.0 * u_harmonics - t * 3.0);
            float size = 0.015 * (0.5 + pulse * 0.5);

            float dot = dot_shape(uv, dotPos, size);

            // Color based on original grid position
            vec3 dotColor = vec3(
                0.6 + 0.4 * sin(fx * 0.5 + t),
                0.7 + 0.3 * sin(fy * 0.5 + t + 1.0),
                0.9
            );

            // Brightness varies with wave
            dotColor *= 0.6 + 0.4 * pulse;

            color += dot * dotColor * 0.8;
        }
    }

    // Mouse influence - local distortion glow
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float mouseDist = length(uv - mouse);
    color += 0.02 / (mouseDist + 0.1) * vec3(0.7, 0.8, 1.0);

    // Vignette
    float vignette = 1.0 - length(uv) * 0.3;
    color *= vignette;

    // Background
    vec3 bg = vec3(0.01, 0.015, 0.03);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

// "Columna" from John Whitney's "Digital Harmony"
// Original algorithm by Paul Rother, ported from Processing

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

// Soft dot
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.2, d);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    float t = u_time * u_speed * 0.15;

    vec3 color = vec3(0.0);

    // Whitney's parameters
    int npoints = int(60.0 * u_density);
    float ilength = 1.6;
    float stepVal = t * (1.0 / 60.0) * u_harmonics;

    float xleft = -0.8;

    for (int point = 0; point < 120; point++) {
        if (point >= npoints) break;

        float fp = float(point);
        float np = float(npoints);

        // Horizontal position - spread across screen
        float x = xleft + ilength * fp / np;

        // Vertical position with modular wrapping
        float y = ilength * fp * stepVal;
        y = mod(y, ilength) - ilength * 0.5;

        vec2 dotPos = vec2(x, y);

        float dotSize = 0.018;
        float dot = dot_shape(uv, dotPos, dotSize);

        // Color gradient based on position
        vec3 dotColor = vec3(
            0.9,
            0.8 + 0.2 * sin(fp * 0.2 + t),
            0.7 + 0.3 * sin(fp * 0.1 + t * 0.5)
        );

        color += dot * dotColor * 0.9;
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

// Fractal Palette - adapted from Shadertoy
// Iterative UV fractal with cosine color palette

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);

    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution) / u_resolution.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);

    float t = u_time * u_speed;
    float iterations = 4.0 * u_harmonics;

    for (float i = 0.0; i < 8.0; i++) {
        if (i >= iterations) break;

        uv = fract(uv * (1.5 * u_density)) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        vec3 col = palette(length(uv0) + i * 0.4 + t * 0.4);

        d = sin(d * 8.0 + t) / 8.0;
        d = abs(d);

        d = pow(0.01 / d, 1.2);

        finalColor += col * d;
    }

    // Mouse interaction - slight distortion
    vec2 mouse = u_mouse / u_resolution - 0.5;
    float mouseDist = length(uv0 - mouse * 2.0);
    finalColor += palette(mouseDist + t * 0.2) * 0.02 / (mouseDist + 0.3);

    gl_FragColor = vec4(finalColor, 1.0);
}

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Distance from mouse position
    float dist = distance(uv, mouse);

    // Animated gradient influenced by mouse position
    float r = 0.5 + 0.5 * sin(t + uv.x * 3.0 * u_scale + dist * 5.0);
    float g = 0.5 + 0.5 * sin(t * 0.7 + uv.y * 3.0 * u_scale - dist * 3.0);
    float b = 0.5 + 0.5 * sin(t * 1.3 + (uv.x + uv.y) * 2.0 * u_scale);

    // Add a glow around the mouse
    float glow = 0.05 / (dist + 0.05);
    vec3 color = vec3(r, g, b) + glow * 0.3 * u_intensity;

    // Ripple effect
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uv, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

#extension GL_OES_standard_derivatives : enable
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_buffer;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec4 data = texture2D(u_buffer, uv);

    float a = data.r;
    float b = data.g;

    // Color based on chemical concentrations
    float t = u_time * u_speed;

    // Create color gradient based on B chemical
    vec3 color = vec3(0.0);

    // Background color (high A, low B)
    vec3 bgColor = vec3(0.02, 0.03, 0.08);

    // Pattern color (low A, high B)
    vec3 patternColor = vec3(
        0.5 + 0.3 * sin(t * 0.5),
        0.6 + 0.3 * sin(t * 0.5 + 2.094),
        0.9 + 0.1 * sin(t * 0.5 + 4.188)
    );

    // Edge/transition color
    vec3 edgeColor = vec3(1.0, 0.8, 0.5);

    // Mix colors based on B concentration
    color = mix(bgColor, patternColor, b * u_intensity);

    // Add edge highlighting
    float edge = abs(dFdx(b)) + abs(dFdy(b));
    edge = smoothstep(0.0, 0.1, edge * 10.0);
    color += edge * edgeColor * 0.5 * u_intensity;

    // Mouse glow
    vec2 mouse = u_mouse / u_resolution;
    float mouseDist = length(uv - mouse);
    color += 0.05 / (mouseDist + 0.1) * vec3(0.5, 0.7, 1.0);

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

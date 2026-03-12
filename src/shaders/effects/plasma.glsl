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

    // Classic plasma effect
    float freq = 10.0 * u_scale;
    float v1 = sin(uv.x * freq + t);
    float v2 = sin(freq * (uv.x * sin(t * 0.5) + uv.y * cos(t * 0.3)) + t);
    float v3 = sin(sqrt(freq * freq * ((uv.x - 0.5 + sin(t * 0.2)) * (uv.x - 0.5 + sin(t * 0.2)) + (uv.y - 0.5) * (uv.y - 0.5))) + t);
    float v4 = sin(sqrt(freq * freq * (uv.x * uv.x + uv.y * uv.y)) + t);

    float v = (v1 + v2 + v3 + v4) * 0.25;

    // Mouse influence
    float mouseDist = distance(uv, mouse);
    v += sin(mouseDist * 20.0 * u_scale - t * 3.0) * 0.3 * u_intensity * (1.0 - smoothstep(0.0, 0.4, mouseDist));

    vec3 color = vec3(
        sin(v * 3.14159 * u_intensity) * 0.5 + 0.5,
        sin(v * 3.14159 * u_intensity + 2.094) * 0.5 + 0.5,
        sin(v * 3.14159 * u_intensity + 4.188) * 0.5 + 0.5
    );

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

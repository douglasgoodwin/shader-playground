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

    // Display divergence as main pattern
    float div = data.z;

    // Create color from the flow field
    vec2 flow = data.xy;
    float flowMag = length(flow);

    // Base visualization - divergence
    float v = 0.5 + div * u_intensity;

    // Color based on flow direction and divergence
    vec3 color = vec3(v);

    // Add color variation based on flow
    float angle = atan(flow.y, flow.x);
    vec3 flowColor = vec3(
        0.5 + 0.5 * sin(angle + u_time * u_speed),
        0.5 + 0.5 * sin(angle + 2.094 + u_time * u_speed * 0.7),
        0.5 + 0.5 * sin(angle + 4.188 + u_time * u_speed * 1.3)
    );

    color = mix(color, flowColor * v * 2.0, flowMag * u_intensity);

    // Mouse glow
    vec2 mouse = u_mouse / u_resolution;
    float mouseDist = distance(uv, mouse);
    color += 0.1 / (mouseDist + 0.2) * vec3(0.2, 0.3, 0.5) * u_intensity;

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

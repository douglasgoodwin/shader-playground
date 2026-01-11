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
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float t = u_time * u_speed;

    // Tunnel/warp effect
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // Warp the space
    float warpAngle = angle + sin(radius * 5.0 * u_scale - t * 2.0) * 0.5 * u_intensity;
    float warpRadius = radius + sin(angle * 3.0 * u_scale + t) * 0.1 * u_intensity;

    // Mouse distortion
    float mouseDist = distance(uv, mouse);
    warpAngle += sin(mouseDist * 10.0 * u_scale) * 0.3 * u_intensity / (mouseDist + 0.3);

    // Create color bands
    float pattern = sin(warpAngle * 6.0 * u_scale + t) * sin(warpRadius * 15.0 * u_scale - t * 3.0);

    vec3 color = vec3(
        0.5 + 0.5 * sin(pattern * 2.0 * u_intensity + t),
        0.5 + 0.5 * sin(pattern * 2.0 * u_intensity + t + 2.094),
        0.5 + 0.5 * sin(pattern * 2.0 * u_intensity + t + 4.188)
    );

    // Darken center
    color *= smoothstep(0.0, 0.3, radius);

    // Ripple effect
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float rad = age * 0.5 * u_speed;
            float ring = abs(rippleDist - rad);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

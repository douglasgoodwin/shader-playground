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
    vec2 u = gl_FragCoord.xy / u_resolution.xy;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Warp x apart at the top
    float x = u.x - 0.1 * (u.x - 0.5) * u.y;

    // Warp away from center point (0.5, 0.25) - creates cylinder bulge
    float z = 0.3 + 0.6 * (x - smoothstep(0.0, 0.75 / (0.5 - abs(x - 0.5)),
                                          1.0 - abs(u.y - 0.25)));

    // Horizontal stripes that scroll
    float stripeCount = 7.0 * u_scale;
    float f = fract(x * stripeCount + t * 0.14);

    // The magic: creates the 3D cylinder illusion
    float ff = f;
    float zz = z;
    float pattern = mod(u.y / 0.1 - min(f / z, --ff / --zz), 0.4);
    float bw = pattern > 0.2 ? 1.0 : 0.0;

    // Base color
    vec3 color = vec3(bw) * u_intensity;

    // Add subtle color tint based on position
    color *= vec3(0.95, 0.95, 1.0);

    // Mouse glow
    float mouseDist = distance(u, mouse);
    color += 0.15 * u_intensity / (mouseDist + 0.3) * vec3(0.3, 0.5, 1.0);

    // Ripple effect
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(u, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

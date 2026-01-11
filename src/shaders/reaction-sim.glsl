precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_buffer;
uniform int u_frame;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform vec2 u_mouse;

// Sample neighboring pixels
vec4 tex(vec2 offset) {
    return texture2D(u_buffer, (gl_FragCoord.xy + offset) / u_resolution);
}

// Hash for random initialization
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;

    if (u_frame < 5) {
        // Initialize with noise pattern
        float n = hash(gl_FragCoord.xy + fract(u_time) * 100.0);
        float n2 = hash(gl_FragCoord.xy * 0.1 + 50.0);

        // Create some initial structure
        float dist = length(uv - 0.5);
        float ring = smoothstep(0.3, 0.25, dist) * smoothstep(0.15, 0.2, dist);

        gl_FragColor = vec4(
            n * 0.5 + ring * 0.5,
            n2 * 0.5,
            0.0,
            1.0
        );
        return;
    }

    // Gray-Scott reaction-diffusion parameters
    float feed = 0.037 * u_scale;
    float kill = 0.06 + 0.02 * u_intensity;
    float dA = 1.0;
    float dB = 0.5;
    float dt = 1.0 * u_speed;

    // Get current state
    vec4 current = tex(vec2(0.0));
    float a = current.r;
    float b = current.g;

    // Laplacian (9-point stencil)
    vec4 n  = tex(vec2( 0.0,  1.0));
    vec4 s  = tex(vec2( 0.0, -1.0));
    vec4 e  = tex(vec2( 1.0,  0.0));
    vec4 w  = tex(vec2(-1.0,  0.0));
    vec4 ne = tex(vec2( 1.0,  1.0));
    vec4 nw = tex(vec2(-1.0,  1.0));
    vec4 se = tex(vec2( 1.0, -1.0));
    vec4 sw = tex(vec2(-1.0, -1.0));

    float laplaceA = (n.r + s.r + e.r + w.r) * 0.2
                   + (ne.r + nw.r + se.r + sw.r) * 0.05
                   - a;
    float laplaceB = (n.g + s.g + e.g + w.g) * 0.2
                   + (ne.g + nw.g + se.g + sw.g) * 0.05
                   - b;

    // Reaction-diffusion equations
    float reaction = a * b * b;
    float newA = a + (dA * laplaceA - reaction + feed * (1.0 - a)) * dt;
    float newB = b + (dB * laplaceB + reaction - (kill + feed) * b) * dt;

    // Add chemical near mouse
    float mouseDist = length(uv - mouse);
    if (mouseDist < 0.02) {
        newB += 0.1;
    }

    // Clamp values
    newA = clamp(newA, 0.0, 1.0);
    newB = clamp(newB, 0.0, 1.0);

    gl_FragColor = vec4(newA, newB, 0.0, 1.0);
}

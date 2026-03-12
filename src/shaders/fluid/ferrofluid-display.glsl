precision highp float;

uniform sampler2D u_state;
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_metallic;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 px = 1.0 / u_resolution;

    vec4 state = texture2D(u_state, uv);
    float B = state.g;

    // Gradient of B for edge detection / normal approximation
    float bR = texture2D(u_state, uv + vec2(px.x, 0.0)).g;
    float bL = texture2D(u_state, uv - vec2(px.x, 0.0)).g;
    float bU = texture2D(u_state, uv + vec2(0.0, px.y)).g;
    float bD = texture2D(u_state, uv - vec2(0.0, px.y)).g;

    vec2 grad = vec2(bR - bL, bU - bD) / (2.0 * px);
    float gradMag = length(grad);

    // Ferrofluid base: dark iron color
    vec3 darkIron = vec3(0.02, 0.02, 0.03);
    vec3 lightIron = vec3(0.15, 0.15, 0.18);

    // Pattern shape from B concentration
    float pattern = smoothstep(0.1, 0.4, B);

    // Metallic highlight on edges (gradient-based fake specular)
    float edgeHighlight = smoothstep(0.5, 3.0, gradMag) * u_metallic;

    // Fake view-dependent iridescence from gradient angle
    float angle = atan(grad.y, grad.x);
    float iridescence = sin(angle * 2.0 + u_time * 0.5) * 0.5 + 0.5;

    // Oil-slick rainbow colors on the metallic highlights
    vec3 rainbow;
    rainbow.r = sin(iridescence * 6.28 + 0.0) * 0.5 + 0.5;
    rainbow.g = sin(iridescence * 6.28 + 2.09) * 0.5 + 0.5;
    rainbow.b = sin(iridescence * 6.28 + 4.19) * 0.5 + 0.5;
    rainbow = mix(vec3(0.7, 0.75, 0.8), rainbow, 0.4);

    // Compose: dark base + pattern raises slightly + edges get metallic highlights
    vec3 base = mix(darkIron, lightIron, pattern * 0.3);
    vec3 highlight = rainbow * edgeHighlight * 0.8;

    // Fresnel-like rim on strong edges
    float fresnel = pow(edgeHighlight, 2.0) * 0.5;
    vec3 rim = vec3(0.4, 0.45, 0.55) * fresnel;

    // Subtle ambient reflection on the "wet" surface
    float wet = pattern * 0.05;
    vec3 ambient = vec3(0.1, 0.12, 0.18) * wet;

    vec3 color = base + highlight + rim + ambient;

    gl_FragColor = vec4(color, 1.0);
}

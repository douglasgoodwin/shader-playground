precision mediump float;

uniform vec2 u_resolution;
uniform float u_scale;
uniform float u_smooth;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float valueNoise(vec2 p, float smoothness) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // At smoothness = 0, u is (0,0) so every pixel in a cell takes the
    // top-left corner's hash — pure blocks. At smoothness = 1, u is a
    // cubic smoothstep — full value noise.
    vec2 u = smoothstep(0.0, 1.0, f) * smoothness;

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float n = valueNoise(p * u_scale, u_smooth);
    gl_FragColor = vec4(vec3(n), 1.0);
}

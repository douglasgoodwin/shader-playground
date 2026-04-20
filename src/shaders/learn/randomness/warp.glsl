precision mediump float;

uniform vec2 u_resolution;
uniform float u_scale;
uniform float u_strength;
uniform float u_radius;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = smoothstep(0.0, 1.0, f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    // Perturb the sample coordinate with noise, giving the shape an organic wobble.
    vec2 offset = vec2(
        valueNoise(p * u_scale + vec2(0.0, 0.0)),
        valueNoise(p * u_scale + vec2(5.2, 1.3))
    ) - 0.5;

    vec2 q = p + offset * u_strength;
    float d = length(q);
    float mask = 1.0 - smoothstep(u_radius - 0.01, u_radius + 0.01, d);
    gl_FragColor = vec4(vec3(mask), 1.0);
}

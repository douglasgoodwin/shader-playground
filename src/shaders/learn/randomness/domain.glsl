precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_scale;
uniform float u_strength;
uniform float u_speed;

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

float fbm(vec2 p) {
    float amplitude = 1.0;
    float frequency = 1.0;
    float sum = 0.0;
    float total = 0.0;

    for (int i = 0; i < 5; i++) {
        sum += valueNoise(p * frequency) * amplitude;
        total += amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return sum / total;
}

// Inigo Quilez's domain-warp trick: feed the output of one FBM into the input
// of another, a few times. Tiny time offsets give a slow flowing motion.
void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 q0 = p * u_scale;
    float t = u_time * u_speed;

    vec2 q = vec2(
        fbm(q0 + vec2(0.0, t)),
        fbm(q0 + vec2(5.2, 1.3 - t))
    );

    vec2 r = vec2(
        fbm(q0 + q * u_strength + vec2(1.7, 9.2 + t)),
        fbm(q0 + q * u_strength + vec2(8.3 - t, 2.8))
    );

    float n = fbm(q0 + r * u_strength);
    gl_FragColor = vec4(vec3(n), 1.0);
}

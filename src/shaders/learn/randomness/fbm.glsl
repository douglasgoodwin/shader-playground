precision mediump float;

uniform vec2 u_resolution;
uniform float u_scale;
uniform float u_octaves;
uniform float u_persistence;

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

float fbm(vec2 p, float octaves, float persistence) {
    float amplitude = 1.0;
    float frequency = 1.0;
    float sum = 0.0;
    float total = 0.0;

    for (int i = 0; i < 6; i++) {
        if (float(i) >= octaves) break;
        sum += valueNoise(p * frequency) * amplitude;
        total += amplitude;
        frequency *= 2.0;
        amplitude *= persistence;
    }
    return sum / total;
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float n = fbm(p * u_scale, u_octaves, u_persistence);
    gl_FragColor = vec4(vec3(n), 1.0);
}

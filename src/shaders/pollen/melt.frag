// Bronze patina on a melting model — verdigris pools in drooping areas
uniform float u_time;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

float hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3d(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
        f.z);
}

float fbm(vec3 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise3d(p);
        p *= 2.0; a *= 0.5;
    }
    return v;
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.5, 1.0, 0.8));

    vec3 bronze = vec3(0.55, 0.35, 0.17);
    vec3 bronzeHi = vec3(0.85, 0.65, 0.35);

    // Patina accumulates where the melt pools — lower areas, upward-facing
    float upFacing = max(dot(n, vec3(0.0, 1.0, 0.0)), 0.0);
    float patinaN = fbm(vPosition * 0.12 + vec3(0.0, u_time * 0.02, 0.0));
    float patina = smoothstep(0.3, 0.7, upFacing * 0.6 + patinaN * 0.6);

    vec3 patinaColor = mix(vec3(0.15, 0.42, 0.35), vec3(0.35, 0.72, 0.58), patinaN);

    vec3 baseColor = mix(bronze, patinaColor, patina);

    float diff = max(dot(n, l), 0.0);
    float spec = pow(max(dot(reflect(-l, n), v), 0.0), 64.0);
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 4.0);

    vec3 color = baseColor * (0.2 + diff * 0.6);
    color += bronzeHi * spec * 0.6 * (1.0 - patina);
    color += vec3(0.3, 0.5, 0.4) * fresnel * 0.2;

    gl_FragColor = vec4(color, 1.0);
}

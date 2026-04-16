// Molten lava / magma with glowing cracks
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
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.3, 0.8, 0.5));

    float t = u_time * 0.15;

    // Slow-churning lava pattern
    float n1 = fbm(vPosition * 1.5 + vec3(t, t * 0.7, -t * 0.3));
    float n2 = fbm(vPosition * 3.0 - vec3(t * 0.5, -t, t * 0.8));

    // Cracks — sharp ridges in noise
    float crack = smoothstep(0.42, 0.48, n1) * smoothstep(0.58, 0.52, n1);
    crack += smoothstep(0.38, 0.44, n2) * smoothstep(0.54, 0.48, n2);
    crack = min(crack * 2.0, 1.0);

    // Temperature — hotter in cracks and low areas
    float temp = crack * 0.8 + n1 * 0.3;

    // Lava color ramp: black rock → deep red → orange → yellow-white
    vec3 color;
    if (temp < 0.3) {
        color = mix(vec3(0.05, 0.02, 0.02), vec3(0.4, 0.05, 0.0), temp / 0.3);
    } else if (temp < 0.6) {
        color = mix(vec3(0.4, 0.05, 0.0), vec3(1.0, 0.35, 0.0), (temp - 0.3) / 0.3);
    } else {
        color = mix(vec3(1.0, 0.35, 0.0), vec3(1.0, 0.85, 0.3), (temp - 0.6) / 0.4);
    }

    // Subtle surface shading for the cooled rock
    float diff = max(dot(n, l), 0.0);
    color *= 0.7 + diff * 0.3;

    // Emissive glow from cracks — doesn't need lighting
    color += vec3(1.0, 0.3, 0.05) * crack * 0.5;

    // Fresnel rim — faint heat haze glow
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 3.0);
    color += vec3(0.8, 0.2, 0.0) * fresnel * 0.2;

    gl_FragColor = vec4(color, 1.0);
}

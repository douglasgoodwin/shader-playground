// Melt — noise-driven downward dripping displacement
// Vertices slide down as if the model is melting, with noise breakup
uniform float u_time;
uniform float u_intensity;

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

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    // Height-dependent melt: top melts more
    float heightBias = smoothstep(-1.0, 1.5, position.y);

    // Noise breakup so it doesn't melt uniformly
    float n = noise3d(position * 3.0 + vec3(0.0, -u_time * 0.3, 0.0));
    float n2 = noise3d(position * 7.0 + vec3(u_time * 0.1, -u_time * 0.5, u_time * 0.2));

    // Drip: downward displacement
    float drip = heightBias * (n * 0.7 + n2 * 0.3);
    float dripAmount = drip * 0.3 * u_intensity;

    // Lateral spread — melting things bulge outward slightly
    vec3 outward = normalize(vec3(position.x, 0.0, position.z) + vec3(0.001));
    float spread = drip * heightBias * 0.05 * u_intensity;

    vec3 newPos = position;
    newPos.y -= dripAmount;
    newPos += outward * spread;

    // Slight normal-direction noise displacement for blobby surface
    float blobby = (n2 - 0.5) * 0.03 * u_intensity;
    newPos += normal * blobby;

    vec4 worldPos = modelMatrix * vec4(newPos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

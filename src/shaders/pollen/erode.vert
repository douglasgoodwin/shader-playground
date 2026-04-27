// Erode — noise-based inward collapse, as if the model is dissolving
// Vertices near noise threshold retract inward toward center
uniform float u_time;
uniform float u_intensity;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vErosion;

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
    for (int i = 0; i < 4; i++) {
        v += a * noise3d(p);
        p *= 2.0; a *= 0.5;
    }
    return v;
}

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    // Animated erosion field
    float t = u_time * 0.2;
    float erosionNoise = fbm(position * 2.0 + vec3(t, -t * 0.7, t * 0.3));

    // Erosion threshold sweeps through the model over time
    float threshold = sin(u_time * 0.3) * 0.3 + 0.5;
    float erosion = smoothstep(threshold - 0.15, threshold + 0.15, erosionNoise);

    vErosion = erosion;

    // Eroded vertices collapse inward along normal
    float collapse = erosion * 0.15 * u_intensity;
    vec3 newPos = position - normal * collapse;

    // Add jitter to eroding vertices
    float jitter = (noise3d(position * 20.0 + u_time) - 0.5) * erosion * 0.02 * u_intensity;
    newPos += normal * jitter;

    vec4 worldPos = modelMatrix * vec4(newPos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

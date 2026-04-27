// Amoeba Dance — audio-reactive multi-scale vertex displacement
// FFT bands map to spatial frequencies on the mesh:
//   bass     → large-scale inflation (the whole form breathes)
//   lowMid   → slow undulating waves across the surface
//   mid      → medium ripple displacement
//   highMid  → fine surface perturbation
//   treble   → micro noise jitter
// Overall energy modulates a time-varying organic wobble
uniform float u_time;
uniform float u_intensity;
uniform float u_bass;
uniform float u_lowMid;
uniform float u_mid;
uniform float u_highMid;
uniform float u_treble;
uniform float u_energy;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vDisplacement;

// Simple 3D hash for high-freq noise
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

    float t = u_time;
    vec3 pos = position;
    float r = length(pos);
    float disp = 0.0;

    // --- BASS: large-scale breathing ---
    // The whole form inflates/deflates with low frequency energy
    float breathPhase = sin(t * 0.8) * 0.3 + 0.7; // baseline pulse
    float bassDisp = u_bass * breathPhase * 0.25;
    disp += bassDisp;

    // --- LOW MID: slow undulating waves ---
    // Large wavelength sinusoidal displacement across the surface
    float wave1 = sin(pos.y * 2.0 + t * 1.5) * cos(pos.x * 1.5 - t * 0.8);
    float wave2 = sin(pos.z * 2.5 - t * 1.2) * cos(pos.y * 1.8 + t * 0.6);
    disp += u_lowMid * (wave1 + wave2) * 0.12;

    // --- MID: medium-frequency ripple ---
    // Concentric ripple from center + traveling waves
    float ripple = sin(r * 8.0 - t * 4.0) * 0.5;
    ripple += sin(pos.x * 6.0 + pos.z * 4.0 - t * 3.0) * 0.3;
    ripple += sin(pos.y * 7.0 - pos.x * 3.0 + t * 2.5) * 0.2;
    disp += u_mid * ripple * 0.08;

    // --- HIGH MID: fine surface perturbation ---
    float fine = noise3d(pos * 5.0 + t * 2.0) - 0.5;
    fine += (noise3d(pos * 9.0 - t * 1.5) - 0.5) * 0.5;
    disp += u_highMid * fine * 0.1;

    // --- TREBLE: micro noise jitter ---
    float jitter = (noise3d(pos * 20.0 + t * 8.0) - 0.5);
    disp += u_treble * jitter * 0.06;

    // --- Overall energy: organic wobble modulation ---
    float wobble = sin(pos.x * 3.0 + t * 2.0) *
                   sin(pos.y * 3.0 - t * 1.7) *
                   sin(pos.z * 3.0 + t * 1.3);
    disp += u_energy * wobble * 0.04;

    // Apply displacement along normal
    disp *= u_intensity;
    pos += normal * disp;

    vDisplacement = disp;

    vec4 worldPos = modelMatrix * vec4(pos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

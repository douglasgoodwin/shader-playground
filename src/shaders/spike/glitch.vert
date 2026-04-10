// Glitch — horizontal slice bands that shift and jitter
// Slices of the model slide sideways at different rates
uniform float u_time;
uniform float u_intensity;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    vec3 newPos = position;

    // Slice the model into horizontal bands
    float sliceFreq = 15.0;
    float sliceY = floor(position.y * sliceFreq) / sliceFreq;

    // Each slice gets a random phase and amplitude
    float sliceHash = hash(sliceY * 127.1);
    float sliceHash2 = hash(sliceY * 311.7);

    // Intermittent glitch: most slices are still, some are active
    float glitchTime = floor(u_time * 4.0); // changes 4x per second
    float isActive = step(0.7, hash(sliceY + glitchTime)); // 30% of slices glitch

    // Horizontal shift
    float shiftX = (sliceHash - 0.5) * 2.0 * isActive* u_intensity * 0.25;
    float shiftZ = (sliceHash2 - 0.5) * 2.0 * isActive* u_intensity * 0.15;

    // Occasional vertical gap — slices separate
    float gap = isActive* (sliceHash - 0.5) * u_intensity * 0.05;

    newPos.x += shiftX;
    newPos.z += shiftZ;
    newPos.y += gap;

    // Subtle continuous wobble on all vertices
    float wobble = sin(position.y * 30.0 + u_time * 8.0) * 0.003 * u_intensity;
    newPos.x += wobble;

    vec4 worldPos = modelMatrix * vec4(newPos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

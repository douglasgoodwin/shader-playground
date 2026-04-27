// Face-driven vertex displacement
// Facial expressions map to geometric deformations:
//   mouth open  → inflate outward from center
//   smile       → twist around Y axis
//   brow raise  → upward wave from top
//   eye blink   → squash vertically
//   pucker      → pinch inward toward center
//   cheek puff  → lateral bulge
//   jaw X       → shear sideways
uniform float u_time;
uniform float u_intensity;
uniform float u_mouthOpen;
uniform float u_smile;
uniform float u_browRaise;
uniform float u_eyeBlink;
uniform float u_pucker;
uniform float u_cheekPuff;
uniform float u_jawX;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vEnergy;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    vec3 pos = position;
    float r = length(pos);
    float y = pos.y;

    // --- Mouth open: inflate along normal, stronger near center ---
    float inflateMask = exp(-r * 0.8); // peaks at center
    float inflate = u_mouthOpen * 0.2 * inflateMask * u_intensity;
    pos += normal * inflate;

    // --- Smile: twist around Y axis, proportional to height ---
    float twistAngle = u_smile * y * 0.5 * u_intensity;
    float ct = cos(twistAngle);
    float st = sin(twistAngle);
    pos.xz = mat2(ct, -st, st, ct) * pos.xz;

    // --- Brow raise: upward displacement wave from the top ---
    float topBias = smoothstep(0.0, 1.5, y); // only upper portion
    float browLift = u_browRaise * topBias * 0.15 * u_intensity;
    pos.y += browLift;
    // Also fan outward slightly at top
    pos.xz += normalize(pos.xz + vec2(0.001)) * u_browRaise * topBias * 0.04 * u_intensity;

    // --- Eye blink: vertical squash ---
    float squash = 1.0 - u_eyeBlink * 0.2 * u_intensity;
    pos.y *= squash;
    // Conserve volume: expand laterally
    float expand = 1.0 + u_eyeBlink * 0.1 * u_intensity;
    pos.xz *= expand;

    // --- Pucker: pinch inward toward Y axis ---
    float pinch = 1.0 - u_pucker * 0.25 * u_intensity;
    pos.xz *= pinch;
    // Elongate vertically to compensate
    pos.y *= 1.0 + u_pucker * 0.12 * u_intensity;

    // --- Cheek puff: lateral bulge ---
    float puffMask = 1.0 - abs(y) * 0.5; // strongest at equator
    puffMask = max(puffMask, 0.0);
    float puff = u_cheekPuff * puffMask * 0.15 * u_intensity;
    pos.xz += normalize(pos.xz + vec2(0.001)) * puff;

    // --- Jaw X: horizontal shear ---
    pos.x += u_jawX * 0.15 * u_intensity;

    // --- Subtle time-based wobble modulated by overall facial energy ---
    float energy = u_mouthOpen + u_smile + u_browRaise + u_pucker + u_cheekPuff;
    float wobble = sin(r * 8.0 - u_time * 3.0) * energy * 0.008 * u_intensity;
    pos += normal * wobble;

    vEnergy = energy;

    vec4 worldPos = modelMatrix * vec4(pos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

// Breathing pulse — sinusoidal expansion/contraction along normals
// with a traveling wave so different parts pulse at different phases
uniform float u_time;
uniform float u_intensity;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    // Phase offset based on height + radial distance for organic feel
    float phase = position.y * 2.0 + length(position.xz) * 1.5;

    // Multi-frequency breathing
    float breath = sin(u_time * 1.2 + phase) * 0.6
                 + sin(u_time * 2.7 - phase * 0.5) * 0.25
                 + sin(u_time * 0.4 + phase * 2.0) * 0.15;

    // Displacement along normal, scaled by intensity
    float displacement = breath * 0.08 * u_intensity;
    vec3 newPos = position + normal * displacement;

    vec4 worldPos = modelMatrix * vec4(newPos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

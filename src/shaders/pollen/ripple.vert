// Ripple — concentric waves emanating from a point, traveling across the surface
uniform float u_time;
uniform float u_intensity;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;

    // Distance from center of model
    float dist = length(position);

    // Multiple ripple sources at different speeds and phases
    float ripple1 = sin(dist * 12.0 - u_time * 3.0) * exp(-dist * 0.5);
    float ripple2 = sin(dist * 8.0 - u_time * 2.0 + 1.5) * exp(-dist * 0.3);

    // Traveling wave along Y axis
    float wave = sin(position.y * 6.0 - u_time * 2.5) * 0.5;

    float displacement = (ripple1 * 0.5 + ripple2 * 0.3 + wave * 0.2) * 0.06 * u_intensity;

    vec3 newPos = position + normal * displacement;

    vec4 worldPos = modelMatrix * vec4(newPos, 1.0);
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

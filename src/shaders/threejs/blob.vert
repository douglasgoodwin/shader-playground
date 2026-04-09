uniform float u_time;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;

void main() {
    vUv = uv;
    vNormal = normal;
    vPosition = position;

    // Displace vertices along normals
    float displacement = sin(position.x * 3.0 + u_time) *
                         sin(position.y * 3.0 + u_time * 0.8) *
                         sin(position.z * 3.0 + u_time * 1.2) * 0.15;
    vec3 newPosition = position + normal * displacement;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
}

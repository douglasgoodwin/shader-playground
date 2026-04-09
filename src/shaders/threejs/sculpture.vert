uniform float u_time;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vUv = uv;
    vPosition = position;

    // Apply instance transform when using InstancedMesh
    #ifdef USE_INSTANCING
        vec4 localPos = instanceMatrix * vec4(position, 1.0);
        vec3 transformedNormal = mat3(instanceMatrix) * normal;
    #else
        vec4 localPos = vec4(position, 1.0);
        vec3 transformedNormal = normal;
    #endif

    vNormal = normalize(normalMatrix * transformedNormal);

    vec4 worldPos = modelMatrix * localPos;
    vWorldPosition = worldPos.xyz;
    vViewDir = normalize(cameraPosition - worldPos.xyz);

    gl_Position = projectionMatrix * viewMatrix * worldPos;
}

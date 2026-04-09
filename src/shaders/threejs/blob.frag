uniform float u_time;
uniform vec2 u_resolution;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;

void main() {
    // Fresnel-like rim lighting
    vec3 viewDir = normalize(cameraPosition - vPosition);
    float fresnel = pow(1.0 - abs(dot(viewDir, vNormal)), 2.0);

    // Animated color palette
    vec3 col1 = vec3(0.2, 0.5, 0.9);
    vec3 col2 = vec3(0.9, 0.3, 0.5);
    vec3 color = mix(col1, col2, fresnel + sin(u_time * 0.5) * 0.3);

    // Add rim glow
    color += vec3(0.4, 0.6, 1.0) * fresnel * 0.8;

    gl_FragColor = vec4(color, 1.0);
}

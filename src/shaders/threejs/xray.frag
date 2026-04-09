uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);

    // Core x-ray: edge glow based on Fresnel
    float fresnel = pow(1.0 - abs(dot(v, n)), 1.8);

    // Inner structure lines — cross-section bands
    float slice = sin(vPosition.x * 12.0 + u_time * 0.5) *
                  sin(vPosition.y * 12.0 - u_time * 0.3) *
                  sin(vPosition.z * 12.0 + u_time * 0.7);
    float innerLine = smoothstep(0.85, 0.95, slice);

    // Subtle pulsing
    float pulse = 0.9 + 0.1 * sin(u_time * 2.0);

    // Cool blue-white x-ray tint
    vec3 edgeColor = vec3(0.6, 0.85, 1.0);
    vec3 innerColor = vec3(0.3, 0.5, 0.7);
    vec3 coreColor = vec3(0.05, 0.08, 0.15);

    vec3 color = mix(coreColor, edgeColor, fresnel * pulse);
    color += innerColor * innerLine * 0.3;

    // Bright silhouette rim
    color += vec3(0.7, 0.9, 1.0) * pow(fresnel, 5.0) * 0.8;

    float alpha = fresnel * 0.7 + 0.1 + innerLine * 0.15;

    gl_FragColor = vec4(color, alpha);
}

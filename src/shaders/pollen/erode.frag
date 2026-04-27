// X-ray look on eroding model — eroded areas glow hot at the boundary
uniform float u_time;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vErosion;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);

    float fresnel = pow(1.0 - abs(dot(v, n)), 1.8);

    // Inner structure lines
    float slice = sin(vPosition.x * 12.0 + u_time * 0.5) *
                  sin(vPosition.y * 12.0 - u_time * 0.3) *
                  sin(vPosition.z * 12.0 + u_time * 0.7);
    float innerLine = smoothstep(0.85, 0.95, slice);

    vec3 edgeColor = vec3(0.6, 0.85, 1.0);
    vec3 coreColor = vec3(0.05, 0.08, 0.15);

    vec3 color = mix(coreColor, edgeColor, fresnel);
    color += vec3(0.3, 0.5, 0.7) * innerLine * 0.3;

    // Erosion boundary glow — hot orange/red at the dissolving edge
    float boundaryGlow = smoothstep(0.3, 0.5, vErosion) * smoothstep(0.8, 0.5, vErosion);
    vec3 hotColor = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.8, 0.2), boundaryGlow);
    color += hotColor * boundaryGlow * 2.0;

    // Eroded areas become more transparent
    float alpha = fresnel * 0.7 + 0.1 + innerLine * 0.15;
    alpha *= mix(1.0, 0.2, vErosion);

    // Bright rim
    color += vec3(0.7, 0.9, 1.0) * pow(fresnel, 5.0) * 0.8;

    gl_FragColor = vec4(color, alpha);
}

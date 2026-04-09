uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);

    float fresnel = pow(1.0 - abs(dot(v, n)), 2.5);

    // Scan lines
    float scanSpeed = u_time * 3.0;
    float scanFreq = 80.0;
    float scan = sin(vWorldPosition.y * scanFreq - scanSpeed) * 0.5 + 0.5;
    scan = smoothstep(0.3, 0.7, scan);

    // Coarse flicker bands
    float band = sin(vWorldPosition.y * 8.0 - u_time * 1.5) * 0.5 + 0.5;
    band = smoothstep(0.4, 0.6, band);

    // Global flicker
    float flicker = 0.85 + 0.15 * sin(u_time * 15.7) * sin(u_time * 23.3);

    // Color: cyan hologram tint with chromatic fringe
    vec3 holoColor = vec3(0.1, 0.7, 1.0);
    vec3 fringe = vec3(0.0, 0.3, 0.0) * sin(vWorldPosition.y * 40.0 + u_time) * fresnel;

    float alpha = fresnel * 0.6 + scan * 0.15 + band * 0.1 + 0.08;
    alpha *= flicker;

    vec3 color = holoColor * (fresnel * 1.5 + 0.2);
    color += fringe;
    color *= flicker;
    color += vec3(0.3, 0.8, 1.0) * scan * 0.15;

    // Hot edge glow
    color += vec3(0.2, 0.9, 1.0) * pow(fresnel, 4.0) * 1.2;

    gl_FragColor = vec4(color, alpha);
}

// Hologram glitch — scan lines, chromatic fringe, flicker
uniform float u_time;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);

    float fresnel = pow(1.0 - abs(dot(v, n)), 2.5);

    // Scan lines
    float scan = sin(vWorldPosition.y * 80.0 - u_time * 3.0) * 0.5 + 0.5;
    scan = smoothstep(0.3, 0.7, scan);

    // Glitch bands — sync with vertex glitch timing
    float glitchTime = floor(u_time * 4.0);
    float sliceY = floor(vPosition.y * 15.0) / 15.0;
    float isActive = step(0.7, hash(sliceY + glitchTime));

    // Chromatic split in glitched bands
    float chromaShift = isActive* 0.04;
    vec3 holoR = vec3(1.0, 0.1, 0.2) * (fresnel + 0.15);
    vec3 holoG = vec3(0.1, 1.0, 0.3) * (fresnel + 0.15);
    vec3 holoB = vec3(0.1, 0.3, 1.0) * (fresnel + 0.15);

    // Shift channels based on normal direction for depth
    float rShift = dot(n, vec3(1.0, 0.0, 0.0)) * chromaShift;
    float bShift = dot(n, vec3(-1.0, 0.0, 0.0)) * chromaShift;

    vec3 color = mix(
        vec3(0.1, 0.7, 1.0) * (fresnel * 1.5 + 0.2), // base hologram
        holoR * 0.5 + holoG * 0.3 + holoB * 0.5,      // chromatic split
        isActive* 0.6
    );

    // Flicker
    float flicker = 0.85 + 0.15 * sin(u_time * 15.7) * sin(u_time * 23.3);
    color *= flicker;

    // Scan line overlay
    color += vec3(0.3, 0.8, 1.0) * scan * 0.15;

    // Hot edge glow
    color += vec3(0.2, 0.9, 1.0) * pow(fresnel, 4.0) * 1.2;

    // Glitched bands get extra brightness
    color += vec3(0.5, 0.8, 1.0) * isActive* 0.3;

    float alpha = fresnel * 0.6 + scan * 0.15 + 0.15;
    alpha *= flicker;

    gl_FragColor = vec4(color, alpha);
}

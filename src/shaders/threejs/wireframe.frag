// Glowing wireframe / grid overlay on dark surface
uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);

    // Grid lines in object space — three axis-aligned grids
    float spacing = 0.25;
    vec3 grid = abs(fract(vPosition / spacing + 0.5) - 0.5);
    float lineX = smoothstep(0.04, 0.01, grid.x);
    float lineY = smoothstep(0.04, 0.01, grid.y);
    float lineZ = smoothstep(0.04, 0.01, grid.z);
    float line = max(lineX, max(lineY, lineZ));

    // Animated pulse traveling along Y
    float pulse = smoothstep(0.3, 0.0, abs(fract(vPosition.y * 0.5 - u_time * 0.2) - 0.5));
    float glow = line * (0.6 + pulse * 0.4);

    // Wire color — cool cyan with warm highlights at pulse
    vec3 wireColor = mix(vec3(0.1, 0.6, 0.9), vec3(0.3, 0.9, 1.0), pulse);

    // Dark base surface with subtle shading
    float diff = max(dot(n, normalize(vec3(0.5, 1.0, 0.8))), 0.0);
    vec3 base = vec3(0.02, 0.03, 0.05) * (0.5 + diff * 0.5);

    // Fresnel edge glow
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 3.0);

    vec3 color = mix(base, wireColor, glow);
    color += wireColor * fresnel * 0.15;

    gl_FragColor = vec4(color, 1.0);
}

// Amoeba Dance — color driven by audio frequency bands
// Bass warms the core, mid drives iridescence, treble sparks the edges
uniform float u_time;
uniform float u_bass;
uniform float u_lowMid;
uniform float u_mid;
uniform float u_highMid;
uniform float u_treble;
uniform float u_energy;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vDisplacement;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.3, 0.8, 0.5));

    float diff = max(dot(n, l), 0.0);
    float spec = pow(max(dot(reflect(-l, n), v), 0.0), 48.0);
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 3.0);

    // Deep core color — shifts warm with bass
    vec3 deepColor = vec3(0.05, 0.03, 0.08);
    deepColor += vec3(0.35, 0.08, 0.02) * u_bass; // bass → deep red/amber glow

    // Mid-surface: iridescent palette driven by mid frequencies
    float iriPhase = vDisplacement * 8.0 + u_time * 0.15 + u_mid * 2.0;
    vec3 iriColor = palette(iriPhase);

    // Mix deep and iri based on displacement — protruding areas show more color
    float dispNorm = clamp(abs(vDisplacement) * 6.0, 0.0, 1.0);
    vec3 surfaceColor = mix(deepColor, iriColor * 0.6, dispNorm);

    // Low-mid adds a warm organic glow
    surfaceColor += vec3(0.12, 0.06, 0.02) * u_lowMid;

    // Lighting
    vec3 color = surfaceColor * (0.3 + diff * 0.5);
    color += vec3(0.8, 0.9, 1.0) * spec * (0.2 + u_highMid * 0.4);

    // Rim glow — intensity tracks energy, hue shifts with treble
    vec3 rimBase = mix(
        vec3(0.15, 0.2, 0.5),  // quiet: cool blue rim
        vec3(0.5, 0.3, 0.8),   // loud: violet-magenta rim
        clamp(u_energy * 2.0, 0.0, 1.0)
    );
    color += rimBase * fresnel * (0.5 + u_energy * 1.5);

    // Treble sparkle at silhouette edges
    float sparkle = fresnel * u_treble * 3.0;
    color += vec3(0.8, 0.9, 1.0) * sparkle;

    // High-mid adds subtle green-cyan bioluminescence
    float bioGlow = max(dot(n, vec3(0.0, -1.0, 0.0)), 0.0); // underside
    color += vec3(0.0, 0.15, 0.12) * u_highMid * bioGlow * 2.0;

    // Overall brightness pulse with energy
    color *= 0.8 + u_energy * 0.4;

    // Subsurface scattering hint — bass makes it feel alive
    float sss = pow(max(dot(v, -l + n * 0.4), 0.0), 3.0);
    color += vec3(0.4, 0.1, 0.05) * sss * u_bass * 0.5;

    gl_FragColor = vec4(color, 1.0);
}

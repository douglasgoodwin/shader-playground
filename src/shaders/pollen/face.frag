// Face-driven coloring — facial energy drives color warmth and rim glow
uniform float u_time;
uniform float u_mouthOpen;
uniform float u_smile;
uniform float u_browRaise;
uniform float u_eyeBlink;
uniform float u_pucker;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying float vEnergy;

vec3 palette(float t) {
    // warm-to-cool palette driven by expression
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.10, 0.20);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.4, 0.8, 0.6));

    float diff = max(dot(n, l), 0.0);
    float spec = pow(max(dot(reflect(-l, n), v), 0.0), 32.0);
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 3.0);

    // Base color shifts with expression energy
    float energy = vEnergy * 0.2;
    vec3 cool = vec3(0.15, 0.20, 0.35); // resting state
    vec3 warm = vec3(0.50, 0.25, 0.15); // high expression

    vec3 baseColor = mix(cool, warm, clamp(energy, 0.0, 1.0));

    // Mouth open adds red pulse
    baseColor += vec3(0.3, 0.05, 0.0) * u_mouthOpen;

    // Smile shifts toward golden
    baseColor += vec3(0.15, 0.12, 0.0) * u_smile;

    // Brow raise adds cool blue uplighting
    float topFace = max(dot(n, vec3(0.0, 1.0, 0.0)), 0.0);
    baseColor += vec3(0.0, 0.1, 0.25) * u_browRaise * topFace;

    // Pucker → concentrated, saturated
    baseColor = mix(baseColor, baseColor * 1.4, u_pucker * 0.3);

    // Lighting
    vec3 color = baseColor * (0.3 + diff * 0.5) + spec * 0.25;

    // Rim glow — intensifies with expression
    vec3 rimColor = palette(energy + u_time * 0.05);
    color += rimColor * fresnel * (0.3 + energy * 0.5);

    // Blink dims everything briefly
    color *= 1.0 - u_eyeBlink * 0.4;

    // Subtle iridescent edge
    color += vec3(0.2, 0.3, 0.5) * fresnel * 0.2;

    gl_FragColor = vec4(color, 1.0);
}

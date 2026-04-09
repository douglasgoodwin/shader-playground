uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.80, 0.90, 0.30);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.4, 0.8, 0.6));

    // Height-based contour lines
    float spacing = 0.35;
    float y = vWorldPosition.y + u_time * 0.15;
    float contour = abs(fract(y / spacing) - 0.5) * 2.0;
    float line = 1.0 - smoothstep(0.0, 0.06, contour);

    // Thinner secondary lines
    float y2 = vWorldPosition.y + u_time * 0.15;
    float contour2 = abs(fract(y2 / (spacing * 0.25)) - 0.5) * 2.0;
    float line2 = 1.0 - smoothstep(0.0, 0.04, contour2);

    // Background: subtle shaded surface
    float diff = max(dot(n, l), 0.0);
    vec3 bgColor = vec3(0.95, 0.93, 0.88) * (0.3 + diff * 0.4);

    // Contour colors
    float colorT = vWorldPosition.y * 0.15 + u_time * 0.05;
    vec3 lineColor = palette(colorT) * 0.85;
    vec3 lineColor2 = palette(colorT + 0.3) * 0.45;

    vec3 color = bgColor;
    color = mix(color, lineColor2, line2 * 0.5);
    color = mix(color, lineColor, line);

    // Edge darkening
    float edge = pow(1.0 - abs(dot(v, n)), 2.0);
    color = mix(color, vec3(0.15, 0.12, 0.1), edge * 0.6);

    gl_FragColor = vec4(color, 1.0);
}

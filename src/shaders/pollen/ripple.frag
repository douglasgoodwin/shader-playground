// Contour lines on a rippling model — height bands shift with the deformation
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

    // Contour lines based on world position (moves with deformation)
    float spacing = 0.3;
    float y = vWorldPosition.y + u_time * 0.1;
    float contour = abs(fract(y / spacing) - 0.5) * 2.0;
    float line = 1.0 - smoothstep(0.0, 0.06, contour);

    // Radial contours too — concentric rings
    float r = length(vWorldPosition.xz);
    float rContour = abs(fract(r / spacing) - 0.5) * 2.0;
    float rLine = 1.0 - smoothstep(0.0, 0.05, rContour);

    float diff = max(dot(n, l), 0.0);
    vec3 bgColor = vec3(0.95, 0.93, 0.88) * (0.3 + diff * 0.4);

    float colorT = vWorldPosition.y * 0.2 + u_time * 0.05;
    vec3 lineColor = palette(colorT) * 0.85;
    vec3 rLineColor = palette(colorT + 0.5) * 0.6;

    vec3 color = bgColor;
    color = mix(color, rLineColor, rLine * 0.4);
    color = mix(color, lineColor, line);

    // Edge darkening
    float edge = pow(1.0 - abs(dot(v, n)), 2.0);
    color = mix(color, vec3(0.15, 0.12, 0.1), edge * 0.6);

    gl_FragColor = vec4(color, 1.0);
}

uniform float u_time;
uniform vec2 u_resolution;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;
varying vec2 vUv;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.5, 0.8, 0.6));

    // Compute light intensity
    float diff = max(dot(n, l), 0.0);
    float ambient = 0.15;
    float intensity = ambient + diff * 0.85;

    // Screen-space halftone dots
    vec2 fragCoord = gl_FragCoord.xy;
    float dotSpacing = 6.0;
    vec2 cell = floor(fragCoord / dotSpacing);
    vec2 cellCenter = (cell + 0.5) * dotSpacing;
    float dist = length(fragCoord - cellCenter) / (dotSpacing * 0.5);

    // Dot size based on darkness (darker = bigger dots)
    float dotSize = (1.0 - intensity) * 1.1;
    float dot = 1.0 - smoothstep(dotSize - 0.15, dotSize + 0.15, dist);

    // Ink color — warm black
    vec3 inkColor = vec3(0.12, 0.10, 0.08);
    vec3 paperColor = vec3(0.95, 0.92, 0.87);

    vec3 color = mix(paperColor, inkColor, dot);

    // Subtle edge outline
    float edge = pow(1.0 - abs(dot(v, n)), 3.0);
    float edgeLine = smoothstep(0.6, 0.8, edge);
    color = mix(color, inkColor, edgeLine * 0.8);

    gl_FragColor = vec4(color, 1.0);
}

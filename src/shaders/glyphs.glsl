precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265358979

// SDF primitives

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdCross(vec2 p, float size, float thick) {
    vec2 q = abs(p);
    float d = min(
        max(q.x - thick, q.y - size),
        max(q.x - size, q.y - thick)
    );
    return d;
}

float sdTriangle(vec2 p, float r) {
    p.y += r * 0.15;
    float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

float sdDiamond(vec2 p, float size) {
    vec2 q = abs(p);
    float d = (q.x + q.y - size) * 0.7071;
    return d;
}

float sdStar(vec2 p, float r) {
    float a = atan(p.y, p.x) + PI / 2.0;
    float seg = PI * 2.0 / 5.0;
    a = abs(mod(a, seg) - seg * 0.5);
    float d = length(p);
    float inner = r * 0.4;
    float shape = d - mix(inner, r, pow(cos(a * 5.0 / PI), 3.0));
    return shape;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Grid
    float gridSize = floor(4.0 * u_scale + 0.5);
    float aspect = u_resolution.x / u_resolution.y;
    vec2 st = uv * vec2(gridSize * aspect, gridSize);
    vec2 cellId = floor(st);
    vec2 cellUv = fract(st) - 0.5;

    // Per-cell phase offset based on position
    float cellPhase = (cellId.x + cellId.y * 3.17) * 0.7;

    // Mouse distance in grid space for local influence
    vec2 mouseGrid = mouse * vec2(gridSize * aspect, gridSize);
    float mouseDist = distance(cellId + 0.5, mouseGrid);
    float mouseBoost = 0.8 / (mouseDist + 1.0);

    // Morph cycle: 5 shapes, smoothly interpolating
    float morphSpeed = (0.4 + mouseBoost) * u_speed;
    float cycle = mod(t * morphSpeed + cellPhase, 5.0);
    float shapeIdx = floor(cycle);
    float blend = fract(cycle);

    // Smooth blend curve
    blend = blend * blend * (3.0 - 2.0 * blend);

    // Evaluate adjacent shapes and mix
    float symbolSize = 0.32 * u_intensity;

    float d1, d2;

    // Shape A
    float idxA = mod(shapeIdx, 5.0);
    if (idxA < 0.5) d1 = sdCircle(cellUv, symbolSize);
    else if (idxA < 1.5) d1 = sdCross(cellUv, symbolSize, symbolSize * 0.25);
    else if (idxA < 2.5) d1 = sdTriangle(cellUv, symbolSize);
    else if (idxA < 3.5) d1 = sdDiamond(cellUv, symbolSize);
    else d1 = sdStar(cellUv, symbolSize);

    // Shape B
    float idxB = mod(shapeIdx + 1.0, 5.0);
    if (idxB < 0.5) d2 = sdCircle(cellUv, symbolSize);
    else if (idxB < 1.5) d2 = sdCross(cellUv, symbolSize, symbolSize * 0.25);
    else if (idxB < 2.5) d2 = sdTriangle(cellUv, symbolSize);
    else if (idxB < 3.5) d2 = sdDiamond(cellUv, symbolSize);
    else d2 = sdStar(cellUv, symbolSize);

    float d = mix(d1, d2, blend);

    // Color from morph phase
    float hue = cycle / 5.0 + cellPhase * 0.1;
    vec3 shapeColor = vec3(
        0.5 + 0.5 * sin(hue * PI * 2.0),
        0.5 + 0.5 * sin(hue * PI * 2.0 + PI * 2.0 / 3.0),
        0.5 + 0.5 * sin(hue * PI * 2.0 + PI * 4.0 / 3.0)
    ) * u_intensity;

    // Render
    vec3 bg = vec3(0.06, 0.06, 0.1);
    float fill = smoothstep(0.01, -0.01, d);
    float edge = smoothstep(0.02, 0.005, abs(d));
    vec3 edgeColor = shapeColor * 1.4;
    vec3 fillColor = shapeColor * 0.7;

    vec3 color = bg;
    color = mix(color, fillColor, fill);
    color = mix(color, edgeColor, edge * 0.6);

    // Mouse glow
    float mouseGlow = 0.15 / (distance(uv, mouse) + 0.15);
    color += mouseGlow * 0.1 * shapeColor;

    // Ripple effect
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;
        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uv, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

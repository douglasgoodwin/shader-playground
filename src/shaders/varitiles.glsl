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

// Hash functions
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return vec2(
        fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453),
        fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453)
    );
}

// Rotate a point
vec2 rot(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// SDF shapes
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdBox(vec2 p, vec2 size) {
    vec2 d = abs(p) - size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdTriangle(vec2 p, float r) {
    float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

float sdHex(vec2 p, float r) {
    vec2 q = abs(p);
    float d = max(q.x * 0.866 + q.y * 0.5, q.y) - r;
    return d;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Grid setup
    float gridSize = floor(6.0 * u_scale + 0.5);
    float aspect = u_resolution.x / u_resolution.y;
    vec2 st = uv * vec2(gridSize * aspect, gridSize);
    vec2 cellId = floor(st);
    vec2 cellUv = fract(st) - 0.5;

    // Per-cell random values
    float r0 = hash(cellId);
    float r1 = hash(cellId + 100.0);
    float r2 = hash(cellId + 200.0);
    vec2 r3 = hash2(cellId + 300.0);

    // Shape selection (4 shapes)
    float shapeType = floor(r0 * 4.0);

    // Per-cell rotation (slow animated spin + random offset)
    float rotation = r1 * PI * 2.0 + t * (0.2 + r2 * 0.3);

    // Scale pulsing
    float scaleBase = 0.28 + r2 * 0.1;
    float scalePulse = scaleBase + sin(t * (0.5 + r1) + r0 * PI * 2.0) * 0.05;
    float shapeSize = scalePulse * u_intensity;

    // Mouse disturbance — distance in grid coords
    vec2 mouseGrid = mouse * vec2(gridSize * aspect, gridSize);
    float mouseDist = distance(cellId + 0.5, mouseGrid);
    float mouseWave = sin(mouseDist * 2.0 - t * 3.0) * 0.5 + 0.5;
    float mouseInfluence = 1.0 / (mouseDist * 0.5 + 1.0);

    // Apply mouse disturbance to rotation and scale
    rotation += mouseInfluence * mouseWave * 1.5;
    shapeSize += mouseInfluence * 0.05;

    // Rotate cell UV
    vec2 ruv = rot(cellUv, rotation);

    // Evaluate chosen shape
    float d;
    if (shapeType < 0.5) {
        d = sdCircle(ruv, shapeSize);
    } else if (shapeType < 1.5) {
        d = sdBox(ruv, vec2(shapeSize * 0.8));
    } else if (shapeType < 2.5) {
        d = sdTriangle(ruv, shapeSize);
    } else {
        d = sdHex(ruv, shapeSize);
    }

    // Color: hue from cell position + random offset, animated
    float hue = r0 + (cellId.x + cellId.y) * 0.05 + t * 0.1;
    vec3 shapeColor = vec3(
        0.5 + 0.45 * sin(hue * PI * 2.0),
        0.5 + 0.45 * sin(hue * PI * 2.0 + 2.09),
        0.5 + 0.45 * sin(hue * PI * 2.0 + 4.19)
    ) * u_intensity;

    // Neighbor influence: blend hue slightly toward neighbors
    float neighborHue = hash(cellId + vec2(1.0, 0.0)) + hash(cellId + vec2(0.0, 1.0));
    neighborHue *= 0.5;
    shapeColor = mix(shapeColor, vec3(
        0.5 + 0.45 * sin(neighborHue * PI * 2.0 + t * 0.15),
        0.5 + 0.45 * sin(neighborHue * PI * 2.0 + 2.09),
        0.5 + 0.45 * sin(neighborHue * PI * 2.0 + 4.19)
    ) * u_intensity, 0.2);

    // Background per cell (subtle variation)
    vec3 bg = vec3(0.05, 0.05, 0.08) + r3.x * 0.03;

    // Render shape with soft edge
    float fill = smoothstep(0.01, -0.01, d);
    float outline = smoothstep(0.02, 0.005, abs(d));

    vec3 color = bg;
    color = mix(color, shapeColor * 0.6, fill);
    color = mix(color, shapeColor * 1.2, outline * 0.5);

    // Subtle grid lines
    vec2 grid = abs(fract(st) - 0.5);
    float gridLine = smoothstep(0.48, 0.5, max(grid.x, grid.y));
    color = mix(color, vec3(0.12, 0.12, 0.18), gridLine * 0.4);

    // Mouse glow
    float mouseGlow = 0.12 / (distance(uv, mouse) + 0.12);
    color += mouseGlow * 0.08 * shapeColor;

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

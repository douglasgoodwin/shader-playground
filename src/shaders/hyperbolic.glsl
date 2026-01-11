precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265359

// Complex number operations
vec2 cMul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 cDiv(vec2 a, vec2 b) {
    float d = dot(b, b);
    return vec2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / d;
}

vec2 cConj(vec2 z) {
    return vec2(z.x, -z.y);
}

// Möbius transformation for hyperbolic translation
vec2 mobius(vec2 z, vec2 c) {
    return cDiv(z - c, vec2(1.0, 0.0) - cMul(cConj(c), z));
}

// Hyperbolic distance from origin
float hypDist(vec2 z) {
    float r = length(z);
    if (r >= 1.0) return 100.0;
    return log((1.0 + r) / (1.0 - r));
}

// Reflect across a hyperbolic geodesic
vec2 hypReflect(vec2 z, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    vec2 n = vec2(c, s);
    // Reflect in the line through origin at given angle
    float d = dot(z, n);
    return 2.0 * d * n - z;
}

// Get the tile index for coloring
vec3 hyperbolicTile(vec2 z) {
    float t = u_time * u_speed * 0.3;

    // Number of sides for the polygon (try 3-7)
    float p = 4.0; // Square-ish
    float q = 6.0; // 6 meeting at each vertex

    // Adjust for scale
    float sc = u_scale;
    z *= sc;

    // Apply mouse-based Möbius transformation (moves the view)
    vec2 mouse = (u_mouse / u_resolution - 0.5) * 0.8;
    z = mobius(z, mouse);

    float angle = PI / p;
    float angle2 = PI / q;

    // Iteratively reflect to find fundamental domain
    float colorIndex = 0.0;
    vec2 cellId = vec2(0.0);

    for (int i = 0; i < 30; i++) {
        bool reflected = false;

        // Get angle of point
        float a = atan(z.y, z.x);

        // Reflect to first sector
        float sector = floor(a / (2.0 * angle) + 0.5);
        if (abs(sector) > 0.0) {
            z = hypReflect(z, sector * 2.0 * angle);
            colorIndex += sector;
            reflected = true;
        }

        // Reflect across the circular arc (geodesic)
        // The geodesic for {p,q} tiling
        float geodesicRadius = 1.0 / sin(angle);
        vec2 geodesicCenter = vec2(1.0 / tan(angle), 0.0);

        vec2 toCenter = z - geodesicCenter;
        float dist = length(toCenter);

        if (dist < geodesicRadius) {
            // Inversion in the circle
            z = geodesicCenter + toCenter * (geodesicRadius * geodesicRadius) / (dist * dist);
            colorIndex += 1.0;
            cellId.x += 1.0;
            reflected = true;
        }

        if (!reflected) break;
    }

    // Create pattern within fundamental domain
    float r = length(z);
    float a = atan(z.y, z.x);

    // Edge detection for the tile boundaries
    float edge = 0.0;

    // Edge along the straight sides
    float straightEdge = abs(abs(a) - angle);
    edge = max(edge, smoothstep(0.03, 0.01, straightEdge));

    // Edge along the circular arc
    vec2 geodesicCenter = vec2(1.0 / tan(angle), 0.0);
    float geodesicRadius = 1.0 / sin(angle);
    float arcDist = abs(length(z - geodesicCenter) - geodesicRadius);
    edge = max(edge, smoothstep(0.03, 0.01, arcDist));

    // Color based on cell
    vec3 color1 = vec3(
        0.5 + 0.5 * sin(colorIndex * 0.5 + t),
        0.5 + 0.5 * sin(colorIndex * 0.5 + t + 2.094),
        0.5 + 0.5 * sin(colorIndex * 0.5 + t + 4.188)
    );

    vec3 color2 = vec3(
        0.5 + 0.5 * sin(colorIndex * 0.7 + t + 1.0),
        0.5 + 0.5 * sin(colorIndex * 0.7 + t + 3.094),
        0.5 + 0.5 * sin(colorIndex * 0.7 + t + 5.188)
    );

    // Checker pattern
    float checker = mod(colorIndex, 2.0);
    vec3 tileColor = mix(color1, color2, checker);

    // Add interior pattern
    float pattern = sin(r * 20.0 - t * 2.0) * 0.5 + 0.5;
    tileColor *= 0.7 + 0.3 * pattern;

    // Add edges
    vec3 edgeColor = vec3(1.0) * u_intensity;

    return mix(tileColor * u_intensity, edgeColor, edge * 0.8);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    // Scale to fit Poincaré disk
    vec2 z = uv * 2.0;
    float r = length(z);

    vec3 color;

    if (r < 0.98) {
        // Inside the disk
        color = hyperbolicTile(z);

        // Fade at the edge of the disk
        color *= smoothstep(1.0, 0.95, r);
    } else {
        // Outside the disk - dark background
        color = vec3(0.02);
    }

    // Draw the disk boundary
    float diskEdge = abs(r - 0.99);
    color += smoothstep(0.02, 0.005, diskEdge) * vec3(0.5) * u_intensity;

    // Ripple effect
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

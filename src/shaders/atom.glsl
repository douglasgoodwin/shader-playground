precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_speed;
uniform float u_density;    // controls brightness
uniform float u_harmonics;  // controls scale

const float PI = 3.14159265;
const float TAU = 6.28318530;

// Distance from pixel to nearest dot on a circle
float circleDots(vec2 p, float radius, float numDots) {
    float angle = atan(p.y, p.x);
    float dotSpacing = TAU / numDots;
    float nearestAngle = floor(angle / dotSpacing + 0.5) * dotSpacing;

    float d = 1e10;
    for (int i = -1; i <= 1; i++) {
        float t = nearestAngle + float(i) * dotSpacing;
        vec2 dotPos = radius * vec2(cos(t), sin(t));
        d = min(d, length(p - dotPos));
    }
    return d;
}

// Distance from pixel to nearest dot on a rotated ellipse
// flow: angular offset that moves dots along the ellipse path
float ellipseDots(vec2 p, float a, float b, float rotation, float numDots, float flow) {
    float cr = cos(rotation);
    float sr = sin(rotation);
    vec2 lp = vec2(cr * p.x + sr * p.y, -sr * p.x + cr * p.y);

    // Subtract flow so we find the nearest dot in the shifted grid
    float angle = atan(lp.y / b, lp.x / a) - flow;
    float dotSpacing = TAU / numDots;
    float nearestAngle = floor(angle / dotSpacing + 0.5) * dotSpacing;

    float d = 1e10;
    for (int i = -1; i <= 1; i++) {
        float t = nearestAngle + float(i) * dotSpacing + flow;
        vec2 dotLocal = vec2(a * cos(t), b * sin(t));
        vec2 dotWorld = vec2(cr * dotLocal.x - sr * dotLocal.y,
                             sr * dotLocal.x + cr * dotLocal.y);
        d = min(d, length(p - dotWorld));
    }
    return d;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed;
    float spin = t * 0.5;

    float radius = 0.35 * u_harmonics;
    float ellipseA = radius;
    float ellipseB = radius * 0.45;
    float numCircleDots = 90.0;
    float numEllipseDots = 70.0;
    float dotSize = 0.004 * u_harmonics;

    // Outer circle
    float d = circleDots(uv, radius, numCircleDots);

    // Three ellipses rotated 60 degrees apart, spinning together
    // Points flow along each ellipse path
    float flow = t * 1.5;
    for (int i = 0; i < 3; i++) {
        float rot = spin + float(i) * PI / 3.0;
        float ed = ellipseDots(uv, ellipseA, ellipseB, rot, numEllipseDots, flow);
        d = min(d, ed);
    }

    // Hard-ish dots with slight softness
    float brightness = smoothstep(dotSize, dotSize * 0.25, d);

    // Subtle glow around dots
    float glow = 0.0004 / (d * d + 0.0004) * 0.15;

    vec3 color = vec3(0.9, 0.1, 0.02) * brightness * u_density
               + vec3(0.5, 0.03, 0.0) * glow * u_density;

    gl_FragColor = vec4(color, 1.0);
}

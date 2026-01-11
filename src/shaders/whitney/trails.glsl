// Whitney Music Box with Trails - inspired by Jim Bumgardner's blur version
// Simulates motion blur by drawing multiple time-offset copies

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359
#define TAU 6.28318530718

// Soft dot
float dot_shape(vec2 uv, vec2 center, float radius) {
    float d = length(uv - center);
    return smoothstep(radius, radius * 0.1, d);
}

// HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    float t = u_time * u_speed * 0.3;

    vec3 color = vec3(0.0);

    // Number of dots
    int npoints = int(36.0 * u_density);
    float maxRadius = 0.9;

    // Trail length (number of ghost copies)
    const int trailLength = 12;
    float trailStep = 0.015 / u_speed; // Time offset between trail segments

    for (int i = 1; i <= 72; i++) {
        if (i > npoints) break;

        float fi = float(i);
        float np = float(npoints);

        // Radius from center
        float r = (1.0 - fi / np) * maxRadius;

        // Angular speed proportional to index
        float angularSpeed = fi * u_harmonics;

        // Draw trail (multiple time-offset copies)
        for (int trail = 0; trail < trailLength; trail++) {
            float trailOffset = float(trail) * trailStep;
            float trailT = t - trailOffset;

            float a = trailT * angularSpeed;

            float x = cos(a) * r;
            float y = sin(a) * r;

            vec2 dotPos = vec2(x, y);

            // Trail fades out
            float trailFade = 1.0 - float(trail) / float(trailLength);
            trailFade = trailFade * trailFade; // Quadratic falloff

            // Smaller dots for trail
            float dotSize = (0.012 + 0.008 * (1.0 - fi / np)) * (0.5 + 0.5 * trailFade);
            float dot = dot_shape(uv, dotPos, dotSize);

            // Color with hue shift along trail
            float hue = fract(fi / np + t * 0.01 - float(trail) * 0.01);
            vec3 dotColor = hsv2rgb(vec3(hue, 0.7, 1.0));

            color += dot * dotColor * trailFade * 0.4;
        }
    }

    // Mouse glow
    vec2 mouse = u_mouse / u_resolution;
    mouse = mouse * 2.0 - 1.0;
    mouse.x *= u_resolution.x / u_resolution.y;
    float mouseDist = length(uv - mouse);
    color += 0.01 / (mouseDist + 0.1) * vec3(0.7, 0.8, 1.0);

    // Background with subtle radial gradient
    float centerDist = length(uv);
    vec3 bg = vec3(0.01, 0.01, 0.02) + 0.02 / (centerDist + 0.3) * vec3(0.1, 0.15, 0.25);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}

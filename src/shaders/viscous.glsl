precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

// Noise functions for generating viscous-like patterns
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                   dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// Domain warping for viscous fingering effect
float warpedNoise(vec2 p, float t) {
    vec2 q = vec2(
        noise(p + vec2(0.0, 0.0)),
        noise(p + vec2(5.2, 1.3))
    );

    vec2 r = vec2(
        noise(p + 4.0 * q + vec2(1.7, 9.2) + 0.15 * t),
        noise(p + 4.0 * q + vec2(8.3, 2.8) + 0.126 * t)
    );

    return noise(p + 4.0 * r);
}

// Fractal brownian motion with domain warping
float fbmWarp(vec2 p, float t) {
    float f = 0.0;
    float amp = 0.5;
    float freq = 1.0;

    for (int i = 0; i < 5; i++) {
        f += amp * warpedNoise(p * freq, t);
        freq *= 2.0;
        amp *= 0.5;
    }

    return f;
}

// Curl noise for flow-like patterns
vec2 curlNoise(vec2 p, float t) {
    float eps = 0.01;
    float n1 = fbmWarp(p + vec2(eps, 0.0), t);
    float n2 = fbmWarp(p - vec2(eps, 0.0), t);
    float n3 = fbmWarp(p + vec2(0.0, eps), t);
    float n4 = fbmWarp(p - vec2(0.0, eps), t);

    float dndx = (n1 - n2) / (2.0 * eps);
    float dndy = (n3 - n4) / (2.0 * eps);

    return vec2(dndy, -dndx);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed * 0.3;

    // Centered coordinates
    vec2 p = (uv - 0.5) * 3.0 * u_scale;

    // Mouse influence
    vec2 toMouse = mouse - uv;
    float mouseDist = length(toMouse);
    p += toMouse * 0.5 / (mouseDist + 0.3);

    // Generate viscous fingering pattern
    float n1 = fbmWarp(p, t);
    float n2 = fbmWarp(p + vec2(100.0), t * 0.7);
    float n3 = fbmWarp(p * 1.5 + vec2(50.0), t * 1.3);

    // Curl for flow direction
    vec2 curl = curlNoise(p, t);
    float flowAngle = atan(curl.y, curl.x);

    // Create branching/fingering pattern
    float fingers = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        vec2 fp = p * (1.0 + fi * 0.5);
        fp += curl * 0.2 * (fi + 1.0);
        float fn = fbmWarp(fp, t + fi * 10.0);
        fn = smoothstep(0.0, 0.1, abs(fn)) * smoothstep(0.4, 0.1, abs(fn));
        fingers += fn * (1.0 - fi * 0.2);
    }

    // Base color from noise
    vec3 color = vec3(0.02, 0.02, 0.05);

    // Finger coloring
    vec3 fingerColor = vec3(
        0.5 + 0.5 * sin(n1 * 3.0 + t + flowAngle),
        0.5 + 0.5 * sin(n2 * 3.0 + t * 0.7 + 2.094),
        0.5 + 0.5 * sin(n3 * 3.0 + t * 1.3 + 4.188)
    );

    color += fingers * fingerColor * u_intensity;

    // Add glow along the fingers
    float glow = smoothstep(0.3, 0.0, abs(n1 - 0.1));
    color += glow * 0.3 * vec3(0.4, 0.6, 1.0) * u_intensity;

    // Branching highlights
    float branch = smoothstep(0.02, 0.0, abs(fract(n1 * 5.0 + t) - 0.5) - 0.4);
    color += branch * 0.2 * fingerColor;

    // Mouse glow
    color += 0.1 / (mouseDist + 0.15) * vec3(0.3, 0.4, 0.6) * u_intensity;

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

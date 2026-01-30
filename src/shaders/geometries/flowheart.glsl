// Flowing Heart - Procedural glowing heart with organic movement
// Inspired by wyatt's "Lover" shader, simplified to single pass

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359

// Hash and noise functions
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Heart signed distance function
float heartSDF(vec2 p) {
    p.x = abs(p.x);

    if (p.y + p.x > 1.0) {
        return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    }

    return sqrt(min(dot(p - vec2(0.0, 1.0), p - vec2(0.0, 1.0)),
                    dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0))))
           * sign(p.x - p.y);
}

// Rope-like distortion along the heart edge
vec2 ropeDistort(vec2 p, float t) {
    float angle = atan(p.y - 0.3, p.x);
    float dist = length(p - vec2(0.0, 0.3));

    // Multiple wave frequencies for organic feel
    float wave = 0.0;
    wave += 0.03 * sin(angle * 8.0 + t * 2.0) * u_harmonics;
    wave += 0.02 * sin(angle * 13.0 - t * 3.0) * u_harmonics;
    wave += 0.015 * sin(angle * 21.0 + t * 1.5) * u_harmonics;

    // Add flowing noise
    float n = fbm(vec2(angle * 3.0, t * 0.5) * u_density);
    wave += 0.04 * (n - 0.5) * u_harmonics;

    // Radial distortion
    return p + normalize(p - vec2(0.0, 0.3)) * wave;
}

// Flowing displacement field
vec2 flowField(vec2 p, float t) {
    float n1 = fbm(p * 2.0 * u_density + t * 0.3);
    float n2 = fbm(p * 2.0 * u_density + t * 0.3 + 100.0);
    return vec2(n1 - 0.5, n2 - 0.5) * 0.15 * u_harmonics;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    // Center and scale
    vec2 p = (uv - 0.5) * 2.0;
    p.x *= aspect;
    p.y -= 0.1; // Move heart up slightly

    float t = u_time * u_speed;

    // Apply flowing distortion
    vec2 flow = flowField(p, t);
    vec2 distortedP = p + flow;

    // Apply rope-like edge distortion
    distortedP = ropeDistort(distortedP, t);

    // Scale for heart size
    float scale = 1.8;
    float d = heartSDF(distortedP * scale);

    // Create multiple layers for rope-like appearance
    float rope = 0.0;

    // Main rope strand
    float thickness = 0.02 + 0.01 * sin(t * 2.0);
    rope += smoothstep(thickness, thickness * 0.3, abs(d));

    // Secondary strands that weave
    for (float i = 1.0; i < 4.0; i++) {
        float offset = 0.015 * sin(t * (1.5 + i * 0.3) + i * 2.0);
        float strand = smoothstep(thickness * 0.7, thickness * 0.2, abs(d + offset * u_harmonics));
        rope += strand * (0.5 / i);
    }

    rope = clamp(rope, 0.0, 1.0);

    // Inner glow
    float innerGlow = smoothstep(0.3, -0.1, d);
    innerGlow *= 0.3 * (0.5 + 0.5 * sin(t * 0.5));

    // Outer glow
    float outerGlow = smoothstep(0.4, 0.0, abs(d));
    outerGlow *= 0.5;

    // Pulsing
    float pulse = 0.8 + 0.2 * sin(t * 1.5);

    // Color
    vec3 ropeColor = vec3(1.0, 0.9, 0.95);
    vec3 glowColor = vec3(1.0, 0.4, 0.5);
    vec3 innerColor = vec3(1.0, 0.2, 0.4) * 0.3;

    // Compose
    vec3 color = vec3(0.02, 0.01, 0.02); // Dark background
    color += innerColor * innerGlow * pulse;
    color += glowColor * outerGlow * pulse * u_density;
    color += ropeColor * rope * pulse;

    // Add subtle noise texture
    color += (hash(uv * 1000.0 + t) - 0.5) * 0.02;

    // Mouse interaction - ripple from mouse
    vec2 mouse = u_mouse / u_resolution;
    if (length(u_mouse) > 1.0) {
        mouse = mouse * 2.0 - 1.0;
        mouse.x *= aspect;
        float mouseDist = length(p - mouse);
        color += glowColor * 0.3 * exp(-mouseDist * 3.0);
    }

    // Vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.8;
    color *= vignette;

    // Gamma
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}

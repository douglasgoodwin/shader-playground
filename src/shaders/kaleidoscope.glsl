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

// Rotate 2D
vec2 rotate(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// Kaleidoscope fold - reflects coordinates to create symmetry
vec2 kaleidoscope(vec2 p, float segments) {
    float angle = PI / segments;
    float a = atan(p.y, p.x);

    // Fold into segment
    a = mod(a, 2.0 * angle) - angle;

    return length(p) * vec2(cos(a), abs(sin(a)));
}

// Noise for patterns
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float t = u_time * u_speed;

    // Number of mirror segments (6-12 looks good)
    float segments = 6.0 + floor(u_scale * 4.0);

    // Rotate the whole thing slowly
    uv = rotate(uv, t * 0.1);

    // Mouse affects the center offset
    vec2 center = mouse * 0.3;
    uv -= center;

    // Apply kaleidoscope folding
    vec2 kp = kaleidoscope(uv, segments);

    // Create layered patterns
    vec3 color = vec3(0.0);

    // Layer 1: Flowing shapes
    vec2 p1 = kp * 3.0;
    p1 = rotate(p1, t * 0.2);
    float pattern1 = sin(p1.x * 5.0 + t) * sin(p1.y * 5.0 + t * 0.7);
    pattern1 = smoothstep(-0.2, 0.2, pattern1);

    vec3 col1 = vec3(
        0.5 + 0.5 * sin(t + pattern1 * 3.0),
        0.5 + 0.5 * sin(t * 0.7 + pattern1 * 3.0 + 2.094),
        0.5 + 0.5 * sin(t * 1.3 + pattern1 * 3.0 + 4.188)
    );
    color += pattern1 * col1;

    // Layer 2: Noise-based organic shapes
    vec2 p2 = kp * 2.0 + vec2(t * 0.1, 0.0);
    float pattern2 = fbm(p2 * 3.0);
    pattern2 = smoothstep(0.3, 0.7, pattern2);

    vec3 col2 = vec3(
        0.5 + 0.5 * sin(t * 1.1 + 1.0),
        0.5 + 0.5 * sin(t * 0.9 + 3.094),
        0.5 + 0.5 * sin(t * 1.2 + 5.188)
    );
    color += pattern2 * col2 * 0.5;

    // Layer 3: Radial lines
    float angle = atan(kp.y, kp.x);
    float radius = length(kp);
    float lines = sin(angle * 20.0 + radius * 10.0 - t * 2.0);
    lines = smoothstep(0.0, 0.1, lines) * smoothstep(0.5, 0.3, radius);

    vec3 col3 = vec3(1.0, 0.9, 0.8);
    color += lines * col3 * 0.3;

    // Layer 4: Center glow
    float glow = 0.1 / (radius + 0.1);
    vec3 glowCol = vec3(
        0.5 + 0.5 * sin(t * 2.0),
        0.5 + 0.5 * sin(t * 2.0 + 2.094),
        0.5 + 0.5 * sin(t * 2.0 + 4.188)
    );
    color += glow * glowCol * 0.5;

    // Layer 5: Sparkling dots
    vec2 dotUV = kp * 10.0;
    vec2 dotID = floor(dotUV);
    vec2 dotF = fract(dotUV) - 0.5;
    float sparkle = hash(dotID + floor(t));
    float dot = smoothstep(0.3, 0.0, length(dotF)) * step(0.9, sparkle);
    color += dot * vec3(1.0) * u_intensity;

    // Apply intensity
    color *= u_intensity;

    // Vignette
    float vig = 1.0 - length(uv) * 0.5;
    color *= vig;

    // Ripple effect
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float rad = age * 0.5 * u_speed;
            float ring = abs(rippleDist - rad);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

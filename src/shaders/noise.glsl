// Boiling Methane Sea - translated from Shader Park
// Turbulent liquid surface like a moon of Jupiter

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "lygia/math/rotate3dX.glsl"
#include "lygia/math/rotate3dY.glsl"
#include "lygia/generative/random.glsl"

// Smooth 3D noise
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic smooth

    float a = dot(random3(i), f);
    float b = dot(random3(i + vec3(1, 0, 0)), f - vec3(1, 0, 0));
    float c = dot(random3(i + vec3(0, 1, 0)), f - vec3(0, 1, 0));
    float d = dot(random3(i + vec3(1, 1, 0)), f - vec3(1, 1, 0));
    float e = dot(random3(i + vec3(0, 0, 1)), f - vec3(0, 0, 1));
    float g = dot(random3(i + vec3(1, 0, 1)), f - vec3(1, 0, 1));
    float h = dot(random3(i + vec3(0, 1, 1)), f - vec3(0, 1, 1));
    float k = dot(random3(i + vec3(1, 1, 1)), f - vec3(1, 1, 1));

    return mix(mix(mix(a, b, f.x), mix(c, d, f.x), f.y),
               mix(mix(e, g, f.x), mix(h, k, f.x), f.y), f.z);
}

// Fractal noise with turbulence
float fractalNoise(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

// Scene - boiling liquid sphere
float scene(vec3 p, vec3 rd, float t) {
    // Exact Shader Park formula:
    // fractalNoise(getSpace()*4 + time*.01 + fractalNoise(getRayDirection()*2 + vec3(0,0,-1*time)*.1))
    float innerNoise = fractalNoise(rd * 2.0 + vec3(0.0, 0.0, -t * 0.1));
    float n = fractalNoise(p * 4.0 * u_scale + t * 0.01 + vec3(innerNoise));

    // sphere(0.5 + n * 0.02) with shell(0.1)
    float sphere = length(p) - (0.5 + n * 0.02 * u_intensity);
    return abs(sphere) - 0.1;
}

// Get noise for coloring
float getNoise(vec3 p, vec3 rd, float t) {
    float innerNoise = fractalNoise(rd * 2.0 + vec3(0.0, 0.0, -t * 0.1));
    return fractalNoise(p * 4.0 * u_scale + t * 0.01 + vec3(innerNoise));
}

// Calculate normal
vec3 getNormal(vec3 p, vec3 rd, float t) {
    vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(
        scene(p + e.xyy, rd, t) - scene(p - e.xyy, rd, t),
        scene(p + e.yxy, rd, t) - scene(p - e.yxy, rd, t),
        scene(p + e.yyx, rd, t) - scene(p - e.yyx, rd, t)
    ));
}

// Raymarching
float raymarch(vec3 ro, vec3 rd, float t) {
    float d = 0.0;

    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * d;
        float ds = scene(p, rd, t);
        d += ds * 0.4;
        if (abs(ds) < 0.001 || d > 10.0) break;
    }

    return d;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Mouse rotation
    vec2 mouse = u_mouse / u_resolution - 0.5;
    rd = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * rd;
    ro = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * ro;

    // Raymarch
    float d = raymarch(ro, rd, t);

    // Deep space background
    vec3 color = vec3(0.01, 0.01, 0.02);

    if (d < 10.0) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p, rd, t);

        // Get noise value
        float noiseVal = getNoise(p, rd, t);

        // Shader Park: col = vec3(n)*.5+.5; color(pow(col, vec3(2))+normal*.2)
        vec3 col = vec3(noiseVal) * 0.5 + 0.5;
        vec3 baseColor = pow(col, vec3(2.0)) + n * 0.2;

        // Lighting
        vec3 lightDir = normalize(vec3(1.0, 0.8, 0.6));
        float diff = max(dot(n, lightDir), 0.0);

        // shine(n + 0.2) - variable shininess
        vec3 viewDir = normalize(ro - p);
        vec3 halfDir = normalize(lightDir + viewDir);
        float shininess = max((noiseVal + 0.2) * 50.0 * u_intensity, 1.0);
        float spec = pow(max(dot(n, halfDir), 0.0), shininess);

        // metal(0.2) - subtle metallic fresnel
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0) * 0.2;

        // Combine lighting
        color = baseColor * (0.15 + diff * 0.6);
        color += vec3(1.0, 0.95, 0.9) * spec * 0.7;
        color += baseColor * fresnel;

        // Subtle rim for atmosphere
        float rim = 1.0 - max(dot(n, viewDir), 0.0);
        color += vec3(0.3, 0.35, 0.4) * pow(rim, 4.0) * 0.15;
    }

    // Ripple effect
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.4 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.03, 0.0, ring) * exp(-age * 2.5 / u_intensity);
            color += ripple * u_rippleColors[i] * 0.5;
        }
    }

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}

// Gyroid - translated from Shader Park
// Triply periodic minimal surface with noise coloring

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "../lygia/math/const.glsl"
#include "../lygia/math/rotate3dX.glsl"
#include "../lygia/math/rotate3dY.glsl"
#include "../lygia/generative/snoise.glsl"

#define MAX_STEPS 200
#define MAX_DIST 10.0
#define SURF_DIST 0.001

// Gyroid surface - triply periodic minimal surface
float gyroid(vec3 p, float scale) {
    p *= scale;
    return dot(sin(p), cos(vec3(p.z, p.x, p.y) + PI)) / scale;
}

// Scene SDF - gyroid carved sphere
float scene(vec3 p) {
    float t = u_time * u_speed * 0.5;

    // Rotate
    p = rotate3dX(t * 0.5) * p;

    // Slight x-axis squeeze like original
    p.x *= 0.9;

    // Noise modulation for sphere radius
    float n1 = sin(snoise(p * 0.4) * 6.0) * 0.5 + 0.5;
    float sphereR = 0.6 + n1 * 0.25;

    // Sphere
    float sph = length(p) - sphereR;

    // Gyroid with adjustable scale (default 16 in original)
    float gyScale = 16.0 * u_harmonics;
    float gy = gyroid(p, gyScale);

    // Combine: sphere with gyroid surface detail
    // The gyroid carves channels into the sphere
    return max(sph, abs(gy) - 0.03 / u_harmonics);
}

// Calculate normal
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + e.xyy) - scene(p - e.xyy),
        scene(p + e.yxy) - scene(p - e.yxy),
        scene(p + e.yyx) - scene(p - e.yyx)
    ));
}

// Raymarching - small step size for high-frequency gyroid detail
float raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = scene(p);
        d += ds * 0.1;  // Small steps for thin gyroid channels
        if (abs(ds) < SURF_DIST || d > MAX_DIST) break;
    }

    return d;
}

// Coloring based on position and gyroid
vec3 getColor(vec3 p, vec3 n) {
    float t = u_time * u_speed * 0.5;

    // Gyroid value for coloring
    float gyScale = 16.0 * u_harmonics;
    float gy = gyroid(p, gyScale);

    // Noise-based coloring like vectorContourNoise
    vec3 noiseP = p * 3.0 + vec3(0.0, 0.0, t * 0.5);
    float nVal = snoise(noiseP) + gy;

    // Sharp color bands
    float band = sin(nVal * 2.0 * u_density) * 0.5 + 0.5;
    float exponent = 50.0 / u_density;
    vec3 col = vec3(pow(band, exponent));

    // Add some color variation
    col *= vec3(1.0, 0.95, 0.9);

    return col;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed * 0.5;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Mouse rotation
    vec2 mouse = u_mouse / u_resolution - 0.5;
    rd = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * rd;
    ro = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * ro;

    // Raymarch
    float d = raymarch(ro, rd);

    vec3 color = vec3(0.02, 0.02, 0.03);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);

        // Get color
        vec3 baseColor = getColor(p, n);

        // Metallic lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        float diff = max(dot(n, lightDir), 0.0);

        // Specular (metallic shine = 0.4, metal = 0.9)
        vec3 viewDir = normalize(ro - p);
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(n, halfDir), 0.0), 64.0);

        // Fresnel
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0);

        // Combine with metallic material
        color = baseColor * (0.15 + diff * 0.4);
        color += vec3(1.0) * spec * 0.9; // metal reflection
        color += baseColor * fresnel * 0.4;

        // Rim light
        float rim = 1.0 - max(dot(n, viewDir), 0.0);
        color += vec3(0.3, 0.4, 0.5) * pow(rim, 3.0) * 0.3;
    }

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}

// Oscillating Sphere - translated from Shader Park
// Sphere with wavy surface distortion and HSV color cycling

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "/lygia/math/const.glsl"
#include "/lygia/math/rotate3dX.glsl"
#include "/lygia/math/rotate3dY.glsl"
#include "/lygia/color/space/hsv2rgb.glsl"

#define MAX_STEPS 600
#define MAX_DIST 10.0
#define SURF_DIST 0.001

// Cartesian to spherical coordinates
// Returns vec3(r, theta, phi) where theta is polar angle, phi is azimuthal
vec3 toSpherical(vec3 p) {
    float r = length(p);
    float theta = acos(p.y / (r + 0.0001)); // polar angle from y-axis
    float phi = atan(p.z, p.x);              // azimuthal angle in xz plane
    return vec3(r, theta, phi);
}

// Oscillation function from Shader Park
float oscillate(float x) {
    return sin(20.0 * x * u_harmonics) * 0.5;
}

// Scene SDF - oscillating sphere
float scene(vec3 p) {
    float t = u_time * u_speed * 0.5;

    // Convert to spherical coordinates
    vec3 s = toSpherical(p);

    // Create oscillating displacement
    // m = min(oscillate(s.y + s.x + time), oscillate(s.z))
    // In spherical: s.x = r, s.y = theta, s.z = phi
    float m = min(
        oscillate(s.y + s.x + t),
        oscillate(s.z)
    );

    // Base sphere with expansion
    float sphere = length(p) - 0.5;

    // Apply expansion (expand by 0.5 * m)
    float expansion = 0.5 * m * u_density;

    return sphere - expansion;
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

// Raymarching with small step size to handle high-frequency detail
float raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = scene(p);

        // Small step multiplier (0.04) prevents overstepping thin geometry
        // This matches Shader Park's setStepSize(.04)
        d += ds * 0.04;

        if (abs(ds) < SURF_DIST || d > MAX_DIST) break;
    }

    return d;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed * 0.5;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.5);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Mouse rotation
    vec2 mouse = u_mouse / u_resolution - 0.5;
    rd = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * rd;
    ro = rotate3dY(mouse.x * 3.0) * rotate3dX(-mouse.y * 2.0) * ro;

    // Raymarch
    float d = raymarch(ro, rd);

    // Background
    vec3 color = vec3(0.02, 0.02, 0.03);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);

        // HSV color from Shader Park
        // hue = abs(sin(time * 0.2))
        float hue = abs(sin(t * 0.4));
        float saturation = 1.0;
        float value = 1.0;
        vec3 baseColor = hsv2rgb(vec3(hue, saturation, value));

        // Lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        float diff = max(dot(n, lightDir), 0.0);

        // Ambient occlusion approximation (from occlusion(-10))
        // Negative occlusion in Shader Park means less shadowing
        float ao = 0.5 + 0.5 * n.y;

        // Specular
        vec3 viewDir = normalize(ro - p);
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(n, halfDir), 0.0), 32.0);

        // Fresnel rim
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0);

        // Combine
        color = baseColor * (0.2 + diff * 0.6) * ao;
        color += vec3(1.0) * spec * 0.5;
        color += baseColor * fresnel * 0.3;
    }

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}

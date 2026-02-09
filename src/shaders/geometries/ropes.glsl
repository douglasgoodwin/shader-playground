// Ropes - translated from Shadertoy by iq
// Intertwined strands with animated light bands

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "../lygia/math/const.glsl"
#include "../lygia/generative/random.glsl"

vec2 sincos(float x) {
    return vec2(sin(x), cos(x));
}

vec3 opU(vec3 d1, vec3 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

// Flattened ribbon SDF instead of cylinder
vec2 sdRibbon(vec3 p) {
    // Flatten: wide in x, thin in z
    vec2 cross = vec2(p.x * 0.7, p.z * 2.2);
    return vec2(length(cross), (p.y + 40.0) / 80.0);
}

// Current - moderately flat
// vec2 cross = vec2(p.x * 0.5, p.z * 2.0);

// Flatter ribbon (wider, thinner)
// vec2 cross = vec2(p.x * 0.3, p.z * 4.0);

// Very flat like paper
// vec2 cross = vec2(p.x * 0.2, p.z * 8.0);

// Almost cylindrical
// vec2 cross = vec2(p.x * 0.8, p.z * 1.2);

vec3 map(vec3 p, float time) {
    // Grid cell ID for variation
    vec2 id = floor((p.xz + 1.0) / 2.0);
    float ph = random(id + 113.1);
    float ve = random(id);

    // Repeat space
    p.xz = mod(p.xz + 1.0, 2.0) - 1.0;

    // Wavy motion - anchored at bottom (y=0), sway increases with height
    float anchorFactor = smoothstep(-40.0, 20.0, p.y);
    p.xz += anchorFactor * 0.5 * cos(2.0 * ve * time + (p.y + ph) * vec2(0.53, 0.32) - vec2(1.57, 0.0));

    // Four intertwined strands
    vec3 p1 = p; p1.xz += anchorFactor * 0.15 * sincos(p.y - ve * time * ve + 0.0);
    vec3 p2 = p; p2.xz += anchorFactor * 0.15 * sincos(p.y - ve * time * ve + 2.0);
    vec3 p3 = p; p3.xz += anchorFactor * 0.15 * sincos(p.y - ve * time * ve + 4.0);
    vec3 p4 = p; p4.xz += anchorFactor * 0.15 * sincos(p.y - ve * time * ve + 8.0);

    vec2 h1 = sdRibbon(p1);
    vec2 h2 = sdRibbon(p2);
    vec2 h3 = sdRibbon(p3);
    vec2 h4 = sdRibbon(p4);

    // Strand thickness with variation
    float thick = 0.1 * u_density;
    return opU(opU(opU(
        vec3(h1.x - thick * (0.8 + 0.2 * sin(200.0 * h1.y)), ve + 0.000, h1.y),
        vec3(h2.x - thick * (0.8 + 0.2 * sin(200.0 * h2.y)), ve + 0.015, h2.y)),
        vec3(h3.x - thick * (0.8 + 0.2 * sin(200.0 * h3.y)), ve + 0.015, h3.y)),
        vec3(h4.x - thick * (0.8 + 0.2 * sin(200.0 * h4.y)), ve + 0.060, h4.y));
}

vec3 intersect(vec3 ro, vec3 rd, float px, float maxdist, float time) {
    vec3 res = vec3(-1.0);
    float t = 0.0;

    for (int i = 0; i < 200; i++) {
        vec3 h = map(ro + t * rd, time);
        res = vec3(t, h.yz);
        if (abs(h.x) < (px * t) || t > maxdist) break;
        t += min(h.x, 0.5) * 0.85;
    }

    return res;
}

vec3 calcNormal(vec3 pos, float time) {
    const vec2 e = vec2(1.0, -1.0) * 0.003;
    return normalize(
        e.xyy * map(pos + e.xyy, time).x +
        e.yyx * map(pos + e.yyx, time).x +
        e.yxy * map(pos + e.yxy, time).x +
        e.xxx * map(pos + e.xxx, time).x
    );
}

float calcOcc(vec3 pos, vec3 nor, float time) {
    const float h = 0.1;
    float ao = 0.0;

    for (int i = 0; i < 11; i++) {
        vec3 dir = sin(float(i) * vec3(1.0, 7.13, 13.71) + vec3(0.0, 2.0, 4.0));
        dir = dir + 2.0 * nor * max(0.0, -dot(nor, dir));
        float d = map(pos + h * dir, time).x;
        ao += h - d;
    }

    return clamp(1.0 - 0.7 * ao, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd, float px, float time) {
    // Blue underwater background
    vec3 fogColor = vec3(0.02, 0.08, 0.15);
    vec3 col = fogColor;

    const float maxdist = 32.0;
    vec3 res = intersect(ro, rd, px, maxdist, time);

    if (res.x < maxdist) {
        vec3 pos = ro + res.x * rd;
        vec3 nor = calcNormal(pos, time);
        float occ = calcOcc(pos, nor, time);

        // Dark green color palette
        vec3 matCol = 0.5 + 0.5 * cos(res.y * 15.0 * u_harmonics + vec3(2.0, 2.5, 4.0));
        matCol *= 0.5 + 1.0 * nor.y;
        matCol += clamp(1.0 + dot(rd, nor), 0.1, 1.0);

        // Animated light bands along ropes
        float u = 800.0 * res.z - sin(res.y) * time;
        matCol *= 0.95 + 0.05 * cos(u + PI * cos(1.5 * u + PI * cos(3.0 * u)) + vec3(0.0, 1.0, 2.0));

        // Dark green tint instead of purple
        matCol *= vec3(0.3, 0.8, 0.2);
        matCol *= occ;

        // Moving highlight band
        float fl = mod((0.5 + cos(2.0 + res.y * 47.0)) * time + res.y * 7.0, 4.0) / 4.0;
        matCol *= 2.5 - 1.5 * smoothstep(0.02, 0.04, abs(res.z - fl));

        // Blue underwater fog - blend toward fogColor with distance
        float fog = exp(-0.08 * res.x);
        col = mix(fogColor, matCol, fog);

        // Far distance fade
        col = mix(fogColor, col, 1.0 - smoothstep(20.0, 30.0, res.x));
    }

    return pow(col, vec3(0.5, 1.0, 0.5));
}

void main() {
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution) / u_resolution.y;

    float time = u_time * u_speed;

    // Camera setup
    vec3 ro = vec3(1.6, 2.4, 1.2);
    vec3 ta = vec3(0.0, 0.0, 0.0);
    float fl = 3.0;

    // Mouse look
    vec2 mouse = u_mouse / u_resolution - 0.5;
    ro.x += mouse.x * 2.0;
    ro.y += mouse.y * 2.0;

    // Camera matrix
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x * uu + p.y * vv + fl * ww);

    // Render
    vec3 col = render(ro, rd, 1.0 / (u_resolution.y * fl), time);

    // Vignette
    vec2 q = gl_FragCoord.xy / u_resolution;
    col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.3);

    gl_FragColor = vec4(col, 0.5);
}

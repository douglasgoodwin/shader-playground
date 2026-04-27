// Three-layer matte compositor — Janie Geiser inspired
// back layer + front layer + matte. The shader perturbs the matte over
// time so the hole breathes, drifts, and shimmers along its edge.
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_back;
uniform sampler2D u_front;
uniform sampler2D u_matte;

uniform vec2 u_resolution;
uniform vec2 u_backSize;
uniform vec2 u_frontSize;
uniform vec2 u_matteSize;

uniform int u_hasBack;
uniform int u_hasFront;
uniform int u_hasMatte;

uniform float u_time;
uniform float u_drift;       // matte UV displacement amount
uniform float u_breath;      // scale wobble
uniform float u_jitter;      // edge / threshold jitter
uniform float u_speed;       // overall animation speed
uniform float u_softness;    // how soft the matte falloff is
uniform int u_useLuminance;  // 1 = use matte luminance, 0 = use matte alpha

#define PI 3.14159265359

// Cover-fit UV: keep aspect, fill the screen
vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    if (texSize.x < 1.5 || texSize.y < 1.5) return uv;
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

// Cheap value noise — for matte UV drift and threshold jitter.
// Doesn't need to be pretty; it just needs to wobble continuously.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * vnoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    float t = u_time * u_speed;

    // --- 1. Back layer ---
    vec3 back = vec3(0.05);
    if (u_hasBack == 1) {
        back = texture2D(u_back, coverUV(v_uv, u_backSize, u_resolution)).rgb;
    }

    // --- 2. Front layer ---
    vec3 front = vec3(1.0, 0.55, 0.15); // fallback orange so the matte reads
    if (u_hasFront == 1) {
        front = texture2D(u_front, coverUV(v_uv, u_frontSize, u_resolution)).rgb;
    }

    // --- 3. Matte — time-warped UVs ---
    vec2 matteUV = coverUV(v_uv, u_matteSize, u_resolution);

    // Slow breathing scale around center
    float breath = 1.0 + sin(t * 0.4) * u_breath;
    matteUV = (matteUV - 0.5) / breath + 0.5;

    // Drift the matte UVs with low-frequency noise — the hole wanders
    vec2 drift;
    drift.x = fbm(matteUV * 2.0 + vec2(t * 0.15, 0.0)) - 0.5;
    drift.y = fbm(matteUV * 2.0 + vec2(0.0, t * 0.13 + 7.3)) - 0.5;
    matteUV += drift * u_drift;

    float mask = 0.0;
    if (u_hasMatte == 1) {
        vec4 m = texture2D(u_matte, matteUV);
        mask = (u_useLuminance == 1) ? dot(m.rgb, vec3(0.299, 0.587, 0.114)) : m.a;
    } else {
        // Procedural fallback: a soft circle so the demo runs without an upload
        vec2 p = (v_uv - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);
        float r = length(p);
        mask = 1.0 - smoothstep(0.18, 0.32, r);
    }

    // Per-frame edge jitter — film-grain shimmer at the boundary
    float grain = (fbm(v_uv * 200.0 + t * 8.0) - 0.5) * u_jitter;
    mask += grain;

    // Softness: remap the mask through a smoothstep so the falloff width
    // is controllable, and the threshold itself wobbles slightly.
    float thresh = 0.5 + sin(t * 0.7) * 0.04;
    float half_w = max(u_softness, 0.001);
    mask = smoothstep(thresh - half_w, thresh + half_w, mask);
    mask = clamp(mask, 0.0, 1.0);

    vec3 color = mix(back, front, mask);
    gl_FragColor = vec4(color, 1.0);
}

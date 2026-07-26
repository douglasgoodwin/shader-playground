// Color-keyed assembly.
//
// One piece of "organizing media" — a still or a video with flat color
// areas — decides which of five video layers shows at each pixel. Every
// pixel picks the slot whose key color is closest to the map's color
// there, so a red area plays video 1, a blue area video 2, and so on.
//
// The videos are stenciled in screen space: each one fills the frame and
// the map cuts it. That keeps the geometry of the source intact and lets
// the map function purely as a score.
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_map;
uniform sampler2D u_v0;
uniform sampler2D u_v1;
uniform sampler2D u_v2;
uniform sampler2D u_v3;
uniform sampler2D u_v4;

uniform vec2  u_resolution;
uniform vec2  u_mapSize;
uniform vec2  u_sizes[5];
uniform float u_has[5];      // 1.0 when that slot has media loaded
uniform vec3  u_keys[5];      // display space, for the swatch an empty slot draws
uniform vec3  u_matchKeys[5]; // same colors already normalized for comparison
uniform int   u_hasMap;
uniform int   u_slotCount;   // active slots, 1..5
uniform float u_tolerance;   // how far a map color may sit from a key
uniform float u_softness;    // width of the falloff at the match edge
uniform int   u_chromaOnly;  // 1 = compare hue/saturation, ignore brightness
uniform int   u_unmatched;   // 0 = black, 1 = the map itself
uniform float u_scale;       // zoom applied to every video layer
uniform int   u_preview;     // 1 = show the raw map instead of the composite

#define SLOTS 5

vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    if (texSize.x < 1.5 || texSize.y < 1.5) return uv;
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

// Sampler arrays can't be indexed by a runtime value in GLSL ES 1.00,
// so the five layers are dispatched by hand.
vec3 slotTexel(int i, vec2 uv) {
    if (i == 0) return texture2D(u_v0, uv).rgb;
    if (i == 1) return texture2D(u_v1, uv).rgb;
    if (i == 2) return texture2D(u_v2, uv).rgb;
    if (i == 3) return texture2D(u_v3, uv).rgb;
    return texture2D(u_v4, uv).rgb;
}

vec2 slotSize(int i) {
    vec2 s = vec2(1.0);
    for (int j = 0; j < SLOTS; j++) {
        if (j == i) s = u_sizes[j];
    }
    return s;
}

float slotHas(int i) {
    float h = 0.0;
    for (int j = 0; j < SLOTS; j++) {
        if (j == i) h = u_has[j];
    }
    return h;
}

vec3 slotKey(int i) {
    vec3 k = vec3(0.0);
    for (int j = 0; j < SLOTS; j++) {
        if (j == i) k = u_keys[j];
    }
    return k;
}

vec3 slotColor(int i, vec2 screenUV) {
    // Empty slot: flash its key color so the layout reads before all five
    // videos are in place.
    if (slotHas(i) < 0.5) return slotKey(i) * 0.6;
    vec2 uv = (screenUV - 0.5) / max(u_scale, 0.01) + 0.5;
    return slotTexel(i, coverUV(uv, slotSize(i), u_resolution));
}

// Flat graphic color survives compression better in hue than in value, so
// chroma-only matching normalizes brightness away before comparing. Only the
// map color needs this at fragment rate — the keys arrive pre-normalized.
vec3 forMatch(vec3 c) {
    if (u_chromaOnly == 0) return c;
    float peak = max(c.r, max(c.g, c.b));
    return c / max(peak, 0.02);
}

void main() {
    vec3 mapColor = vec3(0.0);
    if (u_hasMap == 1) {
        mapColor = texture2D(u_map, coverUV(v_uv, u_mapSize, u_resolution)).rgb;
    }

    if (u_preview == 1) {
        gl_FragColor = vec4(mapColor, 1.0);
        return;
    }

    if (u_hasMap == 0) {
        // No map yet — lay the active slots out in vertical bands so the
        // page shows something useful the moment videos are dropped in.
        int band = int(floor(v_uv.x * float(u_slotCount)));
        if (band > u_slotCount - 1) band = u_slotCount - 1;
        gl_FragColor = vec4(slotColor(band, v_uv), 1.0);
        return;
    }

    vec3 probe = forMatch(mapColor);

    int best = 0;
    float bestDist = 1e6;
    for (int i = 0; i < SLOTS; i++) {
        if (i > u_slotCount - 1) break;
        float d = distance(probe, u_matchKeys[i]);
        if (d < bestDist) {
            bestDist = d;
            best = i;
        }
    }

    float half_w = max(u_softness, 0.001);
    float match = 1.0 - smoothstep(u_tolerance - half_w, u_tolerance + half_w, bestDist);

    vec3 unmatched = (u_unmatched == 1) ? mapColor : vec3(0.0);
    vec3 color = mix(unmatched, slotColor(best, v_uv), match);

    gl_FragColor = vec4(color, 1.0);
}

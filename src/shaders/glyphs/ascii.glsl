precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform sampler2D u_fontAtlas;
uniform float u_numChars;

#define MAX_STEPS 60
#define MAX_DIST 40.0
#define SURF_DIST 0.003
#define CONTRAST_EXP 2.5

// ============================================================
// 6D SHAPE VECTORS - Must match JavaScript font atlas order
// Characters: ' .'-|/\_iczu1UBMW@#' (19 chars)
// ============================================================

vec3 getShapeA(int idx) {
    if (idx == 0) return vec3(0.0, 0.0, 0.0);       // space
    if (idx == 1) return vec3(0.0, 0.0, 0.0);       // .
    if (idx == 2) return vec3(0.3, 0.3, 0.0);       // '
    if (idx == 3) return vec3(0.0, 0.0, 0.55);      // -
    if (idx == 4) return vec3(0.4, 0.4, 0.5);       // |
    if (idx == 5) return vec3(0.0, 0.75, 0.35);     // /
    if (idx == 6) return vec3(0.75, 0.0, 0.35);     // backslash
    if (idx == 7) return vec3(0.0, 0.0, 0.0);       // _
    if (idx == 8) return vec3(0.3, 0.3, 0.35);      // i
    if (idx == 9) return vec3(0.35, 0.1, 0.45);     // c
    if (idx == 10) return vec3(0.0, 0.6, 0.55);     // z
    if (idx == 11) return vec3(0.45, 0.55, 0.45);   // u
    if (idx == 12) return vec3(0.4, 0.4, 0.45);     // 1
    if (idx == 13) return vec3(0.5, 0.5, 0.5);      // U
    if (idx == 14) return vec3(0.7, 0.7, 0.8);      // B
    if (idx == 15) return vec3(0.85, 0.85, 0.7);    // M
    if (idx == 16) return vec3(0.7, 0.7, 0.75);     // W
    if (idx == 17) return vec3(0.75, 0.75, 0.85);   // @
    if (idx == 18) return vec3(0.65, 0.65, 0.75);   // #
    return vec3(0.0);
}

vec3 getShapeB(int idx) {
    if (idx == 0) return vec3(0.0, 0.0, 0.0);       // space
    if (idx == 1) return vec3(0.0, 0.15, 0.15);     // .
    if (idx == 2) return vec3(0.0, 0.0, 0.0);       // '
    if (idx == 3) return vec3(0.55, 0.0, 0.0);      // -
    if (idx == 4) return vec3(0.5, 0.4, 0.4);       // |
    if (idx == 5) return vec3(0.35, 0.75, 0.0);     // /
    if (idx == 6) return vec3(0.35, 0.0, 0.75);     // backslash
    if (idx == 7) return vec3(0.0, 0.75, 0.75);     // _
    if (idx == 8) return vec3(0.35, 0.3, 0.3);      // i
    if (idx == 9) return vec3(0.0, 0.35, 0.1);      // c
    if (idx == 10) return vec3(0.55, 0.6, 0.0);     // z
    if (idx == 11) return vec3(0.45, 0.55, 0.55);   // u
    if (idx == 12) return vec3(0.45, 0.4, 0.4);     // 1
    if (idx == 13) return vec3(0.5, 0.6, 0.6);      // U
    if (idx == 14) return vec3(0.8, 0.7, 0.7);      // B
    if (idx == 15) return vec3(0.7, 0.75, 0.75);    // M
    if (idx == 16) return vec3(0.75, 0.85, 0.85);   // W
    if (idx == 17) return vec3(0.85, 0.65, 0.65);   // @
    if (idx == 18) return vec3(0.75, 0.65, 0.65);   // #
    return vec3(0.0);
}

// Sample character from font atlas
float sampleChar(int charIdx, vec2 uv) {
    float col = float(charIdx);
    // Flip Y because WebGL textures have Y=0 at bottom, Canvas has Y=0 at top
    vec2 charUV = vec2((col + uv.x) / u_numChars, 1.0 - uv.y);
    return texture2D(u_fontAtlas, charUV).r;
}

void applyContrast(inout vec3 a, inout vec3 b, float exponent) {
    float maxVal = max(max(max(a.x, a.y), max(a.z, b.x)), max(b.y, b.z));
    if (maxVal < 0.01) return;
    a = pow(a / maxVal, vec3(exponent)) * maxVal;
    b = pow(b / maxVal, vec3(exponent)) * maxVal;
}

int findBestChar(vec3 sampleA, vec3 sampleB) {
    float minDist = 1000.0;
    int bestIdx = 0;
    int numChars = int(u_numChars);

    for (int i = 0; i < 20; i++) {
        if (i >= numChars) break;
        vec3 charA = getShapeA(i);
        vec3 charB = getShapeB(i);
        vec3 dA = sampleA - charA;
        vec3 dB = sampleB - charB;
        float dist = dot(dA, dA) + dot(dB, dB);
        if (dist < minDist) {
            minDist = dist;
            bestIdx = i;
        }
    }
    return bestIdx;
}

// ============================================================
// 3D RAYMARCHING (Platonic solids)
// ============================================================

#include "/lygia/math/rotate2d.glsl"
#include "/lygia/sdf/octahedronSDF.glsl"
#include "/lygia/sdf/boxSDF.glsl"

float sdTetrahedron(vec3 p, float r) {
    float md = max(max(-p.x - p.y - p.z, p.x + p.y - p.z),
                   max(-p.x + p.y + p.z, p.x - p.y + p.z));
    return (md - r) / sqrt(3.0);
}

float sdIcosahedron(vec3 p, float r) {
    float phi = 1.618033988749895;
    vec3 n = normalize(vec3(phi, 1.0, 0.0));
    p = abs(p);
    float a = dot(p, n);
    float b = dot(p, n.zxy);
    float c = dot(p, n.yzx);
    float d = dot(p, normalize(vec3(1.0)));
    return max(max(max(a, b), c), d) - r;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float map(vec3 p) {
    float t = u_time * u_speed * 0.3;

    vec3 p1 = p;
    p1.xz *= rotate2d(t);
    p1.xy *= rotate2d(t * 0.7);
    float oct = octahedronSDF(p1, 1.2 * u_scale);

    vec3 p2 = p - vec3(cos(t) * 2.5, sin(t * 0.5) * 0.5, sin(t) * 2.5) * u_scale;
    p2.xy *= rotate2d(t * 1.5);
    p2.yz *= rotate2d(t * 1.2);
    float tet = sdTetrahedron(p2, 0.7 * u_scale);

    vec3 p3 = p - vec3(cos(t + 2.094) * 2.5, sin(t * 0.5 + 1.0) * 0.5, sin(t + 2.094) * 2.5) * u_scale;
    p3.xz *= rotate2d(t * 0.8);
    p3.xy *= rotate2d(t * 1.1);
    float cube = boxSDF(p3, vec3(0.55 * u_scale));

    vec3 p4 = p - vec3(cos(t + 4.188) * 2.5, sin(t * 0.5 + 2.0) * 0.5, sin(t + 4.188) * 2.5) * u_scale;
    p4.yz *= rotate2d(t * 1.3);
    p4.xz *= rotate2d(t * 0.9);
    float ico = sdIcosahedron(p4, 0.55 * u_scale);

    float d = smin(oct, tet, 0.2);
    d = smin(d, cube, 0.2);
    d = smin(d, ico, 0.2);

    return d;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = map(p);
        d += ds * 0.7;
        if (d > MAX_DIST || ds < SURF_DIST) break;
    }
    return d;
}

float sampleBrightness(vec2 uv, vec3 ro, vec3 right, vec3 up, vec3 forward) {
    vec3 rd = normalize(uv.x * right + uv.y * up + 1.5 * forward);
    float d = rayMarch(ro, rd);

    if (d >= MAX_DIST) return 0.0;

    vec3 p = ro + rd * d;
    vec3 n = calcNormal(p);

    vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
    float diff = max(dot(n, lightDir), 0.0);

    vec3 viewDir = normalize(ro - p);
    float rim = 1.0 - max(dot(viewDir, n), 0.0);
    rim = pow(rim, 2.0) * 0.4;

    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16.0);

    float brightness = diff * 0.65 + rim * 0.35 + spec * 0.25;
    float depthFade = 1.0 - d / MAX_DIST;
    brightness *= depthFade;

    return clamp(brightness * u_intensity, 0.0, 1.0);
}

void main() {
    float charSize = 14.0 / u_scale;

    vec2 cellCoord = floor(gl_FragCoord.xy / charSize);
    vec2 cellUV = fract(gl_FragCoord.xy / charSize);

    vec2 cellCenter = (cellCoord + 0.5) * charSize;
    vec2 baseUV = (cellCenter - 0.5 * u_resolution.xy) / u_resolution.y;

    vec2 mouse = u_mouse / u_resolution - 0.5;
    vec3 ro = vec3(0.0, 0.0, -6.0);
    ro.xz *= rotate2d(mouse.x * 3.14159);
    ro.y += mouse.y * 4.0;

    vec3 lookAt = vec3(0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    float cellW = charSize / u_resolution.y;
    float cellH = charSize / u_resolution.y;

    vec2 offTL = vec2(-0.25, 0.30) * vec2(cellW, cellH);
    vec2 offTR = vec2(0.25, 0.35) * vec2(cellW, cellH);
    vec2 offML = vec2(-0.25, -0.05) * vec2(cellW, cellH);
    vec2 offMR = vec2(0.25, 0.0) * vec2(cellW, cellH);
    vec2 offBL = vec2(-0.25, -0.35) * vec2(cellW, cellH);
    vec2 offBR = vec2(0.25, -0.30) * vec2(cellW, cellH);

    float sTL = sampleBrightness(baseUV + offTL, ro, right, up, forward);
    float sTR = sampleBrightness(baseUV + offTR, ro, right, up, forward);
    float sML = sampleBrightness(baseUV + offML, ro, right, up, forward);
    float sMR = sampleBrightness(baseUV + offMR, ro, right, up, forward);
    float sBL = sampleBrightness(baseUV + offBL, ro, right, up, forward);
    float sBR = sampleBrightness(baseUV + offBR, ro, right, up, forward);

    vec3 sampleA = vec3(sTL, sTR, sML);
    vec3 sampleB = vec3(sMR, sBL, sBR);

    applyContrast(sampleA, sampleB, CONTRAST_EXP);

    int bestCharIdx = findBestChar(sampleA, sampleB);

    float pixel = sampleChar(bestCharIdx, cellUV);

    float t = u_time * u_speed;
    vec2 samplePos = cellCenter / u_resolution;

    float avgBrightness = (sTL + sTR + sML + sMR + sBL + sBR) / 6.0;

    vec3 baseColor = vec3(0.15, 0.95, 0.45);
    float hueShift = sin(samplePos.x * 3.14159 + t * 0.3) * 0.15;
    baseColor = vec3(
        0.1 + hueShift * 0.5,
        0.92 - abs(hueShift) * 0.15,
        0.45 + sin(samplePos.y * 3.14159 + t * 0.2) * 0.2
    );

    baseColor *= (0.5 + avgBrightness * 0.6);

    vec3 color = pixel * baseColor;

    float scanline = sin(gl_FragCoord.y * 1.0) * 0.025;
    color -= scanline;

    color += vec3(0.0, 0.015, 0.008) * avgBrightness;

    gl_FragColor = vec4(color, 1.0);
}

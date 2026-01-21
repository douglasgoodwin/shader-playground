precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_contrast;
uniform float u_charSize;
uniform float u_speed;

#define NUM_CHARS 26

// ============================================================
// 6D SHAPE VECTORS - Following Alex Harri's approach
// Characters chosen for good contour following
// ============================================================

vec3 getShapeA(int idx) {
    if (idx == 0) return vec3(0.0, 0.0, 0.0);       // space
    if (idx == 1) return vec3(0.0, 0.0, 0.0);       // .
    if (idx == 2) return vec3(0.2, 0.2, 0.0);       // '
    if (idx == 3) return vec3(0.25, 0.0, 0.0);      // `
    if (idx == 4) return vec3(0.0, 0.25, 0.0);      // ,
    if (idx == 5) return vec3(0.0, 0.0, 0.55);      // -
    if (idx == 6) return vec3(0.0, 0.0, 0.0);       // _
    if (idx == 7) return vec3(0.35, 0.35, 0.45);    // |
    if (idx == 8) return vec3(0.0, 0.7, 0.35);      // /
    if (idx == 9) return vec3(0.7, 0.0, 0.35);      // backslash
    if (idx == 10) return vec3(0.75, 0.75, 0.35);   // T
    if (idx == 11) return vec3(0.55, 0.0, 0.55);    // L
    if (idx == 12) return vec3(0.0, 0.55, 0.0);     // J
    if (idx == 13) return vec3(0.6, 0.6, 0.35);     // Y
    if (idx == 14) return vec3(0.55, 0.55, 0.4);    // V
    if (idx == 15) return vec3(0.35, 0.1, 0.45);    // c
    if (idx == 16) return vec3(0.35, 0.35, 0.45);   // o
    if (idx == 17) return vec3(0.65, 0.65, 0.45);   // n
    if (idx == 18) return vec3(0.45, 0.45, 0.45);   // u
    if (idx == 19) return vec3(0.25, 0.25, 0.3);    // i
    if (idx == 20) return vec3(0.1, 0.35, 0.45);    // (
    if (idx == 21) return vec3(0.35, 0.1, 0.45);    // )
    if (idx == 22) return vec3(0.65, 0.65, 0.75);   // #
    if (idx == 23) return vec3(0.75, 0.75, 0.85);   // @
    if (idx == 24) return vec3(0.85, 0.85, 0.7);    // M
    if (idx == 25) return vec3(0.7, 0.7, 0.75);     // W
    return vec3(0.0);
}

vec3 getShapeB(int idx) {
    if (idx == 0) return vec3(0.0, 0.0, 0.0);
    if (idx == 1) return vec3(0.0, 0.15, 0.15);
    if (idx == 2) return vec3(0.0, 0.0, 0.0);
    if (idx == 3) return vec3(0.0, 0.0, 0.0);
    if (idx == 4) return vec3(0.0, 0.0, 0.25);
    if (idx == 5) return vec3(0.55, 0.0, 0.0);
    if (idx == 6) return vec3(0.0, 0.75, 0.75);
    if (idx == 7) return vec3(0.45, 0.35, 0.35);
    if (idx == 8) return vec3(0.35, 0.7, 0.0);
    if (idx == 9) return vec3(0.35, 0.0, 0.7);
    if (idx == 10) return vec3(0.35, 0.35, 0.35);
    if (idx == 11) return vec3(0.0, 0.75, 0.75);
    if (idx == 12) return vec3(0.55, 0.45, 0.65);
    if (idx == 13) return vec3(0.35, 0.35, 0.35);
    if (idx == 14) return vec3(0.4, 0.2, 0.2);
    if (idx == 15) return vec3(0.0, 0.35, 0.1);
    if (idx == 16) return vec3(0.45, 0.35, 0.35);
    if (idx == 17) return vec3(0.45, 0.45, 0.45);
    if (idx == 18) return vec3(0.45, 0.55, 0.55);
    if (idx == 19) return vec3(0.3, 0.25, 0.25);
    if (idx == 20) return vec3(0.1, 0.1, 0.35);
    if (idx == 21) return vec3(0.1, 0.35, 0.1);
    if (idx == 22) return vec3(0.75, 0.65, 0.65);
    if (idx == 23) return vec3(0.85, 0.65, 0.65);
    if (idx == 24) return vec3(0.7, 0.75, 0.75);
    if (idx == 25) return vec3(0.75, 0.85, 0.85);
    return vec3(0.0);
}

int getCharBitmap(int idx) {
    if (idx == 0) return 0;
    if (idx == 1) return 4;
    if (idx == 2) return 4194304;
    if (idx == 3) return 1048576;
    if (idx == 4) return 16;
    if (idx == 5) return 14336;
    if (idx == 6) return 31;
    if (idx == 7) return 4473924;
    if (idx == 8) return 1180434;
    if (idx == 9) return 17043521;
    if (idx == 10) return 18667550;
    if (idx == 11) return 1082401;
    if (idx == 12) return 4767792;
    if (idx == 13) return 4539953;
    if (idx == 14) return 4461841;
    if (idx == 15) return 459822;
    if (idx == 16) return 476718;
    if (idx == 17) return 9879666;
    if (idx == 18) return 493614;
    if (idx == 19) return 4198532;
    if (idx == 20) return 4917796;
    if (idx == 21) return 1320196;
    if (idx == 22) return 11512810;
    if (idx == 23) return 15652782;
    if (idx == 24) return 18732593;
    if (idx == 25) return 18405233;
    return 0;
}

float renderChar(int bitmap, vec2 p) {
    p = floor(p * vec2(5.0, 5.0));
    if (p.x < 0.0 || p.y < 0.0 || p.x >= 5.0 || p.y >= 5.0) return 0.0;

    int idx = int(p.x) + int(p.y) * 5;
    int powerOfTwo = 1;
    for (int i = 0; i < 25; i++) {
        if (i >= idx) break;
        powerOfTwo *= 2;
    }
    return mod(floor(float(bitmap) / float(powerOfTwo)), 2.0);
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

    for (int i = 0; i < NUM_CHARS; i++) {
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
// WAVE PATTERN - Horizontal bands with wavy edges
// Similar to Alex Harri's luminance wave demo
// ============================================================

float wavePattern(vec2 uv, float t) {
    // Create horizontal bands with sine wave distortion
    float y = uv.y;

    // Add wave distortion to y
    float wave1 = sin(uv.x * 6.0 + t) * 0.08;
    float wave2 = sin(uv.x * 3.0 - t * 0.7) * 0.05;
    float wave3 = sin(uv.x * 12.0 + t * 1.5) * 0.02;

    y += wave1 + wave2 + wave3;

    // Create smooth bands (0 to 1 repeating)
    float bands = fract(y * 4.0);

    // Smooth the bands into a gradient
    return bands;
}

// Sample brightness at a point
float sampleBrightness(vec2 uv, float t) {
    return wavePattern(uv, t);
}

void main() {
    float charSize = u_charSize;
    float t = u_time * u_speed;

    // Cell coordinates
    vec2 cellCoord = floor(gl_FragCoord.xy / charSize);
    vec2 cellUV = fract(gl_FragCoord.xy / charSize);

    // Cell center in normalized coordinates
    vec2 cellCenter = (cellCoord + 0.5) * charSize / u_resolution;

    // Calculate sampling offsets
    vec2 cellSizeNorm = charSize / u_resolution;

    // 6-region sampling (staggered 2x3 grid)
    vec2 offTL = vec2(-0.25, 0.30) * cellSizeNorm;
    vec2 offTR = vec2(0.25, 0.35) * cellSizeNorm;
    vec2 offML = vec2(-0.25, -0.05) * cellSizeNorm;
    vec2 offMR = vec2(0.25, 0.0) * cellSizeNorm;
    vec2 offBL = vec2(-0.25, -0.35) * cellSizeNorm;
    vec2 offBR = vec2(0.25, -0.30) * cellSizeNorm;

    // Sample brightness at 6 positions
    float sTL = sampleBrightness(cellCenter + offTL, t);
    float sTR = sampleBrightness(cellCenter + offTR, t);
    float sML = sampleBrightness(cellCenter + offML, t);
    float sMR = sampleBrightness(cellCenter + offMR, t);
    float sBL = sampleBrightness(cellCenter + offBL, t);
    float sBR = sampleBrightness(cellCenter + offBR, t);

    // Pack into vec3 pairs
    vec3 sampleA = vec3(sTL, sTR, sML);
    vec3 sampleB = vec3(sMR, sBL, sBR);

    // Apply contrast enhancement
    applyContrast(sampleA, sampleB, u_contrast);

    // Find best character
    int bestCharIdx = findBestChar(sampleA, sampleB);
    int bitmap = getCharBitmap(bestCharIdx);

    // Render the character
    float pixel = renderChar(bitmap, cellUV);

    // Get average brightness for coloring
    float avgBrightness = (sTL + sTR + sML + sMR + sBL + sBR) / 6.0;

    // Color: white on black, brightness affects intensity
    vec3 charColor = vec3(0.9, 0.95, 1.0) * (0.5 + avgBrightness * 0.5);

    vec3 color = pixel * charColor;

    // Show original pattern on right side for comparison
    vec2 uv = gl_FragCoord.xy / u_resolution;
    if (uv.x > 0.5) {
        // Right half: show the original smooth pattern
        float pattern = wavePattern(uv, t);
        color = vec3(pattern);

        // Draw divider line
        if (abs(uv.x - 0.5) < 0.002) {
            color = vec3(0.3, 0.5, 1.0);
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

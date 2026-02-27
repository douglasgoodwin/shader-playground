precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_contrast;
uniform float u_charSize;
uniform float u_speed;
uniform sampler2D u_fontAtlas;
uniform float u_numChars;
uniform float u_atlasSize;

// ============================================================
// 6D SHAPE VECTORS for character selection
// These must match the character order in the JavaScript font atlas
// Characters: ' .\'-|/\_iczu1UBMW@#' (19 chars)
// Index:      0  1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
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

// Wave pattern - horizontal bands with wavy edges
float wavePattern(vec2 uv, float t) {
    float y = uv.y;
    float wave1 = sin(uv.x * 6.0 + t) * 0.6;
    float wave2 = sin(uv.x * 3.0 - t * 0.7) * 0.4;
    float wave3 = sin(uv.x * 10.0 + t * 1.5) * 0.15;
    y += wave1 + wave2 + wave3;
    return fract(y * 4.0);
}

void main() {
    float charSize = u_charSize;
    float t = u_time * u_speed;

    vec2 cellCoord = floor(gl_FragCoord.xy / charSize);
    vec2 cellUV = fract(gl_FragCoord.xy / charSize);
    vec2 cellCenter = (cellCoord + 0.5) * charSize / u_resolution;
    vec2 cellSizeNorm = charSize / u_resolution;

    // 6-region sampling (staggered 2x3 grid)
    vec2 offTL = vec2(-0.25, 0.30) * cellSizeNorm;
    vec2 offTR = vec2(0.25, 0.35) * cellSizeNorm;
    vec2 offML = vec2(-0.25, -0.05) * cellSizeNorm;
    vec2 offMR = vec2(0.25, 0.0) * cellSizeNorm;
    vec2 offBL = vec2(-0.25, -0.35) * cellSizeNorm;
    vec2 offBR = vec2(0.25, -0.30) * cellSizeNorm;

    float sTL = wavePattern(cellCenter + offTL, t);
    float sTR = wavePattern(cellCenter + offTR, t);
    float sML = wavePattern(cellCenter + offML, t);
    float sMR = wavePattern(cellCenter + offMR, t);
    float sBL = wavePattern(cellCenter + offBL, t);
    float sBR = wavePattern(cellCenter + offBR, t);

    vec3 sampleA = vec3(sTL, sTR, sML);
    vec3 sampleB = vec3(sMR, sBL, sBR);

    applyContrast(sampleA, sampleB, u_contrast);

    int bestCharIdx = findBestChar(sampleA, sampleB);

    // Sample from font atlas
    float pixel = sampleChar(bestCharIdx, cellUV);

    float avgBrightness = (sTL + sTR + sML + sMR + sBL + sBR) / 6.0;

    // Color similar to Alex's demo - light blue/white on dark
    vec3 charColor = vec3(0.7, 0.85, 1.0);
    vec3 color = pixel * charColor;

    // Show original pattern on right side for comparison
    vec2 uv = gl_FragCoord.xy / u_resolution;
    if (uv.x > 0.5) {
        float pattern = wavePattern(uv, t);
        // Blue gradient like Alex's demo
        vec3 darkBlue = vec3(0.05, 0.1, 0.3);
        vec3 lightBlue = vec3(0.4, 0.7, 0.85);
        color = mix(darkBlue, lightBlue, pattern);

        // Divider line
        if (abs(uv.x - 0.5) < 0.003) {
            color = vec3(0.2, 0.3, 0.4);
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

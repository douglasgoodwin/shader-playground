precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_imageSize;
uniform sampler2D u_image;
uniform sampler2D u_fontAtlas;
uniform float u_numChars;
uniform float u_contrast;
uniform float u_charSize;

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

// Sample image brightness at UV coordinates
float sampleBrightness(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    vec3 color = texture2D(u_image, uv).rgb;
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    float charSize = u_charSize;

    // Calculate image display area (fit to screen, centered)
    float screenAspect = u_resolution.x / u_resolution.y;
    float imageAspect = u_imageSize.x / u_imageSize.y;

    vec2 scale;
    vec2 offset;

    if (screenAspect > imageAspect) {
        scale = vec2(imageAspect / screenAspect, 1.0);
        offset = vec2((1.0 - scale.x) * 0.5, 0.0);
    } else {
        scale = vec2(1.0, screenAspect / imageAspect);
        offset = vec2(0.0, (1.0 - scale.y) * 0.5);
    }

    // Cell coordinates
    vec2 cellCoord = floor(gl_FragCoord.xy / charSize);
    vec2 cellUV = fract(gl_FragCoord.xy / charSize);

    // Cell center in normalized screen coordinates
    vec2 cellCenter = (cellCoord + 0.5) * charSize / u_resolution;

    // Convert to image UV
    vec2 imageUV = (cellCenter - offset) / scale;

    // Check if we're outside the image bounds
    if (imageUV.x < 0.0 || imageUV.x > 1.0 || imageUV.y < 0.0 || imageUV.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Flip Y for image coordinates
    imageUV.y = 1.0 - imageUV.y;

    // Calculate sampling offsets in image space
    vec2 cellSizeInImage = charSize / u_resolution / scale;

    // 6-region sampling (staggered 2x3 grid)
    vec2 offTL = vec2(-0.25, -0.30) * cellSizeInImage;
    vec2 offTR = vec2(0.25, -0.35) * cellSizeInImage;
    vec2 offML = vec2(-0.25, 0.05) * cellSizeInImage;
    vec2 offMR = vec2(0.25, 0.0) * cellSizeInImage;
    vec2 offBL = vec2(-0.25, 0.35) * cellSizeInImage;
    vec2 offBR = vec2(0.25, 0.30) * cellSizeInImage;

    // Sample brightness at 6 positions
    float sTL = sampleBrightness(imageUV + offTL);
    float sTR = sampleBrightness(imageUV + offTR);
    float sML = sampleBrightness(imageUV + offML);
    float sMR = sampleBrightness(imageUV + offMR);
    float sBL = sampleBrightness(imageUV + offBL);
    float sBR = sampleBrightness(imageUV + offBR);

    // Pack into vec3 pairs
    vec3 sampleA = vec3(sTL, sTR, sML);
    vec3 sampleB = vec3(sMR, sBL, sBR);

    // Apply contrast enhancement
    applyContrast(sampleA, sampleB, u_contrast);

    // Find best character
    int bestCharIdx = findBestChar(sampleA, sampleB);

    // Render the character from font atlas
    float pixel = sampleChar(bestCharIdx, cellUV);

    // Get average brightness for coloring
    float avgBrightness = (sTL + sTR + sML + sMR + sBL + sBR) / 6.0;

    // Sample original color for tinting
    vec3 originalColor = texture2D(u_image, imageUV).rgb;

    // Preserve original colors
    vec3 charColor = originalColor * (0.7 + avgBrightness * 0.3);

    // Boost saturation slightly
    float gray = dot(charColor, vec3(0.299, 0.587, 0.114));
    charColor = mix(vec3(gray), charColor, 1.3);

    vec3 color = pixel * charColor;

    gl_FragColor = vec4(color, 1.0);
}

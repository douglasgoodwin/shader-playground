precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_density;
uniform float u_circleSize;
uniform float u_contrast;
uniform float u_jitter;
uniform float u_ellipse;    // 1.0 = circle, >1 = elongated along edges
uniform vec3 u_bgColor;

#include "/lygia/generative/random.glsl"

// Sample image luminance with aspect ratio correction
float sampleLuminance(vec2 uv) {
    float canvasAspect = u_resolution.x / u_resolution.y;
    float texAspect = u_textureSize.x / u_textureSize.y;

    vec2 texUV = uv;
    if (canvasAspect > texAspect) {
        float scale = texAspect / canvasAspect;
        texUV.x = (uv.x - 0.5) / scale + 0.5;
    } else {
        float scale = canvasAspect / texAspect;
        texUV.y = (uv.y - 0.5) / scale + 0.5;
    }

    if (texUV.x < 0.0 || texUV.x > 1.0 || texUV.y < 0.0 || texUV.y > 1.0) {
        return 1.0;
    }

    // Flip Y — WebGL textures have origin at bottom-left, images at top-left
    texUV.y = 1.0 - texUV.y;

    vec3 color = texture2D(u_texture, texUV).rgb;
    float lum = dot(color, vec3(0.299, 0.587, 0.114));

    lum = (lum - 0.5) * u_contrast + 0.5;
    return clamp(lum, 0.0, 1.0);
}

// Multi-scale gradient — finds edge direction even from deep inside shapes.
// Samples at 3 scales: local (~2px), medium (~1 cell), large (~4 cells).
// Returns the gradient with strongest magnitude across all scales.
// Only 12 texture reads total, computed once per pixel.
vec2 multiScaleGradient(vec2 uv, float cellSize) {
    vec2 best = vec2(0.0);
    float bestMag = 0.0;

    // Scale 1: local edges (~2px)
    vec2 e1 = vec2(2.0) / u_resolution;
    vec2 g1 = vec2(
        sampleLuminance(uv + vec2(e1.x, 0.0)) - sampleLuminance(uv - vec2(e1.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e1.y)) - sampleLuminance(uv - vec2(0.0, e1.y))
    );
    float m1 = length(g1);
    if (m1 > bestMag) { bestMag = m1; best = g1; }

    // Scale 2: medium (~1 cell width)
    vec2 e2 = vec2(cellSize) / u_resolution;
    vec2 g2 = vec2(
        sampleLuminance(uv + vec2(e2.x, 0.0)) - sampleLuminance(uv - vec2(e2.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e2.y)) - sampleLuminance(uv - vec2(0.0, e2.y))
    );
    float m2 = length(g2);
    if (m2 > bestMag) { bestMag = m2; best = g2; }

    // Scale 3: large (~4 cell widths, reaches edges from deep interior)
    vec2 e3 = vec2(cellSize * 4.0) / u_resolution;
    vec2 g3 = vec2(
        sampleLuminance(uv + vec2(e3.x, 0.0)) - sampleLuminance(uv - vec2(e3.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e3.y)) - sampleLuminance(uv - vec2(0.0, e3.y))
    );
    float m3 = length(g3);
    if (m3 > bestMag) { bestMag = m3; best = g3; }

    return best;
}

// Ellipse ring — distance from ellipse boundary, oriented by angle
float ellipseRing(vec2 p, vec2 center, float radius, float ratio, float angle, float thickness, float aa) {
    vec2 d = p - center;
    float c = cos(angle);
    float s = sin(angle);
    vec2 rotated = vec2(c * d.x + s * d.y, -s * d.x + c * d.y);
    // Scale gradient-direction axis → narrower there, elongated perpendicular (along edge)
    rotated.x *= ratio;
    float dist = abs(length(rotated) - radius);
    return 1.0 - smoothstep(thickness * 0.5 - aa, thickness * 0.5 + aa, dist);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 pixel = gl_FragCoord.xy;

    vec3 finalColor = u_bgColor;

    // Grid cell size in pixels
    float cellPx = 40.0 / u_density;

    float aa = 1.2;
    float strokeWidth = 2.5;
    const int NUM_CIRCLES = 5;

    // Compute gradient ONCE per pixel at multiple scales (12 texture reads)
    // This gives edge direction even from deep inside dark shapes
    vec2 grad = multiScaleGradient(uv, cellPx);
    float gradMag = length(grad);
    float gradAngle = atan(grad.y, grad.x);
    float edgeStrength = smoothstep(0.01, 0.15, gradMag);

    // Ellipse ratio: blend from circle (1) toward u_ellipse based on edge strength
    // In completely flat areas (no edge detected at any scale), stays circular
    float ratio = mix(1.0, u_ellipse, edgeStrength);

    // Search +-2 cells (25 cells × 5 circles = 125 iterations, 25 texture reads)
    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            vec2 cellID = floor(pixel / cellPx) + vec2(float(dx), float(dy));
            vec2 cellOrigin = cellID * cellPx;
            vec2 cellCenter = cellOrigin + cellPx * 0.5;

            vec2 sampleUV = cellCenter / u_resolution;
            float lum = sampleLuminance(sampleUV);
            float darkness = 1.0 - lum;

            if (darkness < 0.08) continue;

            // Per-cell angle: use gradient direction with random fallback
            float fallbackAngle = random(cellID + 99.0) * 3.14159;
            float angle = mix(fallbackAngle, gradAngle, edgeStrength);

            float circleCount = darkness * float(NUM_CIRCLES);

            for (int k = 0; k < NUM_CIRCLES; k++) {
                if (float(k) >= circleCount) break;

                float kf = float(k);
                vec2 seed2 = cellID * 17.31 + kf * 5.7;
                float seed = random(seed2);
                vec2 seedVec = random2(seed2 + 3.1);

                vec2 baseOffset = (seedVec * 2.0 - 1.0) * cellPx * 0.4;

                float freq1 = 1.0 + seed * 2.5;
                float freq2 = 1.3 + random(seed2 + 7.0) * 2.5;
                vec2 animOffset = vec2(
                    sin(u_time * freq1 + seed * 6.28),
                    cos(u_time * freq2 + seed * 3.14)
                ) * cellPx * 0.12 * u_jitter;

                vec2 center = cellCenter + baseOffset + animOffset;

                float baseRadius = darkness * cellPx * (0.6 + seedVec.x * 0.8) * u_circleSize;
                float rWobble = sin(u_time * (1.5 + seed * 2.0) + kf * 1.7) * cellPx * 0.06 * u_jitter;
                float radius = max(baseRadius + rWobble, 2.0);

                // Per-circle angle variation for organic feel
                float circleAngle = angle + (seed - 0.5) * 0.4;

                float alpha = ellipseRing(pixel, center, radius, ratio, circleAngle, strokeWidth, aa);

                if (alpha > 0.0) {
                    finalColor = mix(finalColor, vec3(1.0), alpha * 0.9);
                }
            }
        }
    }

    gl_FragColor = vec4(finalColor, 1.0);
}

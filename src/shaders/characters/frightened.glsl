precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_blinkSpeed;
uniform float u_sizeVariation;

// Circle SDF
float sdCircle(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}

// Smooth minimum for metaball blending
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Repulsion force from one blob to another
vec2 repel(vec2 pos, vec2 other, float minDist) {
    vec2 diff = pos - other;
    float dist = length(diff);
    if (dist < minDist && dist > 0.001) {
        return normalize(diff) * (minDist - dist) * 0.5;
    }
    return vec2(0.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    float t = u_time;

    // Tiny nervous trembling for the whole group
    vec2 tremble = vec2(
        sin(t * 1.70) * 0.002 + sin(t * 2.30) * 0.001,
        cos(t * 1.90) * 0.002 + cos(t * 2.90) * 0.001
    );

    // Base positions - arranged in a loose ring that orbits slowly
    float spread = 0.09;
    vec2 base1 = vec2(cos(t * 0.3 + 0.0) * spread, sin(t * 0.3 + 0.0) * spread);
    vec2 base2 = vec2(cos(t * 0.3 + 1.05) * spread, sin(t * 0.03 + 1.05) * spread);
    vec2 base3 = vec2(cos(t * 0.3 + 2.1) * spread, sin(t * 0.03 + 2.1) * spread);
    vec2 base4 = vec2(cos(t * 0.3 + 3.15) * spread, sin(t * 0.3 + 3.15) * spread);
    vec2 base5 = vec2(cos(t * 0.3 + 4.2) * spread, sin(t * 0.03 + 4.2) * spread);
    vec2 base6 = vec2(cos(t * 0.3 + 5.25) * spread, sin(t * 0.3 + 5.25) * spread);

    // Add individual nervous jitter
    base1 += vec2(sin(t * 2.1) * 0.015, cos(t * 2.3) * 0.012);
    base2 += vec2(sin(t * 2.4 + 1.0) * 0.0013, cos(t * 2.0 + 1.0) * 0.0014);
    base3 += vec2(sin(t * 1.9 + 2.0) * 0.0014, cos(t * 2.5 + 2.0) * 0.0011);
    base4 += vec2(sin(t * 2.2 + 3.0) * 0.0012, cos(t * 1.8 + 3.0) * 0.0015);
    base5 += vec2(sin(t * 2.6 + 4.0) * 0.0011, cos(t * 2.1 + 4.0) * 0.0013);
    base6 += vec2(sin(t * 1.7 + 5.0) * 0.0015, cos(t * 2.4 + 5.0) * 0.0012);

    // Radius with variation controlled by uniform
    float baseRadius = 0.042;
    float variation = u_sizeVariation * 0.015;
    float r1 = baseRadius + sin(t * 1.7) * variation;
    float r2 = baseRadius + sin(t * 2.1 + 1.0) * variation;
    float r3 = baseRadius + sin(t * 1.9 + 2.0) * variation;
    float r4 = baseRadius + sin(t * 2.3 + 3.0) * variation;
    float r5 = baseRadius + sin(t * 1.8 + 4.0) * variation;
    float r6 = baseRadius + sin(t * 2.0 + 5.0) * variation;
    float avgRadius = baseRadius;
    float minDist = avgRadius * 0.02; // Minimum distance between blob centers

    // Apply repulsion iteratively (fake physics)
    vec2 blob1 = base1, blob2 = base2, blob3 = base3;
    vec2 blob4 = base4, blob5 = base5, blob6 = base6;

    // Several iterations of repulsion
    for (int i = 0; i < 4; i++) {
        vec2 r1 = repel(blob1, blob2, minDist) + repel(blob1, blob3, minDist) + repel(blob1, blob4, minDist) + repel(blob1, blob5, minDist) + repel(blob1, blob6, minDist);
        vec2 r2 = repel(blob2, blob1, minDist) + repel(blob2, blob3, minDist) + repel(blob2, blob4, minDist) + repel(blob2, blob5, minDist) + repel(blob2, blob6, minDist);
        vec2 r3 = repel(blob3, blob1, minDist) + repel(blob3, blob2, minDist) + repel(blob3, blob4, minDist) + repel(blob3, blob5, minDist) + repel(blob3, blob6, minDist);
        vec2 r4 = repel(blob4, blob1, minDist) + repel(blob4, blob2, minDist) + repel(blob4, blob3, minDist) + repel(blob4, blob5, minDist) + repel(blob4, blob6, minDist);
        vec2 r5 = repel(blob5, blob1, minDist) + repel(blob5, blob2, minDist) + repel(blob5, blob3, minDist) + repel(blob5, blob4, minDist) + repel(blob5, blob6, minDist);
        vec2 r6 = repel(blob6, blob1, minDist) + repel(blob6, blob2, minDist) + repel(blob6, blob3, minDist) + repel(blob6, blob4, minDist) + repel(blob6, blob5, minDist);

        blob1 += r1; blob2 += r2; blob3 += r3;
        blob4 += r4; blob5 += r5; blob6 += r6;
    }

    // Add global tremble
    blob1 += tremble; blob2 += tremble; blob3 += tremble;
    blob4 += tremble; blob5 += tremble; blob6 += tremble;

    // Pastel colors for each blob
    vec3 col1 = vec3(0.95, 0.75, 0.80); // Soft pink
    vec3 col2 = vec3(0.75, 0.85, 0.95); // Soft blue
    vec3 col3 = vec3(0.85, 0.95, 0.80); // Soft green
    vec3 col4 = vec3(0.95, 0.90, 0.75); // Soft yellow
    vec3 col5 = vec3(0.88, 0.78, 0.95); // Soft lavender
    vec3 col6 = vec3(0.78, 0.92, 0.90); // Soft mint

    // Background - soft warm grey
    vec3 bg = vec3(0.4, 0.4, 0.5);
    vec3 color = bg;

    // Distance fields for each blob
    float d1 = sdCircle(uv, blob1, r1);
    float d2 = sdCircle(uv, blob2, r2);
    float d3 = sdCircle(uv, blob3, r3);
    float d4 = sdCircle(uv, blob4, r4);
    float d5 = sdCircle(uv, blob5, r5);
    float d6 = sdCircle(uv, blob6, r6);

    // Smooth blend all into one metaball shape
    float k = 0.04; // Blend smoothness
    float d = d1;
    d = smin(d, d2, k);
    d = smin(d, d3, k);
    d = smin(d, d4, k);
    d = smin(d, d5, k);
    d = smin(d, d6, k);

    // Blend colors based on proximity to each blob
    if (d < 0.02) {
        float w1 = 1.0 / (0.01 + max(0.0, d1));
        float w2 = 1.0 / (0.01 + max(0.0, d2));
        float w3 = 1.0 / (0.01 + max(0.0, d3));
        float w4 = 1.0 / (0.01 + max(0.0, d4));
        float w5 = 1.0 / (0.01 + max(0.0, d5));
        float w6 = 1.0 / (0.01 + max(0.0, d6));
        float wTotal = w1 + w2 + w3 + w4 + w5 + w6;

        vec3 blobColor = (col1 * w1 + col2 * w2 + col3 * w3 + col4 * w4 + col5 * w5 + col6 * w6) / wTotal;
        float edge = smoothstep(0.02, -0.01, d);
        color = mix(bg, blobColor, edge);
    }

    // Eyes - two on each blob, looking nervously
    vec2 lookDir = vec2(sin(t * 2.1), cos(t * 1.7)) * 0.004;
    float eyeRadius = 0.006;
    float eyeSpread = 0.011;

    // Blink - brief close then back open, speed controlled by uniform
    float blinkPeriod = 3.5 / max(u_blinkSpeed, 0.01);
    float blinkCycle = mod(t, blinkPeriod);
    float blinkDuration = 0.12;
    float blinkMid = 0.06;
    // Close then open: eyes stay open except during brief blink
    float closing = smoothstep(0.0, blinkMid, blinkCycle);
    float opening = smoothstep(blinkMid, blinkDuration, blinkCycle);
    float blink = 1.0 - closing * (1.0 - opening);
    float eyeHeight = eyeRadius * blink; // Squash eye vertically when blinking

    vec2 eyeUp = vec2(0.0, 0.015) + lookDir;
    vec2 eyeL = vec2(-eyeSpread, 0.0);
    vec2 eyeR = vec2(eyeSpread, 0.0);

    // Draw eyes on each blob (squash vertically when blinking)
    // Only draw eyes inside the combined metaball shape
    vec2 eyeScale = vec2(1.0, blink + 0.01);

    if (d < 0.0) {
        vec2 e1L = (uv - blob1 - eyeUp - eyeL) / eyeScale;
        vec2 e1R = (uv - blob1 - eyeUp - eyeR) / eyeScale;
        vec2 e2L = (uv - blob2 - eyeUp - eyeL) / eyeScale;
        vec2 e2R = (uv - blob2 - eyeUp - eyeR) / eyeScale;
        vec2 e3L = (uv - blob3 - eyeUp - eyeL) / eyeScale;
        vec2 e3R = (uv - blob3 - eyeUp - eyeR) / eyeScale;
        vec2 e4L = (uv - blob4 - eyeUp - eyeL) / eyeScale;
        vec2 e4R = (uv - blob4 - eyeUp - eyeR) / eyeScale;
        vec2 e5L = (uv - blob5 - eyeUp - eyeL) / eyeScale;
        vec2 e5R = (uv - blob5 - eyeUp - eyeR) / eyeScale;
        vec2 e6L = (uv - blob6 - eyeUp - eyeL) / eyeScale;
        vec2 e6R = (uv - blob6 - eyeUp - eyeR) / eyeScale;

        if (length(e1L) < eyeRadius) color = vec3(0.1);
        if (length(e1R) < eyeRadius) color = vec3(0.2);
        if (length(e2L) < eyeRadius) color = vec3(0.3);
        if (length(e2R) < eyeRadius) color = vec3(0.4);
        if (length(e3L) < eyeRadius) color = vec3(0.5);
        if (length(e3R) < eyeRadius) color = vec3(0.6);
        if (length(e4L) < eyeRadius) color = vec3(0.7);
        if (length(e4R) < eyeRadius) color = vec3(0.8);
        if (length(e5L) < eyeRadius) color = vec3(0.9);
        if (length(e5R) < eyeRadius) color = vec3(0.9);
        if (length(e6L) < eyeRadius) color = vec3(0.5);
        if (length(e6R) < eyeRadius) color = vec3(0.5);
    }

    gl_FragColor = vec4(color, 1.0);
}

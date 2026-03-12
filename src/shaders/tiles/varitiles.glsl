#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

#define WEDGE_COUNT 12

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 palette(float t) {
    vec3 a = vec3(0.60, 0.10, 0.80);
    vec3 b = vec3(0.50, 0.90, 0.20);
    vec3 c = vec3(1.00, 0.90, 0.80);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.2831853 * (c * t + d));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 p  = (fragCoord - 0.5 * u_resolution) / u_resolution.y;
    float r = length(p);

    float a   = atan(p.y, p.x);
    float ang = (a + 3.14159265) / (2.0 * 3.14159265); // [0,1)

    // Discrete “frames”
    float fps   = 2.0;                 // try 1.0–4.0
    float frame = floor(u_time * fps);
    float seed  = frame * 37.17;

    // Controls
    float rings   = 14.0;
    float gapBase = 0.015;

    // -------------------------------------------------------
    // 1) Build non-uniform wedge partition for this frame
    // -------------------------------------------------------
    float weightsSum = 0.0;
    for (int i = 0; i < WEDGE_COUNT; i++) {
        float w = 0.25 + 1.75 * hash11(seed + float(i) * 11.3); // positive
        weightsSum += w;
    }

    // Find which wedge 'ang' falls into and the local coordinate within it
    float accum = 0.0;
    float wedgeStart = 0.0;
    float wedgeWidth = 1.0 / float(WEDGE_COUNT);
    float wa = 0.0;

    for (int i = 0; i < WEDGE_COUNT; i++) {
        float w = 0.25 + 1.75 * hash11(seed + float(i) * 11.3);
        float width = w / weightsSum; // normalized
        float nextAccum = accum + width;

        // Branchless-ish selection: set when ang is in [accum, nextAccum)
        float inWedge = step(accum, ang) * (1.0 - step(nextAccum, ang));

        wedgeStart = mix(wedgeStart, accum, inWedge);
        wedgeWidth = mix(wedgeWidth, width, inWedge);
        wa = mix(wa, float(i), inWedge);

        accum = nextAccum;
    }

    // Local wedge coordinate in [0,1)
    float fa = (ang - wedgeStart) / max(wedgeWidth, 1e-5);

    // -------------------------------------------------------
    // 2) Per-wedge / per-frame radial quantization (rings)
    // -------------------------------------------------------
    float wedgeJitter = mix(0.6, 1.4, hash11(wa + 10.0 + seed));
    float localRings  = rings * wedgeJitter;

    float rw = pow(r, mix(0.85, 1.25, hash11(wa + 30.0)));
    float wr = floor(rw * localRings);
    float fr = fract(rw * localRings);

    vec2 cell = vec2(wa, wr);

    // -------------------------------------------------------
    // 3) Variable radial-line thickness per wedge (optional)
    // -------------------------------------------------------
    float sliceWidth = mix(0.6, 2.2, hash11(wa + 100.0));
    float radialFreq  = mix(1.0, 6.0, hash11(wa + 200.0));
    float radialPhase = 6.2831853 * hash11(wa + 300.0);
    float radialMod   = 0.65 + 0.55 * sin(radialFreq * r * 6.2831853 + radialPhase);

    float gapA = gapBase * sliceWidth * radialMod;
    float gapR = gapBase;

    // Separators (black)
    float edgeA = smoothstep(0.0, gapA, fa) * smoothstep(0.0, gapA, 1.0 - fa);
    float edgeR = smoothstep(0.0, gapR, fr) * smoothstep(0.0, gapR, 1.0 - fr);
    float mask  = edgeA * edgeR;

    // Holes and color, frame-dependent
    float drop = step(0.10, hash21(cell + vec2(2.0, seed)));
    float t    = hash21(cell + vec2(7.0, seed));
    vec3 col   = palette(t);
    col *= mix(0.85, 1.15, hash11(wr + wa * 17.0));

    // Disc boundary
    float disc = smoothstep(0.98, 0.96, r);

    vec3 outCol = mix(vec3(0.0), col, mask * drop) * disc;
    gl_FragColor = vec4(outCol, 1.0);
}
// Datamosh: simulate the codec-glitch aesthetic without touching a codec.
// Real datamoshing strips I-frames so motion vectors from one scene get
// applied to pixel data from another, smearing it. We mimic that by:
//   1. Estimating optical flow between the current and previous source frame
//      using gradient-based "normal flow" (Lucas-Kanade with one equation:
//      Ix*u + Iy*v + It = 0  →  flow = -It * grad / |grad|^2).
//   2. Advecting the previous output buffer along that flow.
//   3. Rarely refreshing macroblocks from the live source — fewer keyframes
//      means stale buffer content rides the motion field for longer, which
//      is what produces the characteristic smear.
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_prev;         // previous output buffer
uniform sampler2D u_source;       // current source frame
uniform sampler2D u_prevSource;   // source frame from one tick ago
uniform vec2 u_resolution;
uniform vec2 u_textureSize;
uniform int u_hasTexture;
uniform float u_time;
uniform float u_decay;
uniform float u_flowScale;        // multiplier on per-frame flow displacement
uniform float u_keyframeRate;     // 0..1 — fraction of blocks refreshed per tick
uniform float u_blockGrid;        // macroblock count along the longer axis

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 sampleProcedural(vec2 uv) {
    float t = u_time;
    float y = 0.5 + 0.35 * sin(t * 2.0);
    float bar = exp(-pow((uv.y - y) * 6.0, 2.0));
    return vec3(0.5 + 0.5 * sin(t),
                0.5 + 0.5 * sin(t * 1.3 + 2.0),
                0.5 + 0.5 * sin(t * 0.7 + 4.0)) * bar;
}

vec3 sampleSource(vec2 uv)     { return u_hasTexture == 1 ? texture2D(u_source,     uv).rgb : sampleProcedural(uv); }
vec3 samplePrevSource(vec2 uv) { return u_hasTexture == 1 ? texture2D(u_prevSource, uv).rgb : sampleProcedural(uv); }

void main() {
    vec2 srcUV = v_uv;

    // Gradient-based optical flow (single-pixel normal flow). Cheap, noisy,
    // and exactly the kind of approximate motion estimate that gives mosh
    // its character — clean flow would just look like a warp.
    vec2 px = 1.0 / max(u_textureSize, vec2(1.0));
    float lc = luma(sampleSource(srcUV));
    float lp = luma(samplePrevSource(srcUV));
    float It = lc - lp;
    float Ix = 0.5 * (luma(sampleSource(srcUV + vec2(px.x, 0.0))) -
                      luma(sampleSource(srcUV - vec2(px.x, 0.0))));
    float Iy = 0.5 * (luma(sampleSource(srcUV + vec2(0.0, px.y))) -
                      luma(sampleSource(srcUV - vec2(0.0, px.y))));
    vec2 grad = vec2(Ix, Iy);
    vec2 flow = -It * grad / (dot(grad, grad) + 0.0001);
    flow = clamp(flow, vec2(-0.05), vec2(0.05));

    // Advect last frame's buffer along the estimated flow. Because the
    // buffer holds *old* content but the flow comes from the *current*
    // source, the wrong pixels get pushed along the right paths — that's
    // the mosh.
    vec3 advected = texture2D(u_prev, v_uv - flow * u_flowScale).rgb;
    advected *= (1.0 - u_decay);

    // Macroblock keyframe injection. Each block independently rolls dice
    // each refresh tick; below the threshold it refreshes from the source.
    float grid = max(u_blockGrid, 1.0);
    vec2 block = floor(v_uv * grid) / grid;
    float refreshTick = floor(u_time * 4.0);
    float kf = step(1.0 - u_keyframeRate, hash(block + refreshTick));
    vec3 fresh = sampleSource(srcUV);

    gl_FragColor = vec4(mix(advected, fresh, kf), 1.0);
}

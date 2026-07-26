// Concentric ring rotator.
//
// The frame is cut into a stack of concentric annuli around a movable
// center. Each ring samples the source video at its own rotated angle,
// so the same footage appears at several different rotations at once.
//
// Looping is the whole point of this page, so rotation is driven by
// u_phase (0..1 across one pass of the source) times an INTEGER number
// of turns per ring. At phase 1 every ring has turned a whole number of
// times and is back where it started — exactly when the video wraps.
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_texture;
uniform vec2  u_textureSize;
uniform vec2  u_resolution;
uniform int   u_hasTexture;

uniform vec2  u_center;      // ring center, screen uv
uniform float u_phase;       // 0..1 position within the loop
uniform int   u_ringCount;   // rings in the stack, 1..MAX_RINGS
uniform float u_turns[8];    // signed integer turns per loop, per ring
uniform float u_inner;       // radius where the stack starts
uniform float u_outer;       // radius where the stack ends
uniform float u_spacing;     // 1 = equal width, 2 = equal area
uniform float u_feather;     // crossfade width at ring seams, in ring units
uniform float u_spread;      // static angular offset, ring index * spread
uniform int   u_outsideMode; // 0 = untouched source, 1 = black
uniform int   u_edgeMode;    // 0 = clamp, 1 = mirror

#define MAX_RINGS 8
#define TAU 6.28318530718

// Cover-fit UV: keep the source's aspect, fill the canvas.
vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    if (texSize.x < 1.5 || texSize.y < 1.5) return uv;
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

// Rotation pulls content in from outside the frame whenever a ring
// reaches past the edge. Mirroring reads better there than the smeared
// row of edge pixels CLAMP_TO_EDGE gives you.
// Triangle wave with period 2, so [0,1] passes through untouched and only
// the overshoot folds back. (abs(fract(uv*0.5)*2-1) looks similar but is
// inverted on [0,1] — it would flip the frame.)
vec2 mirrorUV(vec2 uv) {
    vec2 t = mod(uv, 2.0);
    return min(t, 2.0 - t);
}

vec3 sampleSource(vec2 screenUV) {
    vec2 uv = coverUV(screenUV, u_textureSize, u_resolution);
    if (u_edgeMode == 1) uv = mirrorUV(uv);
    else uv = clamp(uv, 0.0, 1.0);
    return texture2D(u_texture, uv).rgb;
}

// Sample the source as if this ring had been spun by `turns` whole
// rotations over the loop. p is the aspect-corrected offset from center,
// r its length; we rebuild the point at the same radius but a rolled-back
// angle, then undo the aspect correction to get back to screen uv.
vec3 sampleRing(float angle, float r, float turns, float ringIndex, float aspect) {
    float rolled = angle - (TAU * turns * u_phase + ringIndex * u_spread);
    vec2 q = vec2(cos(rolled), sin(rolled)) * r;
    return sampleSource(u_center + vec2(q.x / aspect, q.y));
}

// Uniform arrays can only be indexed by a constant expression in GLSL
// ES 1.00. A loop index counts as one, so walk the array and keep the
// entry that matches.
float turnsAt(int index) {
    float t = 0.0;
    for (int i = 0; i < MAX_RINGS; i++) {
        if (i == index) t = u_turns[i];
    }
    return t;
}

void main() {
    float aspect = u_resolution.x / u_resolution.y;
    vec2 p = (v_uv - u_center) * vec2(aspect, 1.0);
    float r = length(p);
    float angle = atan(p.y, p.x);

    vec3 plain = (u_hasTexture == 1) ? sampleSource(v_uv) : vec3(0.06);

    // Outside the stack, and inside the hole, the footage is left alone —
    // that contrast is what makes the rings read as cut out of it.
    if (r > u_outer) {
        gl_FragColor = vec4(u_outsideMode == 1 ? vec3(0.0) : plain, 1.0);
        return;
    }
    if (r < u_inner) {
        gl_FragColor = vec4(plain, 1.0);
        return;
    }
    if (u_hasTexture == 0) {
        gl_FragColor = vec4(plain, 1.0);
        return;
    }

    float count = float(u_ringCount);

    // Normalized position across the stack, warped by u_spacing so the
    // rings can be equal-width (1.0) or equal-area (2.0) or anywhere
    // between, then scaled up to ring units.
    float span = max(u_outer - u_inner, 1e-4);
    float rn = clamp((r - u_inner) / span, 0.0, 1.0);
    float fk = pow(rn, u_spacing) * count;

    int k = int(floor(fk));
    if (k < 0) k = 0;
    if (k > u_ringCount - 1) k = u_ringCount - 1;
    float frac = fk - floor(fk);

    vec3 color = sampleRing(angle, r, turnsAt(k), float(k), aspect);

    // Soft seams: near a boundary, crossfade with the neighbouring ring so
    // the cut dissolves instead of tearing. At feather 0 this is skipped
    // and the edges stay hard, which is usually what you want.
    if (u_feather > 0.001) {
        float f = min(u_feather, 0.5);
        int nb = k;
        float w = 0.0;
        if (frac < f) {
            nb = k - 1;
            w = 0.5 - 0.5 * (frac / f);
        } else if (frac > 1.0 - f) {
            nb = k + 1;
            w = 0.5 * ((frac - (1.0 - f)) / f);
        }
        if (nb >= 0 && nb <= u_ringCount - 1 && w > 0.0) {
            vec3 other = sampleRing(angle, r, turnsAt(nb), float(nb), aspect);
            color = mix(color, other, w);
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

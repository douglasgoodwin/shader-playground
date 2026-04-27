// Droste on feedback
// Each frame: sample the previous frame at z^α (the Escher/De-Smit-Lenstra
// complex power map) and blend with fresh video. α = 1 - i·ln(r)/(2π) makes
// one full rotation around the origin correspond to a zoom by r, so the
// feedback loop itself manufactures the mise-en-abyme self-similarity that
// Escher had to paint by hand.

precision highp float;

varying vec2 v_uv;

uniform sampler2D u_prev;
uniform sampler2D u_video;
uniform int u_hasVideo;
uniform vec2 u_videoSize;
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_zoomR;      // mise-en-abyme zoom factor (16, 64, 256…)
uniform float u_rotation;   // extra rotation of the spiral (radians)
uniform float u_decay;      // 0..1 — how strongly the previous frame persists
uniform float u_videoGain;  // 0..1 — how strongly fresh video bleeds in
uniform float u_innerHole;  // radius of central "no-warp" disk where fresh video dominates
uniform float u_twist;      // 0..1 — mix between pure zoom feedback (0) and full Droste (1)

#define PI  3.14159265359
#define TAU 6.28318530718

vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

vec2 cmul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 clog(vec2 z) {
    return vec2(0.5 * log(max(dot(z, z), 1e-20)), atan(z.y, z.x));
}

vec2 cexp(vec2 z) {
    return exp(z.x) * vec2(cos(z.y), sin(z.y));
}

void main() {
    float aspect = u_resolution.x / u_resolution.y;
    // centered, longer-axis-scaled coords so origin is screen center
    vec2 z = (v_uv - 0.5) * 2.0;
    z.x *= aspect;

    // Droste exponent. u_twist lets us cross-fade between a plain zoom feedback
    // (β = 0 → α = 1 → identity) and the full Escher spiral (β = ln(r)/2π).
    float lnR = log(max(u_zoomR, 1.001));
    float beta = u_twist * lnR / TAU;
    vec2 alpha = vec2(1.0, -beta);

    // w = z^α = exp(α · log z)
    vec2 logz = clog(z);
    vec2 aLogZ = cmul(alpha, logz);
    aLogZ.y += u_rotation;

    // Log-magnitude wrap: fold |w| into the canonical annulus [1/√r, √r] so
    // samples landing outside the screen come back through the scale period.
    // (This is the self-similar identification source ≡ source·r.)
    float period = lnR;
    aLogZ.x = mod(aLogZ.x + period * 0.5, period) - period * 0.5;

    vec2 warped = cexp(aLogZ);

    // Map back to uv space (undo aspect correction on x)
    vec2 sampleUV = vec2(warped.x / aspect, warped.y) * 0.5 + 0.5;

    // Feedback sample
    vec3 prevColor = vec3(0.0);
    if (all(greaterThanEqual(sampleUV, vec2(0.0))) && all(lessThanEqual(sampleUV, vec2(1.0)))) {
        prevColor = texture2D(u_prev, sampleUV).rgb;
    }

    // Fresh video sample (at v_uv, unwarped — this is where new content enters)
    vec3 videoColor;
    if (u_hasVideo == 1) {
        videoColor = texture2D(u_video, coverUV(v_uv, u_videoSize, u_resolution)).rgb;
    } else {
        // procedural stand-in so the page is legible without a video loaded
        float t = u_time * 0.4;
        videoColor = vec3(
            0.5 + 0.5 * sin(v_uv.x * 7.0 + t),
            0.5 + 0.5 * sin(v_uv.y * 9.0 + t * 1.3 + 2.0),
            0.5 + 0.5 * sin((v_uv.x + v_uv.y) * 11.0 + t * 0.7 + 4.0)
        );
    }

    // Inner hole: near the origin, let fresh video show through undistorted.
    // This is the ambiguous Escher center — in Path 2 it's not empty, it's
    // continuously re-painted by the live source.
    float r = length(z);
    float holeMask = 1.0 - smoothstep(u_innerHole, u_innerHole * 1.6, r);

    // Blend: feedback holds memory, video bleeds in globally, and the hole
    // forces fresh video at the ambiguous center.
    vec3 color = mix(videoColor * u_videoGain, prevColor, u_decay);
    color = mix(color, videoColor, holeMask * u_videoGain);

    gl_FragColor = vec4(color, 1.0);
}

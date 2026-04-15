// Click-to-zoom crossfade — mimics Google Maps tile transitions
precision highp float;

uniform vec2      u_resolution;
uniform vec2      u_videoSize;   // native video dimensions
uniform sampler2D u_texA;
uniform sampler2D u_texB;
uniform float     u_progress;    // 0 = idle (showing A), 1 = fully transitioned to B

const float ZOOM_MAX = 2.0;
const float BLUR_MAX = 16.0;  // max blur radius in pixels

// Multi-pass blur — 3 rings of 8 taps each for a stronger gaussian-like blur
vec4 blur(sampler2D tex, vec2 uv, vec2 texel, float radius) {
    if (radius < 0.5) return texture2D(tex, uv);

    vec4 sum = texture2D(tex, uv);
    float total = 1.0;

    // 3 concentric rings at 100%, 66%, 33% of radius
    for (float ring = 1.0; ring <= 3.0; ring += 1.0) {
        float r = radius * ring / 3.0;
        float weight = 1.0 / ring;  // inner rings weighted more
        for (float a = 0.0; a < 6.283; a += 0.785) {  // 8 angles per ring
            vec2 off = vec2(cos(a), sin(a)) * texel * r;
            sum += texture2D(tex, uv + off) * weight;
            total += weight;
        }
    }
    return sum / total;
}

// object-fit: cover — map screen UV to texture UV
vec2 coverUV(vec2 uv) {
    float screenAspect = u_resolution.x / u_resolution.y;
    float videoAspect  = u_videoSize.x / u_videoSize.y;

    vec2 scale = vec2(1.0);
    if (screenAspect > videoAspect) {
        // screen is wider than video — fit width, crop top/bottom
        scale.y = videoAspect / screenAspect;
    } else {
        // screen is taller than video — fit height, crop sides
        scale.x = screenAspect / videoAspect;
    }
    return (uv - 0.5) * scale + 0.5;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv.y = 1.0 - uv.y;  // flip for video/webcam
    vec2 texel = 1.0 / u_resolution;

    // Smooth the progress curve
    float t = u_progress * u_progress * (3.0 - 2.0 * u_progress);

    // Zoom into center of texA
    float zoom = 1.0 + (ZOOM_MAX - 1.0) * t;
    vec2 zoomedUV = (uv - 0.5) / zoom + 0.5;

    // Apply cover mapping to both
    vec2 uvA = coverUV(zoomedUV);
    vec2 uvB = coverUV(uv);

    // Blur ramps up as we zoom — peaks mid-transition, like loading low-res tiles
    float blurAmount = sin(t * 3.14159) * BLUR_MAX;
    vec4 colA = blur(u_texA, uvA, texel, blurAmount);

    // texB also starts blurry and sharpens as it fades in
    float blurB = (1.0 - t) * BLUR_MAX * 0.6;
    vec4 colB = blur(u_texB, uvB, texel, blurB);

    // Crossfade kicks in during the second half of the transition
    float blend = smoothstep(0.3, 0.8, t);

    gl_FragColor = mix(colA, colB, blend);
}

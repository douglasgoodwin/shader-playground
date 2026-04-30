// Slit-scan feedback: each frame samples one slit (column or row) from the
// live source at u_slitPos and writes it to the leading edge of the buffer;
// the rest of the buffer scrolls by u_speed pixels in the opposite direction.
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_prev;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform vec2 u_resolution;
uniform int u_hasTexture;
uniform float u_time;
uniform float u_slitPos;     // 0..1 — column (horizontal) or row (vertical)
uniform float u_speed;       // pixels per frame; also slit thickness on output
uniform float u_decay;       // 0..1 — per-frame fade applied to scrolled pixels
uniform float u_direction;   // +1 = write at trailing edge (right/bottom), -1 = inverse
uniform float u_vertical;    // 0 = horizontal scroll, 1 = vertical scroll

vec3 sampleSource(vec2 uv) {
    if (u_hasTexture == 1) return texture2D(u_texture, uv).rgb;
    // Procedural fallback: a vertically oscillating colored bar.
    // Slit-scanning it produces a sine-wave streak — useful sanity check.
    float t = u_time;
    float y = 0.5 + 0.35 * sin(t * 2.0);
    float bar = exp(-pow((uv.y - y) * 6.0, 2.0));
    vec3 c = vec3(
        0.5 + 0.5 * sin(t),
        0.5 + 0.5 * sin(t * 1.3 + 2.0),
        0.5 + 0.5 * sin(t * 0.7 + 4.0)
    );
    return c * bar;
}

void main() {
    bool vertical = u_vertical > 0.5;
    vec2 axis = vertical ? vec2(0.0, 1.0) : vec2(1.0, 0.0);
    float axisLen = vertical ? u_resolution.y : u_resolution.x;
    float pixelStep = u_speed / axisLen;

    float coord = dot(v_uv, axis);
    bool inWriteRegion = u_direction > 0.0
        ? (coord >= 1.0 - pixelStep)
        : (coord < pixelStep);

    if (inWriteRegion) {
        vec2 srcUV = vertical ? vec2(v_uv.x, u_slitPos) : vec2(u_slitPos, v_uv.y);
        gl_FragColor = vec4(sampleSource(srcUV), 1.0);
    } else {
        vec2 src = v_uv + axis * (pixelStep * u_direction);
        vec3 prev = texture2D(u_prev, src).rgb;
        gl_FragColor = vec4(prev * (1.0 - u_decay), 1.0);
    }
}

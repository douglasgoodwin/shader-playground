// Risograph printing simulation — halftone dots with overprint blending
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform int u_hasTexture;
uniform float u_intensity;
uniform float u_scale;

vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

vec3 sampleTexture(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    if (u_hasTexture == 1) return texture2D(u_texture, coverUV(uv, u_textureSize, u_resolution)).rgb;
    float t = u_time * 0.2;
    return vec3(
        0.5 + 0.4 * cos(uv.x * 6.28 + t),
        0.5 + 0.4 * cos(uv.x * 6.28 + t + 2.094),
        0.5 + 0.4 * cos(uv.x * 6.28 + t + 4.189)
    ) * (0.3 + 0.7 * uv.y);
}

// Rotate UV for halftone screen angle
vec2 rotateUV(vec2 uv, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
}

// Halftone dot: returns 0 (no ink) or 1 (ink) based on channel intensity
float halftone(vec2 fragCoord, float channel, float angle) {
    float freq = u_resolution.y * u_scale / 30.0;
    vec2 rotated = rotateUV(fragCoord, angle);
    vec2 cell = fract(rotated / freq) - 0.5;
    float dist = length(cell);
    // Larger dots for darker areas (more ink)
    float radius = channel * 0.45 * u_intensity;
    return smoothstep(radius + 0.02, radius - 0.02, dist);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 src = sampleTexture(uv);

    // Convert to CMYK
    float k = min(min(1.0 - src.r, 1.0 - src.g), 1.0 - src.b);
    float invK = 1.0 / max(1.0 - k, 0.001);
    float cyan    = (1.0 - src.r - k) * invK;
    float magenta = (1.0 - src.g - k) * invK;
    float yellow  = (1.0 - src.b - k) * invK;

    // CMYK ink colors
    vec3 inkYellow  = vec3(1.0, 0.92, 0.0);      // yellow
    vec3 inkPink    = vec3(0.95, 0.0, 0.47);      // pink/magenta
    vec3 inkBlue    = vec3(0.0, 0.60, 0.87);      // cyan/blue
    vec3 inkBlack   = vec3(0.1, 0.1, 0.1);        // key/black

    // CMYK screen angles: Y 0°, M 75°, C 15°, K 45°
    float dotYellow = halftone(gl_FragCoord.xy, yellow,  0.0);     //  0 degrees
    float dotPink   = halftone(gl_FragCoord.xy, magenta, 1.309);   // 75 degrees
    float dotBlue   = halftone(gl_FragCoord.xy, cyan,    0.262);   // 15 degrees
    float dotBlack  = halftone(gl_FragCoord.xy, k,       0.785);   // 45 degrees

    // Start with white paper, multiply each ink layer
    vec3 color = vec3(0.95, 0.93, 0.9); // slightly warm paper
    color *= mix(vec3(1.0), inkYellow, dotYellow);
    color *= mix(vec3(1.0), inkPink,   dotPink);
    color *= mix(vec3(1.0), inkBlue,   dotBlue);
    color *= mix(vec3(1.0), inkBlack,  dotBlack);

    gl_FragColor = vec4(color, 1.0);
}

// Posterize with ordered Bayer dithering
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

// 4x4 Bayer dither matrix — returns value in [-0.5, 0.5]
float bayer4(vec2 pos) {
    vec2 q = mod(floor(pos), 4.0);
    float idx = q.x + q.y * 4.0;

    // 4x4 Bayer matrix values (0-15), normalized to [0,1)
    //  0  8  2 10
    //  12 4 14  6
    //  3 11  1  9
    //  15 7 13  5
    float val;
    if (idx < 4.0) {
        if (idx < 1.0) val = 0.0;
        else if (idx < 2.0) val = 8.0;
        else if (idx < 3.0) val = 2.0;
        else val = 10.0;
    } else if (idx < 8.0) {
        if (idx < 5.0) val = 12.0;
        else if (idx < 6.0) val = 4.0;
        else if (idx < 7.0) val = 14.0;
        else val = 6.0;
    } else if (idx < 12.0) {
        if (idx < 9.0) val = 3.0;
        else if (idx < 10.0) val = 11.0;
        else if (idx < 11.0) val = 1.0;
        else val = 9.0;
    } else {
        if (idx < 13.0) val = 15.0;
        else if (idx < 14.0) val = 7.0;
        else if (idx < 15.0) val = 13.0;
        else val = 5.0;
    }

    return val / 16.0 - 0.5;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 src = sampleTexture(uv);

    // Number of quantization levels (2 to 14)
    float levels = floor(u_scale * 4.0 + 2.0);

    // Apply ordered dither before quantization
    float dither = bayer4(gl_FragCoord.xy) * u_intensity / levels;
    vec3 dithered = src + vec3(dither);

    // Quantize
    vec3 color = floor(dithered * levels + 0.5) / levels;
    color = clamp(color, 0.0, 1.0);

    gl_FragColor = vec4(color, 1.0);
}

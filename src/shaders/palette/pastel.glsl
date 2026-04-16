// Pastel palette — soft color remapping with hue preservation
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

// 5-stop pastel gradient lookup
vec3 pastelGradient(float t) {
    vec3 c0 = vec3(1.0, 0.80, 0.85);   // soft pink
    vec3 c1 = vec3(0.78, 0.72, 0.93);  // lavender
    vec3 c2 = vec3(0.70, 0.93, 0.82);  // mint
    vec3 c3 = vec3(1.0, 0.97, 0.82);   // cream
    vec3 c4 = vec3(0.68, 0.85, 0.96);  // baby blue

    t = clamp(t, 0.0, 1.0);

    if (t < 0.25) return mix(c0, c1, t / 0.25);
    if (t < 0.50) return mix(c1, c2, (t - 0.25) / 0.25);
    if (t < 0.75) return mix(c2, c3, (t - 0.50) / 0.25);
    return mix(c3, c4, (t - 0.75) / 0.25);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 src = sampleTexture(uv);

    // Luminance
    float lum = dot(src, vec3(0.299, 0.587, 0.114));

    // Scale luminance range for palette lookup
    float idx = clamp(lum * u_scale, 0.0, 1.0);

    // Slow palette rotation over time
    idx = fract(idx + u_time * 0.03);

    vec3 pastel = pastelGradient(idx);

    // Preserve some of the original hue — tint the pastel toward the source
    vec3 srcNorm = src / (max(lum, 0.01)); // original hue direction
    vec3 tinted = pastel * mix(vec3(1.0), srcNorm, 0.2);

    // Blend between original and pastel based on intensity
    vec3 color = mix(src, tinted, u_intensity);

    gl_FragColor = vec4(color, 1.0);
}

// Duotone — two-color gradient mapping with selectable palette colors
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform int u_hasTexture;
uniform float u_intensity;
uniform float u_scale;
uniform vec3 u_colorA;
uniform vec3 u_colorB;

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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 src = sampleTexture(uv);

    // Luminance
    float lum = dot(src, vec3(0.299, 0.587, 0.114));

    // Contrast curve
    float mid = 0.5;
    float range = max(u_intensity, 0.05);
    lum = smoothstep(mid - range * 0.5, mid + range * 0.5, lum);

    // Map between the two selected colors
    vec3 color = mix(u_colorA, u_colorB, lum);

    gl_FragColor = vec4(color, 1.0);
}

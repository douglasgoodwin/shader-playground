// Thermal / infrared camera palette
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

// 7-stop thermal gradient
vec3 thermalGradient(float t) {
    vec3 c0 = vec3(0.0, 0.0, 0.0);         // black (cold)
    vec3 c1 = vec3(0.0, 0.0, 0.5);         // deep blue
    vec3 c2 = vec3(0.5, 0.0, 0.5);         // purple
    vec3 c3 = vec3(1.0, 0.0, 0.0);         // red
    vec3 c4 = vec3(1.0, 0.5, 0.0);         // orange
    vec3 c5 = vec3(1.0, 1.0, 0.0);         // yellow
    vec3 c6 = vec3(1.0, 1.0, 1.0);         // white (hot)

    t = clamp(t, 0.0, 1.0);
    float s = t * 6.0;
    int i = int(floor(s));
    float f = fract(s);

    if (i == 0) return mix(c0, c1, f);
    if (i == 1) return mix(c1, c2, f);
    if (i == 2) return mix(c2, c3, f);
    if (i == 3) return mix(c3, c4, f);
    if (i == 4) return mix(c4, c5, f);
    return mix(c5, c6, f);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 src = sampleTexture(uv);

    // Luminance
    float lum = dot(src, vec3(0.299, 0.587, 0.114));

    // Contrast/sensitivity curve
    float contrast = u_intensity * 2.0;
    lum = pow(lum, max(contrast, 0.1));

    // Scale the thermal range
    lum = clamp(lum * u_scale, 0.0, 1.0);

    vec3 color = thermalGradient(lum);

    gl_FragColor = vec4(color, 1.0);
}
